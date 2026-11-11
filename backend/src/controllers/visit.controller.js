const service = require('../services/visit.service');

function handle(operation, status = 200) {
  return async (req, res, next) => {
    try {
      return res.status(status).json({ success: true, data: await operation(req) });
    } catch (error) {
      if (!['VALIDATION_ERROR', 'TOKEN_NOT_FOUND', 'VISIT_NOT_COMPLETED', 'FEEDBACK_EXISTS'].includes(error.code)) return next(error);
      return res.status(error.status).json({ success: false, error: { code: error.code, message: error.message } });
    }
  };
}

module.exports = {
  history: handle(req => service.history(req.user.id, req.query)),
  submitFeedback: handle(req => service.submitFeedback(req.user.id, req.params.id, req.body), 201),
  getFeedback: handle(req => service.getFeedback(req.user.id, req.params.id)),
};
