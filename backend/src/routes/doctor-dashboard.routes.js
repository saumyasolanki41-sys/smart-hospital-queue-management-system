const express = require('express');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const { getDoctorDashboard } = require('../controllers/dashboard.controller');

const router = express.Router();
router.get('/', authenticate, allowRoles('doctor'), getDoctorDashboard);

module.exports = router;
