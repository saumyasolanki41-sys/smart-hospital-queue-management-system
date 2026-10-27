const { OAuth2Client } = require('google-auth-library');
const validator = require('validator');

const client = new OAuth2Client();

function authError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

async function verifyGoogleToken(idToken) {
  if (
    typeof idToken !== 'string' ||
    !idToken.trim() ||
    idToken.length > 8192
  ) {
    throw authError(400, 'INVALID_INPUT', 'Google ID token is required.');
  }

  const clientId = process.env.GOOGLE_WEB_CLIENT_ID?.trim();

  if (!clientId || !clientId.endsWith('.apps.googleusercontent.com')) {
    throw new Error('Configure GOOGLE_WEB_CLIENT_ID.');
  }

  let ticket;

  try {
    ticket = await client.verifyIdToken({
      idToken,
      audience: clientId,
    });
  } catch {
    throw authError(
      401,
      'INVALID_GOOGLE_TOKEN',
      'Google sign-in could not be verified.'
    );
  }

  const payload = ticket.getPayload();

  if (
    !payload ||
    typeof payload.sub !== 'string' ||
    !payload.sub ||
    typeof payload.email !== 'string' ||
    !validator.isEmail(payload.email) ||
    payload.email_verified !== true
  ) {
    throw authError(
      401,
      'INVALID_GOOGLE_TOKEN',
      'Google sign-in could not be verified.'
    );
  }

  const email = payload.email.trim().toLowerCase();

  const authoritativeEmail =
    email.endsWith('@gmail.com') ||
    (typeof payload.hd === 'string' && payload.hd.trim().length > 0);

  if (!authoritativeEmail) {
    throw authError(
      403,
      'EMAIL_VERIFICATION_REQUIRED',
      'Additional email verification is required.'
    );
  }

  const name = typeof payload.name === 'string'
    ? payload.name.replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, 100)
    : '';

  return {
    googleSubject: payload.sub,
    email,
    name: name.length >= 2 ? name : 'Google User',
  };
}

module.exports = { verifyGoogleToken };