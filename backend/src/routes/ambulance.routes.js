const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const controller = require('../controllers/ambulance.controller');

const router = express.Router();
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 120,
  keyGenerator: (req) => req.user.id,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many ambulance updates. Try again later.' } },
});

router.use(authenticate, allowRoles('admin', 'receptionist'));
router.get('/', controller.listAmbulances);
router.get('/:id', controller.getAmbulance);
router.post('/', allowRoles('admin'), limiter, controller.createAmbulance);
router.patch('/:id', limiter, controller.updateAmbulance);

module.exports = router;
