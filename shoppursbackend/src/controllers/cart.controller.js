const { pool: db } = require('../config/database');

const addToCart = async (req, res) => {
  try {
    const { productId, quantity, unitId } = req.body;
    const userId = req.user.userId;

    // First check if product exists and get its details
    const [products] = await db.promise().query(
      'SELECT * FROM product_master WHERE PROD_ID = ? AND (DEL_STATUS IS NULL OR DEL_STATUS != "Y")',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Check if product unit exists
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_ID = ? AND PU_PROD_ID = ?',
      [unitId, productId]
    );

    if (units.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product unit not found'
      });
    }

    // Check if item already exists in cart
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cart WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
      [userId, productId, unitId]
    );

    if (existingItems.length > 0) {
      // Update quantity if item exists
      await db.promise().query(
        'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
        [quantity, userId, productId, unitId]
      );
    } else {
      // Insert new cart item
      await db.promise().query(
        'INSERT INTO cart (USER_ID, PROD_ID, UNIT_ID, QUANTITY, CREATED_DATE) VALUES (?, ?, ?, ?, NOW())',
        [userId, productId, unitId, quantity]
      );
    }

    res.json({
      success: true,
      message: 'Item added to cart successfully'
    });
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding item to cart',
      error: error.message
    });
  }
};

const addToCartAuto = async (req, res) => {
  try {
    const { productId } = req.body;
    const userId = req.user.userId;

    // First check if product exists and get its details
    const [products] = await db.promise().query(
      'SELECT * FROM product_master WHERE PROD_ID = ? AND (DEL_STATUS IS NULL OR DEL_STATUS != "Y")',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get all units for this product and find the one with minimum PU_PROD_UNIT_VALUE
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ? AND PU_STATUS = "A" ORDER BY PU_PROD_UNIT_VALUE ASC LIMIT 1',
      [productId]
    );

    if (units.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No active units found for this product'
      });
    }

    const selectedUnit = units[0];
    const unitId = selectedUnit.PU_ID;
    const quantity = selectedUnit.PU_PROD_UNIT_VALUE;

    // Check if item already exists in cart with this unit
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cart WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
      [userId, productId, unitId]
    );

    if (existingItems.length > 0) {
      // Update quantity if item exists
      await db.promise().query(
        'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
        [quantity, userId, productId, unitId]
      );
    } else {
      // Insert new cart item
      await db.promise().query(
        'INSERT INTO cart (USER_ID, PROD_ID, UNIT_ID, QUANTITY, CREATED_DATE) VALUES (?, ?, ?, ?, NOW())',
        [userId, productId, unitId, quantity]
      );
    }

    res.json({
      success: true,
      message: 'Item added to cart automatically with minimum unit',
      data: {
        productId: productId,
        unitId: unitId,
        unitName: selectedUnit.PU_PROD_UNIT,
        unitValue: selectedUnit.PU_PROD_UNIT_VALUE,
        quantity: quantity,
        rate: selectedUnit.PU_PROD_RATE,
        total: selectedUnit.PU_PROD_RATE * quantity
      }
    });
  } catch (error) {
    console.error('Add to cart auto error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding item to cart automatically',
      error: error.message
    });
  }
};

