const mongoose = require('mongoose');

const queueTokenSchema = new mongoose.Schema({
  patient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctor: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: true },
  queueDate: { type: String, required: true, match: /^\d{4}-\d{2}-\d{2}$/ },
  tokenNumber: { type: Number, required: true, min: 1, validate: Number.isInteger },
  status: { type: String, enum: ['waiting', 'called', 'completed', 'cancelled', 'skipped'], default: 'waiting' },
  active: { type: Boolean, default: true, select: false },
  calledAt: { type: Date },
  completedAt: { type: Date },
  skippedAt: { type: Date },
  feedback: {
    type: new mongoose.Schema({
      rating: { type: Number, required: true, min: 1, max: 5, validate: Number.isInteger },
      comment: { type: String, maxlength: 1000, default: '' },
      submittedAt: { type: Date, required: true },
    }, { _id: false }),
    default: undefined,
  },
}, { timestamps: true });

queueTokenSchema.index({ doctor: 1, queueDate: 1, tokenNumber: 1 }, { unique: true });
queueTokenSchema.index({ patient: 1, doctor: 1, queueDate: 1 }, {
  unique: true, partialFilterExpression: { active: true },
});
queueTokenSchema.index({ patient: 1, queueDate: 1, createdAt: -1 });
queueTokenSchema.index({ doctor: 1 }, { unique: true, partialFilterExpression: { status: 'called' } });
queueTokenSchema.index({ queueDate: 1, status: 1 });

module.exports = mongoose.model('QueueToken', queueTokenSchema);
