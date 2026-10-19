const { test } = require('node:test');
const assert = require('node:assert/strict');
const Request = require('../src/models/AmbulanceRequest');
const Ambulance = require('../src/models/Ambulance');
const service = require('../src/services/ambulance-eta.service');
const travel = require('../src/services/travel.service');
const ml = require('../src/services/ml.service');

const id = '507f1f77bcf86cd799439011';
const user = { id, role: 'patient' };
function setup(t) {
  const state = { request: { status: 'assigned', ambulance: '507f1f77bcf86cd799439012', latitude: 28.6, longitude: 77.4 },
    ambulance: { status: 'busy', location: { latitude: 28.7, longitude: 77.5, updatedAt: new Date() } },
    route: { distanceKm: 12, routeMinutes: 25 }, weather: { severity: 1, impact: 1, code: 63, time: new Date() },
    prediction: { minutes: 29, source: 'ml', reason: null } };
  const query = (read) => ({ select: () => ({ lean: async () => read() }) });
  const find = t.mock.method(Request, 'findOne', () => query(() => state.request));
  const vehicle = t.mock.method(Ambulance, 'findOne', () => query(() => state.ambulance));
  const route = t.mock.method(travel, 'roadRoute', async () => state.route);
  const weather = t.mock.method(travel, 'pickupWeather', async () => state.weather);
  const predict = t.mock.method(ml, 'predict', async () => state.prediction);
  const previous = process.env.ML_SERVICE_URL;
  process.env.ML_SERVICE_URL = 'https://ml.example';
  t.after(() => {
    if (previous === undefined) delete process.env.ML_SERVICE_URL;
    else process.env.ML_SERVICE_URL = previous;
  });
  return { state, find, vehicle, route, weather, predict };
}

test('ETA reads only the owned request and sends anonymous travel features to ML', async (t) => {
  const { find, vehicle, predict } = setup(t);
  const result = await service.getEta(user, id, {});
  assert.deepEqual(find.mock.calls[0].arguments[0], { _id: id, patient: id });
  assert.equal(vehicle.mock.calls[0].arguments[0].activeRequest, id);
  assert.equal(result.source, 'ml');
  assert.equal(result.etaMinutes, 29);
  assert.equal(result.latitude, undefined);
  assert.equal(predict.mock.calls[0].arguments[1].Distance_to_Incident, 12);
  assert.equal(predict.mock.calls[0].arguments[1].Traffic_Level, 2);
  assert.equal(predict.mock.calls[0].arguments[1].patient, undefined);
  assert.equal(predict.mock.calls[0].arguments[1].latitude, undefined);
});

test('missing or another patient request stops before external calls', async (t) => {
  const { state, route } = setup(t);
  state.request = null;
  await assert.rejects(service.getEta(user, id, {}), { code: 'REQUEST_NOT_FOUND' });
  assert.equal(route.mock.callCount(), 0);
});

test('pending and terminal requests do not claim an ambulance arrival time', async (t) => {
  const { state, route } = setup(t);
  for (const status of ['pending', 'completed', 'cancelled']) {
    state.request.status = status;
    assert.equal((await service.getEta(user, id, {})).reason, 'request_not_assigned');
  }
  assert.equal(route.mock.callCount(), 0);
});

test('missing, invalid or stale ambulance location stops prediction', async (t) => {
  const { state, route } = setup(t);
  state.ambulance.location.updatedAt = new Date(Date.now() - 11 * 60000);
  assert.equal((await service.getEta(user, id, {})).reason, 'ambulance_location_stale_or_missing');
  state.ambulance.location.updatedAt = new Date();
  state.ambulance.location.latitude = 91;
  assert.equal((await service.getEta(user, id, {})).reason, 'invalid_coordinates');
  assert.equal(route.mock.callCount(), 0);
});

test('routing failure returns unavailable while weather or model failures keep route duration', async (t) => {
  const { state } = setup(t);
  state.route = { reason: 'routing_not_configured' };
  assert.equal((await service.getEta(user, id, {})).etaMinutes, null);
  state.route = { distanceKm: 12, routeMinutes: 25 };
  state.weather = { reason: 'weather_unavailable' };
  let result = await service.getEta(user, id, {});
  assert.equal(result.etaMinutes, 25);
  assert.equal(result.source, 'routing');
  state.weather = { severity: 0, impact: 0 };
  state.prediction = { minutes: 25, source: 'fallback', reason: 'ml_unavailable' };
  result = await service.getEta(user, id, {});
  assert.equal(result.source, 'routing');
  assert.equal(result.reason, 'ml_unavailable');
});

test('distance outside model training range uses routing and rejects coordinate query overrides', async (t) => {
  const { state, predict } = setup(t);
  state.route.distanceKm = 100;
  assert.equal((await service.getEta(user, id, {})).reason, 'outside_ml_distance_range');
  assert.equal(predict.mock.callCount(), 0);
  await assert.rejects(service.getEta(user, id, { latitude: '0' }), { code: 'VALIDATION_ERROR' });
});
