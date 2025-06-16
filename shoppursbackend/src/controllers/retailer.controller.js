const { pool: db } = require('../config/database');

const getRetailerList = async (req, res) => {
  try {
    const [retailers] = await db.promise().query(`
      SELECT RET_ID, RET_CODE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, 
             RET_ADDRESS, RET_CITY, RET_STATE, RET_PIN_CODE, RET_PHOTO,
             SHOP_OPEN_STATUS
      FROM retailer_info 
      WHERE RET_DEL_STATUS = 'active'
    `);

    res.json({
      success: true,
      data: retailers
    });
  } catch (error) {
    console.error('Error fetching retailer list:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer list',
      error: error.message
    });
  }
};

const getRetailerInfo = async (req, res) => {
  try {
    const { retailerId } = req.params;

    const [retailers] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_ID = ? AND RET_DEL_STATUS = 'active'
    `, [retailerId]);

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
    console.error('Error fetching retailer info:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer info',
      error: error.message
    });
  }
};

const getRetailerByUserMobile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { lat, long } = req.query;

    // First, get the user's mobile number
    const [users] = await db.promise().query(`
      SELECT MOBILE FROM user_info 
      WHERE USER_ID = ? AND ISACTIVE = 'Y'
    `, [userId]);

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = users[0].MOBILE;

    // Then, find the retailer with matching mobile number
    const [retailers] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS = 'active'
    `, [userMobile]);

    if (retailers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No retailer found with your mobile number'
      });
    }

    const retailer = retailers[0];
    const retailerMobile = retailer.RET_MOBILE_NO;

    // If lat and long are provided, update them in retailer_info
    if (lat !== undefined && long !== undefined) {
      await db.promise().query(
        'UPDATE retailer_info SET RET_LAT = ?, RET_LONG = ? WHERE RET_ID = ?',
        [lat, long, retailer.RET_ID]
      );
      // Also update the retailer object for response
      retailer.RET_LAT = lat;
      retailer.RET_LONG = long;
    }

    // Get users with the same mobile number as the retailer
    const [retailerUsers] = await db.promise().query(`
      SELECT USER_ID FROM user_info 
      WHERE MOBILE = ? AND ISACTIVE = 'Y'
    `, [retailerMobile]);

    const userIds = retailerUsers.map(user => user.USER_ID);

    if (userIds.length === 0) {
      // No users found with retailer's mobile number, return empty data
      res.json({
        success: true,
        data: {
          retailer: retailer,
          sales_summary: {
            total_orders: 0,
            total_sales_amount: 0,
            total_items_sold: 0,
            average_order_value: 0
          },
          graph_data: {
            monthly_sales: [],
            daily_sales: []
          },
          top_products: [],
          recent_orders: []
        }
      });
      return;
    }

    // Get total sales data from cust_order table
    const [totalSales] = await db.promise().query(`
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as total_sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as total_items_sold,
        COALESCE(AVG(CO_TOTAL_AMT), 0) as average_order_value
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ? 
        AND co.CO_STATUS != 'cancelled'
    `, [retailerMobile]);

    // Get monthly sales data for graph (last 12 months)
    const [monthlySales] = await db.promise().query(`
      SELECT 
        DATE_FORMAT(CREATED_DATE, '%Y-%m') as month,
        COUNT(*) as orders_count,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as items_sold
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
        AND co.CREATED_DATE >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(CREATED_DATE, '%Y-%m')
      ORDER BY month ASC
    `, [retailerMobile]);

    // Get daily sales data for the current month
    const [dailySales] = await db.promise().query(`
      SELECT 
        DATE(CREATED_DATE) as date,
        COUNT(*) as orders_count,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as items_sold
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
        AND MONTH(CREATED_DATE) = MONTH(CURDATE())
        AND YEAR(CREATED_DATE) = YEAR(CURDATE())
      GROUP BY DATE(CREATED_DATE)
      ORDER BY date ASC
    `, [retailerMobile]);

    // Get top selling products
    const [topProducts] = await db.promise().query(`
      SELECT 
        cod.PROD_NAME as product_name,
        SUM(cod.COD_QTY) as total_quantity,
        SUM(cod.COD_QTY * cod.PROD_SP) as total_amount,
        COUNT(DISTINCT co.CO_ID) as order_count
      FROM cust_order co
      JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
      GROUP BY cod.PROD_ID, cod.PROD_NAME
      ORDER BY total_quantity DESC
      LIMIT 10
    `, [retailerMobile]);

    // Get recent orders
    const [recentOrders] = await db.promise().query(`
      SELECT 
        co.CO_ID as ORDER_ID,
        co.CO_NO as ORDER_NUMBER,
        co.CREATED_DATE,
        co.CO_CUST_NAME as customer_name,
        co.CO_CUST_MOBILE as customer_mobile,
        co.CO_TOTAL_AMT as ORDER_TOTAL,
        cod.total_quantity,
        co.CO_STATUS as ORDER_STATUS,
        co.CO_PAYMENT_MODE as PAYMENT_METHOD
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
      ORDER BY co.CREATED_DATE DESC
      LIMIT 10
    `, [retailerMobile]);

    res.json({
      success: true,
      data: {
        retailer: retailer,
        sales_summary: {
          total_orders: totalSales[0].total_orders,
          total_sales_amount: parseFloat(totalSales[0].total_sales_amount),
          total_items_sold: totalSales[0].total_items_sold,
          average_order_value: parseFloat(totalSales[0].average_order_value)
        },
        graph_data: {
          monthly_sales: monthlySales.map(row => ({
            month: row.month,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          })),
          daily_sales: dailySales.map(row => ({
            date: row.date,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          }))
        },
        top_products: topProducts.map(row => ({
          product_name: row.product_name,
          total_quantity: row.total_quantity,
          total_amount: parseFloat(row.total_amount),
          order_count: row.order_count
        })),
        recent_orders: recentOrders.map(row => ({
          order_id: row.ORDER_ID,
          order_number: row.ORDER_NUMBER,
          order_date: row.CREATED_DATE,
          customer_name: row.customer_name,
          customer_mobile: row.customer_mobile,
          total_amount: parseFloat(row.ORDER_TOTAL),
          total_quantity: row.total_quantity || 0,
          status: row.ORDER_STATUS,
          payment_mode: row.PAYMENT_METHOD
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching retailer by user mobile:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer information',
      error: error.message
    });
  }
};

const updateRetailerProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      RET_TYPE,
      RET_NAME,
      RET_SHOP_NAME,
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
      long, // Optional longitude parameter
      lat   // Optional latitude parameter
    } = req.body;

    // First, get the user's mobile number
    const [users] = await db.promise().query(`
      SELECT MOBILE FROM user_info 
      WHERE USER_ID = ? AND ISACTIVE = 'Y'
    `, [userId]);

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = users[0].MOBILE;

    // Check if retailer exists for this user
    const [existingRetailer] = await db.promise().query(`
      SELECT RET_ID FROM retailer_info 
      WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS = 'active'
    `, [userMobile]);

    if (existingRetailer.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No retailer profile found for your account'
      });
    }

    const retailerId = existingRetailer[0].RET_ID;

    // Build dynamic update query based on provided fields
    const updateFields = [];
    const updateValues = [];

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
    if (RET_ADDRESS !== undefined) {
      updateFields.push('RET_ADDRESS = ?');
      updateValues.push(RET_ADDRESS);
    }
    if (RET_PIN_CODE !== undefined) {
      updateFields.push('RET_PIN_CODE = ?');
      updateValues.push(RET_PIN_CODE);
    }
    if (RET_EMAIL_ID !== undefined) {
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
    // Handle latitude - prioritize 'lat' parameter over 'RET_LAT'
    const latValue = lat !== undefined ? lat : RET_LAT;
    if (latValue !== undefined) {
      updateFields.push('RET_LAT = ?');
      updateValues.push(latValue);
    }
    
    // Handle longitude - prioritize 'long' parameter over 'RET_LONG'
    const longValue = long !== undefined ? long : RET_LONG;
    if (longValue !== undefined) {
      updateFields.push('RET_LONG = ?');
      updateValues.push(longValue);
    }
    if (SHOP_OPEN_STATUS !== undefined) {
      updateFields.push('SHOP_OPEN_STATUS = ?');
      updateValues.push(SHOP_OPEN_STATUS);
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
    updateValues.push(userMobile);

    // Add retailer ID for WHERE clause
    updateValues.push(retailerId);

    const updateQuery = `
      UPDATE retailer_info 
      SET ${updateFields.join(', ')}
      WHERE RET_ID = ?
    `;

    await db.promise().query(updateQuery, updateValues);

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
      message: 'Retailer profile updated successfully',
      data: retailerData,
      uploadedFile: req.uploadedFile ? {
        filename: req.uploadedFile.filename,
        url: `http://localhost:3000/uploads/retailers/profiles/${req.uploadedFile.filename}`
      } : null
    });

  } catch (error) {
    console.error('Error updating retailer profile:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating retailer profile',
      error: error.message
    });
  }
};


