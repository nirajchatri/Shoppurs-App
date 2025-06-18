const express = require('express');
const router = express.Router();
const employeeMiddleware = require('../middleware/employee.middleware');
const { orderPaymentUpload, retailerProfileUpload } = require('../middleware/upload.middleware');
const {
  fetchOrders,
  searchOrders,
  getOrderDetails,
  updateOrderStatus,
  placeOrderForCustomer,
  getRetailerList,
  searchRetailers,
  editRetailer,
  getRetailerByPhone,
  getStaMaster,
  getTodayDwr,
  startDay,
  endDay,
  createCustomerByEmployee,
  createCustomerWithMultipleAddressesByEmployee,
  getCustomerDetailsByEmployee,
  searchCustomersByEmployee
} = require('../controllers/employee.controller');

// Apply employee middleware to all routes
router.use(employeeMiddleware);

// Order Management Routes
router.get('/orders', fetchOrders);
router.get('/orders/search', searchOrders);
router.get('/orders/:orderId', getOrderDetails);
router.put('/orders/:orderId/status', orderPaymentUpload, updateOrderStatus);
router.post('/place-order', placeOrderForCustomer);

// Retailer Management Routes
router.get('/retailers', getRetailerList);
router.get('/retailers/search', searchRetailers);
router.put('/retailers/:retailerId/edit', retailerProfileUpload, editRetailer);
router.get('/get-retailer-by-phone/:phone', getRetailerByPhone);

// STA Master Routes
router.get('/sta-master', getStaMaster);

// DWR (Daily Work Report) Routes
router.get('/dwr/today', getTodayDwr);
router.post('/dwr/start-day', startDay);
router.put('/dwr/end-day', endDay);

// Customer Management Routes
router.post('/create-customer', createCustomerByEmployee);
router.post('/create-customer-with-addresses', createCustomerWithMultipleAddressesByEmployee);
router.get('/get-customer-details/:customerId', getCustomerDetailsByEmployee);
router.get('/search-customers', searchCustomersByEmployee);

module.exports = router; 