const addToCartByBarcode = async (req, res) => {
  try {
    const { PRDB_BARCODE } = req.body;
    const userId = req.user.userId;

    // Validate input
    if (!PRDB_BARCODE) {
      return res.status(400).json({
        success: false,
        message: 'Barcode is required'
      });
    }

    // Find product using barcode
    const [barcodeResults] = await db.promise().query(
      'SELECT PRDB_PROD_ID FROM product_barcodes WHERE PRDB_BARCODE = ? AND SOLD_STATUS = "A"',
      [PRDB_BARCODE]
    );

    if (barcodeResults.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found with this barcode or barcode is not active'
      });
    }

    const productId = barcodeResults[0].PRDB_PROD_ID;

    // Check if product exists and get its details
    const [products] = await db.promise().query(
      'SELECT * FROM product_master WHERE PROD_ID = ? AND (DEL_STATUS IS NULL OR DEL_STATUS != "Y")',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found or deleted'
      });
    }

    // Get all units for this product and find the one with minimum PU_PROD_UNIT_VALUE
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ? AND PU_STATUS = "A" ORDER BY PU_PROD_UNIT_VALUE ASC LIMIT 1',
      [productId]
    );

    if (units.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No active units found for this product'
      });
    }

    const selectedUnit = units[0];
    const unitId = selectedUnit.PU_ID;
    const quantity = selectedUnit.PU_PROD_UNIT_VALUE;

    // Check if item already exists in cart with this unit
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cart WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
      [userId, productId, unitId]
    );

    if (existingItems.length > 0) {
      // Update quantity if item exists
      await db.promise().query(
        'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
        [quantity, userId, productId, unitId]
      );
    } else {
      // Insert new cart item
      await db.promise().query(
        'INSERT INTO cart (USER_ID, PROD_ID, UNIT_ID, QUANTITY, CREATED_DATE) VALUES (?, ?, ?, ?, NOW())',
        [userId, productId, unitId, quantity]
      );
    }

    res.json({
      success: true,
      message: 'Product added to cart successfully using barcode',
      data: {
        barcode: PRDB_BARCODE,
        productId: productId,
        productName: products[0].PROD_NAME,
        unitId: unitId,
        unitName: selectedUnit.PU_PROD_UNIT,
        unitValue: selectedUnit.PU_PROD_UNIT_VALUE,
        quantity: quantity,
        rate: selectedUnit.PU_PROD_RATE,
        total: selectedUnit.PU_PROD_RATE * quantity
      }
    });
  } catch (error) {
    console.error('Add to cart by barcode error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding item to cart using barcode',
      error: error.message
    });
  }
};

const editCartUnit = async (req, res) => {
  try {
    const { cartId, unitId } = req.body;
    const userId = req.user.userId;

    // Validate input
    if (!cartId || !unitId) {
      return res.status(400).json({
        success: false,
        message: 'Cart ID and Unit ID are required'
      });
    }

    // Get cart item and verify it belongs to the user
    const [cartItems] = await db.promise().query(
      'SELECT * FROM cart WHERE CART_ID = ? AND USER_ID = ?',
      [cartId, userId]
    );

    if (cartItems.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found or does not belong to user'
      });
    }

    const cartItem = cartItems[0];
    const productId = cartItem.PROD_ID;

    // Validate that the new unit exists and belongs to the same product
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_ID = ? AND PU_PROD_ID = ? AND PU_STATUS = "A"',
      [unitId, productId]
    );

    if (units.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Unit not found or not active for this product'
      });
    }

    const newUnit = units[0];
    const newQuantity = newUnit.PU_PROD_UNIT_VALUE;

    // Check if there's already a cart item with this unit for the same product
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cart WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ? AND CART_ID != ?',
      [userId, productId, unitId, cartId]
    );

    if (existingItems.length > 0) {
      // If item with new unit already exists, merge quantities and delete current item
      await db.promise().query(
        'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
        [newQuantity, userId, productId, unitId]
      );

      await db.promise().query(
        'DELETE FROM cart WHERE CART_ID = ? AND USER_ID = ?',
        [cartId, userId]
      );

      return res.json({
        success: true,
        message: 'Unit changed and quantities merged with existing cart item',
        data: {
          action: 'merged',
          productId: productId,
          newUnitId: unitId,
          newQuantity: newQuantity,
          unitName: newUnit.PU_PROD_UNIT,
          unitValue: newUnit.PU_PROD_UNIT_VALUE,
          rate: newUnit.PU_PROD_RATE
        }
      });
    } else {
      // Update the cart item with new unit and quantity
      await db.promise().query(
        'UPDATE cart SET UNIT_ID = ?, QUANTITY = ? WHERE CART_ID = ? AND USER_ID = ?',
        [unitId, newQuantity, cartId, userId]
      );

      return res.json({
        success: true,
        message: 'Cart item unit updated successfully',
        data: {
          action: 'updated',
          cartId: cartId,
          productId: productId,
          newUnitId: unitId,
          newQuantity: newQuantity,
          unitName: newUnit.PU_PROD_UNIT,
          unitValue: newUnit.PU_PROD_UNIT_VALUE,
          rate: newUnit.PU_PROD_RATE,
          total: newUnit.PU_PROD_RATE * newQuantity
        }
      });
    }

  } catch (error) {
    console.error('Edit cart unit error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating cart unit',
      error: error.message
    });
  }
};

