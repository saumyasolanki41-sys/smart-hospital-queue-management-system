const express = require('express');
const {
  register, googleLogin, verifyRegistration, login, verifyLogin,
} = require('../controllers/auth.controller');
const {
  registrationLimiter, googleLoginLimiter, verificationLimiter,
  passwordLoginLimiter, loginVerificationLimiter,
} = require('../middleware/authLimiter');

const router = express.Router();

router.post('/register', registrationLimiter, register);
router.post('/register/verify', verificationLimiter, verifyRegistration);
router.post('/google', googleLoginLimiter, googleLogin);
router.post('/login', passwordLoginLimiter, login);
router.post('/login/verify', loginVerificationLimiter, verifyLogin);
module.exports = router;
