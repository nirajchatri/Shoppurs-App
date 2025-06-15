# Retailer Edit APIs Documentation

## Overview
This document describes the 2 new APIs for editing retailer details, available for **Employee** and **Admin** roles.

## Features
- ✅ **Partial Field Updates**: Only send the fields you want to update
- ✅ **Photo Upload Support**: Handle `RET_PHOTO` uploads with validation
- ✅ **Market Standard Validation**: Email, mobile, PIN code, GST number validation
- ✅ **Role-based Access Control**: Separate endpoints for Employee and Admin
- ✅ **Comprehensive Error Handling**: Detailed error messages and status codes
- ✅ **Audit Trail**: Tracks who updated what and when

---

## 1. Employee Edit Retailer API

### **Endpoint**
```
PUT /api/employee/retailers/:retailerId/edit
```

### **Authentication**
- **Required**: Bearer Token
- **Role**: Employee only
- **Middleware**: `employeeMiddleware`, `retailerProfileUpload`

### **Request Format**

#### **Headers**
```
Authorization: Bearer <employee_token>
Content-Type: multipart/form-data
```

#### **URL Parameters**
- `retailerId` (required): The ID of the retailer to edit

#### **Form Data Fields** (all optional)
```json
{
  "RET_CODE": "string",
  "RET_TYPE": "string", 
  "RET_NAME": "string",
  "RET_SHOP_NAME": "string",
  "RET_MOBILE_NO": "string (10 digits, starting with 6-9)",
  "RET_ADDRESS": "string",
  "RET_PIN_CODE": "string (6 digits)",
  "RET_EMAIL_ID": "string (valid email format)",
  "RET_COUNTRY": "string",
  "RET_STATE": "string", 
  "RET_CITY": "string",
  "RET_GST_NO": "string (valid GST format)",
  "RET_LAT": "decimal",
  "RET_LONG": "decimal",
  "SHOP_OPEN_STATUS": "string",
  "BARCODE_URL": "string",
  "profileImage": "file (image, max 5MB)"
}
```

### **Validation Rules**
- **Mobile Number**: Must be 10 digits starting with 6-9
- **PIN Code**: Must be exactly 6 digits  
- **Email**: Must be valid email format (optional)
- **GST Number**: Must follow GST format pattern (optional)
- **Profile Image**: JPG/PNG/GIF, max 5MB

### **Success Response**
```json
{
  "success": true,
  "message": "Retailer updated successfully by employee",
  "data": {
    "RET_ID": 1,
    "RET_CODE": "RET001",
    "RET_TYPE": "Grocery",
    "RET_NAME": "John Doe",
    "RET_SHOP_NAME": "Doe's Store",
    "RET_MOBILE_NO": "9876543210",
    "RET_ADDRESS": "123 Main Street",
    "RET_PIN_CODE": "110001", 
    "RET_EMAIL_ID": "john@example.com",
    "RET_PHOTO": "retailer_profile_1670000000000-123456789.jpg",
    "RET_PHOTO_URL": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1670000000000-123456789.jpg",
    "RET_COUNTRY": "India",
    "RET_STATE": "Delhi", 
    "RET_CITY": "New Delhi",
    "RET_GST_NO": "07AAACH7409R1ZZ",
    "RET_LAT": "28.6139",
    "RET_LONG": "77.2090",
    "RET_DEL_STATUS": "active",
    "CREATED_DATE": "2023-12-01T10:30:00.000Z",
    "UPDATED_DATE": "2023-12-13T13:10:20.000Z",
    "CREATED_BY": "admin",
    "UPDATED_BY": "employee_john",
    "SHOP_OPEN_STATUS": "open",
    "BARCODE_URL": "https://example.com/barcode"
  },
  "uploadedFile": {
    "filename": "retailer_profile_1670000000000-123456789.jpg",
    "url": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1670000000000-123456789.jpg"
  },
  "updated_by": "employee_john",
  "updated_fields": 3
}
```

---

## 2. Admin Edit Retailer API

### **Endpoint**
```
PUT /api/admin/edit-retailer/:retailerId
```

### **Authentication**
- **Required**: Bearer Token
- **Role**: Admin only  
- **Middleware**: `adminMiddleware`, `retailerProfileUpload`

### **Request Format**

#### **Headers**
```
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data
```

#### **URL Parameters**
- `retailerId` (required): The ID of the retailer to edit

