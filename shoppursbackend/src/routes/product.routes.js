const express = require('express');
const router = express.Router();
const { getProductList, getProductDetails, getProductsUnderCategory, getProductsUnderSubCategory, getProductUnits, searchProducts, getProductIdByBarcode } = require('../controllers/product.controller');
const { productImagesUpload } = require('../middleware/upload.middleware');
const authMiddleware = require('../middleware/auth.middleware');
const { base_url } = require('../../environment');

router.get('/list', authMiddleware, getProductList);
router.get('/details/:id', authMiddleware, getProductDetails);
router.get('/category/:categoryId', authMiddleware, getProductsUnderCategory);
router.get('/subcategory/:subCategoryId', authMiddleware, getProductsUnderSubCategory);
router.get('/units/:productId', authMiddleware, getProductUnits);
router.get('/search', authMiddleware, searchProducts);
router.post('/get-by-barcode', authMiddleware, getProductIdByBarcode);

// Example route for uploading product images
router.post('/upload-images', authMiddleware, productImagesUpload, (req, res) => {
  try {
    if (!req.uploadedFiles || req.uploadedFiles.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No product images uploaded'
      });
    }

    const uploadedImages = req.uploadedFiles.map(file => ({
      filename: file.filename,
      path: `${base_url}/uploads/products/${file.filename}`,
      full_path: `${base_url}/uploads/products/${file.filename}`,
      originalname: file.originalname,
      size: file.size
    }));

    res.json({
      success: true,
      message: `${req.uploadedFiles.length} product image(s) uploaded successfully`,
      data: {
        images: uploadedImages,
        count: req.uploadedFiles.length
      }
    });
  } catch (error) {
    console.error('Product images upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading product images',
      error: error.message
    });
  }
});

module.exports = router; 