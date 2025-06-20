const { pool: db } = require('../config/database');
const bcrypt = require('bcryptjs');
const path = require('path');
const QRCode = require('qrcode');

// Create directory function
function createDirectory(dirPath) {
  const fs = require('fs');
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

// Product Management APIs
const addProduct = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();

    const {
      prodSubCatId,
      prodName,
      prodCode,
      prodDesc,
      prodMrp,
      prodSp,
      prodReorderLevel,
      prodQoh,
      prodHsnCode,
      prodCgst,
      prodIgst,
      prodSgst,
      prodMfgDate,
      prodExpiryDate,
      prodMfgBy,
      prodCatId,
      isBarcodeAvailable = 'N',
      productUnits = [], // Array of product units
      barcodes = [] // Array of barcodes
    } = req.body;

    // Parse JSON strings if they are strings
    const parsedProductUnits = typeof productUnits === 'string' ? JSON.parse(productUnits) : productUnits;
    const parsedBarcodes = typeof barcodes === 'string' ? JSON.parse(barcodes) : barcodes;

    // Get uploaded image filenames
    const prodImage1 = req.uploadedFiles?.prodImage1 || null;
    const prodImage2 = req.uploadedFiles?.prodImage2 || null;
    const prodImage3 = req.uploadedFiles?.prodImage3 || null;

    // Insert product first
    const [result] = await connection.query(
      `INSERT INTO product_master (
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST, PROD_SGST,
        PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1, PROD_IMAGE_2,
        PROD_IMAGE_3, PROD_CAT_ID, IS_BARCODE_AVAILABLE, DEL_STATUS,
        CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', ?, ?, NOW(), NOW())`,
      [
        prodSubCatId, prodName, prodCode, prodDesc, prodMrp, prodSp,
        prodReorderLevel, prodQoh, prodHsnCode, prodCgst, prodIgst, prodSgst,
        prodMfgDate, prodExpiryDate, prodMfgBy, prodImage1, prodImage2,
        prodImage3, prodCatId, isBarcodeAvailable,
        req.user.USERNAME, req.user.USERNAME
      ]
    );

    const productId = result.insertId;

    // Insert product units if provided
    if (parsedProductUnits && parsedProductUnits.length > 0) {
      const unitValues = parsedProductUnits.map(unit => [
        productId,
        unit.unitName,
        unit.unitValue,
        unit.unitRate,
        'A', // PU_STATUS - Active
        req.user.USERNAME,
        req.user.USERNAME,
        new Date(),
        new Date()
      ]);

      await connection.query(
        `INSERT INTO product_unit (
          PU_PROD_ID, PU_PROD_UNIT, PU_PROD_UNIT_VALUE, PU_PROD_RATE,
          PU_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
        ) VALUES ?`,
        [unitValues]
      );
    }

    if (parsedBarcodes && parsedBarcodes.length > 0) {
      // Get the last barcode code
      const [lastBarcode] = await connection.query(
        'SELECT PRDB_CODE FROM product_barcodes ORDER BY PRDB_ID DESC LIMIT 1'
      );

      let nextNumber = 1;
      if (lastBarcode.length > 0) {
        const lastCode = lastBarcode[0].PRDB_CODE;
        const lastNumber = parseInt(lastCode.replace('BAR', ''));
        nextNumber = lastNumber + 1;
      }

      const barcodeValues = parsedBarcodes.map((barcode, index) => {
        const barcodeCode = `BAR${(nextNumber + index).toString().padStart(3, '0')}`;
        return [
          productId,
          barcodeCode,
          barcode.toString(), // Convert barcode to string in case it's a number
          'A' // SOLD_STATUS - Active
        ];
      });

      await connection.query(
        `INSERT INTO product_barcodes (
          PRDB_PROD_ID, PRDB_CODE, PRDB_BARCODE, SOLD_STATUS
        ) VALUES ?`,
        [barcodeValues]
      );

      // Update product to indicate it has barcodes
      await connection.query(
        'UPDATE product_master SET IS_BARCODE_AVAILABLE = "Y" WHERE PROD_ID = ?',
        [productId]
      );
    }

    await connection.commit();

    // Get the created product with all details
    const [createdProduct] = await connection.query(
      'SELECT * FROM product_master WHERE PROD_ID = ?',
      [productId]
    );

    // Get the product units
    const [productUnitsResult] = await connection.query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ? AND PU_STATUS = "A"',
      [productId]
    );

    // Get the product barcodes
    const [productBarcodes] = await connection.query(
      'SELECT * FROM product_barcodes WHERE PRDB_PROD_ID = ? AND SOLD_STATUS = "A"',
      [productId]
    );

    res.status(201).json({
      success: true,
      message: 'Product added successfully',
      data: {
        product: {
          ...createdProduct[0],
          PROD_IMAGE_1: createdProduct[0].PROD_IMAGE_1 ? `/uploads/products/${createdProduct[0].PROD_IMAGE_1}` : null,
          PROD_IMAGE_2: createdProduct[0].PROD_IMAGE_2 ? `/uploads/products/${createdProduct[0].PROD_IMAGE_2}` : null,
          PROD_IMAGE_3: createdProduct[0].PROD_IMAGE_3 ? `/uploads/products/${createdProduct[0].PROD_IMAGE_3}` : null
        },
        units: productUnitsResult,
        barcodes: productBarcodes
      }
    });
  } catch (error) {
    await connection.rollback();
    console.error('Add product error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding product',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

const editProduct = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { productId } = req.params;
    const {
      prodSubCatId,
      prodName,
      prodCode,
      prodDesc,
      prodMrp,
      prodSp,
      prodReorderLevel,
      prodQoh,
      prodHsnCode,
      prodCgst,
      prodIgst,
      prodSgst,
      prodMfgDate,
      prodExpiryDate,
      prodMfgBy,
      prodCatId,
      isBarcodeAvailable,
      productUnits = [], // Array of product units
      barcodes = [], // Array of barcodes
      removeImages = [] // Array of image numbers to remove (1, 2, or 3)
    } = req.body;

    // Parse JSON strings if they are strings
    const parsedProductUnits = typeof productUnits === 'string' ? JSON.parse(productUnits) : productUnits;
    const parsedBarcodes = typeof barcodes === 'string' ? JSON.parse(barcodes) : barcodes;
    const parsedRemoveImages = typeof removeImages === 'string' ? JSON.parse(removeImages) : removeImages;

    // First check if product exists
    const [existingProduct] = await connection.query(
      'SELECT * FROM product_master WHERE PROD_ID = ?',
      [productId]
    );

    if (existingProduct.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get uploaded image filenames
    const prodImage1 = req.uploadedFiles?.prodImage1 || null;
    const prodImage2 = req.uploadedFiles?.prodImage2 || null;
    const prodImage3 = req.uploadedFiles?.prodImage3 || null;

    // Prepare image update fields
    const currentProduct = existingProduct[0];
    const updatedImages = {
      PROD_IMAGE_1: parsedRemoveImages.includes(1) ? null : (prodImage1 || currentProduct.PROD_IMAGE_1),
      PROD_IMAGE_2: parsedRemoveImages.includes(2) ? null : (prodImage2 || currentProduct.PROD_IMAGE_2),
      PROD_IMAGE_3: parsedRemoveImages.includes(3) ? null : (prodImage3 || currentProduct.PROD_IMAGE_3)
    };

    // Update product details
    await connection.query(
      `UPDATE product_master SET 
        PROD_SUB_CAT_ID = ?, PROD_NAME = ?, PROD_CODE = ?, PROD_DESC = ?,
        PROD_MRP = ?, PROD_SP = ?, PROD_REORDER_LEVEL = ?, PROD_QOH = ?,
        PROD_HSN_CODE = ?, PROD_CGST = ?, PROD_IGST = ?, PROD_SGST = ?,
        PROD_MFG_DATE = ?, PROD_EXPIRY_DATE = ?, PROD_MFG_BY = ?,
        PROD_IMAGE_1 = ?, PROD_IMAGE_2 = ?, PROD_IMAGE_3 = ?,
        PROD_CAT_ID = ?, IS_BARCODE_AVAILABLE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE PROD_ID = ?`,
      [
        prodSubCatId, prodName, prodCode, prodDesc, prodMrp, prodSp,
        prodReorderLevel, prodQoh, prodHsnCode, prodCgst, prodIgst, prodSgst,
        prodMfgDate, prodExpiryDate, prodMfgBy,
        updatedImages.PROD_IMAGE_1, updatedImages.PROD_IMAGE_2, updatedImages.PROD_IMAGE_3,
        prodCatId, isBarcodeAvailable, req.user.USERNAME, productId
      ]
    );

    // Handle product units
    if (parsedProductUnits && parsedProductUnits.length > 0) {
      // Deactivate all existing units
      await connection.query(
        'UPDATE product_unit SET PU_STATUS = "I" WHERE PU_PROD_ID = ?',
        [productId]
      );

      // Insert new units
      const unitValues = parsedProductUnits.map(unit => [
        productId,
        unit.unitName,
        unit.unitValue,
        unit.unitRate,
        'A', // PU_STATUS - Active
        req.user.USERNAME,
        req.user.USERNAME,
        new Date(),
        new Date()
      ]);

      await connection.query(
        `INSERT INTO product_unit (
          PU_PROD_ID, PU_PROD_UNIT, PU_PROD_UNIT_VALUE, PU_PROD_RATE,
          PU_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
        ) VALUES ?`,
        [unitValues]
      );
    }

    // Handle barcodes - First delete existing barcodes, then add new ones
    // Always delete existing barcodes first
    await connection.query(
      'DELETE FROM product_barcodes WHERE PRDB_PROD_ID = ?',
      [productId]
    );

    if (parsedBarcodes && parsedBarcodes.length > 0) {
      // Get the last barcode code
      const [lastBarcode] = await connection.query(
        'SELECT PRDB_CODE FROM product_barcodes ORDER BY PRDB_ID DESC LIMIT 1'
      );

      let nextNumber = 1;
      if (lastBarcode.length > 0) {
        const lastCode = lastBarcode[0].PRDB_CODE;
        const lastNumber = parseInt(lastCode.replace('BAR', ''));
        nextNumber = lastNumber + 1;
      }

      const barcodeValues = parsedBarcodes.map((barcode, index) => {
        const barcodeCode = `BAR${(nextNumber + index).toString().padStart(3, '0')}`;
        return [
          productId,
          barcodeCode,
          barcode.toString(), // Convert barcode to string in case it's a number
          'A' // SOLD_STATUS - Active
        ];
      });

      await connection.query(
        `INSERT INTO product_barcodes (
          PRDB_PROD_ID, PRDB_CODE, PRDB_BARCODE, SOLD_STATUS
        ) VALUES ?`,
        [barcodeValues]
      );

      // Update product to indicate it has barcodes
      await connection.query(
        'UPDATE product_master SET IS_BARCODE_AVAILABLE = "Y" WHERE PROD_ID = ?',
        [productId]
      );
    } else {
      // If no barcodes provided, update product to indicate no barcodes
      await connection.query(
        'UPDATE product_master SET IS_BARCODE_AVAILABLE = "N" WHERE PROD_ID = ?',
        [productId]
      );
    }

    await connection.commit();

    // Get updated product details
    const [updatedProduct] = await connection.query(
      'SELECT * FROM product_master WHERE PROD_ID = ?',
      [productId]
    );

    // Get active units
    const [activeUnits] = await connection.query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ? AND PU_STATUS = "A"',
      [productId]
    );

    // Get active barcodes
    const [activeBarcodes] = await connection.query(
      'SELECT * FROM product_barcodes WHERE PRDB_PROD_ID = ? AND SOLD_STATUS = "A"',
      [productId]
    );

    res.json({
      success: true,
      message: 'Product updated successfully',
      data: {
        product: {
          ...updatedProduct[0],
          PROD_IMAGE_1: updatedProduct[0].PROD_IMAGE_1 ? `/uploads/products/${updatedProduct[0].PROD_IMAGE_1}` : null,
          PROD_IMAGE_2: updatedProduct[0].PROD_IMAGE_2 ? `/uploads/products/${updatedProduct[0].PROD_IMAGE_2}` : null,
          PROD_IMAGE_3: updatedProduct[0].PROD_IMAGE_3 ? `/uploads/products/${updatedProduct[0].PROD_IMAGE_3}` : null
        },
        units: activeUnits,
        barcodes: activeBarcodes
      }
    });
  } catch (error) {
    await connection.rollback();
    console.error('Edit product error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating product',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Category Management APIs
const addCategory = async (req, res) => {
  try {
    const { categoryName, catImage } = req.body;

    const [result] = await db.promise().query(
      `INSERT INTO category (
        CATEGORY_NAME, CAT_IMAGE, DEL_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, 'N', ?, ?, NOW(), NOW())`,
      [categoryName, catImage, req.user.USERNAME, req.user.USERNAME]
    );

    res.status(201).json({
      success: true,
      message: 'Category added successfully',
      categoryId: result.insertId
    });
  } catch (error) {
    console.error('Add category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding category',
      error: error.message
    });
  }
};

const editCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;
    const { categoryName, catImage } = req.body;

    const [result] = await db.promise().query(
      `UPDATE category SET 
        CATEGORY_NAME = ?, CAT_IMAGE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE CATEGORY_ID = ?`,
      [categoryName, catImage, req.user.USERNAME, categoryId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      message: 'Category updated successfully'
    });
  } catch (error) {
    console.error('Edit category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating category',
      error: error.message
    });
  }
};

