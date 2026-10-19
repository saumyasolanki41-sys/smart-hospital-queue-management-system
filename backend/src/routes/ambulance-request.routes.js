const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const service = require('../services/ambulance-request.service');

const router = express.Router();
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 60, keyGenerator: (req) => req.user.id,
  standardHeaders: 'draft-8', legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many request updates. Try again later.' } },
});

function handle(action, status = 200) {
  return async (req, res, next) => {
    try {
      return res.status(status).json({ success: true, data: await action(req) });
    } catch (error) {
      if (!['VALIDATION_ERROR', 'ACTIVE_REQUEST_EXISTS', 'REQUEST_NOT_FOUND', 'REQUEST_CONFLICT', 'AMBULANCE_UNAVAILABLE'].includes(error.code)) return next(error);
      return res.status(error.status).json({ success: false, error: { code: error.code, message: error.message } });
    }
  };
}

router.use(authenticate, allowRoles('patient', 'admin', 'receptionist'));
router.post('/', allowRoles('patient'), limiter, handle((req) => service.createRequest(req.user.id, req.body), 201));
router.get('/', handle((req) => service.listRequests(req.user, req.query)));
router.get('/:id', handle((req) => service.getRequest(req.user, req.params.id)));
router.patch('/:id/assign', allowRoles('admin', 'receptionist'), limiter, handle((req) => service.assignRequest(req.user, req.params.id, req.body)));
router.patch('/:id/complete', allowRoles('admin', 'receptionist'), limiter, handle((req) => service.completeRequest(req.user, req.params.id, req.body)));
router.patch('/:id/cancel', limiter, handle((req) => service.cancelRequest(req.user, req.params.id, req.body)));

module.exports = router;
