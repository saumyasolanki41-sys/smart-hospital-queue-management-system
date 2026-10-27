const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, sparse: true },
  name: { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  department: { type: mongoose.Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
  specialization: { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  experienceYears: { type: Number, min: 0, max: 80, default: 0, validate: Number.isInteger },
  consultationFee: { type: Number, min: 0, max: 100000, default: 0 },
  averageConsultationMinutes: { type: Number, min: 1, max: 120, default: 10, validate: Number.isInteger },
  isAvailable: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Doctor', doctorSchema);
