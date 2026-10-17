const crypto = require('node:crypto');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const LoginChallenge = require('../models/LoginChallenge');
const otpService = require('./otp.service');
const emailService = require('./email.service');
const tokenService = require('./token.service');
const { validateLogin, validateLoginVerification } = require('../validators/login.validator');

const OTP_EXPIRY_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;

let dummyHashPromise;

function loginError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function invalidOtp() {
  return loginError(
    400,
    'INVALID_OR_EXPIRED_OTP',
    'OTP is invalid or expired. Request a new login OTP if needed.'
  );
}

async function requestLogin(body) {
  const result = validateLogin(body);
  if (result.error) {
    throw loginError(400, 'VALIDATION_ERROR', result.error);
  }

  const email = result.data.email;
  const password = result.data.password;

  if (!dummyHashPromise) {
    const dummyPassword = crypto.randomBytes(32).toString('hex');
    dummyHashPromise = bcrypt.hash(dummyPassword, 12);
  }

  let dummyHash;
  try {
    dummyHash = await dummyHashPromise;
  } catch (error) {
    dummyHashPromise = undefined;
    throw error;
  }

  const user = await User.findOne({ email }).select('+passwordHash');

  let hashToCheck = dummyHash;
  if (user && user.passwordHash) {
    hashToCheck = user.passwordHash;
  }

  const isPasswordCorrect = await bcrypt.compare(password, hashToCheck);

  if (!user || !user.passwordHash || !user.emailVerifiedAt || !isPasswordCorrect) {
    throw loginError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect.');
  }

  await LoginChallenge.init();

  const existing = await LoginChallenge.findOne({ user: user._id })
    .select('_id')
    .lean();

  let challengeId;
  if (existing) {
    challengeId = existing._id;
  } else {
    challengeId = new mongoose.Types.ObjectId();
  }

  const otp = otpService.generateOtp();
  const otpHash = otpService.hashOtp(otp, challengeId.toString(), 'login');
  const now = new Date();
  const resendAllowedBefore = new Date(now.getTime() - RESEND_COOLDOWN_MS);
  const expiresAt = new Date(now.getTime() + OTP_EXPIRY_MS);

  try {
    await LoginChallenge.findOneAndUpdate(
      {
        _id: challengeId,
        user: user._id,
        lastSentAt: { $lte: resendAllowedBefore },
      },
      {
        $set: {
          user: user._id,
          passwordHashSnapshot: user.passwordHash,
          otpHash,
          attempts: 0,
          expiresAt: expiresAt,
          lastSentAt: now,
        },
      },
      {
        upsert: true,
        new: true,
        runValidators: true,
      }
    );
  } catch (error) {
    if (error.code === 11000) {
      throw loginError(
        429,
        'LOGIN_COOLDOWN',
        'Please wait 60 seconds before requesting another login OTP.'
      );
    }
    throw error;
  }

  try {
    await emailService.sendLoginOtp(user.email, otp);
  } catch {
    await LoginChallenge.deleteOne({ _id: challengeId, otpHash });
    throw loginError(
      503,
      'EMAIL_UNAVAILABLE',
      'Login email could not be sent. Please try again later.'
    );
  }

  return {
    challengeId: challengeId.toString(),
    message: 'Login OTP sent. Verify it to complete login.',
  };
}

async function verifyLogin(body) {
  const validation = validateLoginVerification(body);
  if (validation.error) {
    throw loginError(400, 'VALIDATION_ERROR', validation.error);
  }

  const challengeId = validation.data.challengeId;
  const otp = validation.data.otp;

  tokenService.getJwtKey();
  await LoginChallenge.init();

  async function checkOtpAndCreateToken(session) {
    const challenge = await LoginChallenge.findById(challengeId)
      .select('+otpHash +passwordHashSnapshot')
      .session(session);

    if (!challenge) {
      return { invalid: true };
    }

    if (challenge.expiresAt.getTime() <= Date.now()) {
      return { invalid: true };
    }

    if (challenge.attempts >= MAX_OTP_ATTEMPTS) {
      return { invalid: true };
    }

    const isOtpCorrect = otpService.verifyOtp(
      otp,
      challenge._id.toString(),
      challenge.otpHash,
      'login'
    );

    if (!isOtpCorrect) {
      await LoginChallenge.updateOne(
        {
          _id: challenge._id,
          otpHash: challenge.otpHash,
          attempts: challenge.attempts,
        },
        { $inc: { attempts: 1 } },
        { session }
      );
      return { invalid: true };
    }

    const user = await User.findById(challenge.user)
      .select('+passwordHash')
      .session(session);

    const consumed = await LoginChallenge.findOneAndDelete(
      {
        _id: challenge._id,
        otpHash: challenge.otpHash,
        attempts: { $lt: MAX_OTP_ATTEMPTS },
        expiresAt: { $gt: new Date() },
      },
      { session }
    );

    if (!consumed || !user) {
      return { invalid: true };
    }

    if (!user.emailVerifiedAt || !user.passwordHash) {
      return { invalid: true };
    }

    if (user.passwordHash !== challenge.passwordHashSnapshot) {
      return { invalid: true };
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

  const result = await mongoose.connection.transaction(
    checkOtpAndCreateToken,
    {
      readConcern: { level: 'snapshot' },
      writeConcern: { w: 'majority' },
      readPreference: 'primary',
    }
  );

  if (result.invalid) {
    throw invalidOtp();
  }

  return result;
}

module.exports = { requestLogin, verifyLogin };
