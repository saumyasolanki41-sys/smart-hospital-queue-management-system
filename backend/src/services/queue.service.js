const mongoose = require('mongoose');
const Doctor = require('../models/Doctor');
const QueueDay = require('../models/QueueDay');
const QueueToken = require('../models/QueueToken');

function queueError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function today() {
  return new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
}

function validId(id) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id)) {
    throw queueError(400, 'VALIDATION_ERROR', 'Send a valid ID.');
  }
  return id;
}

function checkDoctor(doctor) {
  if (!doctor) throw queueError(404, 'DOCTOR_NOT_FOUND', 'Doctor not found.');
  if (!doctor.isAvailable) throw queueError(409, 'DOCTOR_UNAVAILABLE', 'Doctor is not accepting new queue tokens.');
}

const selection = 'doctor queueDate tokenNumber status calledAt completedAt skippedAt createdAt';

async function joinQueue(patientId, body) {
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).length !== 1 || !Object.hasOwn(body, 'doctorId')) {
    throw queueError(400, 'VALIDATION_ERROR', 'Send only doctorId.');
  }
  const doctorId = validId(body.doctorId);
  checkDoctor(await Doctor.findById(doctorId).select('isAvailable').lean());
  await Promise.all([QueueToken.init(), QueueDay.init()]);
  const queueDate = today();
  const dayId = `${doctorId.toLowerCase()}:${queueDate}`;

  try {
    await QueueDay.updateOne({ _id: dayId }, { $setOnInsert: { lastToken: 0 } }, { upsert: true });
  } catch (error) {
    if (error.code !== 11000) throw error;
  }

  let token;
  try {
    token = await mongoose.connection.transaction(async (session) => {
      const doctor = await Doctor.findById(doctorId).select('isAvailable').session(session);
      checkDoctor(doctor);
      if (today() !== queueDate) {
        throw queueError(409, 'QUEUE_DAY_CHANGED', 'A new queue day has started. Try again.');
      }
      if (await QueueToken.exists({ patient: patientId, doctor: doctorId, queueDate, active: true }).session(session)) {
        throw queueError(409, 'ALREADY_IN_QUEUE', 'You already have an active token for this doctor today.');
      }
      const day = await QueueDay.findByIdAndUpdate(dayId, { $inc: { lastToken: 1 } }, {
        session, returnDocument: 'after', runValidators: true,
      });
      const [created] = await QueueToken.create([{
        patient: patientId, doctor: doctorId, queueDate, tokenNumber: day.lastToken,
        status: 'waiting', active: true,
      }], { session });
      return created;
    }, {
      readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' }, readPreference: 'primary',
    });
  } catch (error) {
    if (error.code === 11000) {
      throw queueError(409, 'QUEUE_CONFLICT', 'Queue booking changed. Check your tokens before retrying.');
    }
    throw error;
  }
  return { token: {
    _id: token._id, doctor: token.doctor, queueDate: token.queueDate,
    tokenNumber: token.tokenNumber, status: token.status, createdAt: token.createdAt,
  } };
}

async function myTokens(patientId, query) {
  if (Object.keys(query).some((key) => !['date', 'page', 'limit'].includes(key))) {
    throw queueError(400, 'VALIDATION_ERROR', 'Supported query fields are date, page and limit.');
  }
  const date = query.date === undefined ? today() : query.date;
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
      !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date) {
    throw queueError(400, 'VALIDATION_ERROR', 'Date must be a real date in YYYY-MM-DD format.');
  }
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50) {
    throw queueError(400, 'VALIDATION_ERROR', 'Send a page from 1 to 100000 and limit from 1 to 50.');
  }
  const tokens = await QueueToken.find({ patient: patientId, queueDate: date }).select(selection)
    .populate('doctor', 'name specialization').sort({ createdAt: -1, _id: -1 })
    .skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean();
  return { tokens, date, page: Number(page), limit: Number(limit) };
}

async function tokenStatus(patientId, id) {
  const token = await QueueToken.findOne({ _id: validId(id), patient: patientId }).select(selection).lean();
  if (!token) throw queueError(404, 'TOKEN_NOT_FOUND', 'Queue token not found.');
  let peopleAhead = null;
  let estimatedWaitMinutes = null;
  let averageConsultationMinutes = null;
  let consultationOverdue = null;
  if (token.status === 'waiting' && token.queueDate === today()) {
    peopleAhead = await QueueToken.countDocuments({
      doctor: token.doctor, queueDate: token.queueDate,
      status: 'waiting', tokenNumber: { $lt: token.tokenNumber },
    });
    const doctor = await Doctor.findById(token.doctor).select('averageConsultationMinutes').lean();
    if (doctor) {
      averageConsultationMinutes = doctor.averageConsultationMinutes;
      if (!Number.isInteger(averageConsultationMinutes) ||
          averageConsultationMinutes < 1 || averageConsultationMinutes > 120) {
        averageConsultationMinutes = 10;
      }
      const current = await QueueToken.findOne({ doctor: token.doctor, status: 'called' })
        .select('calledAt').lean();
      let remainingMinutes = 0;
      consultationOverdue = false;
      if (current) {
        const startedAt = current.calledAt ? new Date(current.calledAt).getTime() : NaN;
        let elapsedMinutes = 0;
        if (Number.isFinite(startedAt)) {
          elapsedMinutes = Math.max(0, (Date.now() - startedAt) / 60000);
        }
        consultationOverdue = elapsedMinutes >= averageConsultationMinutes;
        remainingMinutes = Math.max(1, Math.ceil(averageConsultationMinutes - elapsedMinutes));
      }
      estimatedWaitMinutes = peopleAhead * averageConsultationMinutes + remainingMinutes;
    }
  }
  return { token, peopleAhead, estimatedWaitMinutes, averageConsultationMinutes, consultationOverdue };
}

async function cancelToken(patientId, id, body) {
  validId(id);
  if (body !== undefined && (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).length)) {
    throw queueError(400, 'VALIDATION_ERROR', 'Cancellation takes no body or an empty JSON object.');
  }
  const token = await QueueToken.findOneAndUpdate({
    _id: id, patient: patientId, status: 'waiting', active: true,
  }, { $set: { status: 'cancelled', active: false } }, {
    returnDocument: 'after', runValidators: true,
  }).select(selection).lean();
  if (token) return { token };
  const existing = await QueueToken.exists({ _id: id, patient: patientId });
  if (!existing) throw queueError(404, 'TOKEN_NOT_FOUND', 'Queue token not found.');
  throw queueError(409, 'TOKEN_NOT_CANCELLABLE', 'Only a waiting token can be cancelled.');
}

module.exports = { joinQueue, myTokens, tokenStatus, cancelToken };
