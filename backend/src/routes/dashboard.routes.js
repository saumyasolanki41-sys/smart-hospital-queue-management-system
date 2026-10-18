const express = require('express');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');
const { getDashboard } = require('../controllers/dashboard.controller');

const router = express.Router();
router.get('/', authenticate, allowRoles('admin', 'receptionist'), getDashboard);

module.exports = router;
