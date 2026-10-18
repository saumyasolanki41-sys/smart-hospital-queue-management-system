const Department = require('../models/Department');
const Doctor = require('../models/Doctor');
const QueueToken = require('../models/QueueToken');

function dashboardError() {
  const error = new Error('Use only a real date in YYYY-MM-DD format.');
  error.code = 'VALIDATION_ERROR';
  return error;
}

async function getDashboard(query) {
  if (Object.keys(query).some((key) => key !== 'date')) throw dashboardError();
  const date = query.date === undefined
    ? new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10)
    : query.date;
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
      !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date) {
    throw dashboardError();
  }

  const [departments, doctorCounts, tokenCounts] = await Promise.all([
    Department.countDocuments({}),
    Doctor.aggregate([{ $group: {
      _id: null,
      total: { $sum: 1 },
      available: { $sum: { $cond: [{ $eq: ['$isAvailable', true] }, 1, 0] } },
    } }]),
    QueueToken.aggregate([
      { $match: { queueDate: date } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
  ]);

  const doctors = { total: 0, available: 0 };
  if (doctorCounts.length) {
    doctors.total = doctorCounts[0].total;
    doctors.available = doctorCounts[0].available;
  }
  const tokens = { total: 0, waiting: 0, called: 0, completed: 0, cancelled: 0 };
  for (const row of tokenCounts) {
    tokens.total += row.count;
    if (['waiting', 'called', 'completed', 'cancelled'].includes(row._id)) {
      tokens[row._id] = row.count;
    }
  }

  return { date, departments, doctors, tokens };
}

module.exports = { getDashboard };
