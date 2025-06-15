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
      landmark
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
        IS_DEFAULT, ADDRESS_TYPE, LANDMARK, CREATED_DATE
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [userId, address, city, state, country, pincode, isDefault ? 1 : 0, addressType, landmark]
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
      landmark
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
        LANDMARK = ?, UPDATED_DATE = NOW()
      WHERE ADDRESS_ID = ? AND USER_ID = ?`,
      [address, city, state, country, pincode, isDefault ? 1 : 0, 
       addressType, landmark, addressId, userId]
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

module.exports = {
  getAddressList,
  addAddress,
  editAddress,
  getDefaultAddress
}; 