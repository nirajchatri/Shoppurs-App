const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool: db } = require('../config/database');
const axios = require('axios');
const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const createDirectory = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

// Create required directories
createDirectory(path.join(__dirname, '../../uploads/retailers/qrcode'));

async function sendVerificationOTP(phone) {
  const url = 'https://cpaas.messagecentral.com/verification/v3/send';

  const headers = {
    authToken: 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLURFQkUyQjY4OTM4NTRBRCIsImlhdCI6MTcyMjMyNDU4MCwiZXhwIjoxODgwMDA0NTgwfQ.ihHWg1LXsk1WCjmYiCb0fA6sYrbqUORZjsw-0kr90w662ZlW7UCbb_O5GWx9_7gnzWdTA3zoGgmc1p2tQ2B4mg'
  };

  const params = {
    countryCode: '91',
    customerId: 'C-DEBE2B6893854AD',
    flowType: 'SMS',
    mobileNumber: phone
  };

  try {
    const response = await axios.post(url, null, {
      headers: headers,
      params: params
    });
    

    if (response.status !== 200) {
      throw new Error("Please wait 90 seconds before trying again.");
    }

    return response.data;
  } catch (error) {
    console.error("Error sending OTP:", error.message);
    return false;
  }
}


async function validateOTP(phone, verification_code, otp) {
  const url = 'https://cpaas.messagecentral.com/verification/v3/validateOtp';

  const headers = {
    authToken: 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLUZBNTY5QzEzODY0QjQ5OSIsImlhdCI6MTcyMDY3NzcwOSwiZXhwIjoxODc4MzU3NzA5fQ.IKzKR57hg8vdCQux-GnGbuxw1H9BMXxrrJOS_OwUl2TZ2XxDZpDof9wcvenw6yG2Ygjcpfr8dEMVizPZaWf-KA'
  };

  const params = {
    countryCode: '91',
    mobileNumber: phone,
    verificationId: verification_code,
    customerId: 'C-DEBE2B6893854AD',
    code: otp
  };

  try {
    const response = await axios.get(url, {
      headers: headers,
      params: params
    });

    if (response.status !== 200) {
      throw new Error("The OTP is either invalid or has expired.");
    }

    const verificationStatus = response.data?.data?.verificationStatus;
    return verificationStatus === 'VERIFICATION_COMPLETED';
  } catch (error) {
    console.error("Error validating OTP:", error.message);
    throw error;
  }
}



