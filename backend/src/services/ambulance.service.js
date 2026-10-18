const Ambulance = require('../models/Ambulance');

function ambulanceError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function invalid(message) {
  return ambulanceError(400, 'VALIDATION_ERROR', message);
}

function validId(id) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id)) throw invalid('Send a valid ambulance ID.');
  return id;
}

function fields(body, updating) {
  const allowed = ['vehicleNumber', 'driverName', 'driverPhone', 'status', 'location'];
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).length === 0 || Object.keys(body).some((key) => !allowed.includes(key))) {
    throw invalid('Send only supported ambulance fields.');
  }
  const data = {};
  if (!updating || body.vehicleNumber !== undefined) {
    if (typeof body.vehicleNumber !== 'string' || !/^[A-Za-z0-9 -]{4,25}$/.test(body.vehicleNumber)) {
      throw invalid('Vehicle number must contain letters and digits, with optional spaces or hyphens.');
    }
    data.vehicleNumber = body.vehicleNumber.toUpperCase().replace(/[ -]/g, '');
    if (!/^[A-Z0-9]{4,20}$/.test(data.vehicleNumber)) throw invalid('Vehicle number must contain 4 to 20 letters or digits.');
  }
  if (!updating || body.driverName !== undefined) {
    if (typeof body.driverName !== 'string' || body.driverName.trim().length < 2 ||
        body.driverName.trim().length > 100 || /[\u0000-\u001f\u007f]/.test(body.driverName)) {
      throw invalid('Driver name must contain 2 to 100 characters.');
    }
    data.driverName = body.driverName.trim();
  }
  if (!updating || body.driverPhone !== undefined) {
    if (typeof body.driverPhone !== 'string' || !/^\+?[1-9]\d{9,14}$/.test(body.driverPhone.trim())) {
      throw invalid('Driver phone must contain 10 to 15 digits, with an optional leading +.');
    }
    data.driverPhone = body.driverPhone.trim();
  }
  if (body.status !== undefined) {
    if (!['available', 'busy', 'maintenance'].includes(body.status)) throw invalid('Invalid ambulance status.');
    data.status = body.status;
  }
  if (body.location !== undefined) {
    const location = body.location;
    if (!location || typeof location !== 'object' || Array.isArray(location) ||
        Object.keys(location).some((key) => !['latitude', 'longitude'].includes(key)) ||
        typeof location.latitude !== 'number' || !Number.isFinite(location.latitude) ||
        location.latitude < -90 || location.latitude > 90 ||
        typeof location.longitude !== 'number' || !Number.isFinite(location.longitude) ||
        location.longitude < -180 || location.longitude > 180) {
      throw invalid('Location needs numeric latitude (-90 to 90) and longitude (-180 to 180).');
    }
    data.location = { latitude: location.latitude, longitude: location.longitude, updatedAt: new Date() };
  }
  return data;
}

const selection = 'vehicleNumber driverName driverPhone status location createdAt updatedAt';

async function listAmbulances(query) {
  if (Object.keys(query).some((key) => !['status', 'page', 'limit'].includes(key))) throw invalid('Unsupported query field.');
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50) {
    throw invalid('Send page 1 to 100000 and limit 1 to 50.');
  }
  const filter = {};
  if (query.status !== undefined) {
    if (!['available', 'busy', 'maintenance'].includes(query.status)) throw invalid('Invalid ambulance status.');
    filter.status = query.status;
  }
  const ambulances = await Ambulance.find(filter).select(selection).sort({ vehicleNumber: 1, _id: 1 })
    .skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean();
  return { ambulances, page: Number(page), limit: Number(limit) };
}

async function getAmbulance(id) {
  const ambulance = await Ambulance.findById(validId(id)).select(selection).lean();
  if (!ambulance) throw ambulanceError(404, 'AMBULANCE_NOT_FOUND', 'Ambulance not found.');
  return { ambulance };
}

async function createAmbulance(body) {
  const data = fields(body, false);
  await Ambulance.init();
  try {
    const ambulance = await Ambulance.create(data);
    return getAmbulance(ambulance._id.toString());
  } catch (error) {
    if (error.code === 11000) throw ambulanceError(409, 'VEHICLE_EXISTS', 'An ambulance with this vehicle number already exists.');
    throw error;
  }
}

async function updateAmbulance(id, body) {
  validId(id);
  const data = fields(body, true);
  await Ambulance.init();
  let ambulance;
  try {
    ambulance = await Ambulance.findByIdAndUpdate(id, { $set: data }, {
      returnDocument: 'after', runValidators: true,
    }).select(selection).lean();
  } catch (error) {
    if (error.code === 11000) throw ambulanceError(409, 'VEHICLE_EXISTS', 'An ambulance with this vehicle number already exists.');
    throw error;
  }
  if (!ambulance) throw ambulanceError(404, 'AMBULANCE_NOT_FOUND', 'Ambulance not found.');
  return { ambulance };
}

module.exports = { listAmbulances, getAmbulance, createAmbulance, updateAmbulance };
