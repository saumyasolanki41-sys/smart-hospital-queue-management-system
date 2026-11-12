const QueueToken = require('../models/QueueToken');
require('../models/Doctor');
require('../models/Department');

function fail(status, code, message) {
  throw Object.assign(new Error(message), { status, code });
}

function validId(value) {
  if (typeof value !== 'string' || !/^[a-f0-9]{24}$/i.test(value)) {
    fail(400, 'VALIDATION_ERROR', 'Send a valid token ID.');
  }
  return value;
}

function validDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
      !Number.isFinite(Date.parse(value)) || new Date(value).toISOString().slice(0, 10) !== value) {
    fail(400, 'VALIDATION_ERROR', 'Use a real date in YYYY-MM-DD format.');
  }
  return value;
}

async function history(patientId, query) {
  if (Object.keys(query).some(key => !['from', 'to', 'status', 'page', 'limit'].includes(key))) {
    fail(400, 'VALIDATION_ERROR', 'Supported fields are from, to, status, page and limit.');
  }
  const filter = { patient: patientId };
  const status = query.status === undefined ? 'completed' : query.status;
  if (!['all', 'waiting', 'called', 'completed', 'cancelled', 'skipped'].includes(status)) {
    fail(400, 'VALIDATION_ERROR', 'Send a valid visit status.');
  }
  if (status !== 'all') filter.status = status;
  if (query.from !== undefined || query.to !== undefined) {
    filter.queueDate = {};
    if (query.from !== undefined) filter.queueDate.$gte = validDate(query.from);
    if (query.to !== undefined) filter.queueDate.$lte = validDate(query.to);
    if (query.from && query.to && query.from > query.to) fail(400, 'VALIDATION_ERROR', 'from must not exceed to.');
  }
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50) {
    fail(400, 'VALIDATION_ERROR', 'Use page 1 to 100000 and limit 1 to 50.');
  }
  const [visits, total] = await Promise.all([
    QueueToken.find(filter).select('doctor queueDate tokenNumber status calledAt completedAt skippedAt createdAt feedback')
      .populate({ path: 'doctor', select: 'name specialization department', populate: { path: 'department', select: 'name' } })
      .sort({ queueDate: -1, createdAt: -1, _id: -1 }).skip((Number(page) - 1) * Number(limit)).limit(Number(limit)).lean(),
    QueueToken.countDocuments(filter),
  ]);
  return { visits, total, page: Number(page), limit: Number(limit) };
}

async function submitFeedback(patientId, tokenId, body) {
  validId(tokenId);
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).some(key => !['rating', 'comment'].includes(key)) ||
      !Number.isInteger(body.rating) || body.rating < 1 || body.rating > 5 ||
      (body.comment !== undefined && (typeof body.comment !== 'string' || body.comment.trim().length > 1000))) {
    fail(400, 'VALIDATION_ERROR', 'Send an integer rating 1 to 5 and optional comment up to 1000 characters.');
  }
  const feedback = { rating: body.rating, comment: body.comment?.trim() || '', submittedAt: new Date() };
  const token = await QueueToken.findOneAndUpdate({
    _id: tokenId, patient: patientId, status: 'completed', feedback: { $exists: false },
  }, { $set: { feedback } }, { returnDocument: 'after', runValidators: true }).select('feedback').lean();
  if (token) return { tokenId: token._id, feedback: token.feedback };
  const existing = await QueueToken.findOne({ _id: tokenId, patient: patientId }).select('status feedback').lean();
  if (!existing) fail(404, 'TOKEN_NOT_FOUND', 'Queue token not found.');
  if (existing.status !== 'completed') fail(409, 'VISIT_NOT_COMPLETED', 'Feedback requires a completed consultation.');
  fail(409, 'FEEDBACK_EXISTS', 'Feedback has already been submitted for this visit.');
}

async function getFeedback(patientId, tokenId) {
  const token = await QueueToken.findOne({ _id: validId(tokenId), patient: patientId }).select('feedback').lean();
  if (!token) fail(404, 'TOKEN_NOT_FOUND', 'Queue token not found.');
  return { tokenId: token._id, feedback: token.feedback || null };
}

module.exports = { history, submitFeedback, getFeedback };
