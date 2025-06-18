# User Profile Management API Documentation

## 📊 **User Profile APIs for All User Types**

### **Endpoints**
1. `PUT /api/users/update-profile` - Update own name and profile photo
2. `GET /api/users/profile` - Get current user profile

**Access:** Any authenticated user (Customer, Employee, Admin)  
**Purpose:** Allow users to manage their own profile information and photo

---

## 🗄️ **Database Table: `user_info`**

```sql
Fields Used:
- USER_ID (Primary Key, Auto-increment)
- USERNAME (User's display name) ✅ EDITABLE
- EMAIL (User's email address)
- MOBILE (User's mobile number)
- PHOTO (Profile photo file path) ✅ EDITABLE
- USER_TYPE (customer/employee/admin)
- UPDATED_DATE (Last update timestamp) ✅ AUTO-UPDATED
- UPDATED_BY (Who last updated) ✅ AUTO-UPDATED
- ISACTIVE (Y/N - Account status)
```

---

## 🔧 **API 1: Update Profile**

### **Endpoint**
```
PUT /api/users/update-profile
```

### **Authentication**
- **Required**: Bearer Token (Any authenticated user)
- **Data Source**: Uses `USER_ID` from JWT token

### **Request Format**
- **Content-Type**: `multipart/form-data`
- **Fields**:
  - `username` (optional): New username/display name
  - `profilePhoto` (optional): Profile photo file

### **File Upload Specifications**
- **Directory**: `uploads/users/profiles/`
- **Filename Format**: `user_profile_timestamp_randomnumber.extension`
- **Accepted Types**: Image files only (JPEG, PNG, GIF, etc.)
- **Size Limit**: 5MB maximum
- **Field Name**: `profilePhoto`

### **Validation Rules**
- **Username**: 2-100 characters, trimmed
- **Photo**: Must be image file, max 5MB
- **Requirement**: At least one field (username or photo) must be provided
- **User Status**: User must be active (ISACTIVE = 'Y')

---

## 📋 **Request Examples**

### **Update Username Only**
```bash
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "username=John Doe Updated"
```

### **Update Profile Photo Only**
```bash
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "profilePhoto=@/path/to/photo.jpg"
```

### **Update Both Username and Photo**
```bash
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "username=John Doe Updated" \
  -F "profilePhoto=@/path/to/photo.jpg"
```

---

## 📊 **Success Response Format**

