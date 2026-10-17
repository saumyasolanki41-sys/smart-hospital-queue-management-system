const mongoose = require('mongoose');

const passwordResetSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  passwordHashSnapshot: {
    type: String, required: true, select: false, match: /^\$2[ab]\$\d{2}\$[./A-Za-z0-9]{53}$/,
  },
  otpHash: { type: String, required: true, select: false, match: /^[a-f0-9]{64}$/ },
  attempts: { type: Number, default: 0, min: 0, max: 5, validate: Number.isInteger },
  expiresAt: { type: Date, required: true },
  lastSentAt: { type: Date, required: true },
}, { timestamps: true });

passwordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('PasswordReset', passwordResetSchema);
