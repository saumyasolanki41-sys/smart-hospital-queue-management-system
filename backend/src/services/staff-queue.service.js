const Doctor = require('../models/Doctor');
const QueueToken = require('../models/QueueToken');
const mongoose = require('mongoose');
const queueState = require('./queue-state.service');

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

function authorizeDoctor(user, doctor) {
  if (!doctor) throw staffError(404, 'DOCTOR_NOT_FOUND', 'Doctor not found.');
  if (user.role === 'admin' || user.role === 'receptionist') return doctor;
  if (user.role === 'doctor' && doctor.user && doctor.user.toString() === user.id) return doctor;
  throw staffError(403, 'FORBIDDEN', 'You do not have access to this doctor queue.');
}

async function checkAccess(user, doctorId) {
  validId(doctorId);
  return authorizeDoctor(user, await Doctor.findById(doctorId)
    .select('user queuePaused queuePauseReason queuePausedAt').lean());
}

async function lockDoctor(user, doctorId, session) {
  const doctor = await Doctor.findByIdAndUpdate(validId(doctorId), { $inc: { queueRevision: 1 } }, {
    session, returnDocument: 'after',
  }).select('user queuePaused queuePauseReason queuePausedAt');
  return authorizeDoctor(user, doctor);
}

function emptyBody(body) {
  if (body !== undefined && (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).length)) {
    throw staffError(400, 'VALIDATION_ERROR', 'Send no body or an empty JSON object.');
  }
}

function today() {
  return new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
}

const selection = 'patient doctor queueDate tokenNumber status calledAt completedAt skippedAt createdAt';

async function listQueue(user, doctorId, query) {
  const doctor = await checkAccess(user, doctorId);
  if (Object.keys(query).some((key) => !['page', 'limit', 'status'].includes(key))) {
    throw staffError(400, 'VALIDATION_ERROR', 'Supported query fields are page, limit and status.');
  }
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  const status = query.status === undefined ? 'waiting' : query.status;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50 ||
      !['waiting', 'called', 'completed', 'cancelled', 'skipped'].includes(status)) {
    throw staffError(400, 'VALIDATION_ERROR', 'Send valid pagination and queue status.');
  }
  const date = today();
  const tokens = await QueueToken.find({ doctor: doctorId, queueDate: date, status })
    .select(selection).populate('patient', 'name').sort({ tokenNumber: 1 })
    .skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean();
  const currentToken = await QueueToken.findOne({ doctor: doctorId, status: 'called' })
    .select(selection).populate('patient', 'name').lean();
  return { tokens, currentToken, date, page: Number(page), limit: Number(limit), queueState: queueState(doctor) };
}

async function callNext(user, doctorId, body) {
  emptyBody(body);
  await checkAccess(user, doctorId);
  await QueueToken.init();
  let token;
  try {
    token = await mongoose.connection.transaction(async session => {
      const doctor = await lockDoctor(user, doctorId, session);
      if (doctor.queuePaused) throw staffError(409, 'QUEUE_PAUSED', 'Resume the doctor queue before calling the next patient.');
      if (await QueueToken.exists({ doctor: doctorId, status: 'called' }).session(session)) {
        throw staffError(409, 'QUEUE_BUSY', 'Complete or skip the currently called token first.');
      }
      const next = await QueueToken.findOneAndUpdate({
        doctor: doctorId, queueDate: today(), status: 'waiting', active: true,
      }, { $set: { status: 'called', calledAt: new Date() } }, {
        session, sort: { tokenNumber: 1 }, returnDocument: 'after', runValidators: true,
      }).select(selection).populate('patient', 'name').lean();
      if (!next) throw staffError(409, 'QUEUE_EMPTY', 'No patients are waiting for this doctor today.');
      return next;
    });
  } catch (error) {
    if (error.code === 11000) {
      throw staffError(409, 'QUEUE_BUSY', 'Another staff member called a token. Refresh the queue.');
    }
    throw error;
  }
  if (!token) throw staffError(409, 'QUEUE_EMPTY', 'No patients are waiting for this doctor today.');
  return { token };
}

async function setPause(user, doctorId, body, paused) {
  if (paused) {
    if (!body || typeof body !== 'object' || Array.isArray(body) ||
        Object.keys(body).length !== 1 || !['break', 'temporary_delay'].includes(body.reason)) {
      throw staffError(400, 'VALIDATION_ERROR', 'Send only reason: break or temporary_delay.');
    }
  } else {
    emptyBody(body);
  }
  await checkAccess(user, doctorId);
  return mongoose.connection.transaction(async session => {
    const doctor = await lockDoctor(user, doctorId, session);
    if (paused && await QueueToken.exists({ doctor: doctorId, status: 'called' }).session(session)) {
      throw staffError(409, 'QUEUE_BUSY', 'Complete or skip the current consultation before pausing.');
    }
    if (paused && doctor.queuePaused && doctor.queuePauseReason !== body.reason) {
      throw staffError(409, 'QUEUE_PAUSED', 'Queue is already paused. Resume it before choosing another reason.');
    }
    if (Boolean(doctor.queuePaused) !== paused) {
      doctor.queuePaused = paused;
      doctor.queuePauseReason = paused ? body.reason : '';
      doctor.queuePausedAt = paused ? new Date() : null;
      await doctor.save({ session });
    }
    return { doctorId: doctor._id, queueState: queueState(doctor) };
  });
}

async function finishCalledToken(user, doctorId, tokenId, body, status) {
  emptyBody(body);
  validId(tokenId);
  await checkAccess(user, doctorId);
  const changes = { status, active: false };
  if (status === 'completed') changes.completedAt = new Date();
  if (status === 'skipped') changes.skippedAt = new Date();
  const token = await QueueToken.findOneAndUpdate({
    _id: tokenId, doctor: doctorId, status: 'called', active: true,
  }, { $set: changes }, {
    returnDocument: 'after', runValidators: true,
  }).select(selection).populate('patient', 'name').lean();
  if (token) return { token };
  if (!await QueueToken.exists({ _id: tokenId, doctor: doctorId })) {
    throw staffError(404, 'TOKEN_NOT_FOUND', 'Queue token not found for this doctor.');
  }
  throw staffError(409, 'TOKEN_NOT_CALLED', 'Only a currently called token can be completed or skipped.');
}

function completeToken(user, doctorId, tokenId, body) {
  return finishCalledToken(user, doctorId, tokenId, body, 'completed');
}

function skipToken(user, doctorId, tokenId, body) {
  return finishCalledToken(user, doctorId, tokenId, body, 'skipped');
}

module.exports = {
  listQueue, callNext, completeToken, skipToken,
  pauseQueue: (user, doctorId, body) => setPause(user, doctorId, body, true),
  resumeQueue: (user, doctorId, body) => setPause(user, doctorId, body, false),
};
