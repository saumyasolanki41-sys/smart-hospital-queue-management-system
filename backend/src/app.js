const express = require('express');
const mongoose = require('mongoose');
const authRoutes = require('./routes/auth.routes');
const hospitalRoutes = require('./routes/hospital.routes');
const queueRoutes = require('./routes/queue.routes');
const staffQueueRoutes = require('./routes/staff-queue.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const doctorDashboardRoutes = require('./routes/doctor-dashboard.routes');
const ambulanceRoutes = require('./routes/ambulance.routes');
const ambulanceRequestRoutes = require('./routes/ambulance-request.routes');
const cors = require('cors');
const app = express();
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || 'http://localhost:5173',
  methods: ['GET', 'POST', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));
app.use('/api/auth', authRoutes);
app.use('/api', hospitalRoutes);
app.use('/api/queue', queueRoutes);
app.use('/api/staff/queues', staffQueueRoutes);
app.use('/api/staff/dashboard', dashboardRoutes);
app.use('/api/doctor/dashboard', doctorDashboardRoutes);
app.use('/api/ambulances', ambulanceRoutes);
app.use('/api/ambulance-requests', ambulanceRequestRoutes);

app.get('/api/health', (req, res) => {
  const connected = mongoose.connection.readyState === 1;

  if (!connected) {
    return res.status(503).json({
      success: false,
      error: {
        code: 'SERVICE_UNAVAILABLE',
        message: 'Database is unavailable.',
      },
    });
  }

  return res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      database: 'connected',
    },
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found.',
    },
  });
});

app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);

  let status = 500;
  let code = 'INTERNAL_ERROR';
  let message = 'An unexpected error occurred.';

  if (err.type === 'entity.parse.failed') {
    status = 400;
    code = 'INVALID_JSON';
    message = 'Request body must contain valid JSON.';
  } else if (err.type === 'entity.too.large') {
    status = 413;
    code = 'BODY_TOO_LARGE';
    message = 'Request body exceeds the size limit.';
  }

  res.status(status).json({
    success: false,
    error: { code, message },
  });
});
module.exports = app;
