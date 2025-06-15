const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile,
  updateRetailerProfile,
  getRetailerByIdAdmin,
  searchRetailers
} = require('../controllers/retailer.controller');
const { retailerProfileUpload, retailerBarcodeUpload } = require('../middleware/upload.middleware');

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

    // Here you would typically save the file path to the database
    // For now, just return the uploaded file info
    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      data: {
        filename: req.uploadedFile.filename,
        path: req.uploadedFile.path,
        url: `http://localhost:3000/uploads/retailers/profiles/${req.uploadedFile.filename}`,
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

    // Here you would typically save the file path to the database
    // For now, just return the uploaded file info
    res.json({
      success: true,
      message: 'Barcode image uploaded successfully',
      data: {
        filename: req.uploadedFile.filename,
        path: req.uploadedFile.path,
        url: `http://localhost:3000/uploads/retailers/barcodes/${req.uploadedFile.filename}`,
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