const getRetailerByIdAdmin = async (req, res) => {
  try {
    const { retailerId } = req.params;

    const [retailers] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_ID = ? AND RET_DEL_STATUS = 'active'
    `, [retailerId]);


    if (retailers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No retailer found with your mobile number'
      });
    }

    const retailer = retailers[0];

    const retailerMobile = retailer.RET_MOBILE_NO;

    // Get users with the same mobile number as the retailer
    const [retailerUsers] = await db.promise().query(`
      SELECT USER_ID FROM user_info 
      WHERE MOBILE = ? AND ISACTIVE = 'Y'
    `, [retailerMobile]);

    const userIds = retailerUsers.map(user => user.USER_ID);

    if (userIds.length === 0) {
      // No users found with retailer's mobile number, return empty data
      res.json({
        success: true,
        data: {
          retailer: retailer,
          sales_summary: {
            total_orders: 0,
            total_sales_amount: 0,
            total_items_sold: 0,
            average_order_value: 0
          },
          graph_data: {
            monthly_sales: [],
            daily_sales: []
          },
          top_products: [],
          recent_orders: []
        }
      });
      return;
    }

    // Get total sales data from cust_order table
    const [totalSales] = await db.promise().query(`
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as total_sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as total_items_sold,
        COALESCE(AVG(CO_TOTAL_AMT), 0) as average_order_value
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ? 
        AND co.CO_STATUS != 'cancelled'
    `, [retailerMobile]);

    // Get monthly sales data for graph (last 12 months)
    const [monthlySales] = await db.promise().query(`
      SELECT 
        DATE_FORMAT(CREATED_DATE, '%Y-%m') as month,
        COUNT(*) as orders_count,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as items_sold
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
        AND co.CREATED_DATE >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(CREATED_DATE, '%Y-%m')
      ORDER BY month ASC
    `, [retailerMobile]);

    // Get daily sales data for the current month
    const [dailySales] = await db.promise().query(`
      SELECT 
        DATE(CREATED_DATE) as date,
        COUNT(*) as orders_count,
        COALESCE(SUM(CO_TOTAL_AMT), 0) as sales_amount,
        COALESCE(SUM(cod.total_quantity), 0) as items_sold
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
        AND MONTH(CREATED_DATE) = MONTH(CURDATE())
        AND YEAR(CREATED_DATE) = YEAR(CURDATE())
      GROUP BY DATE(CREATED_DATE)
      ORDER BY date ASC
    `, [retailerMobile]);

    // Get top selling products
    const [topProducts] = await db.promise().query(`
      SELECT 
        cod.PROD_NAME as product_name,
        SUM(cod.COD_QTY) as total_quantity,
        SUM(cod.COD_QTY * cod.PROD_SP) as total_amount,
        COUNT(DISTINCT co.CO_ID) as order_count
      FROM cust_order co
      JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
        AND co.CO_STATUS != 'cancelled'
      GROUP BY cod.PROD_ID, cod.PROD_NAME
      ORDER BY total_quantity DESC
      LIMIT 10
    `, [retailerMobile]);

    // Get recent orders
    const [recentOrders] = await db.promise().query(`
      SELECT 
        co.CO_ID as ORDER_ID,
        co.CO_NO as ORDER_NUMBER,
        co.CREATED_DATE,
        co.CO_CUST_NAME as customer_name,
        co.CO_CUST_MOBILE as customer_mobile,
        co.CO_TOTAL_AMT as ORDER_TOTAL,
        cod.total_quantity,
        co.CO_STATUS as ORDER_STATUS,
        co.CO_PAYMENT_MODE as PAYMENT_METHOD
      FROM cust_order co
      LEFT JOIN (
        SELECT COD_CO_ID, SUM(COD_QTY) as total_quantity 
        FROM cust_order_details 
        GROUP BY COD_CO_ID
      ) cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_MOBILE = ?
      ORDER BY co.CREATED_DATE DESC
      LIMIT 10
    `, [retailerMobile]);

    res.json({
      success: true,
      data: {
        retailer: retailer,
        sales_summary: {
          total_orders: totalSales[0].total_orders,
          total_sales_amount: parseFloat(totalSales[0].total_sales_amount),
          total_items_sold: totalSales[0].total_items_sold,
          average_order_value: parseFloat(totalSales[0].average_order_value)
        },
        graph_data: {
          monthly_sales: monthlySales.map(row => ({
            month: row.month,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          })),
          daily_sales: dailySales.map(row => ({
            date: row.date,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          }))
        },
        top_products: topProducts.map(row => ({
          product_name: row.product_name,
          total_quantity: row.total_quantity,
          total_amount: parseFloat(row.total_amount),
          order_count: row.order_count
        })),
        recent_orders: recentOrders.map(row => ({
          order_id: row.ORDER_ID,
          order_number: row.ORDER_NUMBER,
          order_date: row.CREATED_DATE,
          customer_name: row.customer_name,
          customer_mobile: row.customer_mobile,
          total_amount: parseFloat(row.ORDER_TOTAL),
          total_quantity: row.total_quantity || 0,
          status: row.ORDER_STATUS,
          payment_mode: row.PAYMENT_METHOD
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching retailer by user mobile:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer information',
      error: error.message
    });
  }
};

/**
 * Search retailers by code, shop name, or mobile number
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
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
      SELECT RET_ID, RET_CODE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, RET_PHOTO, RET_ADDRESS, RET_CITY, RET_STATE
      FROM retailer_info 
      WHERE RET_DEL_STATUS = 'active'
      AND (
        RET_CODE LIKE ? OR
        RET_SHOP_NAME LIKE ? OR
        RET_MOBILE_NO LIKE ?
      )
      ORDER BY 
        CASE 
          WHEN RET_SHOP_NAME LIKE ? THEN 1
          WHEN RET_SHOP_NAME LIKE ? THEN 2
          ELSE 3
        END,
        RET_SHOP_NAME ASC
    `, [`%${query}%`, `%${query}%`, `%${query}%`, `${query}%`, `%${query}%`]);

    return res.status(200).json({
      success: true,
      message: 'Retailers fetched successfully',
      data: retailers
    });

  } catch (error) {
    console.error('Error in searchRetailers:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

module.exports = {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile,
  updateRetailerProfile,
  getRetailerByIdAdmin,
  searchRetailers
}; 