const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const PendingRegistration = require('../models/PendingRegistration');
const { validateRegistration } = require('../validators/auth.validator');
const otpService = require('./otp.service');
const emailService = require('./email.service');

function serviceError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

async function requestRegistration(body) {
  const result = validateRegistration(body);

  if (result.error) {
    throw serviceError(400, 'VALIDATION_ERROR', result.error);
  }

  const { name, email, password } = result.data;


  await Promise.all([User.init(), PendingRegistration.init()]);

  const passwordHash = await bcrypt.hash(password, 12);

  const accepted = {
    message: 'If registration can proceed, an OTP will be sent to your email.',
  };

  
  if (await User.exists({ email })) {
    return accepted;
  }

  const existing = await PendingRegistration
    .findOne({ email })
    .select('_id')
    .lean();

  const challengeId = existing?._id ?? new mongoose.Types.ObjectId();
  const otp = otpService.generateOtp();
  const otpHash = otpService.hashOtp(otp, challengeId.toString());
  const now = new Date();

  try {
    await PendingRegistration.findOneAndUpdate(
      {
        _id: challengeId,
        email,
        lastSentAt: {
          $lte: new Date(now.getTime() - 60 * 1000),
        },
      },
      {
        $set: {
          name,
          email,
          passwordHash,
          otpHash,
          attempts: 0,
          expiresAt: new Date(now.getTime() + 5 * 60 * 1000),
          lastSentAt: now,
        },
      },
      {
        upsert: true,
        returnDocument: 'after',
        runValidators: true,
      }
    );
  } catch (error) {
    if (error.code === 11000) {
      throw serviceError(
        429,
        'REGISTRATION_COOLDOWN',
        'Please wait 60 seconds before requesting another OTP.'
      );
    }

    throw error;
  }

  try {
    await emailService.sendRegistrationOtp(email, otp);
  } catch {

    await PendingRegistration.deleteOne({
      _id: challengeId,
      otpHash,
    });

    throw serviceError(
      503,
      'EMAIL_UNAVAILABLE',
      'Registration email could not be sent. Please try again later.'
    );
  }

  return accepted;
}

module.exports = { requestRegistration };
