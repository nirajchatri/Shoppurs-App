const { pool: db } = require('../config/database');

const getOrderList = async (req, res) => {
  try {
    const userId = req.user.userId;

    // First get user's mobile number
    const [userInfo] = await db.promise().query(`
      SELECT MOBILE FROM user_info WHERE USER_ID = ?
    `, [userId]);

    if (userInfo.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = userInfo[0].MOBILE;

    // Get retailer info if exists
    const [retailerInfo] = await db.promise().query(`
      SELECT 
        RET_ID, RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, 
        RET_MOBILE_NO, RET_ADDRESS, RET_PIN_CODE, RET_EMAIL_ID, 
        RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, RET_GST_NO, 
        RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, 
        UPDATED_DATE, CREATED_BY, UPDATED_BY, SHOP_OPEN_STATUS
      FROM retailer_info 
      WHERE RET_MOBILE_NO = ?
    `, [userMobile]);

    const [orders] = await db.promise().query(`
      SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
             co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
             co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
             co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
             co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
             co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE,
             co.CREATED_DATE, co.UPDATED_DATE,
             COUNT(cod.COD_ID) as total_items,
             SUM(cod.COD_QTY) as total_quantity
      FROM cust_order co
      LEFT JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
      GROUP BY co.CO_ID
      ORDER BY co.CREATED_DATE DESC
    `, [userMobile]);

    res.json({
      success: true,
      data: {
        orders,
        retailer_info: retailerInfo.length > 0 ? retailerInfo[0] : null,
        user_info: {
          USER_ID: userId,
          MOBILE: userMobile
        }
      }
    });
  } catch (error) {
    console.error('Get order list error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order list',
      error: error.message
    });
  }
};

const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.userId;

    // Get user's mobile number
    const [userInfo] = await db.promise().query(`
      SELECT MOBILE FROM user_info WHERE USER_ID = ?
    `, [userId]);

    if (userInfo.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = userInfo[0].MOBILE;

    // Get order header
    const [orders] = await db.promise().query(`
      SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
             co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
             co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
             co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
             co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
             co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE, co.INVOICE_URL as INVOICE_URL,
             co.CREATED_DATE, co.UPDATED_DATE
      FROM cust_order co 
      WHERE co.CO_ID = ? AND co.CO_CUST_MOBILE = ?
    `, [orderId, userMobile]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items with product details
    const [orderItems] = await db.promise().query(`
      SELECT cod.COD_ID as ORDER_ITEM_ID, cod.COD_CO_ID as ORDER_ID, 
             cod.PROD_ID, cod.COD_QTY as QUANTITY, cod.PROD_SP as UNIT_PRICE,
             (cod.COD_QTY * cod.PROD_SP) as TOTAL_PRICE,
             cod.PROD_NAME, cod.PROD_IMAGE_1, cod.PROD_UNIT,
             cod.PROD_UNIT as PU_PROD_UNIT, '' as PU_PROD_UNIT_VALUE
      FROM cust_order_details cod
      WHERE cod.COD_CO_ID = ?
    `, [orderId]);

    res.json({
      success: true,
      data: {
        order: orders[0],
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

const cancelOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.userId;
    console.log(orderId, userId);

    // Get user's mobile number
    const [userInfo] = await db.promise().query(`
      SELECT MOBILE FROM user_info WHERE USER_ID = ?
    `, [userId]);

    if (userInfo.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = userInfo[0].MOBILE;

    // First check if the order exists and belongs to the user
    const [orders] = await db.promise().query(`
      SELECT CO_ID FROM cust_order 
      WHERE CO_ID = ? AND CO_CUST_MOBILE = ? AND CO_STATUS = 'pending'
    `, [orderId, userMobile]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found or cannot be cancelled'
      });
    }

    // Update the order status to cancelled
    await db.promise().query(`
      UPDATE cust_order 
      SET CO_STATUS = 'cancelled',
          UPDATED_DATE = NOW()
      WHERE CO_ID = ? AND CO_CUST_MOBILE = ? AND CO_STATUS = 'pending'
    `, [orderId, userMobile]);

    res.json({
      success: true,
      message: 'Order cancelled successfully'
    });
  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({
      success: false,
      message: 'Error cancelling order',
      error: error.message
    });
  }
};

const searchOrders = async (req, res) => {
  try {
    const { query } = req.query;
    const userId = req.user.userId;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Get user's mobile number
    const [userInfo] = await db.promise().query(`
      SELECT MOBILE FROM user_info WHERE USER_ID = ?
    `, [userId]);

    if (userInfo.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = userInfo[0].MOBILE;

    // Search orders by order number
    const [orders] = await db.promise().query(`
      SELECT co.CO_ID as ORDER_ID, co.CO_NO as ORDER_NUMBER, co.CO_CUST_CODE as USER_ID,
             co.CO_TOTAL_AMT as ORDER_TOTAL, co.CO_STATUS as ORDER_STATUS,
             co.CO_DELIVERY_ADDRESS as DELIVERY_ADDRESS, co.CO_DELIVERY_CITY as DELIVERY_CITY,
             co.CO_DELIVERY_STATE as DELIVERY_STATE, co.CO_DELIVERY_COUNTRY as DELIVERY_COUNTRY,
             co.CO_PINCODE as DELIVERY_PINCODE, co.CO_PAYMENT_MODE as PAYMENT_METHOD,
             co.CO_DELIVERY_NOTE as ORDER_NOTES, co.CO_IMAGE as PAYMENT_IMAGE,
             co.CREATED_DATE, co.UPDATED_DATE,
             COUNT(cod.COD_ID) as total_items,
             SUM(cod.COD_QTY) as total_quantity
      FROM cust_order co
      LEFT JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ? 
      AND REPLACE(co.CO_NO, 'ORD', '') LIKE ?
      GROUP BY co.CO_ID
      ORDER BY 
        CASE 
          WHEN co.CO_NO = ? THEN 1
          WHEN REPLACE(co.CO_NO, 'ORD', '') = ? THEN 2
          WHEN REPLACE(co.CO_NO, 'ORD', '') LIKE ? THEN 3
          ELSE 4
        END,
        co.CREATED_DATE DESC
    `, [userMobile, `%${query}%`, query, query, `${query}%`]);

    res.json({
      success: true,
      data: orders,
      count: orders.length,
      filters: {
        query: query
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

module.exports = {
  getOrderList,
  getOrderDetails,
  cancelOrder,
  searchOrders
}; 