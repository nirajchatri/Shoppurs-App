# Common Notification Functions Usage Examples

## Overview
Three easy-to-use notification functions are available for use in any API:

1. **`sendNotification`** - Main function (handles single token or array)
2. **`quickNotify`** - Simple single notification
3. **`broadcastNotification`** - Multiple notifications

## Import Statement
```javascript
const { sendNotification, quickNotify, broadcastNotification } = require('../utils/notificationService');
```

## Function Signatures

### 1. sendNotification(fcmTokens, title, body, data = {})
- **fcmTokens**: String or Array - Single FCM token or array of tokens
- **title**: String - Notification title
- **body**: String - Notification message
- **data**: Object - Optional custom data payload

### 2. quickNotify(fcmToken, title, message, customData = {})
- **fcmToken**: String - Single FCM token
- **title**: String - Notification title
- **message**: String - Notification message
- **customData**: Object - Optional custom data payload

### 3. broadcastNotification(fcmTokens, title, message, customData = {})
- **fcmTokens**: Array - Array of FCM tokens
- **title**: String - Notification title
- **message**: String - Notification message
- **customData**: Object - Optional custom data payload

## Usage Examples

### Example 1: Order Confirmation Notification
```javascript
const { quickNotify } = require('../utils/notificationService');

// In your order controller
const placeOrder = async (req, res) => {
  try {
    // ... order processing logic ...
    
    // Get user's FCM token from database
    const [user] = await db.promise().query(
      'SELECT FCM_TOKEN FROM user_info WHERE USER_ID = ?',
      [userId]
    );
    
    if (user.length > 0 && user[0].FCM_TOKEN) {
      // Send order confirmation notification
      const notificationResult = await quickNotify(
        user[0].FCM_TOKEN,
        'Order Confirmed!',
        `Your order #${orderId} has been confirmed and is being processed.`,
        {
          order_id: orderId,
          type: 'order_confirmation',
          action: 'view_order'
        }
      );
      
      console.log('Order notification sent:', notificationResult);
    }
    
    res.json({
      success: true,
      message: 'Order placed successfully',
      data: orderData
    });
    
  } catch (error) {
    // Handle error
  }
};
```

### Example 2: Broadcast Notification to All Users
```javascript
const { broadcastNotification } = require('../utils/notificationService');

// In your admin controller
const sendPromoNotification = async (req, res) => {
  try {
    const { title, message, promo_code } = req.body;
    
    // Get all active users' FCM tokens
    const [users] = await db.promise().query(
      'SELECT FCM_TOKEN FROM user_info WHERE ISACTIVE = "Y" AND FCM_TOKEN IS NOT NULL'
    );
    
    const fcmTokens = users.map(user => user.FCM_TOKEN);
    
    if (fcmTokens.length > 0) {
      // Send broadcast notification
      const result = await broadcastNotification(
        fcmTokens,
        title,
        message,
        {
          type: 'promotion',
          promo_code: promo_code,
          action: 'open_app'
        }
      );
      
      res.json({
        success: true,
        message: 'Promotion notification sent successfully',
        data: result.data
      });
    } else {
      res.json({
        success: false,
        message: 'No active users with FCM tokens found'
      });
    }
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error sending promotion notification',
      error: error.message
    });
  }
};
```

### Example 3: Payment Status Notification
```javascript
const { sendNotification } = require('../utils/notificationService');

// In your payment controller
const updatePaymentStatus = async (req, res) => {
  try {
    const { orderId, status } = req.body;
    
    // Get user FCM token based on order
    const [orderUser] = await db.promise().query(`
      SELECT u.FCM_TOKEN, u.USERNAME, o.ORDER_ID 
      FROM user_info u 
      JOIN orders o ON u.USER_ID = o.USER_ID 
      WHERE o.ORDER_ID = ?
    `, [orderId]);
    
    if (orderUser.length > 0 && orderUser[0].FCM_TOKEN) {
      let notificationTitle, notificationBody;
      
      switch(status) {
        case 'success':
          notificationTitle = '✅ Payment Successful';
          notificationBody = `Payment for order #${orderId} completed successfully!`;
          break;
        case 'failed':
          notificationTitle = '❌ Payment Failed';
          notificationBody = `Payment for order #${orderId} failed. Please try again.`;
          break;
        case 'pending':
          notificationTitle = '⏳ Payment Pending';
          notificationBody = `Payment for order #${orderId} is being processed.`;
          break;
        default:
          notificationTitle = 'Payment Update';
          notificationBody = `Payment status updated for order #${orderId}`;
      }
      
      // Send notification (works with single token)
      const notificationResult = await sendNotification(
        orderUser[0].FCM_TOKEN,
        notificationTitle,
        notificationBody,
        {
          order_id: orderId,
          payment_status: status,
          type: 'payment_update',
          action: 'view_order'
        }
      );
      
      console.log('Payment notification sent:', notificationResult);
    }
    
    res.json({
      success: true,
      message: 'Payment status updated successfully'
    });
    
  } catch (error) {
    console.error('Payment notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating payment status',
      error: error.message
    });
  }
};
```

### Example 4: New Product Announcement
```javascript
const { sendNotification } = require('../utils/notificationService');

