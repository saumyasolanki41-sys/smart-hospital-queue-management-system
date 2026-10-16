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

async function googleLogin(body) {
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
    accessToken: tokenService.issueAccessToken(user._id),
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

module.exports = { googleLogin };