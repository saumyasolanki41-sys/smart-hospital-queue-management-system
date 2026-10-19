const AmbulanceRequest = require('../models/AmbulanceRequest');
const Ambulance = require('../models/Ambulance');
const travel = require('./travel.service');
const ml = require('./ml.service');

function unavailable(reason) {
  return { etaMinutes: null, source: 'unavailable', reason };
}

async function getEta(user, id, query) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id) || Object.keys(query).length) {
    throw Object.assign(new Error('Send a valid request ID with no query fields.'), { status: 400, code: 'VALIDATION_ERROR' });
  }
  const filter = { _id: id };
  if (user.role === 'patient') filter.patient = user.id;
  const request = await AmbulanceRequest.findOne(filter).select('status ambulance latitude longitude').lean();
  if (!request) throw Object.assign(new Error('Ambulance request not found.'), { status: 404, code: 'REQUEST_NOT_FOUND' });
  if (request.status !== 'assigned') return unavailable('request_not_assigned');
  const ambulance = await Ambulance.findOne({ _id: request.ambulance, activeRequest: id })
    .select('location status').lean();
  if (!ambulance || ambulance.status !== 'busy') return unavailable('assignment_unavailable');
  const location = ambulance.location;
  const updatedAt = location?.updatedAt ? new Date(location.updatedAt).getTime() : NaN;
  if (!Number.isFinite(updatedAt) || Date.now() - updatedAt > 10 * 60000 || updatedAt > Date.now() + 60000) {
    return unavailable('ambulance_location_stale_or_missing');
  }
  for (const point of [location, request]) {
    if (typeof point.latitude !== 'number' || !Number.isFinite(point.latitude) || Math.abs(point.latitude) > 90 ||
        typeof point.longitude !== 'number' || !Number.isFinite(point.longitude) || Math.abs(point.longitude) > 180) {
      return unavailable('invalid_coordinates');
    }
  }
  const route = await travel.roadRoute(location, request);
  if (route.reason) return unavailable(route.reason);
  const fallback = Math.round(route.routeMinutes * 100) / 100;
  const result = { etaMinutes: fallback, source: 'routing', reason: null,
    distanceKm: Math.round(route.distanceKm * 1000) / 1000, calculatedAt: new Date(),
    ambulanceLocationUpdatedAt: location.updatedAt, attribution: 'openrouteservice / OpenStreetMap contributors' };
  if (route.distanceKm < 1 || route.distanceKm > 50) return { ...result, reason: 'outside_ml_distance_range' };
  if (!process.env.ML_SERVICE_URL?.trim()) return { ...result, reason: 'ml_not_configured' };
  const weather = await travel.pickupWeather(request);
  if (weather.reason) return { ...result, reason: weather.reason };
  const prediction = await ml.predict('/predict/ambulance-eta', {
    Hour: ml.clinicTime().hour, Traffic_Level: 2, Distance_to_Incident: route.distanceKm,
    Ambulance_Speed: 40, Weather_Severity: weather.severity, Weather_Impact_Level: weather.impact,
    Region_Type: 'Urban', Road_Type: 'Local Road', Emergency_Level: 'Minor', Is_Human_Dispatch: 1,
  }, 'eta_minutes', fallback);
  return { ...result, etaMinutes: prediction.minutes, source: prediction.source === 'ml' ? 'ml' : 'routing',
    reason: prediction.reason, weatherCode: weather.code, weatherTime: weather.time,
    attribution: result.attribution + '; weather by Open-Meteo',
    assumptions: ['moderate_traffic', 'speed_40_kmh', 'urban_local_road', 'default_emergency_level', 'weather_impact_equals_severity'] };
}

module.exports = { getEta };
