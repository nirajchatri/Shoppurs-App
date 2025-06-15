const { pool: db } = require('../config/database');
const bcrypt = require('bcryptjs');

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
      `INSERT INTO product (
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
        'UPDATE product SET IS_BARCODE_AVAILABLE = "Y" WHERE PROD_ID = ?',
        [productId]
      );
    }

    await connection.commit();

    // Get the created product with all details
    const [createdProduct] = await connection.query(
      'SELECT * FROM product WHERE PROD_ID = ?',
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
      'SELECT * FROM product WHERE PROD_ID = ?',
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
      `UPDATE product SET 
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
        'UPDATE product SET IS_BARCODE_AVAILABLE = "Y" WHERE PROD_ID = ?',
        [productId]
      );
    } else {
      // If no barcodes provided, update product to indicate no barcodes
      await connection.query(
        'UPDATE product SET IS_BARCODE_AVAILABLE = "N" WHERE PROD_ID = ?',
        [productId]
      );
    }

    await connection.commit();

    // Get updated product details
    const [updatedProduct] = await connection.query(
      'SELECT * FROM product WHERE PROD_ID = ?',
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
      conditions.push('o.ORDER_STATUS = ?');
      params.push(status);
    }
    if (startDate) {
      conditions.push('o.CREATED_DATE >= ?');
      params.push(startDate);
    }
    if (endDate) {
      conditions.push('o.CREATED_DATE <= ?');
      params.push(endDate);
    }

    if (conditions.length > 0) {
      whereClause = 'WHERE ' + conditions.join(' AND ');
    }

    // Fetch orders with user details and item count
    const [orders] = await db.promise().query(
      `SELECT 
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.DELIVERY_COUNTRY,
        o.DELIVERY_PINCODE,
        o.DELIVERY_LANDMARK,
        o.PAYMENT_METHOD, 
        o.PAYMENT_IMAGE,
        o.ORDER_NOTES,
        o.CREATED_DATE,
        o.UPDATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        COUNT(oi.ORDER_ITEM_ID) as TOTAL_ITEMS
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
       LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
       ${whereClause}
       GROUP BY o.ORDER_ID
       ORDER BY o.CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(DISTINCT o.ORDER_ID) as total 
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
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
    const { status, orderNotes } = req.body;

    // Check if order exists
    const [existingOrder] = await db.promise().query(
      'SELECT ORDER_ID FROM orders WHERE ORDER_ID = ?',
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

    // Update order
    const [result] = await db.promise().query(
      `UPDATE orders SET 
        ORDER_STATUS = ?, 
        ORDER_NOTES = ?, 
        UPDATED_DATE = NOW()
      WHERE ORDER_ID = ?`,
      [status, orderNotes, orderId]
    );

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
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.DELIVERY_COUNTRY,
        o.DELIVERY_PINCODE,
        o.DELIVERY_LANDMARK,
        o.PAYMENT_METHOD, 
        o.ORDER_NOTES,
        o.PAYMENT_IMAGE,
        o.CREATED_DATE,
        o.UPDATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        u.ADDRESS as CUSTOMER_ADDRESS
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
       WHERE o.ORDER_ID = ?`,
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
        oi.ORDER_ITEM_ID,
        oi.PROD_ID,
        oi.UNIT_ID,
        oi.QUANTITY,
        oi.UNIT_PRICE,
        oi.TOTAL_PRICE,
        p.PROD_NAME,
        p.PROD_CODE,
        p.PROD_DESC,
        p.PROD_IMAGE_1
       FROM order_items oi
       LEFT JOIN product p ON oi.PROD_ID = p.PROD_ID
       WHERE oi.ORDER_ID = ?`,
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
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.PAYMENT_METHOD,
        o.CREATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        COUNT(oi.ORDER_ITEM_ID) as TOTAL_ITEMS,
        SUM(oi.QUANTITY) as TOTAL_QUANTITY
      FROM orders o 
      LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
      LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.ORDER_NUMBER LIKE ? 
         OR u.MOBILE LIKE ?
      GROUP BY o.ORDER_ID
      ORDER BY 
        CASE 
          WHEN o.ORDER_NUMBER = ? THEN 1
          WHEN u.MOBILE = ? THEN 1
          WHEN o.ORDER_NUMBER LIKE ? THEN 2
          WHEN u.MOBILE LIKE ? THEN 2
          ELSE 3
        END,
        o.CREATED_DATE DESC
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
      `SELECT o.*, u.USERNAME as CUSTOMER_NAME, u.EMAIL as CUSTOMER_EMAIL, u.MOBILE as CUSTOMER_MOBILE
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      WHERE o.CREATED_BY = ?
      ORDER BY o.CREATED_DATE DESC`,
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
  getRetailerByPhone
}; 