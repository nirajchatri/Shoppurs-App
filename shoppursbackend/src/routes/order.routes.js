const express = require('express');
const router = express.Router();
const { getOrderList, getOrderDetails, cancelOrder, searchOrders } = require('../controllers/order.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getOrderList);
router.get('/details/:orderId', authMiddleware, getOrderDetails);
router.put('/cancel/:orderId', authMiddleware, cancelOrder);
router.get('/search', authMiddleware, searchOrders);

module.exports = router; 