const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { userProfileUpload } = require('../middleware/upload.middleware');
const {
  updateProfile,
  getProfile
} = require('../controllers/user.controller');

// Apply authentication middleware to all routes
router.use(authMiddleware);

// User Profile Routes
router.put('/update-profile', userProfileUpload, updateProfile);
router.get('/profile', getProfile);

module.exports = router; 