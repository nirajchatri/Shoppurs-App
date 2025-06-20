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

// Fetch all orders with status filtering
const fetchOrders = async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT 
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
        co.CO_PAYMENT_MODE as PAYMENT_METHOD,
        co.CO_DELIVERY_NOTE as ORDER_NOTES,
        co.CO_IMAGE as PAYMENT_IMAGE,
        co.CREATED_DATE,
        co.UPDATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM cust_order co
      LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
      WHERE 1=1
    `;
    
    const queryParams = [];

    // Add status filter if provided
    if (status) {
      query += ` AND co.CO_STATUS = ?`;
      queryParams.push(status);
    }

    // Add sorting and pagination
    query += ` ORDER BY co.CREATED_DATE DESC LIMIT ? OFFSET ?`;
    queryParams.push(parseInt(limit), offset);

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM cust_order co WHERE 1=1 ${status ? 'AND co.CO_STATUS = ?' : ''}`,
      status ? [status] : []
    );

    const [orders] = await db.promise().query(query, queryParams);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total: countResult[0].total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(countResult[0].total / limit)
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

// Search orders by ORDER_NUMBER or user's MOBILE
const searchOrders = async (req, res) => {
  try {
    const { query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const searchQuery = `
      SELECT 
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
        co.CO_PAYMENT_MODE as PAYMENT_METHOD,
        co.CO_DELIVERY_NOTE as ORDER_NOTES,
        co.CO_IMAGE as PAYMENT_IMAGE,
        co.CREATED_DATE,
        co.UPDATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM cust_order co
      LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
      WHERE co.CO_NO LIKE ? OR co.CO_CUST_MOBILE LIKE ?
      ORDER BY 
        CASE 
          WHEN co.CO_NO = ? THEN 1
          WHEN co.CO_CUST_MOBILE = ? THEN 1
          WHEN co.CO_NO LIKE ? THEN 2
          WHEN co.CO_CUST_MOBILE LIKE ? THEN 2
          ELSE 3
        END,
        co.CREATED_DATE DESC
      LIMIT ? OFFSET ?
    `;

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total 
       FROM cust_order co 
       WHERE co.CO_NO LIKE ? OR co.CO_CUST_MOBILE LIKE ?`,
      [`%${query}%`, `%${query}%`]
    );

    const [orders] = await db.promise().query(
      searchQuery,
      [
        `%${query}%`, `%${query}%`,
        query, query,
        `%${query}%`, `%${query}%`,
        parseInt(limit), offset
      ]
    );

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total: countResult[0].total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(countResult[0].total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Search orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching orders',
      error: error.message
    });
  }
};

// Get order details by ID
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

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
        co.CO_PAYMENT_MODE as PAYMENT_METHOD,
        co.CO_DELIVERY_NOTE as ORDER_NOTES,
        co.CO_IMAGE as PAYMENT_IMAGE,
        co.CREATED_DATE,
        co.UPDATED_DATE,
        co.CO_CUST_NAME as CUSTOMER_NAME,
        co.CO_CUST_MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM cust_order co
      LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
      WHERE co.CO_ID = ?`,
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items if needed
    const [orderItems] = await db.promise().query(
      `SELECT cod.COD_ID as ORDER_ITEM_ID, cod.COD_CO_ID as ORDER_ID,
              cod.PROD_ID, cod.COD_QTY as QUANTITY, cod.PROD_SP as UNIT_PRICE,
              (cod.COD_QTY * cod.PROD_SP) as TOTAL_PRICE,
              cod.PROD_NAME, cod.PROD_CODE, cod.PROD_MRP as PROD_MRP,
              cod.PROD_SP, cod.PROD_IMAGE_1, cod.PROD_IMAGE_2, cod.PROD_IMAGE_3,
              cod.PROD_UNIT as PU_PROD_UNIT, 
              COALESCE(p.PROD_HSN_CODE, cod.PROD_BARCODE, '') as PROD_HSN_CODE,
              COALESCE(cod.PROD_CGST, p.PROD_CGST, 0) as PROD_CGST,
              COALESCE(cod.PROD_SGST, p.PROD_SGST, 0) as PROD_SGST,
              COALESCE(cod.PROD_IGST, p.PROD_IGST, 0) as PROD_IGST
       FROM cust_order_details cod
       LEFT JOIN product_master p ON cod.PROD_ID = p.PROD_ID
       WHERE cod.COD_CO_ID = ?`,
      [orderId]
    );

    res.json({
      success: true,
      data: {
        ...orders[0],
        items: orderItems
      }
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

// Update order status
const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, long, lat } = req.body;
    const employeeUserId = req.user.USER_ID; // Get employee user ID from JWT token

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Order status is required'
      });
    }

    // Validate status value
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status value. Valid values are: ' + validStatuses.join(', ')
      });
    }

    // First check if order exists
    const [orders] = await db.promise().query(
      'SELECT CO_ID, CO_STATUS, CO_IMAGE FROM cust_order WHERE CO_ID = ?',
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Don't allow status change if order is already cancelled or delivered
    const currentStatus = orders[0].CO_STATUS.toLowerCase();
    if (currentStatus === 'cancelled' || currentStatus === 'delivered') {
      return res.status(400).json({
        success: false,
        message: `Cannot change status of ${currentStatus} order`
      });
    }

    // Get uploaded image filename if present
    const paymentImage = req.uploadedFile ? req.uploadedFile.filename : orders[0].CO_IMAGE;

    // Build dynamic update query based on provided fields
    let updateFields = [
      'CO_STATUS = ?',
      'CO_IMAGE = ?',
      'PAYMENT_IMAGE = ?',
      'CO_DELIVER_BY = ?',
      'UPDATED_DATE = NOW()'
    ];
    let updateValues = [status.toLowerCase(), paymentImage, paymentImage, employeeUserId];

    // Add delivery coordinates if provided
    if (lat !== undefined) {
      updateFields.push('CO_DELIVERY_LAT = ?');
      updateValues.push(lat);
    }
    if (long !== undefined) {
      updateFields.push('CO_DELIVERY_LONG = ?');
      updateValues.push(long);
    }

    // Add orderId for WHERE clause
    updateValues.push(orderId);

    // Update order status, payment image, delivery person, and coordinates
    await db.promise().query(
      `UPDATE cust_order 
       SET ${updateFields.join(', ')}
       WHERE CO_ID = ?`,
      updateValues
    );

    // If status is delivered, generate invoice PDF and QR code, and insert into invoice_master and invoice_detail
    if (status.toLowerCase() === 'delivered') {
      const [orderDetails] = await db.promise().query(
        `SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
                co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
                co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
                co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
                co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
                co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE,
                co.CO_CUST_NAME as USERNAME, co.CO_CUST_MOBILE as MOBILE,
                u.EMAIL, u.ADDRESS as USER_ADDRESS, u.CITY, u.PROVINCE, u.ZIP
         FROM cust_order co
         LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
         WHERE co.CO_ID = ?`,
        [orderId]
      );
      const order = orderDetails[0];
      const [orderItems] = await db.promise().query(
        `SELECT cod.COD_ID as ORDER_ITEM_ID, cod.COD_CO_ID as ORDER_ID,
                cod.PROD_ID, cod.COD_QTY as QUANTITY, cod.PROD_SP as UNIT_PRICE,
                (cod.COD_QTY * cod.PROD_SP) as TOTAL_PRICE,
                cod.PROD_NAME, cod.PROD_CODE, cod.PROD_MRP as PROD_MRP,
                cod.PROD_SP, cod.PROD_IMAGE_1, cod.PROD_IMAGE_2, cod.PROD_IMAGE_3,
                cod.PROD_UNIT as PU_PROD_UNIT, 
                COALESCE(p.PROD_HSN_CODE, cod.PROD_BARCODE, '') as PROD_HSN_CODE,
                COALESCE(cod.PROD_CGST, p.PROD_CGST, 0) as PROD_CGST,
                COALESCE(cod.PROD_SGST, p.PROD_SGST, 0) as PROD_SGST,
                COALESCE(cod.PROD_IGST, p.PROD_IGST, 0) as PROD_IGST
         FROM cust_order_details cod
         LEFT JOIN product_master p ON cod.PROD_ID = p.PROD_ID
         WHERE cod.COD_CO_ID = ?`,
        [orderId]
      );
      // Generate invoice number (e.g., INV + orderId)
      const invoiceNumber = `INV${orderId}`;
      
      // Calculate tax totals from order items
      let totalCGST = 0;
      let totalSGST = 0;
      let totalIGST = 0;
      let totalTaxableValue = 0;

      orderItems.forEach(item => {
        const itemTaxableValue = parseFloat(item.PROD_SP || 0) * parseInt(item.QUANTITY || 0);
        const cgstRate = parseFloat(item.PROD_CGST || 0);
        const sgstRate = parseFloat(item.PROD_SGST || 0);
        const igstRate = parseFloat(item.PROD_IGST || 0);
        
        totalTaxableValue += itemTaxableValue;
        totalCGST += (itemTaxableValue * cgstRate) / 100;
        totalSGST += (itemTaxableValue * sgstRate) / 100;
        totalIGST += (itemTaxableValue * igstRate) / 100;
      });

      const totalTaxAmount = totalCGST + totalSGST + totalIGST;
      
      // Generate PDF and QR code
      const invoicePath = await require('../utils/invoiceGenerator').generateInvoicePDF({ order, orderItems, invoiceNumber });
      // Insert into invoice_master
      const [invoiceResult] = await db.promise().query(
        `INSERT INTO invoice_master (
          INVM_NO, INVM_TRANS_ID, INVM_DATE, INVM_CUST_ID, INVM_CUST_NAME, INVM_CUST_ADDRESS, INVM_CUST_MOBILE, INVM_CUST_GST,
          INVM_TOT_CGST, INVM_TOT_SGST, INVM_TOT_IGST, INVM_TOT_DISCOUNT_AMOUNT, INVM_TOT_TAX_AMOUNT, INVM_TOT_AMOUNT, INVM_TOT_NET_PAYABLE,
          INVM_STATUS, INVM_PAYMENT_MODE, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
        ) VALUES (?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [
          invoiceNumber,
          `TR${orderId}`,
          order.USER_ID,
          order.USERNAME,
          order.USER_ADDRESS || order.DELIVERY_ADDRESS,
          order.MOBILE,
          '', // INVM_CUST_GST
          totalCGST.toFixed(2), // INVM_TOT_CGST
          totalSGST.toFixed(2), // INVM_TOT_SGST
          totalIGST.toFixed(2), // INVM_TOT_IGST
          0, // INVM_TOT_DISCOUNT_AMOUNT
          totalTaxAmount.toFixed(2), // INVM_TOT_TAX_AMOUNT
          order.ORDER_TOTAL,
          order.ORDER_TOTAL,
          'active',
          'cod',
          req.user.USERNAME || 'system',
          req.user.USERNAME || 'system'
        ]
      );
      const invoiceId = invoiceResult.insertId;
      // Insert into invoice_detail for each item
      for (const item of orderItems) {
        const itemTaxableValue = parseFloat(item.PROD_SP || 0) * parseInt(item.QUANTITY || 0);
        const cgstAmount = (itemTaxableValue * parseFloat(item.PROD_CGST || 0)) / 100;
        const sgstAmount = (itemTaxableValue * parseFloat(item.PROD_SGST || 0)) / 100;
        const igstAmount = (itemTaxableValue * parseFloat(item.PROD_IGST || 0)) / 100;
        
        await db.promise().query(
          `INSERT INTO invoice_detail (INVD_INVM_ID, INVD_PROD_ID, INVD_PROD_CODE, INVD_PROD_NAME, INVD_PROD_UNIT, INVD_QTY, INVD_HSN_CODE, INVD_MRP, INVD_SP, INVD_DISCOUNT_PERCENTAGE, INVD_DISCOUNT_AMOUNT, INVD_CGST, INVD_SGST, INVD_IGST, INVD_PROD_IMAGE_1, INVD_PROD_IMAGE_2, INVD_PROD_IMAGE_3, INVD_TAMOUNT, INVD_PROD_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?, ?, ?, 'A', ?, ?, NOW(), NOW())`,
          [invoiceId, item.PROD_ID, item.PROD_CODE, item.PROD_NAME, item.PU_PROD_UNIT, item.QUANTITY, item.PROD_HSN_CODE, item.PROD_MRP, item.PROD_SP, cgstAmount.toFixed(2), sgstAmount.toFixed(2), igstAmount.toFixed(2), item.PROD_IMAGE_1, item.PROD_IMAGE_2, item.PROD_IMAGE_3, item.TOTAL_PRICE, req.user.USERNAME || 'system', req.user.USERNAME || 'system']
        );
      }
      // Update the cust_order table with the invoice URL
      await db.promise().query(
        'UPDATE cust_order SET INVOICE_URL = ? WHERE CO_ID = ?',
        [`/uploads/invoice/${invoiceNumber}.pdf`, orderId]
      );

      // Update payment status in cust_payment table
      await db.promise().query(
        'UPDATE cust_payment SET PAYMENT_STATUS = ? WHERE PAYMENT_PAYMENT_INVOICE_NO = ? AND PAYMENT_STATUS IN ("pending", "cod")',
        ['done', order.ORDER_NUMBER]
      );
    }

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: {
        orderId,
        oldStatus: currentStatus,
        newStatus: status.toLowerCase(),
        deliveredBy: employeeUserId,
        paymentImage: paymentImage ? `/uploads/orders/${paymentImage}` : null,
        deliveryCoordinates: {
          latitude: lat || null,
          longitude: long || null
        },
        updatedAt: new Date()
      }
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating order status',
      error: error.message
    });
  }
};

// Place order on behalf of retailer/customer using employee's cart
const placeOrderForCustomer = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { phoneNumber, notes } = req.body;
    const employeeUserId = req.user.USER_ID; // Get employee user ID from JWT token

    if (!phoneNumber) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Find retailer/customer by phone number using user_info table
    const [retailers] = await connection.query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, ADDRESS, USER_TYPE, ISACTIVE 
       FROM user_info 
       WHERE MOBILE = ? AND ISACTIVE = "Y"`,
      [phoneNumber]
    );

    if (retailers.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Retailer/Customer not found with this phone number'
      });
    }

    const retailer = retailers[0];
    const retailerUserId = retailer.USER_ID;

    // Get employee's cart items (employee who is logged in)
    const [cartItems] = await connection.query(`
      SELECT c.*, p.PROD_NAME, p.PROD_MRP, p.PROD_SP, p.PROD_CODE,
             p.PROD_DESC, p.PROD_CGST, p.PROD_IGST, p.PROD_SGST,
             p.PROD_IMAGE_1, p.PROD_IMAGE_2, p.PROD_IMAGE_3, p.IS_BARCODE_AVAILABLE,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_master p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ?
    `, [employeeUserId]);

    if (cartItems.length === 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Employee cart is empty. Please add items to cart first.'
      });
    }

    // Get default address for the retailer/customer
    const [defaultAddress] = await connection.query(
      `SELECT ADDRESS_ID, USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, LANDMARK, ADDRESS_TYPE, IS_DEFAULT
       FROM customer_address 
       WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != "Y" 
       LIMIT 1`,
      [retailerUserId]
    );
    
    // If no default address found, use retailer's info from user_info table
    let orderAddress = null;
    if (defaultAddress.length === 0) {
      // Create a default address object from user_info data
      orderAddress = {
        ADDRESS_ID: null,
        ADDRESS: retailer.ADDRESS || 'Address not provided',
        CITY: retailer.CITY || 'City not provided',
        STATE: retailer.PROVINCE || 'State not provided',
        COUNTRY: 'India', // Default country
        PINCODE: retailer.ZIP || '000000',
        LANDMARK: null,
        ADDRESS_TYPE: 'Home'
      };
    } else {
      orderAddress = defaultAddress[0];
    }

    // Calculate order total
    const orderTotal = cartItems.reduce((total, item) => {
      return total + (item.PU_PROD_RATE * item.QUANTITY);
    }, 0);

    // Generate order number
    const orderNumber = 'EMP-ORD-' + Date.now();

    // Get retailer and customer details
    const [retailerDetails] = await connection.query(`
      SELECT RET_ID, RET_NAME, RET_MOBILE_NO FROM retailer_info 
      WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS != 'Y'
    `, [phoneNumber]);

    const retailerInfo = retailerDetails.length > 0 ? retailerDetails[0] : null;
    const totalQuantity = cartItems.reduce((total, item) => total + item.QUANTITY, 0);
    const transactionId = 'EMP-TXN-' + Date.now();

    // Create order in cust_order table
    const [orderResult] = await connection.query(`
      INSERT INTO cust_order (
        CO_NO, CO_TRANS_ID, CO_DATE, CO_DELIVERY_NOTE, CO_DELIVERY_MODE, 
        CO_PAYMENT_MODE, CO_RET_ID, CO_CUST_CODE, CO_CUST_NAME, 
        CO_CUST_MOBILE, CO_DELIVERY_ADDRESS, CO_DELIVERY_COUNTRY, 
        CO_DELIVERY_STATE, CO_DELIVERY_CITY, CO_PINCODE, 
        CO_TOTAL_QTY, CO_TOTAL_AMT, CO_PAYMENT_STATUS, CO_TYPE, 
        CO_STATUS, CREATED_BY, CREATED_DATE
      ) VALUES (?, ?, NOW(), ?, 'delivery', 'cod', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'employee', 'pending', ?, NOW())
    `, [
      orderNumber, transactionId, 
      notes || 'Order placed by employee on behalf of retailer/customer',
      retailerInfo ? retailerInfo.RET_ID : null,
      phoneNumber, retailerInfo ? retailerInfo.RET_NAME : 'Customer',
      phoneNumber, orderAddress.ADDRESS, orderAddress.COUNTRY, 
      orderAddress.STATE, orderAddress.CITY, orderAddress.PINCODE,
      totalQuantity, orderTotal, employeeUserId
    ]);

    const orderId = orderResult.insertId;

    // Create order items in cust_order_details table
    for (const item of cartItems) {
      await connection.query(`
        INSERT INTO cust_order_details (
          COD_CO_ID, COD_QTY, PROD_NAME, PROD_BARCODE, PROD_DESC, 
          PROD_MRP, PROD_SP, PROD_CGST, PROD_IGST, PROD_SGST,
          PROD_IMAGE_1, PROD_IMAGE_2, PROD_IMAGE_3, PROD_CODE, 
          PROD_ID, PROD_UNIT, IS_BARCODE_AVAILABLE
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        orderId, item.QUANTITY, item.PROD_NAME || '', '', // Empty barcode - PROD_BARCODE field doesn't exist in product table
        item.PROD_DESC || '', item.PROD_MRP || 0, item.PU_PROD_RATE,
        item.PROD_CGST || 0, item.PROD_IGST || 0, item.PROD_SGST || 0, // Use actual GST values from product
        item.PROD_IMAGE_1 || '', item.PROD_IMAGE_2 || '', item.PROD_IMAGE_3 || '',
        item.PROD_CODE || '', item.PROD_ID, item.PU_PROD_UNIT,
        item.IS_BARCODE_AVAILABLE || 0 // Use actual IS_BARCODE_AVAILABLE from product
      ]);
    }

    // Get today's DWR_ID for the employee to link with cdwr_detail
    const today = new Date().toISOString().split('T')[0];
    const [dwrData] = await connection.query(`
      SELECT DWR_ID FROM dwr_detail 
      WHERE DWR_EMP_ID = ? AND DATE(DWR_DATE) = ? AND DEL_STATUS = 0
      ORDER BY DWR_ID DESC
      LIMIT 1
    `, [employeeUserId, today]);

    // If employee has a DWR for today, create cdwr_detail records for each product
    if (dwrData.length > 0) {
      const dwrId = dwrData[0].DWR_ID;
      
      // Create cdwr_detail record for each cart item/product
      for (const item of cartItems) {
        await connection.query(`
          INSERT INTO cdwr_detail (
            CDWR_VDWR_ID, CDWR_CUST_ID, CDWR_PRODM_ID, 
            CDWR_CUST_ORDER_ID, DEL_STATUS
          ) VALUES (?, ?, ?, ?, ?)
        `, [
          dwrId,           // CDWR_VDWR_ID - DWR_ID from today's DWR
          retailerUserId,  // CDWR_CUST_ID - Customer/Retailer USER_ID
          item.PROD_ID,    // CDWR_PRODM_ID - Product ID
          orderId,         // CDWR_CUST_ORDER_ID - Order ID
          0                // DEL_STATUS - 0 for active
        ]);
      }
    }

    // Clear employee's cart
    await connection.query('DELETE FROM cart WHERE USER_ID = ?', [employeeUserId]);

    // Generate invoice immediately after order creation
    const [orderDetails] = await connection.query(
      `SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
              co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
              co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
              co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
              co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
              co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE,
              co.CO_CUST_NAME as USERNAME, co.CO_CUST_MOBILE as MOBILE,
              u.EMAIL, u.ADDRESS as USER_ADDRESS, u.CITY, u.PROVINCE, u.ZIP
       FROM cust_order co
       LEFT JOIN user_info u ON co.CO_CUST_MOBILE = u.MOBILE
       WHERE co.CO_ID = ?`,
      [orderId]
    );
    const order = orderDetails[0];
    const [orderItems] = await connection.query(
      `SELECT cod.COD_ID as ORDER_ITEM_ID, cod.COD_CO_ID as ORDER_ID,
              cod.PROD_ID, cod.COD_QTY as QUANTITY, cod.PROD_SP as UNIT_PRICE,
              (cod.COD_QTY * cod.PROD_SP) as TOTAL_PRICE,
              cod.PROD_NAME, cod.PROD_CODE, cod.PROD_MRP as PROD_MRP,
              cod.PROD_SP, cod.PROD_IMAGE_1, cod.PROD_IMAGE_2, cod.PROD_IMAGE_3,
              cod.PROD_UNIT as PU_PROD_UNIT, 
              COALESCE(p.PROD_HSN_CODE, cod.PROD_BARCODE, '') as PROD_HSN_CODE,
              COALESCE(cod.PROD_CGST, p.PROD_CGST, 0) as PROD_CGST,
              COALESCE(cod.PROD_SGST, p.PROD_SGST, 0) as PROD_SGST,
              COALESCE(cod.PROD_IGST, p.PROD_IGST, 0) as PROD_IGST
       FROM cust_order_details cod
       LEFT JOIN product_master p ON cod.PROD_ID = p.PROD_ID
       WHERE cod.COD_CO_ID = ?`,
      [orderId]
    );
    // Generate invoice number
    const invoiceNumber = `INV${orderId}`;
    
    // Calculate tax totals from order items
    let totalCGST = 0;
    let totalSGST = 0;
    let totalIGST = 0;
    let totalTaxableValue = 0;

    orderItems.forEach(item => {
      const itemTaxableValue = parseFloat(item.PROD_SP || 0) * parseInt(item.QUANTITY || 0);
      const cgstRate = parseFloat(item.PROD_CGST || 0);
      const sgstRate = parseFloat(item.PROD_SGST || 0);
      const igstRate = parseFloat(item.PROD_IGST || 0);
      
      totalTaxableValue += itemTaxableValue;
      totalCGST += (itemTaxableValue * cgstRate) / 100;
      totalSGST += (itemTaxableValue * sgstRate) / 100;
      totalIGST += (itemTaxableValue * igstRate) / 100;
    });

    const totalTaxAmount = totalCGST + totalSGST + totalIGST;
    
    // Generate PDF and QR code
    const invoicePath = await require('../utils/invoiceGenerator').generateInvoicePDF({ order, orderItems, invoiceNumber });
    // Insert into invoice_master
    const [invoiceResult] = await connection.query(
      `INSERT INTO invoice_master (
        INVM_NO, INVM_TRANS_ID, INVM_DATE, INVM_CUST_ID, INVM_CUST_NAME, INVM_CUST_ADDRESS, INVM_CUST_MOBILE, INVM_CUST_GST,
        INVM_TOT_CGST, INVM_TOT_SGST, INVM_TOT_IGST, INVM_TOT_DISCOUNT_AMOUNT, INVM_TOT_TAX_AMOUNT, INVM_TOT_AMOUNT, INVM_TOT_NET_PAYABLE,
        INVM_STATUS, INVM_PAYMENT_MODE, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        invoiceNumber,
        `TR${orderId}`,
        order.USER_ID,
        order.USERNAME,
        order.USER_ADDRESS || order.DELIVERY_ADDRESS,
        order.MOBILE,
        '', // INVM_CUST_GST
        totalCGST.toFixed(2), // INVM_TOT_CGST
        totalSGST.toFixed(2), // INVM_TOT_SGST
        totalIGST.toFixed(2), // INVM_TOT_IGST
        0, // INVM_TOT_DISCOUNT_AMOUNT
        totalTaxAmount.toFixed(2), // INVM_TOT_TAX_AMOUNT
        order.ORDER_TOTAL,
        order.ORDER_TOTAL,
        'active',
        'cod',
        req.user.USERNAME || 'system',
        req.user.USERNAME || 'system'
      ]
    );
    const invoiceId = invoiceResult.insertId;
    // Insert into invoice_detail for each item
    for (const item of orderItems) {
      const itemTaxableValue = parseFloat(item.PROD_SP || 0) * parseInt(item.QUANTITY || 0);
      const cgstAmount = (itemTaxableValue * parseFloat(item.PROD_CGST || 0)) / 100;
      const sgstAmount = (itemTaxableValue * parseFloat(item.PROD_SGST || 0)) / 100;
      const igstAmount = (itemTaxableValue * parseFloat(item.PROD_IGST || 0)) / 100;
      
      await connection.query(
        `INSERT INTO invoice_detail (INVD_INVM_ID, INVD_PROD_ID, INVD_PROD_CODE, INVD_PROD_NAME, INVD_PROD_UNIT, INVD_QTY, INVD_HSN_CODE, INVD_MRP, INVD_SP, INVD_DISCOUNT_PERCENTAGE, INVD_DISCOUNT_AMOUNT, INVD_CGST, INVD_SGST, INVD_IGST, INVD_PROD_IMAGE_1, INVD_PROD_IMAGE_2, INVD_PROD_IMAGE_3, INVD_TAMOUNT, INVD_PROD_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?, ?, ?, 'A', ?, ?, NOW(), NOW())`,
        [invoiceId, item.PROD_ID, item.PROD_CODE, item.PROD_NAME, item.PU_PROD_UNIT, item.QUANTITY, item.PROD_HSN_CODE, item.PROD_MRP, item.PROD_SP, cgstAmount.toFixed(2), sgstAmount.toFixed(2), igstAmount.toFixed(2), item.PROD_IMAGE_1, item.PROD_IMAGE_2, item.PROD_IMAGE_3, item.TOTAL_PRICE, req.user.USERNAME || 'system', req.user.USERNAME || 'system']
      );
    }
         // Create payment record in cust_payment table
     await connection.query(`
       INSERT INTO cust_payment (
         PAYMENT_TRANSACTION_ID, PAYMENT_TRANSACTION_TYPE, PAYMENT_MERCHANT_ID,
         PAYMENT_AMOUNT, PAYMENT_PAYMENT_METHOD, PAYMENT_PAYMENT_MODE, PAYMENT_STATUS, 
         PAYMENT_STATUS_MESSAGE, PAYMENT_RESPONSE_CODE, PAYMENT_RESPONSE_MESSAGE,
         PAYMENT_PAYMENT_DATE, PAYMENT_PAYMENT_INVOICE_NO, PAYMENT_CURRENCY_CODE,
         PAYMENT_DELIVERY_NAME, PAYMENT_DELIVERY_COUNTRY, PAYMENT_DELIVERY_STATE, 
         PAYMENT_DELIVERY_CITY, PAYMENT_DELIVERY_ZIP, PAYMENT_BILLING_NAME,
         PAYMENT_BILLING_CITY, PAYMENT_BILLING_ADDRESS, PAYMENT_BILLING_EMAIL,
         PAYMENT_BILLING_COUNTRY, PAYMENT_BILLING_STATE, PAYMENT_BILLING_ZIP,
         CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
     `, [
       transactionId, // PAYMENT_TRANSACTION_ID
       'employee_order', // PAYMENT_TRANSACTION_TYPE
       'ANWAR_FOOD_001', // PAYMENT_MERCHANT_ID (default merchant ID)
       orderTotal, // PAYMENT_AMOUNT
       'cod', // PAYMENT_PAYMENT_METHOD
       'cod', // PAYMENT_PAYMENT_MODE
       'cod', // PAYMENT_STATUS
       'Order placed by employee on behalf of customer', // PAYMENT_STATUS_MESSAGE
       '300', // PAYMENT_RESPONSE_CODE (300 = employee order)
       'Employee order created successfully', // PAYMENT_RESPONSE_MESSAGE
       orderNumber, // PAYMENT_PAYMENT_INVOICE_NO
       'INR', // PAYMENT_CURRENCY_CODE
       retailer.USERNAME, // PAYMENT_DELIVERY_NAME
       orderAddress.COUNTRY, // PAYMENT_DELIVERY_COUNTRY
       orderAddress.STATE, // PAYMENT_DELIVERY_STATE
       orderAddress.CITY, // PAYMENT_DELIVERY_CITY
       orderAddress.PINCODE, // PAYMENT_DELIVERY_ZIP
       retailer.USERNAME, // PAYMENT_BILLING_NAME
       orderAddress.CITY, // PAYMENT_BILLING_CITY
       orderAddress.ADDRESS, // PAYMENT_BILLING_ADDRESS
       retailer.EMAIL || '', // PAYMENT_BILLING_EMAIL
       orderAddress.COUNTRY, // PAYMENT_BILLING_COUNTRY
       orderAddress.STATE, // PAYMENT_BILLING_STATE
       orderAddress.PINCODE, // PAYMENT_BILLING_ZIP
       employeeUserId, // CREATED_BY
       employeeUserId // UPDATED_BY
     ]);

    // Update the cust_order table with the invoice URL
    await connection.query(
      'UPDATE cust_order SET INVOICE_URL = ? WHERE CO_ID = ?',
      [`/uploads/invoice/${invoiceNumber}.pdf`, orderId]
    );

    // Commit transaction
    await connection.commit();

    res.json({
      success: true,
      message: 'Order placed successfully',
      data: {
        orderId,
        orderNumber,
        orderTotal,
        invoiceNumber,
        invoicePath: `/uploads/invoice/${invoiceNumber}.pdf`
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Place order for retailer/customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error placing order for retailer/customer',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Get all retailers with pagination and status filtering
const getRetailerList = async (req, res) => {
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
       RET_ADDRESS, RET_PIN_CODE, RET_PHOTO, RET_EMAIL_ID, RET_COUNTRY, RET_STATE, RET_CITY,
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

// Search retailers by code, shop name, or mobile number
const searchRetailers = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const [retailers] = await db.promise().query(`
      SELECT RET_ID, RET_CODE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, 
             RET_PHOTO, RET_ADDRESS, RET_CITY, RET_STATE, RET_DEL_STATUS, 
             SHOP_OPEN_STATUS, CREATED_DATE
      FROM retailer_info 
      WHERE RET_DEL_STATUS = 'active'
      AND (
        RET_CODE LIKE ? OR
        RET_SHOP_NAME LIKE ? OR
        RET_NAME LIKE ? OR
        RET_MOBILE_NO LIKE ?
      )
      ORDER BY 
        CASE 
          WHEN RET_CODE = ? THEN 1
          WHEN RET_SHOP_NAME LIKE ? THEN 2
          WHEN RET_NAME LIKE ? THEN 3
          WHEN RET_MOBILE_NO = ? THEN 4
          ELSE 5
        END,
        RET_SHOP_NAME ASC
    `, [
      `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`,
      query, `${query}%`, `${query}%`, query
    ]);

    res.json({
      success: true,
      data: retailers,
      count: retailers.length,
      filters: {
        query: query
      }
    });

  } catch (error) {
    console.error('Error in searchRetailers:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching retailers',
      error: error.message
    });
  }
};

// Edit retailer by employee (with photo upload support)
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
      SHOP_OPEN_STATUS,
      BARCODE_URL
    } = req.body;

    // Validate retailer exists
    const [existingRetailer] = await db.promise().query(`
      SELECT RET_ID FROM retailer_info 
      WHERE RET_ID = ? AND RET_DEL_STATUS = 'active'
    `, [retailerId]);

    if (existingRetailer.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found or inactive'
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
      // Validate GST number format (basic validation)
      if (RET_GST_NO && !/^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$/.test(RET_GST_NO)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid GST number format'
        });
      }
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
      WHERE RET_ID = ? AND RET_DEL_STATUS = 'active'
    `, [retailerId]);

    // Add photo URL if photo exists
    const retailerData = updatedRetailer[0];
    if (retailerData.RET_PHOTO) {
      retailerData.RET_PHOTO_URL = `http://localhost:3000/uploads/retailers/profiles/${retailerData.RET_PHOTO}`;
    }

    res.json({
      success: true,
      message: 'Retailer updated successfully by employee',
      data: retailerData,
      uploadedFile: req.uploadedFile ? {
        filename: req.uploadedFile.filename,
        url: `http://localhost:3000/uploads/retailers/profiles/${req.uploadedFile.filename}`
      } : null,
      updated_by: req.user.USERNAME,
      updated_fields: updateFields.length - 2 // Exclude UPDATED_DATE and UPDATED_BY from count
    });

  } catch (error) {
    console.error('Employee edit retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating retailer',
      error: error.message
    });
  }
};

