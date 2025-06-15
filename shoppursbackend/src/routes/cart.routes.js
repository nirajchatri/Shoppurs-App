const express = require('express');
const router = express.Router();
const { 
  addToCart, 
  addToCartAuto,
  addToCartByBarcode,
  editCartUnit,
  fetchCart, 
  placeOrder, 
  increaseQuantity, 
  decreaseQuantity,
  getCartItemCount
} = require('../controllers/cart.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { orderPaymentUpload } = require('../middleware/upload.middleware');

router.post('/add', authMiddleware, addToCart);
router.post('/add-auto', authMiddleware, addToCartAuto);
router.post('/add-by-barcode', authMiddleware, addToCartByBarcode);
router.post('/edit-unit', authMiddleware, editCartUnit);
router.get('/fetch', authMiddleware, fetchCart);
router.post('/place-order', authMiddleware, orderPaymentUpload, placeOrder);
router.post('/increase-quantity', authMiddleware, increaseQuantity);
router.post('/decrease-quantity', authMiddleware, decreaseQuantity);
router.get('/count', authMiddleware, getCartItemCount);

module.exports = router; 