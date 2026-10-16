const express = require('express');
const { register,  googleLogin, } = require('../controllers/auth.controller');
const { registrationLimiter,googleLoginLimiter,} = require('../middleware/authLimiter');

const router = express.Router();

router.post('/register', registrationLimiter, register);
router.post('/google', googleLoginLimiter, googleLogin);
module.exports = router;