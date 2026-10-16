const mongoose = require('mongoose');
const validator = require('validator');

const userSchema = new mongoose.Schema(
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
  required: function () {
    return !this.googleSubject;
  },
  select: false,
  match: /^\$2[ab]\$\d{2}\$[./A-Za-z0-9]{53}$/,
},
 googleSubject: {
  type: String,
  minlength: 1,
  maxlength: 255,
  unique: true,
  sparse: true,
  immutable: true,
},
    role: {
      type: String,
      enum: ['patient', 'doctor', 'receptionist', 'admin'],
      default: 'patient',
      required: true,
    },

    emailVerifiedAt: {
      type: Date,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);