// User Management APIs
const fetchUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, userType } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE ISACTIVE = "Y"';
    let params = [];

    if (userType) {
      whereClause += ' AND USER_TYPE = ?';
      params.push(userType);
    }

    const [users] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
       ADDRESS, PHOTO, USER_TYPE, CREATED_DATE, UPDATED_DATE
       FROM user_info ${whereClause}
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM user_info ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalUsers: countResult[0].total,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Fetch users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching users',
      error: error.message
    });
  }
};

const searchUsers = async (req, res) => {
  try {
    const { query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const searchPattern = `%${query}%`;
    const [users] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
       ADDRESS, PHOTO, USER_TYPE, CREATED_DATE, UPDATED_DATE
       FROM user_info 
       WHERE ISACTIVE = "Y" AND (
         USERNAME LIKE ? OR EMAIL LIKE ? OR MOBILE LIKE ?
       )
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [searchPattern, searchPattern, searchPattern, parseInt(limit), offset]
    );

    res.json({
      success: true,
      data: users,
      searchQuery: query
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching users',
      error: error.message
    });
  }
};

const editUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      username,
      email,
      mobile,
      city,
      province,
      zip,
      address,
      userType,
      isActive
    } = req.body;

    // Check if user exists
    const [existingUser] = await db.promise().query(
      'SELECT USER_ID FROM user_info WHERE USER_ID = ?',
      [userId]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const [result] = await db.promise().query(
      `UPDATE user_info SET 
        USERNAME = ?, EMAIL = ?, MOBILE = ?, CITY = ?, PROVINCE = ?, ZIP = ?,
        ADDRESS = ?, USER_TYPE = ?, ISACTIVE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE USER_ID = ?`,
      [
        username, email, mobile, city, province, zip, address,
        userType, isActive, req.user.USERNAME, userId
      ]
    );

    res.json({
      success: true,
      message: 'User updated successfully'
    });
  } catch (error) {
    console.error('Edit user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user',
      error: error.message
    });
  }
};

