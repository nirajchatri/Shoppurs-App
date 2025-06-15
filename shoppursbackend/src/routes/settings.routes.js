const express = require('express');
const router = express.Router();
const { 
  getAdvertising, 
  getBrands, 
  getAppName,
  getAppSupport,
  getAppBankDetails
} = require('../controllers/settings.controller');

// Get all active advertising
router.get('/advertising', getAdvertising);

// Get all active brands
router.get('/brands', getBrands);

// Get app name only
router.get('/app-name', getAppName);

// Get app name and support information
router.get('/app-support', getAppSupport);

// Get app bank details and other information
router.get('/app-bank-details', getAppBankDetails);

module.exports = router; 