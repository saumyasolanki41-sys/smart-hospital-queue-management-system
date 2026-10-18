const service = require('../services/staff-queue.service');

function handleError(error, res, next) {
  const codes = ['VALIDATION_ERROR', 'DOCTOR_NOT_FOUND', 'FORBIDDEN', 'QUEUE_BUSY',
    'QUEUE_EMPTY', 'TOKEN_NOT_FOUND', 'TOKEN_NOT_CALLED'];
  if (!codes.includes(error.code)) return next(error);
  return res.status(error.status).json({
    success: false, error: { code: error.code, message: error.message },
  });
}

async function listQueue(req, res, next) {
  try {
    const data = await service.listQueue(req.user, req.params.doctorId, req.query);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function callNext(req, res, next) {
  try {
    const data = await service.callNext(req.user, req.params.doctorId, req.body);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function completeToken(req, res, next) {
  try {
    const data = await service.completeToken(req.user, req.params.doctorId, req.params.tokenId, req.body);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

module.exports = { listQueue, callNext, completeToken };
