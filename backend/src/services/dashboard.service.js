const Department = require('../models/Department');
const Doctor = require('../models/Doctor');
const QueueToken = require('../models/QueueToken');

function dashboardError() {
  const error = new Error('Use only a real date in YYYY-MM-DD format.');
  error.code = 'VALIDATION_ERROR';
  return error;
}

function dashboardDate(query) {
  if (Object.keys(query).some((key) => key !== 'date')) throw dashboardError();
  const date = query.date === undefined
    ? new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10)
    : query.date;
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
      !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date) {
    throw dashboardError();
  }

  return date;
}

function countTokens(rows) {
  const tokens = { total: 0, waiting: 0, called: 0, completed: 0, cancelled: 0, skipped: 0 };
  for (const row of rows) {
    tokens.total += row.count;
    if (['waiting', 'called', 'completed', 'cancelled', 'skipped'].includes(row._id)) {
      tokens[row._id] = row.count;
    }
  }
  return tokens;
}

async function getDashboard(query) {
  const date = dashboardDate(query);
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
  return { date, departments, doctors, tokens: countTokens(tokenCounts) };
}

async function getDoctorDashboard(userId, query) {
  const date = dashboardDate(query);
  const doctor = await Doctor.findOne({ user: userId })
    .select('name department specialization isAvailable averageConsultationMinutes')
    .populate('department', 'name').lean();
  if (!doctor) {
    const error = new Error('No doctor profile is linked to your account. Ask an admin to link it.');
    error.code = 'DOCTOR_NOT_FOUND';
    throw error;
  }
  const [tokenCounts, currentToken] = await Promise.all([
    QueueToken.aggregate([
      { $match: { doctor: doctor._id, queueDate: date } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
    QueueToken.findOne({ doctor: doctor._id, status: 'called' })
      .select('patient doctor queueDate tokenNumber status calledAt createdAt')
      .populate('patient', 'name').lean(),
  ]);
  return { date, doctor, tokens: countTokens(tokenCounts), currentToken };
}

module.exports = { getDashboard, getDoctorDashboard };
