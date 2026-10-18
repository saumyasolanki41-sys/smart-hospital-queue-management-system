const Doctor = require('../models/Doctor');
const QueueToken = require('../models/QueueToken');

function staffError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function validId(id) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id)) {
    throw staffError(400, 'VALIDATION_ERROR', 'Send a valid ID.');
  }
  return id;
}

async function checkAccess(user, doctorId) {
  validId(doctorId);
  const doctor = await Doctor.findById(doctorId).select('user').lean();
  if (!doctor) throw staffError(404, 'DOCTOR_NOT_FOUND', 'Doctor not found.');
  if (user.role === 'admin' || user.role === 'receptionist') return;
  if (user.role === 'doctor' && doctor.user && doctor.user.toString() === user.id) return;
  throw staffError(403, 'FORBIDDEN', 'You do not have access to this doctor queue.');
}

function emptyBody(body) {
  if (body !== undefined && (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).length)) {
    throw staffError(400, 'VALIDATION_ERROR', 'Send no body or an empty JSON object.');
  }
}

function today() {
  return new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
}

const selection = 'patient doctor queueDate tokenNumber status calledAt completedAt createdAt';

async function listQueue(user, doctorId, query) {
  await checkAccess(user, doctorId);
  if (Object.keys(query).some((key) => !['page', 'limit', 'status'].includes(key))) {
    throw staffError(400, 'VALIDATION_ERROR', 'Supported query fields are page, limit and status.');
  }
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  const status = query.status === undefined ? 'waiting' : query.status;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50 ||
      !['waiting', 'called', 'completed', 'cancelled'].includes(status)) {
    throw staffError(400, 'VALIDATION_ERROR', 'Send valid pagination and queue status.');
  }
  const date = today();
  const tokens = await QueueToken.find({ doctor: doctorId, queueDate: date, status })
    .select(selection).populate('patient', 'name').sort({ tokenNumber: 1 })
    .skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean();
  const currentToken = await QueueToken.findOne({ doctor: doctorId, status: 'called' })
    .select(selection).populate('patient', 'name').lean();
  return { tokens, currentToken, date, page: Number(page), limit: Number(limit) };
}

async function callNext(user, doctorId, body) {
  emptyBody(body);
  await checkAccess(user, doctorId);
  await QueueToken.init();
  if (await QueueToken.exists({ doctor: doctorId, status: 'called' })) {
    throw staffError(409, 'QUEUE_BUSY', 'Complete the currently called token first.');
  }
  let token;
  try {
    token = await QueueToken.findOneAndUpdate({
      doctor: doctorId, queueDate: today(), status: 'waiting', active: true,
    }, { $set: { status: 'called', calledAt: new Date() } }, {
      sort: { tokenNumber: 1 }, returnDocument: 'after', runValidators: true,
    }).select(selection).populate('patient', 'name').lean();
  } catch (error) {
    if (error.code === 11000) {
      throw staffError(409, 'QUEUE_BUSY', 'Another staff member called a token. Refresh the queue.');
    }
    throw error;
  }
  if (!token) throw staffError(409, 'QUEUE_EMPTY', 'No patients are waiting for this doctor today.');
  return { token };
}

async function completeToken(user, doctorId, tokenId, body) {
  emptyBody(body);
  validId(tokenId);
  await checkAccess(user, doctorId);
  const token = await QueueToken.findOneAndUpdate({
    _id: tokenId, doctor: doctorId, status: 'called', active: true,
  }, { $set: { status: 'completed', active: false, completedAt: new Date() } }, {
    returnDocument: 'after', runValidators: true,
  }).select(selection).populate('patient', 'name').lean();
  if (token) return { token };
  if (!await QueueToken.exists({ _id: tokenId, doctor: doctorId })) {
    throw staffError(404, 'TOKEN_NOT_FOUND', 'Queue token not found for this doctor.');
  }
  throw staffError(409, 'TOKEN_NOT_CALLED', 'Only a currently called token can be completed.');
}

module.exports = { listQueue, callNext, completeToken };
