const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const validator = require('validator');
const User = require('../models/User');
const PasswordReset = require('../models/PasswordReset');
const LoginChallenge = require('../models/LoginChallenge');
const otpService = require('./otp.service');
const emailService = require('./email.service');

function resetError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function validateInput(body, resetting) {
  const fields = resetting ? ['email', 'otp', 'newPassword'] : ['email'];
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).some((field) => !fields.includes(field))) {
    throw resetError('VALIDATION_ERROR', 'Send only the required fields.');
  }
  if (typeof body.email !== 'string' || body.email.length > 254 ||
      !validator.isEmail(body.email.trim())) {
    throw resetError('VALIDATION_ERROR', 'Send a valid email address.');
  }
  if (resetting && (typeof body.otp !== 'string' || !/^\d{6}$/.test(body.otp) ||
      typeof body.newPassword !== 'string' || body.newPassword.length < 8 || body.newPassword.trim().length === 0 ||
      Buffer.byteLength(body.newPassword, 'utf8') > 72)) {
    throw resetError('VALIDATION_ERROR', 'Send a six-digit OTP and a password of at least 8 characters, up to 72 bytes, not only whitespace.');
  }
  return body.email.trim().toLowerCase();
}

async function forgotPassword(body) {
  const email = validateInput(body, false);
  const response = { message: 'If this account supports password reset, an OTP will be sent to your email.' };
  const user = await User.findOne({ email }).select('+passwordHash');
  if (!user || !user.passwordHash || !user.emailVerifiedAt) return response;

  await PasswordReset.init();
  const existing = await PasswordReset.findOne({ user: user._id });
  const id = existing ? existing._id : new mongoose.Types.ObjectId();
  const otp = otpService.generateOtp();
  const otpHash = otpService.hashOtp(otp, id.toString(), 'password-reset');
  const now = new Date();

  try {
    await PasswordReset.findOneAndUpdate(
      { _id: id, user: user._id, lastSentAt: { $lte: new Date(now.getTime() - 60000) } },
      { $set: {
        user: user._id, passwordHashSnapshot: user.passwordHash, otpHash,
        attempts: 0, expiresAt: new Date(now.getTime() + 300000), lastSentAt: now,
      } },
      { upsert: true, returnDocument: 'after', runValidators: true }
    );
  } catch (error) {
    if (error.code === 11000) return response;
    throw error;
  }

  try {
    await emailService.sendPasswordResetOtp(email, otp);
  } catch {
    await PasswordReset.deleteOne({ _id: id, otpHash });
    throw resetError('EMAIL_UNAVAILABLE', 'Password reset email could not be sent. Please try again later.');
  }
  return response;
}

async function resetPassword(body) {
  const email = validateInput(body, true);
  await PasswordReset.init();
  await LoginChallenge.init();
  const passwordHash = await bcrypt.hash(body.newPassword, 12);

  const result = await mongoose.connection.transaction(async (session) => {
    const user = await User.findOne({ email }).select('+passwordHash').session(session);
    if (!user || !user.passwordHash || !user.emailVerifiedAt) return false;
    const challenge = await PasswordReset.findOne({ user: user._id })
      .select('+otpHash +passwordHashSnapshot').session(session);
    if (!challenge || challenge.attempts >= 5 || challenge.expiresAt <= new Date() ||
        challenge.passwordHashSnapshot !== user.passwordHash) return false;

    if (!otpService.verifyOtp(body.otp, challenge._id.toString(), challenge.otpHash, 'password-reset')) {
      await PasswordReset.updateOne(
        { _id: challenge._id, otpHash: challenge.otpHash, attempts: challenge.attempts },
        { $inc: { attempts: 1 } }, { session }
      );
      return false;
    }

    const consumed = await PasswordReset.findOneAndDelete({
      _id: challenge._id, otpHash: challenge.otpHash,
      attempts: { $lt: 5 }, expiresAt: { $gt: new Date() },
    }, { session });
    if (!consumed) return false;

    const updated = await User.updateOne(
      { _id: user._id, passwordHash: user.passwordHash },
      { $set: { passwordHash }, $inc: { tokenVersion: 1 } },
      { session, runValidators: true }
    );
    if (updated.modifiedCount !== 1) {
      throw resetError('INVALID_OR_EXPIRED_OTP', 'OTP is invalid or expired. Request a new password reset OTP.');
    }
    await LoginChallenge.deleteMany({ user: user._id }, { session });
    return true;
  }, {
    readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' }, readPreference: 'primary',
  });

  if (!result) {
    throw resetError('INVALID_OR_EXPIRED_OTP', 'OTP is invalid or expired. Request a new password reset OTP.');
  }
  return { message: 'Password reset successful. Log in with your new password.' };
}

module.exports = { forgotPassword, resetPassword };
