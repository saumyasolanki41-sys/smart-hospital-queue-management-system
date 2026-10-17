const validator = require('validator');

function hasOnlyFields(body, fields) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return false;
  }

  for (const field of Object.keys(body)) {
    if (!fields.includes(field)) {
      return false;
    }
  }

  return true;
}

function validateLogin(body) {
  if (!hasOnlyFields(body, ['email', 'password'])) {
    return { error: 'Send email and password as strings.' };
  }

  if (typeof body.email !== 'string' || typeof body.password !== 'string') {
    return { error: 'Send email and password as strings.' };
  }

  const email = body.email.trim().toLowerCase();
  const password = body.password;

  if (email.length > 254 || !validator.isEmail(email)) {
    return { error: 'Invalid login input.' };
  }

  if (password.length === 0 || Buffer.byteLength(password, 'utf8') > 72) {
    return { error: 'Invalid login input.' };
  }

  return {
    data: { email: email, password: password },
  };
}

function validateLoginVerification(body) {
  if (!hasOnlyFields(body, ['challengeId', 'otp'])) {
    return { error: 'Send a valid challengeId and six-digit OTP as strings.' };
  }

  if (typeof body.challengeId !== 'string' || typeof body.otp !== 'string') {
    return { error: 'Send a valid challengeId and six-digit OTP as strings.' };
  }

  const isValidId = /^[a-f0-9]{24}$/i.test(body.challengeId);
  const isValidOtp = /^\d{6}$/.test(body.otp);

  if (!isValidId || !isValidOtp) {
    return { error: 'Send a valid challengeId and six-digit OTP as strings.' };
  }

  return {
    data: { challengeId: body.challengeId, otp: body.otp },
  };
}

module.exports = { validateLogin, validateLoginVerification };
