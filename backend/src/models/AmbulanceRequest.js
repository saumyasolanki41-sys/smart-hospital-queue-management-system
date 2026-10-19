const mongoose = require('mongoose');

const requestSchema = new mongoose.Schema({
  patient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  pickupAddress: { type: String, required: true, trim: true, minlength: 5, maxlength: 300 },
  latitude: { type: Number, required: true, min: -90, max: 90 },
  longitude: { type: Number, required: true, min: -180, max: 180 },
  contactPhone: { type: String, required: true, match: /^\+?[1-9]\d{9,14}$/ },
  status: { type: String, enum: ['pending', 'assigned', 'completed', 'cancelled'], default: 'pending' },
  active: { type: Boolean, default: true, select: false },
  ambulance: { type: mongoose.Schema.Types.ObjectId, ref: 'Ambulance' },
  assignedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  assignedAt: Date,
  completedAt: Date,
  cancelledAt: Date,
}, { timestamps: true });

requestSchema.index({ patient: 1 }, { unique: true, partialFilterExpression: { active: true } });
requestSchema.index({ ambulance: 1 }, { unique: true, partialFilterExpression: { status: 'assigned' } });
requestSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('AmbulanceRequest', requestSchema);
