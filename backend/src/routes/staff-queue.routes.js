const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const controller = require('../controllers/staff-queue.controller');

const router = express.Router();
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  keyGenerator: (req) => req.user.id,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many queue changes. Try again later.' } },
});

router.use(authenticate, allowRoles('admin', 'receptionist', 'doctor'));
router.get('/doctors/:doctorId/tokens', controller.listQueue);
router.post('/doctors/:doctorId/call-next', limiter, controller.callNext);
router.patch('/doctors/:doctorId/tokens/:tokenId/complete', limiter, controller.completeToken);

module.exports = router;
