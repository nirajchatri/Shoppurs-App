const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { retailerProfileUpload, retailerBarcodeUpload } = require('../middleware/upload.middleware');
const { base_url } = require('../../environment');
const {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile,
  updateRetailerProfile,
  getRetailerByIdAdmin,
  searchRetailers
} = require('../controllers/retailer.controller');

// Get list of retailers
router.get('/list', authMiddleware, getRetailerList);

// Get retailer info
router.get('/info/:retailerId', authMiddleware, getRetailerInfo);

// Get retailer info by logged-in user's mobile number
router.get('/my-retailer', authMiddleware, getRetailerByUserMobile);

// Update retailer profile for logged-in user (with optional photo upload)
router.put('/my-retailer', authMiddleware, retailerProfileUpload, updateRetailerProfile);

// Get retailer info by ID (admin)
router.get('/admin/retailer-details/:retailerId', authMiddleware, getRetailerByIdAdmin);

// Search retailers by code, shop name, or mobile number
router.get('/search', authMiddleware, searchRetailers);

// Example route for uploading retailer profile image
router.post('/upload-profile', authMiddleware, retailerProfileUpload, (req, res) => {
  try {
    if (!req.uploadedFile) {
      return res.status(400).json({
        success: false,
        message: 'No profile image uploaded'
      });
    }

    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      data: {
        filename: req.uploadedFile.filename,
        path: `${base_url}/uploads/retailers/profiles/${req.uploadedFile.filename}`,
        full_path: `${base_url}/uploads/retailers/profiles/${req.uploadedFile.filename}`,
        originalname: req.uploadedFile.originalname,
        size: req.uploadedFile.size
      }
    });
  } catch (error) {
    console.error('Profile upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading profile image',
      error: error.message
    });
  }
});

// Example route for uploading retailer barcode image
router.post('/upload-barcode', authMiddleware, retailerBarcodeUpload, (req, res) => {
  try {
    if (!req.uploadedFile) {
      return res.status(400).json({
        success: false,
        message: 'No barcode image uploaded'
      });
    }

    res.json({
      success: true,
      message: 'Barcode image uploaded successfully',
      data: {
        filename: req.uploadedFile.filename,
        path: `${base_url}/uploads/retailers/barcodes/${req.uploadedFile.filename}`,
        full_path: `${base_url}/uploads/retailers/barcodes/${req.uploadedFile.filename}`,
        originalname: req.uploadedFile.originalname,
        size: req.uploadedFile.size
      }
    });
  } catch (error) {
    console.error('Barcode upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading barcode image',
      error: error.message
    });
  }
});

module.exports = router;