### **Profile Update Success**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user": {
      "USER_ID": 123,
      "USERNAME": "John Doe Updated",
      "EMAIL": "john@example.com",
      "MOBILE": "1234567890",
      "PHOTO": "uploads/users/profiles/user_profile_1703001234567_123456789.jpg",
      "USER_TYPE": "customer",
      "UPDATED_DATE": "2023-12-13T10:30:00.000Z"
    },
    "changes_made": {
      "username_updated": true,
      "photo_updated": true,
      "photo_url": "http://localhost:3000/uploads/users/profiles/user_profile_1703001234567_123456789.jpg"
    },
    "updated_by": "john_doe"
  }
}
```

---

## ❌ **Error Responses**

### **No Data Provided**
```json
{
  "success": false,
  "message": "Please provide either username or profile photo to update"
}
```

### **Invalid Username**
```json
{
  "success": false,
  "message": "Username must be at least 2 characters long"
}
```

### **File Too Large**
```json
{
  "success": false,
  "message": "File size too large. Maximum size is 5MB."
}
```

### **Invalid File Type**
```json
{
  "success": false,
  "message": "Only image files are allowed!"
}
```

---

## 🔧 **API 2: Get Profile**

### **Endpoint**
```
GET /api/users/profile
```

### **Authentication**
- **Required**: Bearer Token (Any authenticated user)

### **Request Example**
```bash
curl -X GET "http://localhost:3000/api/users/profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE"
```

### **Success Response**
```json
{
  "success": true,
  "message": "User profile fetched successfully",
  "data": {
    "profile": {
      "USER_ID": 123,
      "USERNAME": "John Doe",
      "EMAIL": "john@example.com",
      "MOBILE": "1234567890",
      "CITY": "Mumbai",
      "PHOTO": "uploads/users/profiles/user_profile_1703001234567_123456789.jpg",
      "USER_TYPE": "customer",
      "CREATED_DATE": "2023-12-01T09:00:00.000Z",
      "UPDATED_DATE": "2023-12-13T10:30:00.000Z",
      "photo_url": "http://localhost:3000/uploads/users/profiles/user_profile_1703001234567_123456789.jpg"
    }
  }
}
```

---

## 🔐 **Security Features**

### **Authentication & Authorization**
1. **JWT Token Required**: All endpoints require valid Bearer token
2. **Self-Access Only**: Users can only update their own profile
3. **Active User Check**: Only active users can update profile
4. **Role Agnostic**: Works for customer, employee, and admin users

### **File Upload Security**
1. **File Type Validation**: Only image files accepted
2. **Size Limitation**: 5MB maximum file size
3. **Secure Filename**: Auto-generated filenames prevent conflicts
4. **Old File Cleanup**: Previous profile photos automatically deleted

---

## 📁 **File Management**

### **Upload Directory Structure**
```
uploads/
└── users/
    └── profiles/
        ├── user_profile_1703001234567_123456789.jpg
        ├── user_profile_1703001234568_987654321.png
        └── user_profile_1703001234569_456789123.gif
```

### **File Naming Convention**
```
Format: user_profile_[timestamp]_[random_number].[extension]
Example: user_profile_1703001234567_123456789.jpg
```

### **Automatic File Management**
1. **Old Photo Deletion**: When user uploads new photo, old photo is automatically deleted
2. **Failed Upload Cleanup**: If database update fails, uploaded file is removed
3. **Path Storage**: Relative path stored in database for portability
4. **URL Generation**: Full URLs generated dynamically in response

---

## 🎯 **Testing Scenarios**

### **Scenario 1: Username Update Only**
```bash
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer USER_TOKEN" \
  -F "username=New Display Name"
```

### **Scenario 2: Photo Update Only**
```bash
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer USER_TOKEN" \
  -F "profilePhoto=@photo.jpg"
```

### **Scenario 3: Get Profile**
```bash
curl -X GET "http://localhost:3000/api/users/profile" \
  -H "Authorization: Bearer USER_TOKEN"
```

---

## ✅ **Status: PRODUCTION READY**

### **Implementation Complete:**
- ✅ **Upload Middleware**: User profile photo upload functionality
- ✅ **File Management**: Automatic directory creation and file handling
- ✅ **User Controller**: Profile update and retrieval endpoints
- ✅ **Route Configuration**: Secure authenticated routes
- ✅ **Error Handling**: Comprehensive error scenarios covered
- ✅ **Security Features**: Authentication, validation, and file security

### **File Structure Created:**
```
src/
├── controllers/user.controller.js ✅ NEW
├── routes/user.routes.js ✅ NEW
├── middleware/upload.middleware.js ✅ UPDATED
└── app.js ✅ UPDATED

uploads/
└── users/
    └── profiles/ ✅ NEW DIRECTORY
```

---

## 🎯 **Quick Test Commands**

```bash
# Get current profile
curl -X GET "http://localhost:3000/api/users/profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE"

# Update username only
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "username=New Name"

# Update photo only
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "profilePhoto=@/path/to/image.jpg"

# Update both
curl -X PUT "http://localhost:3000/api/users/update-profile" \
  -H "Authorization: Bearer YOUR_USER_TOKEN_HERE" \
  -F "username=John Updated" \
  -F "profilePhoto=@/path/to/image.jpg"
```

The User Profile Management APIs are ready for immediate production use! 🚀 