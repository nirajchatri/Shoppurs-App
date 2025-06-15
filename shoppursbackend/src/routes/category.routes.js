const express = require('express');
const router = express.Router();
const { getCategoryList, getSubCategoriesByCategoryId } = require('../controllers/category.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getCategoryList);
router.get('/:categoryId/subcategories', authMiddleware, getSubCategoriesByCategoryId);

module.exports = router; 