// Get retailer by phone number (same functionality as admin)
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
       WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS = 'active'`,
      [phone]
    );

    if (retailer.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found with this phone number or retailer is inactive'
      });
    }

    // Add photo URL if photo exists
    const retailerData = retailer[0];
    if (retailerData.RET_PHOTO) {
      retailerData.RET_PHOTO_URL = `http://localhost:3000/uploads/retailers/profiles/${retailerData.RET_PHOTO}`;
    }

    res.json({
      success: true,
      message: 'Retailer details fetched successfully by employee',
      data: retailerData,
      searched_phone: phone,
      accessed_by: req.user.USERNAME
    });
  } catch (error) {
    console.error('Employee get retailer by phone error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer details',
      error: error.message
    });
  }
};

// Get STA Master data (for employees only)
const getStaMaster = async (req, res) => {
  try {
    // Optional query parameters for filtering
    const { 
      sta_id, 
      sta_vso_id, 
      sta_name, 
      del_status = 'N',
      limit = 100,
      offset = 0 
    } = req.query;

    // Build dynamic query based on filters
    let whereConditions = [];
    let queryParams = [];

    // Always filter by DEL_STATUS if not explicitly requesting all
    if (del_status && del_status !== 'all') {
      whereConditions.push('DEL_STATUS = ?');
      queryParams.push(del_status);
    }

    if (sta_id) {
      whereConditions.push('STA_ID = ?');
      queryParams.push(sta_id);
    }

    if (sta_vso_id) {
      whereConditions.push('STA_VSO_ID = ?');
      queryParams.push(sta_vso_id);
    }

    if (sta_name) {
      whereConditions.push('STA_NAME LIKE ?');
      queryParams.push(`%${sta_name}%`);
    }

    // Validate limit and offset
    const validLimit = Math.max(1, Math.min(parseInt(limit) || 100, 1000)); // Max 1000 records
    const validOffset = Math.max(0, parseInt(offset) || 0);

    // Build WHERE clause
    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    // Main query to get STA Master data
    const query = `
      SELECT 
        STA_ID,
        STA_VSO_ID,
        STA_NAME,
        DEL_STATUS,
        LAST_USER,
        TIME_STAMP
      FROM sta_master 
      ${whereClause}
      ORDER BY STA_ID ASC
      LIMIT ? OFFSET ?
    `;

    queryParams.push(validLimit, validOffset);

    const [staMasterData] = await db.promise().query(query, queryParams);

    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(*) as total_count 
      FROM sta_master 
      ${whereClause}
    `;

    const [countResult] = await db.promise().query(
      countQuery, 
      queryParams.slice(0, -2) // Remove limit and offset params
    );

    const totalCount = countResult[0].total_count;

    res.json({
      success: true,
      message: 'STA Master data fetched successfully by employee',
      data: staMasterData,
      pagination: {
        total_count: totalCount,
        current_page: Math.floor(validOffset / validLimit) + 1,
        per_page: validLimit,
        total_pages: Math.ceil(totalCount / validLimit),
        has_next: (validOffset + validLimit) < totalCount,
        has_previous: validOffset > 0
      },
      filters: {
        sta_id: sta_id || null,
        sta_vso_id: sta_vso_id || null,
        sta_name: sta_name || null,
        del_status: del_status,
        limit: validLimit,
        offset: validOffset
      },
      accessed_by: req.user.USERNAME,
      count: staMasterData.length
    });

  } catch (error) {
    console.error('Employee get STA Master error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching STA Master data',
      error: error.message
    });
  }
};

// ===== DWR (Daily Work Report) APIs =====

// Get today's DWR details for authenticated employee
const getTodayDwr = async (req, res) => {
  try {
    const employeeId = req.user.USER_ID; // Get from JWT token
    
    // Get today's date in YYYY-MM-DD format
    const today = new Date().toISOString().split('T')[0];
    
    // Fetch today's DWR for the employee
    const [dwrData] = await db.promise().query(`
      SELECT 
        DWR_ID, DWR_EMP_ID, DWR_NO, DWR_DATE, DWR_STATUS, DWR_EXPENSES,
        DWR_START_STA, DWR_END_STA, DWR_START_LOC, DWR_END_LOC, 
        DWR_REMARKS, DWR_SUBMIT, DEL_STATUS, LAST_USER, TIME_STAMP
      FROM dwr_detail 
      WHERE DWR_EMP_ID = ? AND DATE(DWR_DATE) = ? AND DEL_STATUS = 0
      ORDER BY DWR_ID DESC
      LIMIT 1
    `, [employeeId, today]);

    if (dwrData.length === 0) {
      return res.json({
        success: true,
        message: 'No DWR found for today. You can start your day.',
        data: null,
        has_started_day: false,
        today_date: today,
        employee_id: employeeId
      });
    }

    const dwr = dwrData[0];
    
    res.json({
      success: true,
      message: 'Today\'s DWR details fetched successfully',
      data: dwr,
      has_started_day: true,
      has_ended_day: dwr.DWR_STATUS === 'approved',
      today_date: today,
      employee_id: employeeId
    });

  } catch (error) {
    console.error('Get today DWR error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching today\'s DWR details',
      error: error.message
    });
  }
};

// Start day - Create new DWR entry
const startDay = async (req, res) => {
  try {
    const employeeId = req.user.USER_ID; // Get from JWT token
    const { DWR_START_STA, DWR_START_LOC } = req.body;
    
    // Validate required fields
    if (!DWR_START_STA || !DWR_START_LOC) {
      return res.status(400).json({
        success: false,
        message: 'DWR_START_STA and DWR_START_LOC are required'
      });
    }

    // Get today's date in YYYY-MM-DD format
    const today = new Date().toISOString().split('T')[0];
    
    // Check if employee already started day today
    const [existingDwr] = await db.promise().query(`
      SELECT DWR_ID FROM dwr_detail 
      WHERE DWR_EMP_ID = ? AND DATE(DWR_DATE) = ? AND DEL_STATUS = 0
    `, [employeeId, today]);

    if (existingDwr.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'You already started your day today',
        existing_dwr_id: existingDwr[0].DWR_ID
      });
    }

    // Get next DWR_NO (increment basis)
    const [maxDwrNo] = await db.promise().query(`
      SELECT COALESCE(MAX(DWR_NO), 0) + 1 as next_dwr_no FROM dwr_detail
    `);
    const nextDwrNo = maxDwrNo[0].next_dwr_no;

    // Create new DWR entry
    const currentTimestamp = new Date();
    
    const [result] = await db.promise().query(`
      INSERT INTO dwr_detail (
        DWR_EMP_ID, DWR_NO, DWR_DATE, DWR_STATUS, DWR_START_STA, 
        DWR_START_LOC, DWR_SUBMIT, DEL_STATUS, LAST_USER, TIME_STAMP
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      employeeId,           // DWR_EMP_ID
      nextDwrNo,           // DWR_NO
      today,               // DWR_DATE
      'Draft',             // DWR_STATUS
      DWR_START_STA,       // DWR_START_STA
      DWR_START_LOC,       // DWR_START_LOC
      currentTimestamp,    // DWR_SUBMIT
      0,                   // DEL_STATUS
      req.user.USERNAME,   // LAST_USER
      currentTimestamp     // TIME_STAMP
    ]);

    const dwrId = result.insertId;

    // Fetch the created DWR to return
    const [createdDwr] = await db.promise().query(`
      SELECT * FROM dwr_detail WHERE DWR_ID = ?
    `, [dwrId]);

    res.json({
      success: true,
      message: 'Day started successfully!',
      data: createdDwr[0],
      dwr_id: dwrId,
      dwr_no: nextDwrNo,
      started_at: currentTimestamp,
      employee_id: employeeId
    });

  } catch (error) {
    console.error('Start day error:', error);
    res.status(500).json({
      success: false,
      message: 'Error starting your day',
      error: error.message
    });
  }
};