// Order Management APIs
const fetchAllOrders = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, startDate, endDate } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    const conditions = [];
    if (status) {
      conditions.push('co.CO_STATUS = ?');
      params.push(status);
    }
    if (startDate) {
      conditions.push('co.CREATED_DATE >= ?');
      params.push(startDate);
    }
    if (endDate) {
      conditions.push('co.CREATED_DATE <= ?');
      params.push(endDate);
    }

    if (conditions.length > 0) {
      whereClause = 'WHERE ' + conditions.join(' AND ');
    }

    // Fetch orders with user details and item count
    const [orders] = await db.promise().query(
      `SELECT 
        co.CO_ID as ORDER_ID, 
        co.CO_NO as ORDER_NUMBER, 
        co.CO_CUST_CODE as USER_ID,
        co.CO_TOTAL_AMT as ORDER_TOTAL, 
        co.CO_STATUS as ORDER_STATUS, 
        co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS,
        co.CO_DELIVERY_CITY as DELIVERY_CITY,
        co.CO_DELIVERY_STATE as DELIVERY_STATE,
        co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
        co.CO_PINCODE as DELIVERY_PINCODE,
        '' as DELIVERY_LANDMARK,
        co.CO_PAYMENT_MODE as PAYMENT_METHOD, 
        co.CO_IMAGE as PAYMENT_IMAGE,
        co.CO_DELIVERY_NOTE as ORDER_NOTES,
        co.CREATED_DATE,
        co.UPDATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        COUNT(cod.COD_ID) as TOTAL_ITEMS
       FROM cust_order co 
       LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
       LEFT JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
       ${whereClause}
       GROUP BY co.CO_ID
       ORDER BY co.CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(DISTINCT co.CO_ID) as total 
       FROM cust_order co 
       LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
       ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalOrders: countResult[0].total,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Fetch orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching orders',
      error: error.message
    });
  }
};

const editOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, orderNotes, invoiceUrl } = req.body;

    // Check if order exists
    const [existingOrder] = await db.promise().query(
      'SELECT CO_ID, CO_NO FROM cust_order WHERE CO_ID = ?',
      [orderId]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Validate status
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order status. Valid statuses are: ' + validStatuses.join(', ')
      });
    }

    // Build update query based on status
    let updateQuery, updateParams;
    
    if (status === 'delivered' && invoiceUrl) {
      // If marking as delivered and invoice URL provided, update status, notes, and invoice URL
      updateQuery = `UPDATE cust_order SET 
        CO_STATUS = ?, 
        CO_DELIVERY_NOTE = ?, 
        INVOICE_URL = ?,
        UPDATED_DATE = NOW()
      WHERE CO_ID = ?`;
      updateParams = [status, orderNotes, invoiceUrl, orderId];
      
      // Also update payment status to completed if it was pending
      await db.promise().query(
        'UPDATE cust_payment SET PAYMENT_STATUS = ? WHERE PAYMENT_PAYMENT_INVOICE_NO = ? AND PAYMENT_STATUS IN ("pending", "cod")',
        ['done', existingOrder[0].CO_NO]
      );
    } else {
      // Standard status update
      updateQuery = `UPDATE cust_order SET 
        CO_STATUS = ?, 
        CO_DELIVERY_NOTE = ?, 
        UPDATED_DATE = NOW()
      WHERE CO_ID = ?`;
      updateParams = [status, orderNotes, orderId];
    }

    // Update order
    const [result] = await db.promise().query(updateQuery, updateParams);

    res.json({
      success: true,
      message: 'Order status updated successfully'
    });
  } catch (error) {
    console.error('Edit order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating order status',
      error: error.message
    });
  }
};

// Add new function to get order details with items
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Get order details with customer info
    const [orderResult] = await db.promise().query(
      `SELECT 
        co.CO_ID as ORDER_ID, 
        co.CO_NO as ORDER_NUMBER, 
        co.CO_CUST_CODE as USER_ID,
        co.CO_TOTAL_AMT as ORDER_TOTAL, 
        co.CO_STATUS as ORDER_STATUS, 
        co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS,
        co.CO_DELIVERY_CITY as DELIVERY_CITY,
        co.CO_DELIVERY_STATE as DELIVERY_STATE,
        co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
        co.CO_PINCODE as DELIVERY_PINCODE,
        '' as DELIVERY_LANDMARK,
        co.CO_PAYMENT_MODE as PAYMENT_METHOD, 
        co.CO_DELIVERY_NOTE as ORDER_NOTES,
        co.CO_IMAGE as PAYMENT_IMAGE_LEGACY,
        co.PAYMENT_IMAGE,
        co.INVOICE_URL,
        co.CREATED_DATE,
        co.UPDATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        u.ADDRESS as CUSTOMER_ADDRESS
       FROM cust_order co 
       LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
       WHERE co.CO_ID = ?`,
      [orderId]
    );

    if (orderResult.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items
    const [orderItems] = await db.promise().query(
      `SELECT 
        cod.COD_ID as ORDER_ITEM_ID,
        cod.PROD_ID,
        '' as UNIT_ID,
        cod.COD_QTY as QUANTITY,
        cod.PROD_SP as UNIT_PRICE,
        (cod.COD_QTY * cod.PROD_SP) as TOTAL_PRICE,
        cod.PROD_NAME,
        cod.PROD_CODE,
        cod.PROD_DESC,
        cod.PROD_IMAGE_1
       FROM cust_order_details cod
       WHERE cod.COD_CO_ID = ?`,
      [orderId]
    );

    // Get retailer info based on customer's phone number
    const [retailerInfo] = await db.promise().query(
      `SELECT 
        RET_ID,
        RET_CODE,
        RET_TYPE,
        RET_NAME,
        RET_SHOP_NAME,
        RET_MOBILE_NO,
        RET_ADDRESS,
        RET_PIN_CODE,
        RET_EMAIL_ID,
        RET_PHOTO,
        RET_COUNTRY,
        RET_STATE,
        RET_CITY,
        RET_GST_NO,
        RET_LAT,
        RET_LONG,
        RET_DEL_STATUS,
        SHOP_OPEN_STATUS,
        BARCODE_URL
       FROM retailer_info
       WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS != 'Y'
       LIMIT 1`,
      [orderResult[0].CUSTOMER_MOBILE]
    );

    const orderDetails = {
      ...orderResult[0],
      ORDER_ITEMS: orderItems,
      RETAILER_INFO: retailerInfo[0] || null,
      PAYMENT_IMAGE: orderResult[0].PAYMENT_IMAGE
    };

    res.json({
      success: true,
      data: orderDetails
    });
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order details',
      error: error.message
    });
  }
};

// Retailer Management APIs
const getAllRetailers = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    if (status) {
      whereClause = 'WHERE RET_DEL_STATUS = ?';
      params.push(status);
    }

    const [retailers] = await db.promise().query(
      `SELECT RET_ID, RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO,
       RET_ADDRESS, RET_PIN_CODE,RET_PHOTO, RET_EMAIL_ID, RET_COUNTRY, RET_STATE, RET_CITY,
       RET_GST_NO, RET_DEL_STATUS, SHOP_OPEN_STATUS, CREATED_DATE
       FROM retailer_info ${whereClause}
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM retailer_info ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        retailers,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalRetailers: countResult[0].total,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Get retailers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailers',
      error: error.message
    });
  }
};

const addRetailer = async (req, res) => {
  try {
    const {
      retCode,
      retType,
      retName,
      retShopName,
      retMobileNo,
      retAddress,
      retPinCode,
      retEmailId,
      retPhoto,
      retCountry,
      retState,
      retCity,
      retGstNo,
      retLat,
      retLong
    } = req.body;

    const [result] = await db.promise().query(
      `INSERT INTO retailer_info (
        RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, RET_ADDRESS,
        RET_PIN_CODE, RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY,
        RET_GST_NO, RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE,
        CREATED_BY, UPDATED_BY
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW(), NOW(), ?, ?)`,
      [
        retCode, retType, retName, retShopName, retMobileNo, retAddress,
        retPinCode, retEmailId, retPhoto, retCountry, retState, retCity,
        retGstNo, retLat, retLong, req.user.USERNAME, req.user.USERNAME
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Retailer added successfully',
      retailerId: result.insertId
    });
  } catch (error) {
    console.error('Add retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding retailer',
      error: error.message
    });
  }
};

