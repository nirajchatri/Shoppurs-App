const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { userProfileUpload } = require('../middleware/upload.middleware');
const {
  updateProfile,
  getProfile,
  updateFcmToken,
  sendNotification,
  getAllFcmTokens
} = require('../controllers/user.controller');

// Apply authentication middleware to all routes
router.use(authMiddleware);

// User Profile Routes
router.put('/update-profile', userProfileUpload, updateProfile);
router.get('/profile', getProfile);

// FCM Token Routes
router.post('/update-fcm-token', updateFcmToken);
router.post('/send-notification', sendNotification);
router.get('/fcm-tokens', getAllFcmTokens);

module.exports = router; 