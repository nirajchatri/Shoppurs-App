const { pool: db } = require('../config/database');

const getAdvertising = async (req, res) => {
  try {
    const [ads] = await db.promise().query('SELECT * FROM advertising');
    
    res.json({
      success: true,
      data: ads
    });
  } catch (error) {
    console.error('Error fetching advertising:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching advertising data',
      error: error.message
    });
  }
};

const getBrands = async (req, res) => {
  try {
    const [brands] = await db.promise().query('SELECT * FROM brand');
    
    res.json({
      success: true,
      data: brands
    });
  } catch (error) {
    console.error('Error fetching brands:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching brand data',
      error: error.message
    });
  }
};

const getAppName = async (req, res) => {
  try {
    const [settings] = await db.promise().query('SELECT app_name FROM app_settings LIMIT 1');
    
    res.json({
      success: true,
      data: settings[0] || {}
    });
  } catch (error) {
    console.error('Error fetching app name:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching app name',
      error: error.message
    });
  }
};

const getAppSupport = async (req, res) => {
  try {
    const [settings] = await db.promise().query(
      'SELECT app_name, support_number, support_email FROM app_settings LIMIT 1'
    );
    
    res.json({
      success: true,
      data: settings[0] || {}
    });
  } catch (error) {
    console.error('Error fetching app support info:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching app support information',
      error: error.message
    });
  }
};

const getAppBankDetails = async (req, res) => {
  try {
    const [settings] = await db.promise().query(`
      SELECT 
        id, app_name, bank_name, branch, ifsc_code, 
        account_number, upi_image_url, created_at, updated_at 
      FROM app_settings 
      LIMIT 1
    `);
    
    res.json({
      success: true,
      data: settings[0] || {}
    });
  } catch (error) {
    console.error('Error fetching app bank details:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching app bank details',
      error: error.message
    });
  }
};

module.exports = {
  getAdvertising,
  getBrands,
  getAppName,
  getAppSupport,
  getAppBankDetails
}; 