const editRetailer = async (req, res) => {
  try {
    const { retailerId } = req.params;
    const {
      RET_CODE,
      RET_TYPE,
      RET_NAME,
      RET_SHOP_NAME,
      RET_MOBILE_NO,
      RET_ADDRESS,
      RET_PIN_CODE,
      RET_EMAIL_ID,
      RET_COUNTRY,
      RET_STATE,
      RET_CITY,
      RET_GST_NO,
      RET_LAT,
      RET_LONG,
      RET_DEL_STATUS,
      SHOP_OPEN_STATUS,
      BARCODE_URL
    } = req.body;

    // Validate retailer exists
    const [existingRetailer] = await db.promise().query(`
      SELECT RET_ID FROM retailer_info 
      WHERE RET_ID = ?
    `, [retailerId]);

    if (existingRetailer.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found'
      });
    }

    // Build dynamic update query based on provided fields
    const updateFields = [];
    const updateValues = [];

    if (RET_CODE !== undefined) {
      updateFields.push('RET_CODE = ?');
      updateValues.push(RET_CODE);
    }
    if (RET_TYPE !== undefined) {
      updateFields.push('RET_TYPE = ?');
      updateValues.push(RET_TYPE);
    }
    if (RET_NAME !== undefined) {
      updateFields.push('RET_NAME = ?');
      updateValues.push(RET_NAME);
    }
    if (RET_SHOP_NAME !== undefined) {
      updateFields.push('RET_SHOP_NAME = ?');
      updateValues.push(RET_SHOP_NAME);
    }
    if (RET_MOBILE_NO !== undefined) {
      // Validate mobile number format
      const mobileRegex = /^[6-9]\d{9}$/;
      if (!mobileRegex.test(RET_MOBILE_NO)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid mobile number format'
        });
      }
      updateFields.push('RET_MOBILE_NO = ?');
      updateValues.push(RET_MOBILE_NO);
    }
    if (RET_ADDRESS !== undefined) {
      updateFields.push('RET_ADDRESS = ?');
      updateValues.push(RET_ADDRESS);
    }
    if (RET_PIN_CODE !== undefined) {
      // Validate pin code format
      const pinCodeRegex = /^\d{6}$/;
      if (!pinCodeRegex.test(RET_PIN_CODE)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid pin code format'
        });
      }
      updateFields.push('RET_PIN_CODE = ?');
      updateValues.push(RET_PIN_CODE);
    }
    if (RET_EMAIL_ID !== undefined) {
      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (RET_EMAIL_ID && !emailRegex.test(RET_EMAIL_ID)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid email format'
        });
      }
      updateFields.push('RET_EMAIL_ID = ?');
      updateValues.push(RET_EMAIL_ID);
    }
    
    // Handle profile image upload
    if (req.uploadedFile) {
      updateFields.push('RET_PHOTO = ?');
      updateValues.push(req.uploadedFile.filename);
    }
    
    if (RET_COUNTRY !== undefined) {
      updateFields.push('RET_COUNTRY = ?');
      updateValues.push(RET_COUNTRY);
    }
    if (RET_STATE !== undefined) {
      updateFields.push('RET_STATE = ?');
      updateValues.push(RET_STATE);
    }
    if (RET_CITY !== undefined) {
      updateFields.push('RET_CITY = ?');
      updateValues.push(RET_CITY);
    }
    if (RET_GST_NO !== undefined) {
      updateFields.push('RET_GST_NO = ?');
      updateValues.push(RET_GST_NO);
    }
    if (RET_LAT !== undefined) {
      updateFields.push('RET_LAT = ?');
      updateValues.push(RET_LAT);
    }
    if (RET_LONG !== undefined) {
      updateFields.push('RET_LONG = ?');
      updateValues.push(RET_LONG);
    }
    if (RET_DEL_STATUS !== undefined) {
      updateFields.push('RET_DEL_STATUS = ?');
      updateValues.push(RET_DEL_STATUS);
    }
    if (SHOP_OPEN_STATUS !== undefined) {
      updateFields.push('SHOP_OPEN_STATUS = ?');
      updateValues.push(SHOP_OPEN_STATUS);
    }
    if (BARCODE_URL !== undefined) {
      updateFields.push('BARCODE_URL = ?');
      updateValues.push(BARCODE_URL);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields provided for update'
      });
    }

    // Always update UPDATED_DATE and UPDATED_BY
    updateFields.push('UPDATED_DATE = NOW()');
    updateFields.push('UPDATED_BY = ?');
    updateValues.push(req.user.USERNAME);

    // Add retailer ID for WHERE clause
    updateValues.push(retailerId);

    const updateQuery = `
      UPDATE retailer_info 
      SET ${updateFields.join(', ')}
      WHERE RET_ID = ?
    `;

    const [result] = await db.promise().query(updateQuery, updateValues);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found'
      });
    }

    // Fetch updated retailer data
    const [updatedRetailer] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_ID = ?
    `, [retailerId]);

    // Add photo URL if photo exists
    const retailerData = updatedRetailer[0];
    if (retailerData.RET_PHOTO) {
      retailerData.RET_PHOTO_URL = `http://localhost:3000/uploads/retailers/profiles/${retailerData.RET_PHOTO}`;
    }

    res.json({
      success: true,
      message: 'Retailer updated successfully by admin',
      data: retailerData,
      uploadedFile: req.uploadedFile ? {
        filename: req.uploadedFile.filename,
        url: `http://localhost:3000/uploads/retailers/profiles/${req.uploadedFile.filename}`
      } : null,
      updated_by: req.user.USERNAME,
      updated_fields: updateFields.length - 2 // Exclude UPDATED_DATE and UPDATED_BY from count
    });
  } catch (error) {
    console.error('Admin edit retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating retailer',
      error: error.message
    });
  }
};

const getSingleRetailer = async (req, res) => {
  try {
    const { retailerId } = req.params;

    const [retailers] = await db.promise().query(
      `SELECT * FROM retailer_info WHERE RET_ID = ?`,
      [retailerId]
    );

    if (retailers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found'
      });
    }

    res.json({
      success: true,
      data: retailers[0]
    });
  } catch (error) {
    console.error('Get single retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer details',
      error: error.message
    });
  }
};

// Add admin search orders function
const searchOrders = async (req, res) => {
  try {
    const { query } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Search orders by order number or user mobile
    const [orders] = await db.promise().query(`
      SELECT DISTINCT
        co.CO_ID as ORDER_ID, 
        co.CO_NO as ORDER_NUMBER, 
        co.CO_CUST_CODE as USER_ID,
        co.CO_TOTAL_AMT as ORDER_TOTAL, 
        co.CO_STATUS as ORDER_STATUS, 
        co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS,
        co.CO_DELIVERY_CITY as DELIVERY_CITY,
        co.CO_DELIVERY_STATE as DELIVERY_STATE,
        co.CO_PAYMENT_MODE as PAYMENT_METHOD,
        co.CREATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        COUNT(cod.COD_ID) as TOTAL_ITEMS,
        SUM(cod.COD_QTY) as TOTAL_QUANTITY
      FROM cust_order co 
      LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
      LEFT JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_NO LIKE ? 
         OR co.CO_CUST_MOBILE LIKE ?
      GROUP BY co.CO_ID
      ORDER BY 
        CASE 
          WHEN co.CO_NO = ? THEN 1
          WHEN co.CO_CUST_MOBILE = ? THEN 1
          WHEN co.CO_NO LIKE ? THEN 2
          WHEN co.CO_CUST_MOBILE LIKE ? THEN 2
          ELSE 3
        END,
        co.CREATED_DATE DESC
      LIMIT 50
    `, [`%${query}%`, `%${query}%`, query, query, `${query}%`, `${query}%`]);

    res.json({
      success: true,
      data: orders,
      count: orders.length,
      filters: {
        query: query
      }
    });
  } catch (error) {
    console.error('Admin search orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching orders',
      error: error.message
    });
  }
};

