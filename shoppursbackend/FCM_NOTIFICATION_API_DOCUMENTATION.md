# FCM Notification API Documentation

## Overview
This document outlines the Firebase Cloud Messaging (FCM) integration APIs for storing FCM tokens and sending push notifications to users.

## Features
- Store/Update FCM tokens for users
- Send notifications to multiple FCM tokens
- Get all FCM tokens for bulk notifications
- Firebase Admin SDK integration

## Setup Instructions

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable Cloud Messaging in the project settings
4. Go to Project Settings > Service Accounts
5. Generate a new private key and download the JSON file

### 2. Server Configuration

#### Option A: Using Service Account Key File
1. Rename the downloaded JSON file to `firebase-service-account-key.json`
2. Place it in the root directory of your project
3. The file structure should match `firebase-service-account-key.example.json`

#### Option B: Using Environment Variables
Add the following to your `.env` file:
```env
FIREBASE_PROJECT_ID="your-firebase-project-id"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour private key here\n-----END PRIVATE KEY-----\n"
```

### 3. Dependencies
The following packages are already included:
- `firebase-admin`: For Firebase Admin SDK

## API Endpoints

### 1. Update FCM Token
**Endpoint:** `PUT /api/user/update-fcm-token`

**Description:** Store or update the FCM token for the authenticated user.

**Authentication:** Required (JWT Token)

**Request Body:**
```json
{
  "fcm_token": "your-fcm-token-here"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token updated successfully",
  "data": {
    "user_id": 123,
    "updated_by": "user@example.com"
  }
}
```

**Error Responses:**
- `400`: Invalid or missing FCM token
- `404`: User not found or inactive
- `500`: Server error

### 2. Send Notification
**Endpoint:** `POST /api/user/send-notification`

**Description:** Send push notifications to multiple FCM tokens.

**Authentication:** Required (JWT Token)

**Request Body:**
```json
{
  "fcm_tokens": [
    "token1",
    "token2",
    "token3"
  ],
  "title": "Notification Title",
  "body": "Notification body message",
  "data": {
    "custom_key": "custom_value",
    "action": "open_app"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification sent successfully",
  "data": {
    "total_tokens": 3,
    "success_count": 2,
    "failure_count": 1,
    "failed_tokens": [
      {
        "token": "failed_token",
        "error": "Registration token is not a valid FCM registration token"
      }
    ],
    "sent_by": "user@example.com"
  }
}
```

**Error Responses:**
- `400`: Invalid input parameters
- `500`: Firebase connection error or server error

### 3. Get All FCM Tokens
**Endpoint:** `GET /api/user/fcm-tokens`

**Description:** Retrieve all FCM tokens from active users (useful for bulk notifications).

**Authentication:** Required (JWT Token)

**Response:**
```json
{
  "success": true,
  "message": "FCM tokens retrieved successfully",
  "data": {
    "total_users": 10,
    "fcm_tokens": [
      "token1",
      "token2",
      "token3"
    ],
    "users": [
      {
        "user_id": 1,
        "username": "john_doe",
        "email": "john@example.com",
        "has_fcm_token": true
      }
    ]
  }
}
```

## Usage Examples

### Frontend Integration (React/JavaScript)

#### 1. Update FCM Token
```javascript
// After getting FCM token from Firebase SDK
const updateFcmToken = async (fcmToken) => {
  try {
    const response = await fetch('/api/user/update-fcm-token', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`
      },
      body: JSON.stringify({
        fcm_token: fcmToken
      })
    });
    
    const result = await response.json();
    console.log('FCM token updated:', result);
  } catch (error) {
    console.error('Error updating FCM token:', error);
  }
};
```

#### 2. Send Notification
```javascript
const sendNotification = async (tokens, title, body, data = {}) => {
  try {
    const response = await fetch('/api/user/send-notification', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`
      },
      body: JSON.stringify({
        fcm_tokens: tokens,
        title: title,
        body: body,
        data: data
      })
    });
    
    const result = await response.json();
    console.log('Notification sent:', result);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
};
```

### Postman Examples

#### 1. Update FCM Token
```
PUT {{base_url}}/api/user/update-fcm-token
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "fcm_token": "dXJhbGVuX3Rva2VuX2hlcmU"
}
```

#### 2. Send Notification
```
POST {{base_url}}/api/user/send-notification
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "fcm_tokens": [
    "token1",
    "token2"
  ],
  "title": "Test Notification",
  "body": "This is a test notification",
  "data": {
    "type": "test",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Database Schema

The `user_info` table should have the following structure:
```sql
CREATE TABLE user_info (
  USER_ID INT PRIMARY KEY,
  UL_ID INT,
  USERNAME VARCHAR(255),
  EMAIL VARCHAR(255),
  MOBILE VARCHAR(20),
  PASSWORD VARCHAR(255),
  CITY VARCHAR(100),
  PROVINCE VARCHAR(100),
  ZIP VARCHAR(20),
  ADDRESS TEXT,
  PHOTO VARCHAR(500),
  FCM_TOKEN TEXT,  -- This field stores the FCM token
  CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CREATED_BY VARCHAR(100),
  UPDATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UPDATED_BY VARCHAR(100),
  USER_TYPE VARCHAR(50),
  ISACTIVE CHAR(1) DEFAULT 'Y',
  is_otp_verify CHAR(1) DEFAULT 'N'
);
```

## Error Handling

### Common Error Codes
- `400`: Bad Request - Invalid input parameters
- `401`: Unauthorized - Invalid or missing JWT token
- `404`: Not Found - User not found or inactive
- `500`: Internal Server Error - Firebase connection error or database error

### Firebase Connection Errors
The API will test Firebase connection before sending notifications and return appropriate error messages if the connection fails.

## Security Considerations
1. All endpoints require JWT authentication
2. FCM tokens are stored securely in the database
3. Failed tokens are logged for debugging but not exposed in production
4. Input validation is performed on all parameters

## Testing
1. Use the test endpoint to verify Firebase connection
2. Test with valid and invalid FCM tokens
3. Test bulk notification sending
4. Monitor success/failure rates

## Troubleshooting

### Firebase Not Initialized
- Ensure service account key file is properly configured
- Check environment variables are set correctly
- Verify Firebase project settings

### Invalid FCM Tokens
- FCM tokens expire periodically
- Test with fresh tokens from the client app
- Monitor failed token responses for debugging

### Network Issues
- Ensure server can reach Firebase servers
- Check firewall settings
- Verify internet connectivity

## Support
For issues or questions, please refer to:
- [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup) 