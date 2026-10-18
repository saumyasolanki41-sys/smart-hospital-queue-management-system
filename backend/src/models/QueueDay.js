const mongoose = require('mongoose');

const queueDaySchema = new mongoose.Schema({
  _id: { type: String, required: true },
  lastToken: { type: Number, default: 0, min: 0, validate: Number.isInteger },
});

module.exports = mongoose.model('QueueDay', queueDaySchema);
