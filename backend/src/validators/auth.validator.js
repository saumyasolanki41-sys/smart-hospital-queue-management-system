const validator = require('validator');

function validateRegistration(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Request body must be an object.' };
  }

  const allowedFields = ['name', 'email', 'password'];

  if (Object.keys(body).some((key) => !allowedFields.includes(key))) {
    return { error: 'Only name, email and password are allowed.' };
  }

  if (
    typeof body.name !== 'string' ||
    typeof body.email !== 'string' ||
    typeof body.password !== 'string'
  ) {
    return { error: 'Name, email and password are required as strings.' };
  }

  const name = body.name.trim();
  const email = body.email.trim().toLowerCase();
  const password = body.password;

  if (
    name.length < 2 ||
    name.length > 100 ||
    /[\u0000-\u001f\u007f]/.test(name)
  ) {
    return { error: 'Name must contain 2 to 100 characters without control characters.' };
  }

  if (email.length > 254 || !validator.isEmail(email)) {
    return { error: 'Enter a valid email address.' };
  }

  if (password.length < 8 || password.trim().length === 0) {
    return { error: 'Password must contain at least 8 characters.' };
  }

  if (Buffer.byteLength(password, 'utf8') > 72) {
    return { error: 'Password must not exceed 72 bytes.' };
  }

  return {
    data: { name, email, password },
  };
}

module.exports = { validateRegistration };