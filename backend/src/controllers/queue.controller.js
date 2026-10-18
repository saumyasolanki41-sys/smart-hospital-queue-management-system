const queueService = require('../services/queue.service');

function handleError(error, res, next) {
  const codes = ['VALIDATION_ERROR', 'DOCTOR_NOT_FOUND', 'DOCTOR_UNAVAILABLE',
    'ALREADY_IN_QUEUE', 'QUEUE_CONFLICT', 'QUEUE_DAY_CHANGED', 'TOKEN_NOT_FOUND', 'TOKEN_NOT_CANCELLABLE'];
  if (!codes.includes(error.code)) return next(error);
  return res.status(error.status).json({
    success: false, error: { code: error.code, message: error.message },
  });
}

async function joinQueue(req, res, next) {
  try {
    const data = await queueService.joinQueue(req.user.id, req.body);
    return res.status(201).json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function myTokens(req, res, next) {
  try {
    const data = await queueService.myTokens(req.user.id, req.query);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function tokenStatus(req, res, next) {
  try {
    const data = await queueService.tokenStatus(req.user.id, req.params.id);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function cancelToken(req, res, next) {
  try {
    const data = await queueService.cancelToken(req.user.id, req.params.id, req.body);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

module.exports = { joinQueue, myTokens, tokenStatus, cancelToken };
