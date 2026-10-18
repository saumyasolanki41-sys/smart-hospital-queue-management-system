const mongoose = require('mongoose');

const queueTokenSchema = new mongoose.Schema({
  patient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctor: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: true },
  queueDate: { type: String, required: true, match: /^\d{4}-\d{2}-\d{2}$/ },
  tokenNumber: { type: Number, required: true, min: 1, validate: Number.isInteger },
  status: { type: String, enum: ['waiting', 'called', 'completed', 'cancelled'], default: 'waiting' },
  active: { type: Boolean, default: true, select: false },
}, { timestamps: true });

queueTokenSchema.index({ doctor: 1, queueDate: 1, tokenNumber: 1 }, { unique: true });
queueTokenSchema.index({ patient: 1, doctor: 1, queueDate: 1 }, {
  unique: true, partialFilterExpression: { active: true },
});
queueTokenSchema.index({ patient: 1, queueDate: 1, createdAt: -1 });

module.exports = mongoose.model('QueueToken', queueTokenSchema);
