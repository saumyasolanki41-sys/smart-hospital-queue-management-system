const registrationService = require('../services/registration.service');
const googleLoginService = require('../services/google-login.service');
const verificationService = require('../services/registration-verification.service');
const loginService = require('../services/login.service');
const passwordResetService = require('../services/password-reset.service');
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

async function googleLogin(req, res, next) {
  if (!req.is('application/json')) {
    return res.status(415).json({
      success: false,
      error: {
        code: 'UNSUPPORTED_MEDIA_TYPE',
        message: 'Use application/json.',
      },
    });
  }

  try {
    const data = await googleLoginService.googleLogin(req.body);

    res.set('Cache-Control', 'no-store');

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    const publicErrors = {
      INVALID_INPUT: 400,
      INVALID_GOOGLE_TOKEN: 401,
      EMAIL_VERIFICATION_REQUIRED: 403,
      ACCOUNT_LINK_REQUIRED: 409,
    };

    if (!Object.hasOwn(publicErrors, error.code)) {
      return next(error);
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
async function verifyRegistration(req, res, next) {
  try {
    const data = await verificationService.verifyRegistration(req.body);

    return res.status(201).json({
      success: true,
      data,
    });
  } catch (error) {
    const publicErrors = {
      VALIDATION_ERROR: 400,
      INVALID_OR_EXPIRED_OTP: 400,
      ACCOUNT_EXISTS: 409,
    };

    if (!Object.hasOwn(publicErrors, error.code)) {
      return next(error);
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
function handleLoginError(error, res, next) {
  let status;

  if (error.code === 'VALIDATION_ERROR' || error.code === 'INVALID_OR_EXPIRED_OTP') {
    status = 400;
  } else if (error.code === 'INVALID_CREDENTIALS') {
    status = 401;
  } else if (error.code === 'LOGIN_COOLDOWN') {
    status = 429;
    res.set('Retry-After', '60');
  } else if (error.code === 'EMAIL_UNAVAILABLE') {
    status = 503;
  } else {
    return next(error);
  }

  return res.status(status).json({
    success: false,
    error: {
      code: error.code,
      message: error.message,
    },
  });
}

async function login(req, res, next) {
  res.set('Cache-Control', 'no-store');
  try {
    const data = await loginService.requestLogin(req.body);
    return res.status(202).json({
      success: true,
      data: data,
    });
  } catch (error) {
    return handleLoginError(error, res, next);
  }
}

async function verifyLogin(req, res, next) {
  res.set('Cache-Control', 'no-store');
  try {
    const data = await loginService.verifyLogin(req.body);
    return res.status(200).json({
      success: true,
      data: data,
    });
  } catch (error) {
    return handleLoginError(error, res, next);
  }
}

function getMe(req, res) {
  return res.status(200).json({
    success: true,
    data: {
      user: req.user,
    },
  });
}

async function forgotPassword(req, res, next) {
  res.set('Cache-Control', 'no-store');
  try {
    const data = await passwordResetService.forgotPassword(req.body);
    return res.status(202).json({ success: true, data });
  } catch (error) {
    return handleLoginError(error, res, next);
  }
}

async function resetPassword(req, res, next) {
  res.set('Cache-Control', 'no-store');
  try {
    const data = await passwordResetService.resetPassword(req.body);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    return handleLoginError(error, res, next);
  }
}

module.exports = {
  register, googleLogin, verifyRegistration, login, verifyLogin, getMe,
  forgotPassword, resetPassword,
};
