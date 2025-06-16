const { pool: db } = require('../config/database');

const getAddressList = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [addresses] = await db.promise().query(`
      SELECT * FROM customer_address 
      WHERE USER_ID = ? AND DEL_STATUS != 'Y'
      ORDER BY IS_DEFAULT DESC, CREATED_DATE DESC
    `, [userId]);

    res.json({
      success: true,
      data: addresses
    });
  } catch (error) {
    console.error('Error fetching address list:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching address list',
      error: error.message
    });
  }
};

const addAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      address,
      city,
      state,
      country,
      pincode,
      isDefault,
      addressType,
      landmark,
      lat,
      long
    } = req.body;

    // If this is set as default, unset any existing default address
    if (isDefault) {
      await db.promise().query(
        'UPDATE customer_address SET IS_DEFAULT = 0 WHERE USER_ID = ?',
        [userId]
      );
    }

    // Insert new address
    const [result] = await db.promise().query(
      `INSERT INTO customer_address (
        USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, 
        IS_DEFAULT, ADDRESS_TYPE, LANDMARK, CUST_LANG, CUST_LONG, CREATED_DATE
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [userId, address, city, state, country, pincode, isDefault ? 1 : 0, addressType, landmark, lat || null, long || null]
    );

    res.status(201).json({
      success: true,
      message: 'Address added successfully',
      addressId: result.insertId
    });
  } catch (error) {
    console.error('Error adding address:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding address',
      error: error.message
    });
  }
};

const editAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { addressId } = req.params;
    const {
      address,
      city,
      state,
      country,
      pincode,
      isDefault,
      addressType,
      landmark,
      lat,
      long
    } = req.body;

    // Verify address belongs to user
    const [existingAddress] = await db.promise().query(
      'SELECT * FROM customer_address WHERE ADDRESS_ID = ? AND USER_ID = ?',
      [addressId, userId]
    );

    if (existingAddress.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // If this is set as default, unset any existing default address
    if (isDefault) {
      await db.promise().query(
        'UPDATE customer_address SET IS_DEFAULT = 0 WHERE USER_ID = ? AND ADDRESS_ID != ?',
        [userId, addressId]
      );
    }

    // Update address
    await db.promise().query(
      `UPDATE customer_address SET 
        ADDRESS = ?, CITY = ?, STATE = ?, COUNTRY = ?, 
        PINCODE = ?, IS_DEFAULT = ?, ADDRESS_TYPE = ?, 
        LANDMARK = ?, CUST_LANG = ?, CUST_LONG = ?, UPDATED_DATE = NOW()
      WHERE ADDRESS_ID = ? AND USER_ID = ?`,
      [address, city, state, country, pincode, isDefault ? 1 : 0, 
       addressType, landmark, lat || null, long || null, addressId, userId]
    );

    res.json({
      success: true,
      message: 'Address updated successfully'
    });
  } catch (error) {
    console.error('Error updating address:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating address',
      error: error.message
    });
  }
};

const getDefaultAddress = async (req, res) => {
  try {
    const userId = req.user.userId;

    // First try to get the default address
    const [defaultAddress] = await db.promise().query(`
      SELECT * FROM customer_address 
      WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != 'Y'
      LIMIT 1
    `, [userId]);

    // If no default address found, get the most recently added address
    if (defaultAddress.length === 0) {
      const [recentAddress] = await db.promise().query(`
        SELECT * FROM customer_address 
        WHERE USER_ID = ? AND DEL_STATUS != 'Y'
        ORDER BY CREATED_DATE DESC
        LIMIT 1
      `, [userId]);

      if (recentAddress.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No address found for the user'
        });
      }

      return res.json({
        success: true,
        data: recentAddress[0]
      });
    }

    res.json({
      success: true,
      data: defaultAddress[0]
    });
  } catch (error) {
    console.error('Error fetching default address:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching default address',
      error: error.message
    });
  }
};

const setDefaultAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { addressId } = req.params;

    // Start transaction
    await db.promise().query('START TRANSACTION');

    try {
      // First, verify that the address exists and belongs to the user
      const [existingAddress] = await db.promise().query(
        'SELECT ADDRESS_ID FROM customer_address WHERE ADDRESS_ID = ? AND USER_ID = ? AND DEL_STATUS != "Y"',
        [addressId, userId]
      );

      if (existingAddress.length === 0) {
        await db.promise().query('ROLLBACK');
        return res.status(404).json({
          success: false,
          message: 'Address not found or does not belong to you'
        });
      }

      // Set all user's addresses to non-default (IS_DEFAULT = 0)
      await db.promise().query(
        'UPDATE customer_address SET IS_DEFAULT = 0, UPDATED_DATE = NOW() WHERE USER_ID = ?',
        [userId]
      );

      // Set the specified address as default (IS_DEFAULT = 1)
      await db.promise().query(
        'UPDATE customer_address SET IS_DEFAULT = 1, UPDATED_DATE = NOW() WHERE ADDRESS_ID = ? AND USER_ID = ?',
        [addressId, userId]
      );

      // Commit transaction
      await db.promise().query('COMMIT');

      // Fetch the updated default address to return in response
      const [updatedAddress] = await db.promise().query(
        'SELECT * FROM customer_address WHERE ADDRESS_ID = ? AND USER_ID = ?',
        [addressId, userId]
      );

      res.json({
        success: true,
        message: 'Default address updated successfully',
        data: updatedAddress[0]
      });

    } catch (error) {
      await db.promise().query('ROLLBACK');
      throw error;
    }

  } catch (error) {
    console.error('Error setting default address:', error);
    res.status(500).json({
      success: false,
      message: 'Error setting default address',
      error: error.message
    });
  }
};

module.exports = {
  getAddressList,
  addAddress,
  editAddress,
  getDefaultAddress,
  setDefaultAddress
}; 