const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const controller = require('../controllers/queue.controller');
const visits = require('../controllers/visit.controller');

const router = express.Router();
const bookingLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  keyGenerator: (req) => req.user.id,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many queue changes. Try again later.' } },
});
const statusLimiter = rateLimit({
  windowMs: 60000, limit: 60, keyGenerator: (req) => req.user.id,
  standardHeaders: 'draft-8', legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many token status checks. Try again later.' } },
});

router.use(authenticate, allowRoles('patient'));
router.post('/tokens', bookingLimiter, controller.joinQueue);
router.get('/tokens/mine', controller.myTokens);
router.get('/history', statusLimiter, visits.history);
router.get('/tokens/:id/feedback', statusLimiter, visits.getFeedback);
router.post('/tokens/:id/feedback', bookingLimiter, visits.submitFeedback);
router.get('/tokens/:id', statusLimiter, controller.tokenStatus);
router.patch('/tokens/:id/cancel', bookingLimiter, controller.cancelToken);

module.exports = router;
