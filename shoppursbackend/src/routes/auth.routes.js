const express = require('express');
const router = express.Router();
const { 
  signup, 
  login, 
  verifyOtp, 
  resetPassword, 
  verifyOtpPassword, 
  changePassword,
  requestPasswordReset,
  confirmOtpForPassword,
  resetPasswordWithPhone,
  resendOtp
} = require('../controllers/auth.controller');

router.post('/signup', signup);
router.post('/login', login);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);
router.post('/verify-otp-password', verifyOtpPassword);
router.post('/change-password', changePassword);

// New improved password reset APIs
router.post('/request-password-reset', requestPasswordReset);
router.post('/confirm-otp-for-password', confirmOtpForPassword);
router.post('/reset-password-with-phone', resetPasswordWithPhone);

// Resend OTP API
router.post('/resend-otp', resendOtp);

module.exports = router; 