// Fetch all users with USER_TYPE employee
const fetchEmployees = async (req, res) => {
  try {
    const [employees] = await db.promise().query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ADDRESS, 
      CREATED_DATE, UPDATED_DATE, USER_TYPE, ISACTIVE 
      FROM user_info 
      WHERE USER_TYPE = 'employee' AND ISACTIVE = 'Y'
      ORDER BY CREATED_DATE DESC`
    );

    res.status(200).json({
      success: true,
      data: employees,
      message: 'Employees fetched successfully'
    });
  } catch (error) {
    console.error('Fetch employees error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employees',
      error: error.message
    });
  }
};

// Fetch all orders created by a specific employee
const fetchEmployeeOrders = async (req, res) => {
  try {
    const { employeeId } = req.params;
    console.log(employeeId);
    // First verify if the user is an employee
    const [employee] = await db.promise().query(
      `SELECT USER_ID, USER_TYPE 
      FROM user_info 
      WHERE USER_ID = ? AND USER_TYPE = 'employee' AND ISACTIVE = 'Y'`,
      [employeeId]
    );

    if (employee.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found or inactive'
      });
    }

    // Fetch all orders created by the employee
    const [orders] = await db.promise().query(
      `SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
              co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
              co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
              co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
              co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
              co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE,
              co.CREATED_DATE, co.UPDATED_DATE,
              co.CO_CUST_NAME as CUSTOMER_NAME, u.EMAIL as CUSTOMER_EMAIL, co.CO_CUST_MOBILE as CUSTOMER_MOBILE
      FROM cust_order co
      LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
      WHERE co.CREATED_BY = ?
      ORDER BY co.CREATED_DATE DESC`,
      [employeeId]
    );

    res.status(200).json({
      success: true,
      data: orders,
      message: 'Employee orders fetched successfully'
    });
  } catch (error) {
    console.error('Fetch employee orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employee orders',
      error: error.message
    });
  }
};

const getRetailerByPhone = async (req, res) => {
  try {
    let { phone } = req.params;

    // Validate phone number
    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Clean the phone number - remove +91 if present
    phone = phone.replace(/^\+91/, '');
    
    // Remove any spaces, dashes, or other non-numeric characters except +
    phone = phone.replace(/[^\d]/g, '');

    // Validate that we have a valid phone number after cleaning
    if (!phone || phone.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format'
      });
    }

    // Get retailer details by phone number
    const [retailer] = await db.promise().query(
      `SELECT 
        RET_ID, RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO,
        RET_ADDRESS, RET_PIN_CODE, RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY,
        RET_STATE, RET_CITY, RET_GST_NO, RET_LAT, RET_LONG, RET_DEL_STATUS,
        CREATED_DATE, UPDATED_DATE, CREATED_BY, UPDATED_BY, SHOP_OPEN_STATUS,
        BARCODE_URL
       FROM retailer_info 
       WHERE RET_MOBILE_NO = ?`,
      [phone]
    );

    if (retailer.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found with this phone number'
      });
    }

    res.json({
      success: true,
      data: retailer[0]
    });
  } catch (error) {
    console.error('Get retailer by phone error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer details',
      error: error.message
    });
  }
};

// Add new customer creation functionality
const createCustomer = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const {
      username,
      email,
      mobile,
      password = '123456', // Default password
      city,
      province,
      zip,
      address,
      // Address fields
      addressDetails,
      addressCity,
      addressState,
      addressCountry = 'India',
      addressPincode,
      landmark,
      addressType = 'Home',
      isDefaultAddress = true,
      // Retailer location fields
      lat,
      long
    } = req.body;

    // Validate required fields
    if (!username || !mobile) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Username and mobile number are required'
      });
    }

    // Validate mobile number format
    const mobileRegex = /^[6-9]\d{9}$/;
    if (!mobileRegex.test(mobile)) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Invalid mobile number format'
      });
    }

    // Check if user already exists
    const [existingUser] = await connection.query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email || `customer_${mobile}@shop.com`, mobile]
    );

    if (existingUser.length > 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Customer already exists with this email or mobile number'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const customerEmail = email || `customer_${mobile}@shop.com`;

    // Insert new customer
    const [userResult] = await connection.query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE, is_otp_verify, CREATED_BY
      ) VALUES (
        1, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'customer', 'Y', 1, ?
      )`,
      [username, customerEmail, mobile, hashedPassword, city, province, zip, address, req.user.USERNAME]
    );

    const userId = userResult.insertId;

    // Create customer address if address details provided
    if (addressDetails || addressCity) {
      await connection.query(
        `INSERT INTO customer_address (
          USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, LANDMARK, 
          ADDRESS_TYPE, IS_DEFAULT, DEL_STATUS, CREATED_DATE
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', NOW())`,
        [
          userId,
          addressDetails || address || 'Address not provided',
          addressCity || city || 'City not provided',
          addressState || province || 'State not provided',
          addressCountry,
          addressPincode || zip || '000000',
          landmark,
          addressType,
          isDefaultAddress ? 1 : 0
        ]
      );
    }

    // Auto-create retailer profile
    const [lastRetailer] = await connection.query(
      'SELECT RET_CODE FROM retailer_info ORDER BY RET_ID DESC LIMIT 1'
    );

    // Generate next retailer code
    let nextNumber = 1;
    if (lastRetailer.length > 0) {
      const lastCode = lastRetailer[0].RET_CODE;
      const lastNumber = parseInt(lastCode.replace('RET', ''));
      nextNumber = lastNumber + 1;
    }

    const retCode = `RET${nextNumber.toString().padStart(3, '0')}`;

    // Create QR code directory
    createDirectory(path.join(__dirname, '../../uploads/retailers/qrcode'));

    let qrFileName = null;
    try {
      // Generate QR code for the phone number
      qrFileName = `qr_${mobile}_${Date.now()}.png`;
      const qrPath = path.join(__dirname, '../../uploads/retailers/qrcode', qrFileName);
      
      // Convert phone to string and add country code
      const phoneWithCode = `+91${mobile.toString()}`;
      
      // Generate QR code
      await QRCode.toFile(qrPath, phoneWithCode, {
        errorCorrectionLevel: 'H',
        width: 500,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      });
    } catch (qrError) {
      console.error('QR Code generation error:', qrError);
      // Continue without QR code if generation fails
    }

    // Insert retailer profile
    await connection.query(
      `INSERT INTO retailer_info (
        RET_CODE, RET_TYPE, RET_NAME, RET_MOBILE_NO, RET_ADDRESS, RET_PIN_CODE, 
        RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, 
        RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE, 
        CREATED_BY, UPDATED_BY, BARCODE_URL
      ) VALUES (
        ?, 'Grocery', ?, ?, ?, ?, ?, 'default-photo.jpg', ?, ?, ?, 
        ?, ?, 'active', NOW(), NOW(), ?, ?, ?
      )`,
      [
        retCode,
        username,
        mobile,
        addressDetails || address || 'Not provided',
        addressPincode || zip || 0,
        customerEmail,
        addressCountry,
        addressState || province || 'Not provided',
        addressCity || city || 'Not provided',
        lat || null,
        long || null,
        req.user.USERNAME,
        req.user.USERNAME,
        qrFileName
      ]
    );

    await connection.commit();

    // Get created customer details
    const [customerDetails] = await connection.query(
      `SELECT u.*, r.RET_ID, r.RET_CODE, r.RET_TYPE 
       FROM user_info u 
       LEFT JOIN retailer_info r ON u.MOBILE = r.RET_MOBILE_NO 
       WHERE u.USER_ID = ?`,
      [userId]
    );

    // Get customer addresses
    const [addresses] = await connection.query(
      'SELECT * FROM customer_address WHERE USER_ID = ? AND DEL_STATUS = "N"',
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'Customer and retailer profile created successfully by admin',
      data: {
        customer: customerDetails[0],
        addresses: addresses,
        createdBy: req.user.USERNAME,
        defaultPassword: password
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Create customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating customer',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

const createCustomerWithMultipleAddresses = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const {
      username,
      email,
      mobile,
      password = '123456', // Default password
      city,
      province,
      zip,
      address,
      addresses = [], // Array of address objects
      // Retailer location fields
      lat,
      long
    } = req.body;

    // Validate required fields
    if (!username || !mobile) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Username and mobile number are required'
      });
    }

    // Validate mobile number format
    const mobileRegex = /^[6-9]\d{9}$/;
    if (!mobileRegex.test(mobile)) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Invalid mobile number format'
      });
    }

    // Check if user already exists
    const [existingUser] = await connection.query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email || `customer_${mobile}@shop.com`, mobile]
    );

    if (existingUser.length > 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Customer already exists with this email or mobile number'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const customerEmail = email || `customer_${mobile}@shop.com`;

    // Insert new customer
    const [userResult] = await connection.query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE, is_otp_verify, CREATED_BY
      ) VALUES (
        1, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'customer', 'Y', 1, ?
      )`,
      [username, customerEmail, mobile, hashedPassword, city, province, zip, address, req.user.USERNAME]
    );

    const userId = userResult.insertId;

    // Create multiple addresses if provided
    if (addresses && addresses.length > 0) {
      for (let i = 0; i < addresses.length; i++) {
        const addr = addresses[i];
        await connection.query(
          `INSERT INTO customer_address (
            USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, LANDMARK, 
            ADDRESS_TYPE, IS_DEFAULT, DEL_STATUS, CREATED_DATE
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', NOW())`,
          [
            userId,
            addr.address || 'Address not provided',
            addr.city || 'City not provided',
            addr.state || 'State not provided',
            addr.country || 'India',
            addr.pincode || '000000',
            addr.landmark,
            addr.addressType || 'Home',
            (i === 0 || addr.isDefault) ? 1 : 0 // First address or explicitly marked as default
          ]
        );
      }
    } else {
      // Create default address from basic info
      await connection.query(
        `INSERT INTO customer_address (
          USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, LANDMARK, 
          ADDRESS_TYPE, IS_DEFAULT, DEL_STATUS, CREATED_DATE
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', NOW())`,
        [
          userId,
          address || 'Address not provided',
          city || 'City not provided',
          province || 'State not provided',
          'India',
          zip || '000000',
          null,
          'Home',
          1
        ]
      );
    }

    // Auto-create retailer profile (same as single address function)
    const [lastRetailer] = await connection.query(
      'SELECT RET_CODE FROM retailer_info ORDER BY RET_ID DESC LIMIT 1'
    );

    let nextNumber = 1;
    if (lastRetailer.length > 0) {
      const lastCode = lastRetailer[0].RET_CODE;
      const lastNumber = parseInt(lastCode.replace('RET', ''));
      nextNumber = lastNumber + 1;
    }

    const retCode = `RET${nextNumber.toString().padStart(3, '0')}`;

    // Create QR code directory
    createDirectory(path.join(__dirname, '../../uploads/retailers/qrcode'));

    let qrFileName = null;
    try {
      qrFileName = `qr_${mobile}_${Date.now()}.png`;
      const qrPath = path.join(__dirname, '../../uploads/retailers/qrcode', qrFileName);
      const phoneWithCode = `+91${mobile.toString()}`;
      
      await QRCode.toFile(qrPath, phoneWithCode, {
        errorCorrectionLevel: 'H',
        width: 500,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      });
    } catch (qrError) {
      console.error('QR Code generation error:', qrError);
    }

    // Insert retailer profile
    await connection.query(
      `INSERT INTO retailer_info (
        RET_CODE, RET_TYPE, RET_NAME, RET_MOBILE_NO, RET_ADDRESS, RET_PIN_CODE, 
        RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, 
        RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE, 
        CREATED_BY, UPDATED_BY, BARCODE_URL
      ) VALUES (
        ?, 'Grocery', ?, ?, ?, ?, ?, 'default-photo.jpg', ?, ?, ?, 
        ?, ?, 'active', NOW(), NOW(), ?, ?, ?
      )`,
      [
        retCode,
        username,
        mobile,
        address || 'Not provided',
        zip || 0,
        customerEmail,
        'India',
        province || 'Not provided',
        city || 'Not provided',
        lat || null,
        long || null,
        req.user.USERNAME,
        req.user.USERNAME,
        qrFileName
      ]
    );

    await connection.commit();

    // Get created customer details
    const [customerDetails] = await connection.query(
      `SELECT u.*, r.RET_ID, r.RET_CODE, r.RET_TYPE 
       FROM user_info u 
       LEFT JOIN retailer_info r ON u.MOBILE = r.RET_MOBILE_NO 
       WHERE u.USER_ID = ?`,
      [userId]
    );

    // Get customer addresses
    const [customerAddresses] = await connection.query(
      'SELECT * FROM customer_address WHERE USER_ID = ? AND DEL_STATUS = "N"',
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'Customer with multiple addresses and retailer profile created successfully by admin',
      data: {
        customer: customerDetails[0],
        addresses: customerAddresses,
        createdBy: req.user.USERNAME,
        defaultPassword: password
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Create customer with multiple addresses error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating customer with multiple addresses',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

const getCustomerDetails = async (req, res) => {
  try {
    const { customerId } = req.params;

    // Get customer details with retailer info
    const [customerDetails] = await db.promise().query(
      `SELECT u.*, r.RET_ID, r.RET_CODE, r.RET_TYPE, r.RET_NAME as RETAILER_NAME,
              r.RET_ADDRESS as RETAILER_ADDRESS, r.RET_CITY as RETAILER_CITY,
              r.RET_STATE as RETAILER_STATE, r.RET_LAT, r.RET_LONG, r.BARCODE_URL
       FROM user_info u 
       LEFT JOIN retailer_info r ON u.MOBILE = r.RET_MOBILE_NO 
       WHERE u.USER_ID = ? AND u.ISACTIVE = 'Y'`,
      [customerId]
    );

    if (customerDetails.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Get customer addresses
    const [addresses] = await db.promise().query(
      'SELECT * FROM customer_address WHERE USER_ID = ? AND DEL_STATUS = "N" ORDER BY IS_DEFAULT DESC, CREATED_DATE DESC',
      [customerId]
    );

    // Get customer order summary
    const [orderSummary] = await db.promise().query(
      `SELECT 
        COUNT(*) as total_orders,
        SUM(CASE WHEN CO_STATUS = 'completed' THEN 1 ELSE 0 END) as completed_orders,
        SUM(CASE WHEN CO_STATUS = 'pending' THEN 1 ELSE 0 END) as pending_orders,
        SUM(CASE WHEN CO_STATUS = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
        SUM(CO_TOTAL_AMT) as total_order_value
       FROM cust_order 
       WHERE CO_CUST_MOBILE = ?`,
      [customerDetails[0].MOBILE]
    );

    res.json({
      success: true,
      message: 'Customer details fetched successfully',
      data: {
        customer: customerDetails[0],
        addresses: addresses,
        orderSummary: orderSummary[0] || {
          total_orders: 0,
          completed_orders: 0,
          pending_orders: 0,
          cancelled_orders: 0,
          total_order_value: 0
        }
      }
    });

  } catch (error) {
    console.error('Get customer details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching customer details',
      error: error.message
    });
  }
};

const searchCustomers = async (req, res) => {
  try {
    const { query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Search customers by name, email, mobile, or address
    const [customers] = await db.promise().query(
      `SELECT u.USER_ID, u.USERNAME, u.EMAIL, u.MOBILE, u.CITY, u.PROVINCE, 
              u.ADDRESS, u.CREATED_DATE, u.USER_TYPE, u.ISACTIVE,
              r.RET_ID, r.RET_CODE, r.RET_TYPE, r.RET_NAME as RETAILER_NAME
       FROM user_info u 
       LEFT JOIN retailer_info r ON u.MOBILE = r.RET_MOBILE_NO 
       WHERE u.USER_TYPE = 'customer' 
       AND u.ISACTIVE = 'Y'
       AND (
         u.USERNAME LIKE ? OR 
         u.EMAIL LIKE ? OR 
         u.MOBILE LIKE ? OR 
         u.CITY LIKE ? OR 
         u.ADDRESS LIKE ?
       )
       ORDER BY u.CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [
        `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`,
        parseInt(limit), offset
      ]
    );

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total
       FROM user_info u 
       WHERE u.USER_TYPE = 'customer' 
       AND u.ISACTIVE = 'Y'
       AND (
         u.USERNAME LIKE ? OR 
         u.EMAIL LIKE ? OR 
         u.MOBILE LIKE ? OR 
         u.CITY LIKE ? OR 
         u.ADDRESS LIKE ?
       )`,
      [`%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`]
    );

    const totalCustomers = countResult[0].total;
    const totalPages = Math.ceil(totalCustomers / limit);

    res.json({
      success: true,
      message: 'Customers search completed',
      data: {
        customers: customers,
        pagination: {
          currentPage: parseInt(page),
          totalPages: totalPages,
          totalCustomers: totalCustomers,
          limit: parseInt(limit),
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        searchQuery: query
      }
    });

  } catch (error) {
    console.error('Search customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching customers',
      error: error.message
    });
  }
};

// ===== User Management APIs (Employee & Admin Creation) =====

// Create Employee User by Admin
const createEmployeeUser = async (req, res) => {
  try {
    const {
      username,
      email,
      mobile,
      password = '123456', // Default password
      city,
      province,
      zip,
      address,
      photo = null,
      fcmToken = null,
      ulId = 2 // Default user level for employees
    } = req.body;

    // Validate required fields
    if (!username || !email || !mobile) {
      return res.status(400).json({
        success: false,
        message: 'Username, email, and mobile number are required'
      });
    }

    // Validate mobile number format
    const mobileRegex = /^[6-9]\d{9}$/;
    if (!mobileRegex.test(mobile)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid mobile number format'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    // Check if user already exists
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, mobile]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or mobile number'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new employee user
    const [userResult] = await db.promise().query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, UPDATED_BY, 
        USER_TYPE, ISACTIVE, is_otp_verify
      ) VALUES (
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, NOW(), ?, 'employee', 'Y', 1
      )`,
      [
        ulId, username, email, mobile, hashedPassword, city, province, zip, address,
        photo, fcmToken, req.user.USERNAME, req.user.USERNAME
      ]
    );

    const userId = userResult.insertId;

    // Get created user details (excluding password)
    const [createdUser] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
              ADDRESS, PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, 
              UPDATED_BY, USER_TYPE, ISACTIVE, is_otp_verify
       FROM user_info WHERE USER_ID = ?`,
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'Employee user created successfully by admin',
      data: {
        user: createdUser[0],
        createdBy: req.user.USERNAME,
        defaultPassword: password,
        userType: 'employee'
      }
    });

  } catch (error) {
    console.error('Create employee user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating employee user',
      error: error.message
    });
  }
};

