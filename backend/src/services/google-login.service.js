const User = require('../models/User');
const googleService = require('./google.service');
const tokenService = require('./token.service');

function loginError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function accountConflict() {
  return loginError(
    409,
    'ACCOUNT_LINK_REQUIRED',
    'Use your original sign-in method to link this Google account.'
  );
}

function validateBody(body) {
  if (
    !body ||
    typeof body !== 'object' ||
    Array.isArray(body) ||
    Object.keys(body).length !== 1 ||
    !Object.hasOwn(body, 'idToken')
  ) {
    throw loginError(
      400,
      'INVALID_INPUT',
      'Send only the idToken field.'
    );
  }

}

async function googleLogin(body) {
  validateBody(body);
  const identity = await googleService.verifyGoogleToken(body.idToken);

  tokenService.getJwtKey();

  await User.init();

  let user = await User.findOne({
    googleSubject: identity.googleSubject,
  });

  if (!user) {
    if (await User.exists({ email: identity.email })) {
      throw accountConflict();
    }

    try {
      user = await User.create({
        name: identity.name,
        email: identity.email,
        googleSubject: identity.googleSubject,
        emailVerifiedAt: new Date(),
        role: 'patient',
      });
    } catch (error) {
      if (error.code !== 11000) throw error;


      user = await User.findOne({
        googleSubject: identity.googleSubject,
      });

      if (!user) throw accountConflict();
    }
  }

  return {
    accessToken: tokenService.issueAccessToken(user._id, user.tokenVersion),
    tokenType: 'Bearer',
    expiresIn: 900,
    user: {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
    },
  };
}

async function linkGoogle(userId, body) {
  validateBody(body);
  const identity = await googleService.verifyGoogleToken(body.idToken);
  await User.init();
  const user = await User.findById(userId).select('email emailVerifiedAt googleSubject');
  if (!user || !user.emailVerifiedAt) {
    throw loginError(401, 'UNAUTHORIZED', 'Log in again before linking Google.');
  }
  if (user.email.toLowerCase() !== identity.email.toLowerCase()) {
    throw loginError(409, 'GOOGLE_EMAIL_MISMATCH', 'Choose the Google account with the same email as your current account.');
  }
  if (user.googleSubject && user.googleSubject !== identity.googleSubject) {
    throw loginError(409, 'GOOGLE_ALREADY_LINKED', 'A different Google identity is already linked to your account.');
  }
  const response = { googleLinked: true, message: 'Google linked successfully. You can now sign in with Google.' };
  if (user.googleSubject === identity.googleSubject) return response;
  try {
    const updated = await User.updateOne({
      _id: user._id, email: user.email, emailVerifiedAt: user.emailVerifiedAt,
      googleSubject: { $exists: false },
    }, { $set: { googleSubject: identity.googleSubject } }, {
      runValidators: true, overwriteImmutable: true,
    });
    if (updated.modifiedCount !== 1) {
      const current = await User.findById(userId).select('googleSubject');
      if (current?.googleSubject !== identity.googleSubject) {
        throw loginError(409, 'ACCOUNT_CHANGED', 'Account changed. Log in again before linking Google.');
      }
    }
  } catch (error) {
    if (error.code === 11000) {
      throw loginError(409, 'GOOGLE_ACCOUNT_IN_USE', 'This Google identity is already linked to another account.');
    }
    throw error;
  }
  return response;
}

module.exports = { googleLogin, linkGoogle };