// In your product controller
const addNewProduct = async (req, res) => {
  try {
    // ... product creation logic ...
    
    // Get FCM tokens of users who opted for product notifications
    const [interestedUsers] = await db.promise().query(`
      SELECT FCM_TOKEN FROM user_info 
      WHERE ISACTIVE = 'Y' 
      AND FCM_TOKEN IS NOT NULL 
      AND product_notifications = 'Y'
    `);
    
    const fcmTokens = interestedUsers.map(user => user.FCM_TOKEN);
    
    if (fcmTokens.length > 0) {
      // Notify about new product
      const result = await sendNotification(
        fcmTokens, // Can handle array of tokens
        '🎉 New Product Alert!',
        `Check out our latest product: ${productName}`,
        {
          product_id: productId,
          product_name: productName,
          type: 'new_product',
          action: 'view_product'
        }
      );
      
      console.log(`New product notification sent to ${result.data.success_count} users`);
    }
    
    res.json({
      success: true,
      message: 'Product added successfully',
      data: productData
    });
    
  } catch (error) {
    // Handle error
  }
};
```

### Example 5: User-Specific Notifications
```javascript
const { quickNotify } = require('../utils/notificationService');

// In your user controller
const sendWelcomeNotification = async (userId) => {
  try {
    // Get user details
    const [user] = await db.promise().query(
      'SELECT USERNAME, FCM_TOKEN FROM user_info WHERE USER_ID = ?',
      [userId]
    );
    
    if (user.length > 0 && user[0].FCM_TOKEN) {
      // Send welcome notification
      await quickNotify(
        user[0].FCM_TOKEN,
        `Welcome ${user[0].USERNAME}!`,
        'Thank you for joining our app. Start exploring amazing products!',
        {
          type: 'welcome',
          user_id: userId,
          action: 'explore_products'
        }
      );
    }
  } catch (error) {
    console.error('Welcome notification error:', error);
  }
};

// Call this function after user registration
const registerUser = async (req, res) => {
  try {
    // ... user registration logic ...
    
    // Send welcome notification asynchronously
    sendWelcomeNotification(newUserId);
    
    res.json({
      success: true,
      message: 'User registered successfully',
      data: userData
    });
    
  } catch (error) {
    // Handle error
  }
};
```

## Response Format

All notification functions return a consistent response format:

```javascript
{
  success: true/false,
  message: "Description of the result",
  data: {
    total_tokens: 3,
    success_count: 2,
    failure_count: 1,
    failed_tokens: [
      {
        token: "invalid_token",
        error: "Registration token is not valid"
      }
    ]
  }
}
```

## Best Practices

### 1. Error Handling
```javascript
const result = await quickNotify(fcmToken, title, message, data);

if (!result.success) {
  console.error('Notification failed:', result.message);
  // Handle failure (optional - notifications are usually non-critical)
}
```

### 2. Async/Non-blocking Notifications
```javascript
// Don't wait for notification to complete
quickNotify(fcmToken, title, message, data).catch(console.error);

// Or use async function without await
const sendNotificationAsync = async (token, title, message) => {
  try {
    await quickNotify(token, title, message);
  } catch (error) {
    console.error('Background notification failed:', error);
  }
};

sendNotificationAsync(fcmToken, title, message);
```

### 3. Batch Processing for Large Lists
```javascript
// For very large lists, process in batches
const batchSize = 1000;
const fcmTokens = getAllTokens(); // Large array

for (let i = 0; i < fcmTokens.length; i += batchSize) {
  const batch = fcmTokens.slice(i, i + batchSize);
  await sendNotification(batch, title, message, data);
  
  // Optional: Add delay between batches
  await new Promise(resolve => setTimeout(resolve, 1000));
}
```

### 4. Database Integration
```javascript
// Helper function to get FCM tokens from database
const getFCMTokens = async (userIds) => {
  const [users] = await db.promise().query(
    'SELECT FCM_TOKEN FROM user_info WHERE USER_ID IN (?) AND FCM_TOKEN IS NOT NULL',
    [userIds]
  );
  return users.map(user => user.FCM_TOKEN);
};

// Usage
const userIds = [1, 2, 3, 4, 5];
const tokens = await getFCMTokens(userIds);
await sendNotification(tokens, 'Group Notification', 'Hello everyone!');
```

## Error Handling

The functions handle common errors gracefully:
- Invalid or expired FCM tokens
- Network connectivity issues
- Firebase service errors
- Empty token arrays

Failed tokens are logged and returned in the response for debugging purposes.

## Integration with Other APIs

You can easily integrate these notification functions into any existing API:

1. **Import** the function you need
2. **Get FCM tokens** from your database
3. **Call the function** with your data
4. **Handle the response** (optional)

The functions are designed to be non-blocking and won't affect your main API response time. 