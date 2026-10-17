const express = require('express');
const {
  register, googleLogin, verifyRegistration, login, verifyLogin, getMe,
  forgotPassword, resetPassword,
} = require('../controllers/auth.controller');
const {
  registrationLimiter, googleLoginLimiter, verificationLimiter,
  passwordLoginLimiter, loginVerificationLimiter, passwordResetLimiter,
} = require('../middleware/authLimiter');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register', registrationLimiter, register);
router.post('/register/verify', verificationLimiter, verifyRegistration);
router.post('/google', googleLoginLimiter, googleLogin);
router.post('/login', passwordLoginLimiter, login);
router.post('/login/verify', loginVerificationLimiter, verifyLogin);
router.get('/me', authenticate, getMe);
router.post('/forgot-password', passwordResetLimiter, forgotPassword);
router.post('/reset-password', passwordResetLimiter, resetPassword);
module.exports = router;