const signup = async (req, res) => {
  try {
    const { username, email, password, mobile, city, province, zip, address } = req.body;

    // Check if user already exists in user_info table only
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, mobile]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or mobile'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user with UL_ID set to 1 (assuming 1 is a valid user level ID)
    const [result] = await db.promise().query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE
      ) VALUES (
        1, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'customer', 'Y'
      )`,
      [username, email, mobile, hashedPassword, city, province, zip, address]
    );

    let dataCode;
    try {
      dataCode = await sendVerificationOTP(mobile);
      console.log(dataCode);
      
      if (dataCode == false) {
        return res.status(500).json({
          success: false,
          message: 'Please wait 60 seconds before trying again.',
          error: "Please wait 60 seconds before trying again."
        });
      }
      
      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        userId: result.insertId,
        verificationId: dataCode?.data?.verificationId || null
      });
    } catch (err) {
      console.log('Error:', err.message);
      return res.status(500).json({
        success: false,
        message: 'Please wait 60 seconds before trying again.',
        error: "Please wait 60 seconds before trying again."
      });
    }
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in registration',
      error: error.message
    });
  }
};

const login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Find user
    const [users] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?' ,
      [phone]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Login failed. Make sure your Phone and password are correct.'
      });
    }

    const user = users[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.PASSWORD);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Login failed. Make sure your email and password are correct.'
      });
    }
    console.log(user['is_otp_verify']);
    if (user['is_otp_verify'] != 1) {
      let dataCode;
      try {
        dataCode = await sendVerificationOTP(phone);
        console.log(dataCode);
      } catch (err) {
        console.log('Error:', err.message);
        return res.status(401).json({
          success: false,
          message: 'You need to verify your account, Please contact support',
          verificationId: null,
          userId: user.USER_ID
        });
      }
      
      return res.status(401).json({
        success: false,
        message: 'You need to verify your account, Please contact support',
        verificationId: dataCode?.data?.verificationId || null,
        userId: user.USER_ID
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.USER_ID, email: user.EMAIL },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '100h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.USER_ID,
        username: user.USERNAME,
        email: user.EMAIL,
        mobile: user.MOBILE,
        role: user.USER_TYPE
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in login',
      error: error.message
    });
  }
};

const verifyOtp = async (req, res) => {
  try {
    const { phone, verification_code, otp, long, lat } = req.body;

    const isOTPValid = await validateOTP(phone, verification_code, otp);
    if (!isOTPValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    const user = existingUser[0];

    // Update is_otp_verify field to true
    await db.promise().query(
      'UPDATE user_info SET is_otp_verify = TRUE WHERE MOBILE = ?',
      [phone]
    );

    // Check if retailer profile already exists
    const [existingRetailer] = await db.promise().query(
      'SELECT * FROM retailer_info WHERE RET_MOBILE_NO = ?',
      [phone]
    );

    // Create retailer profile if it doesn't exist
    if (existingRetailer.length === 0) {
      // Get the last retailer code
      const [lastRetailer] = await db.promise().query(
        'SELECT RET_CODE FROM retailer_info ORDER BY RET_ID DESC LIMIT 1'
      );

      // Generate next retailer code
      let nextNumber = 1;
      if (lastRetailer.length > 0) {
        const lastCode = lastRetailer[0].RET_CODE;
        const lastNumber = parseInt(lastCode.replace('RET', ''));
        nextNumber = lastNumber + 1;
      }

      // Format the code with leading zeros (e.g., RET001, RET002)
      const retCode = `RET${nextNumber.toString().padStart(3, '0')}`;

      try {
        // Generate QR code for the phone number
        const qrFileName = `qr_${phone}_${Date.now()}.png`;
        const qrPath = path.join(__dirname, '../../uploads/retailers/qrcode', qrFileName);
        
        // Convert phone to string and add country code for better identification
        const phoneWithCode = `+91${phone.toString()}`;
        
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
        
        await db.promise().query(
          `INSERT INTO retailer_info (
            RET_CODE, RET_TYPE, RET_NAME, RET_MOBILE_NO, RET_ADDRESS, RET_PIN_CODE, 
            RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, 
            RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE, CREATED_BY, UPDATED_BY,
            BARCODE_URL
          ) VALUES (
            ?, 'Grocery', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW(), NOW(), ?, ?,
            ?
          )`,
          [
            retCode,
            user.USERNAME || 'User',
            phone,
            user.ADDRESS || 'Not provided',
            user.ZIP || 0,
            user.EMAIL,
            'default-photo.jpg',
            'India',
            user.PROVINCE || 'Not provided',
            user.CITY || 'Not provided',
            lat || null,
            long || null,
            phone,
            phone,
            qrFileName
          ]
        );

        console.log(`Retailer profile created for user: ${phone}`);
      } catch (qrError) {
        console.error('QR Code generation error:', qrError);
        // Continue with profile creation even if QR generation fails
        await db.promise().query(
          `INSERT INTO retailer_info (
            RET_CODE, RET_TYPE, RET_NAME, RET_MOBILE_NO, RET_ADDRESS, RET_PIN_CODE, 
            RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, 
            RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE, CREATED_BY, UPDATED_BY
          ) VALUES (
            ?, 'Grocery', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW(), NOW(), ?, ?
          )`,
          [
            retCode,
            user.USERNAME || 'User',
            phone,
            user.ADDRESS || 'Not provided',
            user.ZIP || 0,
            user.EMAIL,
            'default-photo.jpg',
            'India',
            user.PROVINCE || 'Not provided',
            user.CITY || 'Not provided',
            lat || null,
            long || null,
            phone,
            phone
          ]
        );
      }
    } else {
      // Update coordinates if provided
      if (lat && long) {
        await db.promise().query(
          'UPDATE retailer_info SET RET_LAT = ?, RET_LONG = ?, UPDATED_DATE = NOW() WHERE RET_MOBILE_NO = ?',
          [lat, long, phone]
        );
      }

      // If retailer exists but doesn't have a QR code, generate one
      if (!existingRetailer[0].BARCODE_URL) {
        try {
          const qrFileName = `qr_${phone}_${Date.now()}.png`;
          const qrPath = path.join(__dirname, '../../uploads/retailers/qrcode', qrFileName);
          
          // Convert phone to string and add country code for better identification
          const phoneWithCode = `+91${phone.toString()}`;
          
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

          // Update retailer with QR code filename and coordinates if provided
          let updateQuery = 'UPDATE retailer_info SET BARCODE_URL = ?';
          let updateParams = [qrFileName];
          
          if (lat && long) {
            updateQuery += ', RET_LAT = ?, RET_LONG = ?';
            updateParams.push(lat, long);
          }
          
          updateQuery += ', UPDATED_DATE = NOW() WHERE RET_MOBILE_NO = ?';
          updateParams.push(phone);

          await db.promise().query(updateQuery, updateParams);
        } catch (qrError) {
          console.error('QR Code generation error:', qrError);
          // Continue without updating QR code if generation fails, but still update coordinates
          if (lat && long) {
            await db.promise().query(
              'UPDATE retailer_info SET RET_LAT = ?, RET_LONG = ?, UPDATED_DATE = NOW() WHERE RET_MOBILE_NO = ?',
              [lat, long, phone]
            );
          }
        }
      }
    }

    res.json({
      success: true,
      message: 'Account verified successfully please login',
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in verifying OTP',
      error: error.message
    });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { phone } = req.body;

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Send OTP for password reset
    let dataCode;
    await sendVerificationOTP(phone)
      .then(data => {
        console.log(data);
        dataCode = data;
      })
      .catch(err => {
        console.log('Error:', err.message);
        throw new Error('Failed to send OTP');
      });

    res.json({
      success: true,
      message: 'OTP sent successfully for password reset',
      verificationId: dataCode.verificationId || null
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in sending OTP for password reset',
      error: error.message
    });
  }
};

const verifyOtpPassword = async (req, res) => {
  try {
    const { phone, verification_code, otp } = req.body;

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Validate OTP
    const isOTPValid = await validateOTP(phone, verification_code, otp);
    if (!isOTPValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    res.json({
      success: true,
      message: 'OTP verified successfully. You can now change your password.',
    });
  } catch (error) {
    console.error('Verify OTP password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in verifying OTP',
      error: error.message
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const { phone, password, confirmPassword } = req.body;

    // Check if passwords match
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Password and confirm password do not match'
      });
    }

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update the password in database
    await db.promise().query(
      'UPDATE user_info SET PASSWORD = ? WHERE MOBILE = ?',
      [hashedPassword, phone]
    );

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in changing password',
      error: error.message
    });
  }
};

// New improved password reset APIs
const requestPasswordReset = async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Check if user exists with this phone number and meets the criteria
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ? AND ISACTIVE = ? AND is_otp_verify = ?',
      [phone, 'Y', 1]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No active verified user found with this phone number'
      });
    }

    // Send OTP for password reset
    let dataCode;
    try {
      dataCode = await sendVerificationOTP(phone);
      console.log('OTP sent for password reset:', dataCode);
      
      if (dataCode == false) {
        return res.status(500).json({
          success: false,
          message: 'Please wait 60 seconds before trying again.',
          error: "Please wait 60 seconds before trying again."
        });
      }
      
      res.json({
        success: true,
        message: 'Password reset OTP sent successfully',
        verificationId: dataCode?.data?.verificationId || null
      });
    } catch (err) {
      console.log('Error sending OTP:', err.message);
      return res.status(500).json({
        success: false,
        message: 'Please wait 60 seconds before trying again.',
        error: "Please wait 60 seconds before trying again."
      });
    }
  } catch (error) {
    console.error('Request password reset error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in requesting password reset',
      error: error.message
    });
  }
};

const confirmOtpForPassword = async (req, res) => {
  try {
    const { phone, verification_code, otp } = req.body;

    if (!phone || !verification_code || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number, verification code, and OTP are required'
      });
    }

    // Check if user exists with this phone number and meets the criteria
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ? AND ISACTIVE = ? AND is_otp_verify = ?',
      [phone, 'Y', 1]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No active verified user found with this phone number'
      });
    }

    // Validate OTP
    const isOTPValid = await validateOTP(phone, verification_code, otp);
    if (!isOTPValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    res.json({
      success: true,
      message: 'OTP verified successfully. You can now reset your password.'
    });
  } catch (error) {
    console.error('Confirm OTP for password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in verifying OTP for password reset',
      error: error.message
    });
  }
};

const resetPasswordWithPhone = async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and new password are required'
      });
    }

    // Validate password strength (optional)
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update the password in database
    await db.promise().query(
      'UPDATE user_info SET PASSWORD = ? WHERE MOBILE = ?',
      [hashedPassword, phone]
    );

    res.json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (error) {
    console.error('Reset password with phone error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in resetting password',
      error: error.message
    });
  }
};

const resendOtp = async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Optional: Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Send OTP
    let dataCode;
    try {
      dataCode = await sendVerificationOTP(phone);
      console.log('Resend OTP response:', dataCode);
      
      if (dataCode == false) {
        return res.status(500).json({
          success: false,
          message: 'Please wait 60 seconds before trying again.',
          error: "Please wait 60 seconds before trying again."
        });
      }
      
      res.json({
        success: true,
        message: 'OTP resent successfully',
        verificationId: dataCode?.data?.verificationId || null
      });
    } catch (err) {
      console.log('Error resending OTP:', err.message);
      return res.status(500).json({
        success: false,
        message: 'Please wait 60 seconds before trying again.',
        error: "Please wait 60 seconds before trying again."
      });
    }
  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in resending OTP',
      error: error.message
    });
  }
};

module.exports = {
  signup,
  login,
  verifyOtp,
  resetPassword,
  verifyOtpPassword,
  changePassword,
  requestPasswordReset,
  confirmOtpForPassword,
  resetPasswordWithPhone,
  resendOtp
}; 