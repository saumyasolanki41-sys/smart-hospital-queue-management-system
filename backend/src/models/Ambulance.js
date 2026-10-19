const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  latitude: { type: Number, required: true, min: -90, max: 90 },
  longitude: { type: Number, required: true, min: -180, max: 180 },
  updatedAt: { type: Date, required: true },
}, { _id: false });

const ambulanceSchema = new mongoose.Schema({
  vehicleNumber: { type: String, required: true, unique: true, match: /^[A-Z0-9]{4,20}$/ },
  driverName: { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  driverPhone: { type: String, required: true, match: /^\+?[1-9]\d{9,14}$/ },
  status: { type: String, enum: ['available', 'busy', 'maintenance'], default: 'available', index: true },
  location: { type: locationSchema },
  activeRequest: { type: mongoose.Schema.Types.ObjectId, ref: 'AmbulanceRequest', select: false },
}, { timestamps: true });

module.exports = mongoose.model('Ambulance', ambulanceSchema);