// Create Admin User by Admin
const createAdminUser = async (req, res) => {
  try {
    const {
      username,
      email,
      mobile,
      password = '123456', // Default password
      city,
      province,
      zip,
      address,
      photo = null,
      fcmToken = null,
      ulId = 3 // Default user level for admins
    } = req.body;

    // Validate required fields
    if (!username || !email || !mobile) {
      return res.status(400).json({
        success: false,
        message: 'Username, email, and mobile number are required'
      });
    }

    // Validate mobile number format
    const mobileRegex = /^[6-9]\d{9}$/;
    if (!mobileRegex.test(mobile)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid mobile number format'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    // Check if user already exists
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, mobile]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or mobile number'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new admin user
    const [userResult] = await db.promise().query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, UPDATED_BY, 
        USER_TYPE, ISACTIVE, is_otp_verify
      ) VALUES (
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, NOW(), ?, 'admin', 'Y', 1
      )`,
      [
        ulId, username, email, mobile, hashedPassword, city, province, zip, address,
        photo, fcmToken, req.user.USERNAME, req.user.USERNAME
      ]
    );

    const userId = userResult.insertId;

    // Get created user details (excluding password)
    const [createdUser] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
              ADDRESS, PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, 
              UPDATED_BY, USER_TYPE, ISACTIVE, is_otp_verify
       FROM user_info WHERE USER_ID = ?`,
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'Admin user created successfully by admin',
      data: {
        user: createdUser[0],
        createdBy: req.user.USERNAME,
        defaultPassword: password,
        userType: 'admin'
      }
    });

  } catch (error) {
    console.error('Create admin user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating admin user',
      error: error.message
    });
  }
};

