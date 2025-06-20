const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getAddressList,
  addAddress,
  editAddress,
  getDefaultAddress
} = require('../controllers/address.controller');

// Get list of customer addresses
router.get('/list', authMiddleware, getAddressList);

// Get default address
router.get('/default', authMiddleware, getDefaultAddress);

// Add new customer address
router.post('/add', authMiddleware, addAddress);

// Edit customer address
router.put('/edit/:addressId', authMiddleware, editAddress);

module.exports = router; 