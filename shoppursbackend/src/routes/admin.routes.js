const express = require('express');
const router = express.Router();
const adminMiddleware = require('../middleware/admin.middleware');
const { productImagesUpload, retailerProfileUpload } = require('../middleware/upload.middleware');
const {
  addProduct,
  editProduct,
  addCategory,
  editCategory,
  fetchUsers,
  searchUsers,
  editUser,
  fetchAllOrders,
  editOrderStatus,
  getAllRetailers,
  addRetailer,
  editRetailer,
  getSingleRetailer,
  getOrderDetails,
  searchOrders,
  fetchEmployees,
  fetchEmployeeOrders,
  getRetailerByPhone
} = require('../controllers/admin.controller');

// Apply admin middleware to all routes
router.use(adminMiddleware);

// Product Management Routes
router.post('/add-product', productImagesUpload, addProduct);
router.put('/edit-product/:productId', productImagesUpload, editProduct);

// Category Management Routes
router.post('/add-category', addCategory);
router.put('/edit-category/:categoryId', editCategory);

// User Management Routes
router.get('/fetch-user', fetchUsers);
router.get('/search-user', searchUsers);
router.put('/edit-user/:userId', editUser);

// Order Management Routes
router.get('/fetch-all-orders', fetchAllOrders);
router.get('/get-order-details/:orderId', getOrderDetails);
router.put('/edit-order-status/:orderId', editOrderStatus);
router.get('/search-orders', searchOrders);

// Retailer Management Routes
router.get('/get-all-retailer-list', getAllRetailers);
router.post('/add-retailer', addRetailer);
router.put('/edit-retailer/:retailerId', retailerProfileUpload, editRetailer);
router.get('/get-details-single-retailer/:retailerId', getSingleRetailer);
router.get('/get-retailer-by-phone/:phone', getRetailerByPhone);

// Employee Management Routes
router.get('/employees', fetchEmployees);
router.get('/employee-orders/:employeeId', fetchEmployeeOrders);

module.exports = router; 