// Get User Details (Admin/Employee) by Admin
const getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    // Get user details
    const [userDetails] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
              ADDRESS, PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, 
              UPDATED_BY, USER_TYPE, ISACTIVE, is_otp_verify
       FROM user_info 
       WHERE USER_ID = ? AND USER_TYPE IN ('admin', 'employee') AND ISACTIVE = 'Y'`,
      [userId]
    );

    if (userDetails.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found or not an admin/employee'
      });
    }

    const user = userDetails[0];

    // Get additional statistics for employees
    let employeeStats = null;
    if (user.USER_TYPE === 'employee') {
      const [orderStats] = await db.promise().query(
        `SELECT 
          COUNT(CASE WHEN CO_TYPE = 'employee' THEN 1 END) as orders_created,
          SUM(CASE WHEN CO_TYPE = 'employee' THEN CO_TOTAL_AMT ELSE 0 END) as total_sales_value
         FROM cust_order 
         WHERE CREATED_BY = ?`,
        [user.USERNAME]
      );

      const [dwrStats] = await db.promise().query(
        `SELECT 
          COUNT(*) as total_dwr_entries,
          COUNT(CASE WHEN DWR_STATUS = 'approved' THEN 1 END) as completed_days
         FROM dwr_detail 
         WHERE DWR_EMP_ID = ? AND DEL_STATUS = 0`,
        [userId]
      );

      employeeStats = {
        orders_created: orderStats[0]?.orders_created || 0,
        total_sales_value: orderStats[0]?.total_sales_value || 0,
        total_dwr_entries: dwrStats[0]?.total_dwr_entries || 0,
        completed_days: dwrStats[0]?.completed_days || 0
      };
    }

    res.json({
      success: true,
      message: 'User details fetched successfully',
      data: {
        user: user,
        employeeStats: employeeStats
      }
    });

  } catch (error) {
    console.error('Get user details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user details',
      error: error.message
    });
  }
};

// Search Admin/Employee Users
const searchAdminEmployeeUsers = async (req, res) => {
  try {
    const { query, userType, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Build WHERE clause for user type filter
    let userTypeFilter = '';
    const queryParams = [];
    
    if (userType && ['admin', 'employee'].includes(userType)) {
      userTypeFilter = 'AND u.USER_TYPE = ?';
      queryParams.push(userType);
    } else {
      userTypeFilter = 'AND u.USER_TYPE IN (?, ?)';
      queryParams.push('admin', 'employee');
    }

    // Search users by name, email, mobile, or address
    const searchParams = [
      `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`
    ];

    const [users] = await db.promise().query(
      `SELECT u.USER_ID, u.UL_ID, u.USERNAME, u.EMAIL, u.MOBILE, u.CITY, 
              u.PROVINCE, u.ADDRESS, u.CREATED_DATE, u.USER_TYPE, u.ISACTIVE,
              u.CREATED_BY, u.is_otp_verify
       FROM user_info u 
       WHERE u.ISACTIVE = 'Y'
       ${userTypeFilter}
       AND (
         u.USERNAME LIKE ? OR 
         u.EMAIL LIKE ? OR 
         u.MOBILE LIKE ? OR 
         u.CITY LIKE ? OR 
         u.ADDRESS LIKE ?
       )
       ORDER BY u.CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...queryParams, ...searchParams, parseInt(limit), offset]
    );

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total
       FROM user_info u 
       WHERE u.ISACTIVE = 'Y'
       ${userTypeFilter}
       AND (
         u.USERNAME LIKE ? OR 
         u.EMAIL LIKE ? OR 
         u.MOBILE LIKE ? OR 
         u.CITY LIKE ? OR 
         u.ADDRESS LIKE ?
       )`,
      [...queryParams, ...searchParams]
    );

    const totalUsers = countResult[0].total;
    const totalPages = Math.ceil(totalUsers / limit);

    res.json({
      success: true,
      message: 'Admin/Employee users search completed',
      data: {
        users: users,
        pagination: {
          currentPage: parseInt(page),
          totalPages: totalPages,
          totalUsers: totalUsers,
          limit: parseInt(limit),
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        searchQuery: query,
        userTypeFilter: userType || 'all'
      }
    });

  } catch (error) {
    console.error('Search admin/employee users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching admin/employee users',
      error: error.message
    });
  }
};

// Update User Status (Activate/Deactivate)
const updateUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;

    // Validate isActive field
    if (isActive === undefined || !['Y', 'N'].includes(isActive)) {
      return res.status(400).json({
        success: false,
        message: 'isActive field is required and must be Y or N'
      });
    }

    // Check if user exists and is admin/employee
    const [existingUser] = await db.promise().query(
      'SELECT USER_ID, USERNAME, USER_TYPE FROM user_info WHERE USER_ID = ? AND USER_TYPE IN (?, ?)',
      [userId, 'admin', 'employee']
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found or not an admin/employee'
      });
    }

    // Prevent deactivating self
    if (req.user.USER_ID == userId && isActive === 'N') {
      return res.status(400).json({
        success: false,
        message: 'You cannot deactivate your own account'
      });
    }

    // Update user status
    await db.promise().query(
      'UPDATE user_info SET ISACTIVE = ?, UPDATED_DATE = NOW(), UPDATED_BY = ? WHERE USER_ID = ?',
      [isActive, req.user.USERNAME, userId]
    );

    // Get updated user details
    const [updatedUser] = await db.promise().query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, USER_TYPE, ISACTIVE, UPDATED_DATE
       FROM user_info WHERE USER_ID = ?`,
      [userId]
    );

    res.json({
      success: true,
      message: `User ${isActive === 'Y' ? 'activated' : 'deactivated'} successfully`,
      data: {
        user: updatedUser[0],
        updatedBy: req.user.USERNAME
      }
    });

  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user status',
      error: error.message
    });
  }
};

