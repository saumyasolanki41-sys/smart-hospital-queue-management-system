const registrationService = require('../services/registration.service');

async function register(req, res, next) {
  try {
    const data = await registrationService.requestRegistration(req.body);

    return res.status(202).json({
      success: true,
      data,
    });
  } catch (error) {
    const publicErrors = {
      VALIDATION_ERROR: 400,
      REGISTRATION_COOLDOWN: 429,
      EMAIL_UNAVAILABLE: 503,
    };

    if (!Object.hasOwn(publicErrors, error.code)) {
      return next(error);
    }

    if (error.code === 'REGISTRATION_COOLDOWN') {
      res.set('Retry-After', '60');
    }

    return res.status(publicErrors[error.code]).json({
      success: false,
      error: {
        code: error.code,
        message: error.message,
      },
    });
  }
}

module.exports = { register };