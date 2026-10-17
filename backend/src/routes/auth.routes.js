const express = require('express');
const { register,  googleLogin,verifyRegistration, } = require('../controllers/auth.controller');
const { registrationLimiter,googleLoginLimiter,  verificationLimiter,} = require('../middleware/authLimiter');

const router = express.Router();

router.post('/register', registrationLimiter, register);
router.post('/register/verify', verificationLimiter, verifyRegistration);
router.post('/google', googleLoginLimiter, googleLogin);
module.exports = router;