// Get Employee DWR Details by Admin
const getEmployeeDwrDetails = async (req, res) => {
  try {
    const { userId } = req.params;
    const { date, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    // Validate that the user_id is for an employee
    const [employeeCheck] = await db.promise().query(
      'SELECT USER_ID, USERNAME, USER_TYPE FROM user_info WHERE USER_ID = ? AND USER_TYPE = ? AND ISACTIVE = ?',
      [userId, 'employee', 'Y']
    );

    if (employeeCheck.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found or not active'
      });
    }

    const employee = employeeCheck[0];

    // Build date filter - limit to last 30 days
    let dateFilter = 'AND DWR_DATE >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
    const queryParams = [userId];
    
    if (date) {
      // Validate date format (YYYY-MM-DD)
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(date)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date format. Use YYYY-MM-DD format'
        });
      }
      
      // Check if requested date is within last 30 days
      const requestedDate = new Date(date);
      const fourteenDaysAgo = new Date();
      fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 30);
      
      if (requestedDate < fourteenDaysAgo) {
        return res.status(400).json({
          success: false,
          message: 'Date filter is limited to last 30 days only'
        });
      }
      
      dateFilter = 'AND DATE(DWR_DATE) = ? AND DWR_DATE >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
      queryParams.push(date);
    }

    // Get DWR details with pagination and join with sta_master for station names
    const [dwrData] = await db.promise().query(
      `SELECT 
        d.DWR_ID, d.DWR_EMP_ID, d.DWR_NO, d.DWR_DATE, d.DWR_STATUS, d.DWR_EXPENSES,
        d.DWR_START_STA, d.DWR_END_STA, d.DWR_START_LOC, d.DWR_END_LOC, 
        d.DWR_REMARKS, d.DWR_SUBMIT, d.DEL_STATUS, d.LAST_USER, d.TIME_STAMP,
        DATE(d.DWR_DATE) as work_date,
        DATE(d.DWR_SUBMIT) as start_time,
        DATE(d.TIME_STAMP) as end_time,
        TIME(d.DWR_SUBMIT) as start_time_only,
        TIME(d.TIME_STAMP) as end_time_only,
        start_sta.STA_NAME as start_station_name,
        end_sta.STA_NAME as end_station_name
      FROM dwr_detail d
      LEFT JOIN sta_master start_sta ON d.DWR_START_STA = start_sta.STA_ID AND start_sta.DEL_STATUS = 0
      LEFT JOIN sta_master end_sta ON d.DWR_END_STA = end_sta.STA_ID AND end_sta.DEL_STATUS = 0
      WHERE d.DWR_EMP_ID = ? AND d.DEL_STATUS = 0
      ${dateFilter}
      ORDER BY d.DWR_DATE DESC, d.DWR_ID DESC
      LIMIT ? OFFSET ?`,
      [...queryParams, parseInt(limit), offset]
    );

    // Get total count for pagination (with 30-day limit)
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total
       FROM dwr_detail d
       WHERE d.DWR_EMP_ID = ? AND d.DEL_STATUS = 0
       ${dateFilter}`,
      queryParams
    );

    const totalRecords = countResult[0].total;
    const totalPages = Math.ceil(totalRecords / limit);

    // Get summary statistics (with 30-day limit)
    const [summaryStats] = await db.promise().query(
      `SELECT 
        COUNT(*) as total_dwr_entries,
        COUNT(CASE WHEN d.DWR_STATUS = 'approved' THEN 1 END) as completed_days,
        COUNT(CASE WHEN d.DWR_STATUS = 'Draft' THEN 1 END) as draft_days,
        SUM(CASE WHEN d.DWR_EXPENSES IS NOT NULL THEN d.DWR_EXPENSES ELSE 0 END) as total_expenses,
        MIN(d.DWR_DATE) as first_work_date,
        MAX(d.DWR_DATE) as last_work_date
      FROM dwr_detail d
      WHERE d.DWR_EMP_ID = ? AND d.DEL_STATUS = 0
      ${dateFilter}`,
      queryParams
    );

    const summary = summaryStats[0];

    // Format the DWR data for better readability
    const formattedDwrData = dwrData.map(record => ({
      dwr_id: record.DWR_ID,
      dwr_number: record.DWR_NO,
      work_date: record.work_date,
      status: record.DWR_STATUS,
      day_start: {
        station_id: record.DWR_START_STA,
        station_name: record.start_station_name || 'Station not found',
        location: record.DWR_START_LOC,
        time: record.start_time_only,
        full_timestamp: record.DWR_SUBMIT
      },
      day_end: {
        station_id: record.DWR_END_STA,
        station_name: record.end_station_name || (record.DWR_END_STA ? 'Station not found' : null),
        location: record.DWR_END_LOC,
        time: record.end_time_only,
        full_timestamp: record.TIME_STAMP
      },
      expenses: record.DWR_EXPENSES || 0,
      remarks: record.DWR_REMARKS || '',
      last_updated_by: record.LAST_USER,
      is_completed: record.DWR_STATUS === 'approved'
    }));

    res.json({
      success: true,
      message: 'Employee DWR details fetched successfully (Last 30 days)',
      data: {
        employee: {
          user_id: employee.USER_ID,
          username: employee.USERNAME,
          user_type: employee.USER_TYPE
        },
        dwr_records: formattedDwrData,
        summary: {
          total_dwr_entries: summary.total_dwr_entries,
          completed_days: summary.completed_days,
          draft_days: summary.draft_days,
          total_expenses: summary.total_expenses,
          first_work_date: summary.first_work_date,
          last_work_date: summary.last_work_date,
          completion_rate: summary.total_dwr_entries > 0 
            ? Math.round((summary.completed_days / summary.total_dwr_entries) * 100) 
            : 0
        },
        pagination: {
          currentPage: parseInt(page),
          totalPages: totalPages,
          totalRecords: totalRecords,
          limit: parseInt(limit),
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        filters: {
          date_filter: date || null,
          employee_id: userId,
          data_limit: 'Last 30 days only'
        }
      }
    });

  } catch (error) {
    console.error('Get employee DWR details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employee DWR details',
      error: error.message
    });
  }
};

module.exports = {
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
  getRetailerByPhone,
  createCustomer,
  createCustomerWithMultipleAddresses,
  getCustomerDetails,
  searchCustomers,
  createEmployeeUser,
  createAdminUser,
  getUserDetails,
  searchAdminEmployeeUsers,
  updateUserStatus,
  getEmployeeDwrDetails
}; 