const fetchCart = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Fetch cart items with complete product and unit details
    const [cartItems] = await db.promise().query(`
      SELECT 
        c.CART_ID,
        c.USER_ID,
        c.PROD_ID,
        c.UNIT_ID,
        c.QUANTITY,
        c.CREATED_DATE,
        p.PROD_SUB_CAT_ID,
        p.PROD_NAME,
        p.PROD_CODE,
        p.PROD_DESC,
        p.PROD_MRP,
        p.PROD_SP,
        p.PROD_REORDER_LEVEL,
        p.PROD_QOH,
        p.PROD_HSN_CODE,
        p.PROD_CGST,
        p.PROD_IGST,
        p.PROD_SGST,
        p.PROD_MFG_DATE,
        p.PROD_EXPIRY_DATE,
        p.PROD_MFG_BY,
        p.PROD_IMAGE_1,
        p.PROD_IMAGE_2,
        p.PROD_IMAGE_3,
        p.PROD_CAT_ID,
        pu.PU_PROD_UNIT,
        pu.PU_PROD_UNIT_VALUE,
        pu.PU_PROD_RATE,
        pu.PU_STATUS
      FROM cart c
      JOIN product_master p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ? AND p.DEL_STATUS != 'Y'
    `, [userId]);

    // Fetch default address
    const [defaultAddress] = await db.promise().query(`
      SELECT * FROM customer_address 
      WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != 'Y'
      LIMIT 1
    `, [userId]);

    // If no default address, get the first address
    let selectedAddress = null;
    if (defaultAddress.length > 0) {
      selectedAddress = defaultAddress[0];
    } else {
      const [firstAddress] = await db.promise().query(`
        SELECT * FROM customer_address 
        WHERE USER_ID = ? AND DEL_STATUS != 'Y'
        ORDER BY CREATED_DATE DESC
        LIMIT 1
      `, [userId]);
      
      if (firstAddress.length > 0) {
        selectedAddress = firstAddress[0];
      }
    }

    // Get all available units for products in cart
    const productIds = [...new Set(cartItems.map(item => item.PROD_ID))];
    let allUnitsMap = {};
    
    if (productIds.length > 0) {
      const [allUnits] = await db.promise().query(`
        SELECT PU_ID, PU_PROD_ID, PU_PROD_UNIT, PU_PROD_UNIT_VALUE, PU_PROD_RATE, PU_STATUS
        FROM product_unit 
        WHERE PU_PROD_ID IN (${productIds.map(() => '?').join(',')}) AND PU_STATUS = 'A'
        ORDER BY PU_PROD_ID, PU_PROD_UNIT_VALUE ASC
      `, productIds);

      // Group units by product ID
      allUnits.forEach(unit => {
        if (!allUnitsMap[unit.PU_PROD_ID]) {
          allUnitsMap[unit.PU_PROD_ID] = [];
        }
        allUnitsMap[unit.PU_PROD_ID].push({
          id: unit.PU_ID,
          name: unit.PU_PROD_UNIT,
          value: unit.PU_PROD_UNIT_VALUE,
          rate: unit.PU_PROD_RATE,
          status: unit.PU_STATUS
        });
      });
    }

    // Calculate totals using PU_PROD_RATE
    const cartTotal = cartItems.reduce((total, item) => {
      return total + (item.PU_PROD_RATE * item.QUANTITY);
    }, 0);

    // Format response with nested product and unit details
    const formattedCartItems = cartItems.map(item => ({
      cartId: item.CART_ID,
      userId: item.USER_ID,
      quantity: item.QUANTITY,
      createdDate: item.CREATED_DATE,
      product: {
        id: item.PROD_ID,
        subCategoryId: item.PROD_SUB_CAT_ID,
        categoryId: item.PROD_CAT_ID,
        name: item.PROD_NAME,
        code: item.PROD_CODE,
        description: item.PROD_DESC,
        mrp: item.PROD_MRP,
        sellingPrice: item.PROD_SP,
        reorderLevel: item.PROD_REORDER_LEVEL,
        quantityOnHand: item.PROD_QOH,
        hsnCode: item.PROD_HSN_CODE,
        cgst: item.PROD_CGST,
        igst: item.PROD_IGST,
        sgst: item.PROD_SGST,
        manufacturingDate: item.PROD_MFG_DATE,
        expiryDate: item.PROD_EXPIRY_DATE,
        manufacturedBy: item.PROD_MFG_BY,
        images: {
          image1: item.PROD_IMAGE_1,
          image2: item.PROD_IMAGE_2,
          image3: item.PROD_IMAGE_3
        }
      },
      selectedUnit: {
        id: item.UNIT_ID,
        name: item.PU_PROD_UNIT,
        value: item.PU_PROD_UNIT_VALUE,
        rate: item.PU_PROD_RATE,
        status: item.PU_STATUS
      },
      availableUnits: allUnitsMap[item.PROD_ID] || [],
      itemTotal: item.PU_PROD_RATE * item.QUANTITY
    }));

    res.json({
      success: true,
      data: {
        items: formattedCartItems,
        total: cartTotal,
        selectedAddress: selectedAddress
      }
    });
  } catch (error) {
    console.error('Fetch cart error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching cart',
      error: error.message
    });
  }
};

