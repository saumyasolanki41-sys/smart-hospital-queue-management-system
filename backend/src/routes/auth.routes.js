const express = require('express');
const { register } = require('../controllers/auth.controller');
const { registrationLimiter } = require('../middleware/authLimiter');

const router = express.Router();

router.post('/register', registrationLimiter, register);

module.exports = router;