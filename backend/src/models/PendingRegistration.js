const mongoose = require('mongoose');
const validator = require('validator');

const pendingRegistrationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 100,
    },

    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      maxlength: 254,
      unique: true,
      validate: {
        validator: (value) => validator.isEmail(value),
        message: 'Invalid email address.',
      },
    },

    passwordHash: {
      type: String,
      required: true,
      select: false,
      match: /^\$2[ab]\$\d{2}\$[./A-Za-z0-9]{53}$/,
    },

    otpHash: {
      type: String,
      required: true,
      select: false,
      match: /^[a-f0-9]{64}$/,
    },

    expiresAt: {
      type: Date,
      required: true,
    },

    attempts: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
      validate: {
        validator: Number.isInteger,
        message: 'Attempts must be an integer.',
      },
    },

    lastSentAt: {
      type: Date,
      required: true,
    },
  },
  { timestamps: true }
);

pendingRegistrationSchema.index(
  { expiresAt: 1 },
  { expireAfterSeconds: 0 }
);

module.exports = mongoose.model(
  'PendingRegistration',
  pendingRegistrationSchema
);