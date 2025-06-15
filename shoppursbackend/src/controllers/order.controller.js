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
      SELECT o.*, 
             COUNT(oi.ORDER_ITEM_ID) as total_items,
             SUM(oi.QUANTITY) as total_quantity
      FROM orders o
      LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID = ?
      GROUP BY o.ORDER_ID
      ORDER BY o.CREATED_DATE DESC
    `, [userId]);

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

    // Get order header
    const [orders] = await db.promise().query(`
      SELECT * FROM orders 
      WHERE ORDER_ID = ? AND USER_ID = ?
    `, [orderId, userId]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items with product details
    const [orderItems] = await db.promise().query(`
      SELECT oi.*, p.PROD_NAME, p.PROD_IMAGE_1,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE
      FROM order_items oi
      JOIN product p ON oi.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON oi.UNIT_ID = pu.PU_ID
      WHERE oi.ORDER_ID = ?
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
    // First check if the order exists and belongs to the user
    const [orders] = await db.promise().query(`
      SELECT * FROM orders 
      WHERE ORDER_ID = ? AND USER_ID = ? AND ORDER_STATUS = 'pending'
    `, [orderId, userId]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found or cannot be cancelled'
      });
    }

    // Update the order status to cancelled
    await db.promise().query(`
      UPDATE orders 
      SET ORDER_STATUS = 'cancelled',
          UPDATED_DATE = NOW()
      WHERE ORDER_ID = ? AND USER_ID = ? AND ORDER_STATUS = 'pending'
    `, [orderId, userId]);

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

    // Search orders by order number
    const [orders] = await db.promise().query(`
      SELECT o.*, 
             COUNT(oi.ORDER_ITEM_ID) as total_items,
             SUM(oi.QUANTITY) as total_quantity
      FROM orders o
      LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID = ? 
      AND REPLACE(o.ORDER_NUMBER, 'ORD', '') LIKE ?
      GROUP BY o.ORDER_ID
      ORDER BY 
        CASE 
          WHEN o.ORDER_NUMBER = ? THEN 1
          WHEN REPLACE(o.ORDER_NUMBER, 'ORD', '') = ? THEN 2
          WHEN REPLACE(o.ORDER_NUMBER, 'ORD', '') LIKE ? THEN 3
          ELSE 4
        END,
        o.CREATED_DATE DESC
    `, [userId, `%${query}%`, query, query, `${query}%`]);

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