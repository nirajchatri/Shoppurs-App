const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getAddressList,
  addAddress,
  editAddress,
  getDefaultAddress,
  setDefaultAddress
} = require('../controllers/address.controller');

// Get list of customer addresses
router.get('/list', authMiddleware, getAddressList);

// Get default address
router.get('/default', authMiddleware, getDefaultAddress);

// Add new customer address
router.post('/add', authMiddleware, addAddress);

// Edit customer address
router.put('/edit/:addressId', authMiddleware, editAddress);

// Set default address
router.put('/set-default/:addressId', authMiddleware, setDefaultAddress);

module.exports = router; 