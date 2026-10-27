const mongoose = require('mongoose');
const validator = require('validator');
const User = require('../models/User');
const PendingRegistration = require('../models/PendingRegistration');
const otpService = require('./otp.service');

function verificationError(code, message, status = 400) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}

function invalidOtp() {
  return verificationError(
    'INVALID_OR_EXPIRED_OTP',
    'OTP is invalid or expired. Request a new OTP if needed.'
  );
}

function accountConflict() {
  return verificationError(
    'ACCOUNT_EXISTS',
    'Registration could not be completed. Use your existing sign-in method.',
    409
  );
}

async function verifyRegistration(body) {
  if (
    !body ||
    typeof body !== 'object' ||
    Array.isArray(body) ||
    Object.keys(body).some((key) => !['email', 'otp'].includes(key)) ||
    typeof body.email !== 'string' ||
    typeof body.otp !== 'string'
  ) {
    throw verificationError(
      'VALIDATION_ERROR',
      'Send email and OTP as strings.'
    );
  }

  const email = body.email.trim().toLowerCase();
  const otp = body.otp;

  if (
    email.length > 254 ||
    !validator.isEmail(email) ||
    !/^\d{6}$/.test(otp)
  ) {
    throw verificationError(
      'VALIDATION_ERROR',
      'Enter a valid email and six-digit OTP.'
    );
  }

  await Promise.all([User.init(), PendingRegistration.init()]);

  let result;

  try {
    result = await mongoose.connection.transaction(
      async (session) => {
        const pending = await PendingRegistration
          .findOne({ email })
          .select('+passwordHash +otpHash')
          .session(session);

        if (
          !pending ||
          pending.expiresAt.getTime() <= Date.now() ||
          pending.attempts >= 5
        ) {
          return { invalid: true };
        }

        const matches = otpService.verifyOtp(
          otp,
          pending._id.toString(),
          pending.otpHash
        );

        if (!matches) {
          await PendingRegistration.updateOne(
            {
              _id: pending._id,
              otpHash: pending.otpHash,
              attempts: pending.attempts,
            },
            { $inc: { attempts: 1 } },
            { session }
          );

          
          return { invalid: true };
        }

        const consumed = await PendingRegistration.findOneAndDelete(
          {
            _id: pending._id,
            otpHash: pending.otpHash,
            attempts: { $lt: 5 },
            expiresAt: { $gt: new Date() },
          },
          { session }
        );

        if (!consumed) {
          return { invalid: true };
        }

        if (await User.exists({ email }).session(session)) {
          return { conflict: true };
        }

        const [user] = await User.create(
          [{
            name: pending.name,
            email: pending.email,
            passwordHash: pending.passwordHash,
            emailVerifiedAt: new Date(),
            role: 'patient',
          }],
          { session }
        );

        return {
          user: {
            id: user._id.toString(),
            name: user.name,
            email: user.email,
            role: user.role,
          },
        };
      },
      {
        readConcern: { level: 'snapshot' },
        writeConcern: { w: 'majority' },
        readPreference: 'primary',
      }
    );
  } catch (error) {
    if (error.code === 11000) {
      throw accountConflict();
    }

    throw error;
  }

  if (result.invalid) throw invalidOtp();
  if (result.conflict) throw accountConflict();

  return result;
}

module.exports = { verifyRegistration };