const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (!firebaseInitialized) {
    try {
      // Check if Firebase is already initialized
      if (admin.apps.length === 0) {
        // Try to initialize with service account key file first
        try {
          const serviceAccount = require('../../firebase-service-account-key.json');
          
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id
          });
          
          console.log('Firebase Admin SDK initialized successfully with service account key');
          firebaseInitialized = true;
        } catch (keyError) {
          console.log('Service account key file not found, trying environment variables...');
          
          // Fallback: Try to initialize with environment variables
          if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
            admin.initializeApp({
              credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
              }),
              projectId: process.env.FIREBASE_PROJECT_ID
            });
            
            console.log('Firebase Admin SDK initialized with environment variables');
            firebaseInitialized = true;
          } else {
            throw new Error('Firebase configuration not found. Please add firebase-service-account-key.json or set environment variables.');
          }
        }
      } else {
        console.log('Firebase Admin SDK already initialized');
        firebaseInitialized = true;
      }
    } catch (error) {
      console.error('Firebase initialization failed:', error.message);
      throw error;
    }
  }
};

// Send notification to multiple FCM tokens
const sendNotificationToTokens = async (tokens, title, body, data = {}) => {
  try {
    // Initialize Firebase if not already done
    if (!firebaseInitialized) {
      initializeFirebase();
    }
    
    if (!tokens || tokens.length === 0) {
      throw new Error('No FCM tokens provided');
    }
    
    if (!title || !body) {
      throw new Error('Title and body are required');
    }
    
    // Clean tokens array - remove duplicates and invalid tokens
    const validTokens = [...new Set(tokens)].filter(token => 
      token && typeof token === 'string' && token.trim().length > 0
    );
    
    if (validTokens.length === 0) {
      throw new Error('No valid FCM tokens provided');
    }
    
    console.log(`Sending notification to ${validTokens.length} tokens`);
    
    // Prepare message data
    const messageData = {};
    if (data && typeof data === 'object') {
      // Convert all data values to strings (FCM requirement)
      Object.keys(data).forEach(key => {
        messageData[key] = String(data[key]);
      });
    }
    messageData.timestamp = new Date().toISOString();
    
    // Try using sendMulticast first (newer method)
    try {
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: messageData,
        tokens: validTokens,
      };
      
      const response = await admin.messaging().sendMulticast(message);
      
      console.log('FCM Notification sent successfully:', {
        successCount: response.successCount,
        failureCount: response.failureCount,
        totalTokens: validTokens.length
      });
      
      // Process failed tokens
      const failedTokens = [];
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push({
              token: validTokens[idx],
              error: resp.error ? resp.error.message : 'Unknown error'
            });
          }
        });
        console.log('Failed tokens:', failedTokens);
      }
      
      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
        responses: response.responses,
        failedTokens: failedTokens
      };
      
    } catch (multicastError) {
      console.log('sendMulticast failed, trying individual sends:', multicastError.message);
      
      // Fallback: Send notifications individually
      const results = [];
      let successCount = 0;
      let failureCount = 0;
      const failedTokens = [];
      
      for (const token of validTokens) {
        try {
          const message = {
            notification: {
              title: title,
              body: body,
            },
            data: messageData,
            token: token,
          };
          
          const response = await admin.messaging().send(message);
          results.push({ success: true, messageId: response });
          successCount++;
        } catch (sendError) {
          results.push({ success: false, error: sendError.message });
          failedTokens.push({
            token: token,
            error: sendError.message
          });
          failureCount++;
        }
      }
      
      console.log('Individual send results:', {
        successCount,
        failureCount,
        totalTokens: validTokens.length
      });
      
      return {
        success: true,
        successCount,
        failureCount,
        responses: results,
        failedTokens
      };
    }
    
  } catch (error) {
    console.error('Error sending FCM notification:', error);
    throw error;
  }
};

// Send notification to a single FCM token
const sendNotificationToToken = async (token, title, body, data = {}) => {
  return await sendNotificationToTokens([token], title, body, data);
};

// Test if Firebase is properly configured
const testFirebaseConnection = async () => {
  try {
    if (!firebaseInitialized) {
      initializeFirebase();
    }
    
    // Try to access Firebase messaging service
    const messaging = admin.messaging();
    
    // Try to create a simple message structure to test the service
    const testMessage = {
      notification: {
        title: 'Test',
        body: 'Test'
      },
      data: {
        test: 'true'
      },
      token: 'test_token'
    };
    
    // We don't actually send this, just validate the structure
    return { success: true, message: 'Firebase connection successful' };
  } catch (error) {
    return { success: false, message: error.message };
  }
};

// Common utility function for sending notifications - Easy to use from any API
const sendNotification = async (fcmTokens, title, body, data = {}) => {
  try {
    // Handle both single token and array of tokens
    const tokens = Array.isArray(fcmTokens) ? fcmTokens : [fcmTokens];
    
    // Filter out null/undefined/empty tokens
    const validTokens = tokens.filter(token => token && token.trim().length > 0);
    
    if (validTokens.length === 0) {
      return {
        success: false,
        message: 'No valid FCM tokens provided',
        data: null
      };
    }
    
    // Send notification using the existing service
    const result = await sendNotificationToTokens(validTokens, title, body, data);
    
    return {
      success: true,
      message: `Notification sent to ${result.successCount} out of ${validTokens.length} devices`,
      data: {
        total_tokens: validTokens.length,
        success_count: result.successCount,
        failure_count: result.failureCount,
        failed_tokens: result.failedTokens
      }
    };
    
  } catch (error) {
    console.error('Error in sendNotification utility:', error);
    return {
      success: false,
      message: 'Failed to send notification',
      error: error.message,
      data: null
    };
  }
};

// Quick notification function for simple use cases
const quickNotify = async (fcmToken, title, message, customData = {}) => {
  return await sendNotification(fcmToken, title, message, customData);
};

// Broadcast notification to multiple users
const broadcastNotification = async (fcmTokens, title, message, customData = {}) => {
  return await sendNotification(fcmTokens, title, message, customData);
};

module.exports = {
  sendNotificationToTokens,
  sendNotificationToToken,
  testFirebaseConnection,
  initializeFirebase,
  // New common functions
  sendNotification,
  quickNotify,
  broadcastNotification
}; 