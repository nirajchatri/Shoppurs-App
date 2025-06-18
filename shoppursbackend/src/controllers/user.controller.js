const { pool: db } = require('../config/database');
const path = require('path');
const fs = require('fs');

// Update User Profile (Name and Photo)
const updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId; // Get from JWT token (corrected property name)
    const { username } = req.body;

    // Validate input
    if (!username && !req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please provide either username or profile photo to update'
      });
    }

    // Validate username if provided
    if (username) {
      if (typeof username !== 'string' || username.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Username must be at least 2 characters long'
        });
      }

      if (username.trim().length > 100) {
        return res.status(400).json({
          success: false,
          message: 'Username must not exceed 100 characters'
        });
      }
    }

    // Get current user details
    const [currentUser] = await db.promise().query(
      'SELECT USER_ID, USERNAME, PHOTO FROM user_info WHERE USER_ID = ? AND ISACTIVE = ?',
      [userId, 'Y']
    );

    if (currentUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    const user = currentUser[0];
    let updateFields = [];
    let updateValues = [];

    // Handle username update
    if (username && username.trim() !== user.USERNAME) {
      updateFields.push('USERNAME = ?');
      updateValues.push(username.trim());
    }

    // Handle profile photo update
    let newPhotoPath = null;
    if (req.uploadedFile) {
      // Delete old profile photo if exists
      if (user.PHOTO) {
        const oldPhotoPath = path.join(__dirname, '../../', user.PHOTO);
        if (fs.existsSync(oldPhotoPath)) {
          try {
            fs.unlinkSync(oldPhotoPath);
          } catch (deleteError) {
            console.log('Could not delete old profile photo:', deleteError.message);
          }
        }
      }

      // Set new photo path
      newPhotoPath = `uploads/users/profiles/${req.uploadedFile.filename}`;
      updateFields.push('PHOTO = ?');
      updateValues.push(newPhotoPath);
    }

    // Check if there are any updates to make
    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No changes detected. Please provide new username or profile photo'
      });
    }

    // Add metadata fields
    updateFields.push('UPDATED_DATE = NOW()');
    updateFields.push('UPDATED_BY = ?');
    updateValues.push(req.user.email || req.user.username || 'user'); // Use email as fallback for UPDATED_BY

    // Update user profile
    await db.promise().query(
      `UPDATE user_info SET ${updateFields.join(', ')} WHERE USER_ID = ?`,
      [...updateValues, userId]
    );

    // Get updated user details (exclude sensitive information)
    const [updatedUser] = await db.promise().query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, PHOTO, USER_TYPE, UPDATED_DATE 
       FROM user_info WHERE USER_ID = ?`,
      [userId]
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedUser[0],
        changes_made: {
          username_updated: updateFields.some(field => field.includes('USERNAME')),
          photo_updated: updateFields.some(field => field.includes('PHOTO')),
          photo_url: newPhotoPath ? `${req.protocol}://${req.get('host')}/${newPhotoPath}` : null
        },
        updated_by: req.user.email || req.user.username || 'user'
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    
    // If file was uploaded but database update failed, clean up the uploaded file
    if (req.uploadedFile) {
      const uploadedFilePath = path.join(__dirname, '../../uploads/users/profiles/', req.uploadedFile.filename);
      if (fs.existsSync(uploadedFilePath)) {
        try {
          fs.unlinkSync(uploadedFilePath);
        } catch (deleteError) {
          console.log('Could not clean up uploaded file:', deleteError.message);
        }
      }
    }

    res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message
    });
  }
};

// Get Current User Profile
const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId; // Get from JWT token (corrected property name)
    console.log('userId', userId);
    // Debug: Log the userId being searched
    console.log('Searching for user with ID:', userId);
    console.log('User from JWT:', req.user);

    // Get user profile details (exclude sensitive information)
    const [userProfile] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
              ADDRESS, PHOTO, USER_TYPE, CREATED_DATE, UPDATED_DATE, is_otp_verify, ISACTIVE
       FROM user_info 
       WHERE USER_ID = ? AND ISACTIVE = ?`,
      [userId, 'Y']
    );

    console.log('Query result:', userProfile);
    console.log('Number of rows found:', userProfile.length);

    if (userProfile.length === 0) {
      // Try to find the user without the ISACTIVE filter to debug
      const [debugUser] = await db.promise().query(
        'SELECT USER_ID, USERNAME, ISACTIVE FROM user_info WHERE USER_ID = ?',
        [userId]
      );
      
      console.log('Debug query result:', debugUser);
      
      return res.status(404).json({
        success: false,
        message: 'User profile not found or inactive',
        debug: {
          searched_user_id: userId,
          user_found: debugUser.length > 0,
          user_details: debugUser.length > 0 ? debugUser[0] : null
        }
      });
    }

    const user = userProfile[0];
    
    // Add full photo URL if photo exists
    const profileData = {
      ...user,
      photo_url: user.PHOTO ? `${req.protocol}://${req.get('host')}/${user.PHOTO}` : null
    };

    res.json({
      success: true,
      message: 'User profile fetched successfully',
      data: {
        profile: profileData
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user profile',
      error: error.message
    });
  }
};

module.exports = {
  updateProfile,
  getProfile
}; 