// Place Order function
const placeOrder = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { addressId, paymentMethod, notes } = req.body;

    // Start transaction
    await db.promise().query('START TRANSACTION');

    try {
      // Get user's mobile and name
      const [userInfo] = await db.promise().query(`
        SELECT MOBILE, USERNAME FROM user_info WHERE USER_ID = ?
      `, [userId]);

      if (userInfo.length === 0) {
        await db.promise().query('ROLLBACK');
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const userMobile = userInfo[0].MOBILE;
      const userName = userInfo[0].USERNAME;

      // Get cart items with complete product details
            const [cartItems] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, p.PROD_MRP, p.PROD_SP, p.PROD_CODE,
             p.PROD_DESC, p.PROD_CGST, p.PROD_IGST, p.PROD_SGST,
             p.PROD_IMAGE_1, p.PROD_IMAGE_2, p.PROD_IMAGE_3, p.IS_BARCODE_AVAILABLE,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_master p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ?
    `, [userId]);

      if (cartItems.length === 0) {
        await db.promise().query('ROLLBACK');
        return res.status(400).json({
          success: false,
          message: 'Cart is empty'
        });
      }

      // Get address details
      let orderAddress = null;
      if (addressId) {
        const [address] = await db.promise().query(
          'SELECT * FROM customer_address WHERE ADDRESS_ID = ? AND USER_ID = ?',
          [addressId, userId]
        );
        
        if (address.length === 0) {
          await db.promise().query('ROLLBACK');
          return res.status(404).json({
            success: false,
            message: 'Address not found'
          });
        }
        orderAddress = address[0];
      } else {
        // Use default address
        const [defaultAddr] = await db.promise().query(
          'SELECT * FROM customer_address WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != "Y" LIMIT 1',
          [userId]
        );
        
        if (defaultAddr.length === 0) {
          await db.promise().query('ROLLBACK');
          return res.status(400).json({
            success: false,
            message: 'No default address found. Please select an address.'
          });
        }
        orderAddress = defaultAddr[0];
      }

      // Calculate order total and total quantity
      const orderTotal = cartItems.reduce((total, item) => {
        return total + (item.PU_PROD_RATE * item.QUANTITY);
      }, 0);

      const totalQuantity = cartItems.reduce((total, item) => {
        return total + item.QUANTITY;
      }, 0);

      // Generate order number and transaction ID
      const orderNumber = 'ORD' + Date.now();
      const transactionId = 'TXN' + Date.now();

      // Get retailer info based on user's mobile
      const [retailerInfo] = await db.promise().query(`
        SELECT RET_ID FROM retailer_info 
        WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS != 'Y' 
        LIMIT 1
      `, [userMobile]);

      // Create order in cust_order table
      const [orderResult] = await db.promise().query(`
        INSERT INTO cust_order (
          CO_NO, CO_TRANS_ID, CO_DATE, CO_DELIVERY_NOTE, CO_DELIVERY_MODE, 
          CO_PAYMENT_MODE, CO_IMAGE, PAYMENT_IMAGE, CO_RET_ID, CO_CUST_CODE, CO_CUST_NAME, 
          CO_CUST_MOBILE, CO_DELIVERY_ADDRESS, CO_DELIVERY_COUNTRY, 
          CO_DELIVERY_STATE, CO_DELIVERY_CITY, CO_PINCODE, 
          CO_TOTAL_QTY, CO_TOTAL_AMT, CO_PAYMENT_STATUS, CO_TYPE, 
          CO_STATUS, CREATED_BY, CREATED_DATE
        ) VALUES (?, ?, NOW(), ?, 'delivery', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'mobile', 'pending', ?, NOW())
      `, [
        orderNumber, transactionId, notes || '', paymentMethod || 'cod',
        req.uploadedFile ? req.uploadedFile.filename : null, // CO_IMAGE (legacy)
        req.uploadedFile ? req.uploadedFile.filename : null, // PAYMENT_IMAGE (new field)
        retailerInfo.length > 0 ? retailerInfo[0].RET_ID : null,
        userMobile, userName, userMobile,
        orderAddress.ADDRESS, orderAddress.COUNTRY, orderAddress.STATE,
        orderAddress.CITY, orderAddress.PINCODE,
        totalQuantity, orderTotal, userId
      ]);

      const orderId = orderResult.insertId;

      // Create order items in cust_order_details table
      for (const item of cartItems) {
        await db.promise().query(`
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

      // Create payment record in cust_payment table
      await db.promise().query(`
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
        paymentMethod === 'online' ? 'online_payment' : 'cash_on_delivery', // PAYMENT_TRANSACTION_TYPE
        'ANWAR_FOOD_001', // PAYMENT_MERCHANT_ID (default merchant ID)
        orderTotal, // PAYMENT_AMOUNT
        paymentMethod || 'cod', // PAYMENT_PAYMENT_METHOD
        paymentMethod || 'cod', // PAYMENT_PAYMENT_MODE
        paymentMethod === 'online' ? 'pending' : 'cod', // PAYMENT_STATUS
        paymentMethod === 'online' ? 'Payment pending verification' : 'Cash on delivery order created', // PAYMENT_STATUS_MESSAGE
        paymentMethod === 'online' ? '100' : '200', // PAYMENT_RESPONSE_CODE (100=pending, 200=COD)
        paymentMethod === 'online' ? 'Payment submitted successfully' : 'COD order created', // PAYMENT_RESPONSE_MESSAGE
        orderNumber, // PAYMENT_PAYMENT_INVOICE_NO
        'INR', // PAYMENT_CURRENCY_CODE
        userName, // PAYMENT_DELIVERY_NAME
        orderAddress.COUNTRY, // PAYMENT_DELIVERY_COUNTRY
        orderAddress.STATE, // PAYMENT_DELIVERY_STATE
        orderAddress.CITY, // PAYMENT_DELIVERY_CITY
        orderAddress.PINCODE, // PAYMENT_DELIVERY_ZIP
        userName, // PAYMENT_BILLING_NAME
        orderAddress.CITY, // PAYMENT_BILLING_CITY
        orderAddress.ADDRESS, // PAYMENT_BILLING_ADDRESS
        userInfo[0].EMAIL || '', // PAYMENT_BILLING_EMAIL (if available from user_info)
        orderAddress.COUNTRY, // PAYMENT_BILLING_COUNTRY
        orderAddress.STATE, // PAYMENT_BILLING_STATE
        orderAddress.PINCODE, // PAYMENT_BILLING_ZIP
        userId, // CREATED_BY
        userId // UPDATED_BY
      ]);

      // Clear cart
      await db.promise().query('DELETE FROM cart WHERE USER_ID = ?', [userId]);

      // Commit transaction
      await db.promise().query('COMMIT');

      res.status(201).json({
        success: true,
        message: 'Order placed successfully',
        data: {
          orderId: orderId,
          orderNumber: orderNumber,
          orderTotal: orderTotal,
          paymentImage: req.uploadedFile ? `/uploads/orders/${req.uploadedFile.filename}` : null,
          deliveryAddress: {
            address: orderAddress.ADDRESS,
            city: orderAddress.CITY,
            state: orderAddress.STATE,
            country: orderAddress.COUNTRY,
            pincode: orderAddress.PINCODE,
            landmark: orderAddress.LANDMARK
          }
        }
      });

    } catch (error) {
      await db.promise().query('ROLLBACK');
      throw error;
    }

  } catch (error) {
    console.error('Place order error:', error);
    res.status(500).json({
      success: false,
      message: 'Error placing order',
      error: error.message
    });
  }
};

const increaseQuantity = async (req, res) => {
  try {
    const { cartId } = req.body;
    const userId = req.user.userId;

    // Get cart item with product unit details
    const [cartItems] = await db.promise().query(`
      SELECT c.*, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    if (cartItems.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found or does not belong to user'
      });
    }

    const cartItem = cartItems[0];
    const unitValue = cartItem.PU_PROD_UNIT_VALUE;

    // Increase quantity by unit value
    await db.promise().query(
      'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE CART_ID = ? AND USER_ID = ?',
      [unitValue, cartId, userId]
    );

    // Get updated cart item details
    const [updatedItem] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, pu.PU_PROD_RATE, pu.PU_PROD_UNIT_VALUE
      FROM cart c
      JOIN product_master p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    res.json({
      success: true,
      message: 'Quantity increased successfully',
      data: {
        cartId: updatedItem[0].CART_ID,
        quantity: updatedItem[0].QUANTITY,
        itemTotal: updatedItem[0].PU_PROD_RATE * updatedItem[0].QUANTITY
      }
    });
  } catch (error) {
    console.error('Increase quantity error:', error);
    res.status(500).json({
      success: false,
      message: 'Error increasing quantity',
      error: error.message
    });
  }
};

