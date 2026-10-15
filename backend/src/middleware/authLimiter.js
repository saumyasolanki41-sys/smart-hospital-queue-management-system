const { rateLimit } = require('express-rate-limit');

const registrationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMITED',
      message: 'Too many registration requests. Try again later.',
    },
  },
});

module.exports = { registrationLimiter };