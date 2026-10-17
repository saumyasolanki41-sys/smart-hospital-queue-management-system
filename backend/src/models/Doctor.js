const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  department: { type: mongoose.Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
  specialization: { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  experienceYears: { type: Number, min: 0, max: 80, default: 0, validate: Number.isInteger },
  consultationFee: { type: Number, min: 0, max: 100000, default: 0 },
  isAvailable: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Doctor', doctorSchema);