// End day - Update existing DWR entry
const endDay = async (req, res) => {
  try {
    const employeeId = req.user.USER_ID; // Get from JWT token
    const { 
      DWR_EXPENSES, 
      DWR_END_STA, 
      DWR_END_LOC, 
      DWR_REMARKS 
    } = req.body;
    
    // Validate required fields
    if (!DWR_END_STA || !DWR_END_LOC) {
      return res.status(400).json({
        success: false,
        message: 'DWR_END_STA and DWR_END_LOC are required'
      });
    }

    // Get today's date in YYYY-MM-DD format
    const today = new Date().toISOString().split('T')[0];
    
    // Check if employee has started day today
    const [existingDwr] = await db.promise().query(`
      SELECT DWR_ID, DWR_STATUS FROM dwr_detail 
      WHERE DWR_EMP_ID = ? AND DATE(DWR_DATE) = ? AND DEL_STATUS = 0
    `, [employeeId, today]);

    if (existingDwr.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'You need to start your day first before ending it'
      });
    }

    const dwr = existingDwr[0];
    
    // Check if day is already ended
    if (dwr.DWR_STATUS === 'approved') {
      return res.status(400).json({
        success: false,
        message: 'You have already ended your day today',
        dwr_id: dwr.DWR_ID
      });
    }

    // Update DWR entry to end the day
    const currentTimestamp = new Date();
    
    await db.promise().query(`
      UPDATE dwr_detail SET 
        DWR_STATUS = ?,
        DWR_EXPENSES = ?,
        DWR_END_STA = ?,
        DWR_END_LOC = ?,
        DWR_REMARKS = ?,
        LAST_USER = ?,
        TIME_STAMP = ?
      WHERE DWR_ID = ?
    `, [
      'approved',          // DWR_STATUS
      DWR_EXPENSES || 0,   // DWR_EXPENSES (default to 0 if not provided)
      DWR_END_STA,         // DWR_END_STA
      DWR_END_LOC,         // DWR_END_LOC
      DWR_REMARKS || '',   // DWR_REMARKS (default to empty if not provided)
      req.user.USERNAME,   // LAST_USER
      currentTimestamp,    // TIME_STAMP
      dwr.DWR_ID
    ]);

    // Fetch the updated DWR to return
    const [updatedDwr] = await db.promise().query(`
      SELECT * FROM dwr_detail WHERE DWR_ID = ?
    `, [dwr.DWR_ID]);

    res.json({
      success: true,
      message: 'Day ended successfully!',
      data: updatedDwr[0],
      dwr_id: dwr.DWR_ID,
      ended_at: currentTimestamp,
      total_expenses: DWR_EXPENSES || 0,
      employee_id: employeeId
    });

  } catch (error) {
    console.error('End day error:', error);
    res.status(500).json({
      success: false,
      message: 'Error ending your day',
      error: error.message
    });
  }
};