const decreaseQuantity = async (req, res) => {
  try {
    const { cartId } = req.body;
    const userId = req.user.userId;

    // Get cart item with product unit details
    const [cartItems] = await db.promise().query(`
      SELECT c.*, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    if (cartItems.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found or does not belong to user'
      });
    }

    const cartItem = cartItems[0];
    const unitValue = cartItem.PU_PROD_UNIT_VALUE;
    const currentQuantity = cartItem.QUANTITY;

    // If quantity after decrease would be less than or equal to unit value, remove item
    if (currentQuantity <= unitValue) {
      await db.promise().query(
        'DELETE FROM cart WHERE CART_ID = ? AND USER_ID = ?',
        [cartId, userId]
      );

      return res.json({
        success: true,
        message: 'Item removed from cart',
        data: {
          cartId: cartId,
          quantity: 0,
          itemTotal: 0,
          removed: true
        }
      });
    }

    // Decrease quantity by unit value
    await db.promise().query(
      'UPDATE cart SET QUANTITY = QUANTITY - ? WHERE CART_ID = ? AND USER_ID = ?',
      [unitValue, cartId, userId]
    );

    // Get updated cart item details
    const [updatedItem] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, pu.PU_PROD_RATE, pu.PU_PROD_UNIT_VALUE
      FROM cart c
      JOIN product_master p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    res.json({
      success: true,
      message: 'Quantity decreased successfully',
      data: {
        cartId: updatedItem[0].CART_ID,
        quantity: updatedItem[0].QUANTITY,
        itemTotal: updatedItem[0].PU_PROD_RATE * updatedItem[0].QUANTITY,
        removed: false
      }
    });
  } catch (error) {
    console.error('Decrease quantity error:', error);
    res.status(500).json({
      success: false,
      message: 'Error decreasing quantity',
      error: error.message
    });
  }
};

const getCartItemCount = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get total items count and sum of quantities
    const [result] = await db.promise().query(`
      SELECT 
        COUNT(CART_ID) as total_items,
        COALESCE(SUM(QUANTITY), 0) as total_quantity
      FROM cart 
      WHERE USER_ID = ?
    `, [userId]);

    res.json({
      success: true,
      data: {
        totalItems: result[0].total_items,
        totalQuantity: result[0].total_quantity
      }
    });
  } catch (error) {
    console.error('Get cart count error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting cart count',
      error: error.message
    });
  }
};

module.exports = {
  addToCart,
  addToCartAuto,
  addToCartByBarcode,
  editCartUnit,
  fetchCart,
  placeOrder,
  increaseQuantity,
  decreaseQuantity,
  getCartItemCount
}; 