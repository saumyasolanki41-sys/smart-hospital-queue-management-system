const mongoose = require('mongoose');
const Ambulance = require('../models/Ambulance');
const AmbulanceRequest = require('../models/AmbulanceRequest');

function fail(status, code, message) {
  return Object.assign(new Error(message), { status, code });
}

function validId(id) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id)) {
    throw fail(400, 'VALIDATION_ERROR', 'Send a valid ID.');
  }
  return id;
}

function checkBody(body, keys) {
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).length !== keys.length || keys.some((key) => !Object.hasOwn(body, key))) {
    throw fail(400, 'VALIDATION_ERROR', `Send only ${keys.join(', ')}.`);
  }
}

function emptyBody(body) {
  if (body !== undefined) checkBody(body, []);
}

const selection = 'patient pickupAddress latitude longitude contactPhone status ambulance assignedAt completedAt cancelledAt createdAt updatedAt';

async function createRequest(patientId, body) {
  checkBody(body, ['pickupAddress', 'latitude', 'longitude', 'contactPhone']);
  if (typeof body.pickupAddress !== 'string' || body.pickupAddress.trim().length < 5 ||
      body.pickupAddress.trim().length > 300 || /[\u0000-\u001f\u007f]/.test(body.pickupAddress) ||
      typeof body.contactPhone !== 'string' || !/^\+?[1-9]\d{9,14}$/.test(body.contactPhone.trim()) ||
      typeof body.latitude !== 'number' || !Number.isFinite(body.latitude) || Math.abs(body.latitude) > 90 ||
      typeof body.longitude !== 'number' || !Number.isFinite(body.longitude) || Math.abs(body.longitude) > 180) {
    throw fail(400, 'VALIDATION_ERROR', 'Send a pickup address (5 to 300 characters), valid phone and numeric coordinates.');
  }
  await AmbulanceRequest.init();
  try {
    const request = await AmbulanceRequest.create({
      patient: patientId, pickupAddress: body.pickupAddress.trim(), contactPhone: body.contactPhone.trim(),
      latitude: body.latitude, longitude: body.longitude, status: 'pending', active: true,
    });
    return getRequest({ id: patientId, role: 'patient' }, request._id.toString());
  } catch (error) {
    if (error.code === 11000) throw fail(409, 'ACTIVE_REQUEST_EXISTS', 'You already have an active ambulance request.');
    throw error;
  }
}

async function getRequest(user, id) {
  const filter = { _id: validId(id) };
  if (user.role === 'patient') filter.patient = user.id;
  const request = await AmbulanceRequest.findOne(filter).select(selection)
    .populate('ambulance', 'vehicleNumber').lean();
  if (!request) throw fail(404, 'REQUEST_NOT_FOUND', 'Ambulance request not found.');
  return { request };
}

async function listRequests(user, query) {
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  if (Object.keys(query).some((key) => !['page', 'limit', 'status'].includes(key)) ||
      typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50 ||
      (query.status !== undefined && !['pending', 'assigned', 'completed', 'cancelled'].includes(query.status))) {
    throw fail(400, 'VALIDATION_ERROR', 'Send a valid status, page (1 to 100000) and limit (1 to 50).');
  }
  const filter = user.role === 'patient' ? { patient: user.id } : {};
  if (query.status !== undefined) filter.status = query.status;
  const requests = await AmbulanceRequest.find(filter).select(selection)
    .populate('ambulance', 'vehicleNumber')
    .sort({ createdAt: -1, _id: -1 }).skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean();
  return { requests, page: Number(page), limit: Number(limit) };
}

async function assignRequest(user, id, body) {
  validId(id);
  checkBody(body, ['ambulanceId']);
  const ambulanceId = validId(body.ambulanceId);
  await Promise.all([AmbulanceRequest.init(), Ambulance.init()]);
  try {
    await mongoose.connection.transaction(async (session) => {
      const request = await AmbulanceRequest.findOneAndUpdate({ _id: id, status: 'pending', active: true }, {
        $set: { status: 'assigned', ambulance: ambulanceId, assignedBy: user.id, assignedAt: new Date() },
      }, { session, returnDocument: 'after', runValidators: true });
      if (!request) {
        const exists = await AmbulanceRequest.exists({ _id: id }).session(session);
        throw fail(exists ? 409 : 404, exists ? 'REQUEST_CONFLICT' : 'REQUEST_NOT_FOUND', 'Request is missing or no longer pending.');
      }
      const ambulance = await Ambulance.findOneAndUpdate({ _id: ambulanceId, status: 'available', activeRequest: null }, {
        $set: { status: 'busy', activeRequest: request._id },
      }, { session, returnDocument: 'after', runValidators: true });
      if (!ambulance) throw fail(409, 'AMBULANCE_UNAVAILABLE', 'Ambulance is missing, busy or under maintenance.');
    });
  } catch (error) {
    if (error.code === 11000) throw fail(409, 'REQUEST_CONFLICT', 'Assignment changed. Refresh the request before retrying.');
    throw error;
  }
  return getRequest(user, id);
}

async function finishRequest(user, id, body, status) {
  validId(id);
  emptyBody(body);
  await Promise.all([AmbulanceRequest.init(), Ambulance.init()]);
  await mongoose.connection.transaction(async (session) => {
    const filter = { _id: id, active: true };
    if (user.role === 'patient') filter.patient = user.id;
    const request = await AmbulanceRequest.findOne(filter).session(session);
    if (!request) {
      const exists = await AmbulanceRequest.exists(user.role === 'patient' ? { _id: id, patient: user.id } : { _id: id }).session(session);
      throw fail(exists ? 409 : 404, exists ? 'REQUEST_CONFLICT' : 'REQUEST_NOT_FOUND', 'Request is missing or already closed.');
    }
    if ((status === 'completed' && request.status !== 'assigned') ||
        (user.role === 'patient' && request.status !== 'pending')) {
      throw fail(409, 'REQUEST_CONFLICT', 'Patients can cancel only pending requests; completion requires an assignment.');
    }
    if (request.status === 'assigned') {
      const ambulance = await Ambulance.findOneAndUpdate({ _id: request.ambulance, activeRequest: request._id }, {
        $set: { status: 'available' }, $unset: { activeRequest: 1 },
      }, { session, returnDocument: 'after', runValidators: true });
      if (!ambulance) throw fail(409, 'REQUEST_CONFLICT', 'Ambulance assignment changed. Contact staff.');
    }
    request.status = status;
    request.active = false;
    request[status === 'completed' ? 'completedAt' : 'cancelledAt'] = new Date();
    await request.save({ session });
  });
  return getRequest(user, id);
}

module.exports = { createRequest, getRequest, listRequests, assignRequest,
  cancelRequest: (user, id, body) => finishRequest(user, id, body, 'cancelled'),
  completeRequest: (user, id, body) => finishRequest(user, id, body, 'completed') };