#### **Form Data Fields** (all optional)
```json
{
  "RET_CODE": "string",
  "RET_TYPE": "string",
  "RET_NAME": "string", 
  "RET_SHOP_NAME": "string",
  "RET_MOBILE_NO": "string (10 digits, starting with 6-9)",
  "RET_ADDRESS": "string",
  "RET_PIN_CODE": "string (6 digits)",
  "RET_EMAIL_ID": "string (valid email format)",
  "RET_COUNTRY": "string",
  "RET_STATE": "string",
  "RET_CITY": "string", 
  "RET_GST_NO": "string (valid GST format)",
  "RET_LAT": "decimal",
  "RET_LONG": "decimal",
  "RET_DEL_STATUS": "string (admin can change status)",
  "SHOP_OPEN_STATUS": "string",
  "BARCODE_URL": "string",
  "profileImage": "file (image, max 5MB)"
}
```

### **Admin-Specific Features**
- **Can modify `RET_DEL_STATUS`**: Admin can activate/deactivate retailers
- **Full access**: Admin can edit any retailer regardless of ownership

### **Success Response**
```json
{
  "success": true,
  "message": "Retailer updated successfully by admin",
  "data": {
    // ... same structure as employee response
    "UPDATED_BY": "admin_user"
  },
  "uploadedFile": {
    "filename": "retailer_profile_1670000000000-123456789.jpg", 
    "url": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1670000000000-123456789.jpg"
  },
  "updated_by": "admin_user",
  "updated_fields": 5
}
```

---

## Error Responses

### **Authentication Errors**
```json
{
  "success": false,
  "message": "Authentication required"
}
```

### **Authorization Errors**
```json
{
  "success": false, 
  "message": "Access denied. Employee privileges required."
}
```

### **Validation Errors**
```json
{
  "success": false,
  "message": "Invalid mobile number format"
}
```

```json
{
  "success": false,
  "message": "Invalid email format"
}
```

### **File Upload Errors**
```json
{
  "success": false,
  "message": "File size too large. Maximum size is 5MB."
}
```

### **Not Found Errors**
```json
{
  "success": false,
  "message": "Retailer not found or inactive"
}
```

---

## Example Usage

### **Employee Update Example**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/123/edit" \
  -H "Authorization: Bearer <employee_token>" \
  -F "RET_NAME=Updated Name" \
  -F "RET_MOBILE_NO=9876543210" \
  -F "profileImage=@/path/to/new-photo.jpg"
```

### **Admin Update Example**  
```bash
curl -X PUT "http://localhost:3000/api/admin/edit-retailer/123" \
  -H "Authorization: Bearer <admin_token>" \
  -F "RET_SHOP_NAME=Updated Shop Name" \
  -F "RET_DEL_STATUS=inactive" \
  -F "profileImage=@/path/to/new-photo.jpg"
```

---

## Security Features

1. **Role-based Access Control**: Separate endpoints for Employee and Admin
2. **Input Validation**: All inputs are validated for format and security
3. **File Upload Security**: Only images allowed, size limits enforced
4. **SQL Injection Protection**: Parameterized queries used
5. **Audit Trail**: All changes tracked with timestamp and user info

---

## Database Changes

### **Fields Updated**
All fields from the `retailer_info` table can be updated:
- `RET_ID` (read-only)
- `RET_CODE`
- `RET_TYPE` 
- `RET_NAME`
- `RET_SHOP_NAME`
- `RET_MOBILE_NO`
- `RET_ADDRESS`
- `RET_PIN_CODE`
- `RET_EMAIL_ID`
- `RET_PHOTO` (via file upload)
- `RET_COUNTRY`
- `RET_STATE`
- `RET_CITY`
- `RET_GST_NO`
- `RET_LAT`
- `RET_LONG`
- `RET_DEL_STATUS` (admin only)
- `SHOP_OPEN_STATUS`
- `BARCODE_URL`
- `UPDATED_DATE` (auto-updated)
- `UPDATED_BY` (auto-updated)

---

## Testing the APIs

### **Prerequisites**
1. Server running on `http://localhost:3000`
2. Valid Employee or Admin JWT token
3. Existing retailer record in database

### **Testing Steps**
1. **Get Authentication Token**:
   - Login as Employee: `POST /api/auth/login`
   - Login as Admin: `POST /api/auth/login`

2. **Test Partial Update**:
   - Send only the fields you want to update
   - Verify response contains updated data

3. **Test Photo Upload**:
   - Include `profileImage` in form data
   - Verify file is uploaded and URL is returned

4. **Test Validation**:
   - Send invalid mobile number/email
   - Verify appropriate error messages

---

## Performance Considerations

- **Partial Updates**: Only modified fields are updated in database
- **File Upload**: Images stored locally with unique filenames  
- **Response Optimization**: Returns complete retailer data after update
- **Error Handling**: Fast-fail validation for better performance

---

## Status: ✅ **PRODUCTION READY**

Both APIs are fully tested and ready for production use with comprehensive error handling, validation, and security features. 