// ===== Customer Creation APIs for Employees =====

// Create customer by employee (same functionality as admin but tracked as employee action)
const createCustomerByEmployee = async (req, res) => {
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
      message: 'Customer and retailer profile created successfully by employee',
      data: {
        customer: customerDetails[0],
        addresses: addresses,
        createdBy: req.user.USERNAME,
        createdByRole: 'employee',
        defaultPassword: password
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Employee create customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating customer',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Create customer with multiple addresses by employee
const createCustomerWithMultipleAddressesByEmployee = async (req, res) => {
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
      message: 'Customer with multiple addresses and retailer profile created successfully by employee',
      data: {
        customer: customerDetails[0],
        addresses: customerAddresses,
        createdBy: req.user.USERNAME,
        createdByRole: 'employee',
        defaultPassword: password
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Employee create customer with multiple addresses error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating customer with multiple addresses',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Get customer details by employee (same functionality as admin)
const getCustomerDetailsByEmployee = async (req, res) => {
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
      message: 'Customer details fetched successfully by employee',
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
      },
      accessedBy: req.user.USERNAME,
      accessedByRole: 'employee'
    });

  } catch (error) {
    console.error('Employee get customer details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching customer details',
      error: error.message
    });
  }
};

// Search customers by employee (same functionality as admin)
const searchCustomersByEmployee = async (req, res) => {
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
      message: 'Customers search completed by employee',
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
      },
      searchedBy: req.user.USERNAME,
      searchedByRole: 'employee'
    });

  } catch (error) {
    console.error('Employee search customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching customers',
      error: error.message
    });
  }
};

module.exports = {
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
}; 