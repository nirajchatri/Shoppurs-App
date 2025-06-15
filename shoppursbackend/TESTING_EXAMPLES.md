# Retailer Edit APIs - Testing Examples & Sample Data

## 🔑 **Step 1: Get Authentication Tokens**

### **Login as Employee**
```bash
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@example.com",
    "password": "password123"
  }'
```

### **Login as Admin**
```bash
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com", 
    "password": "admin123"
  }'
```

**Response Example:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "USER_ID": 1,
      "USERNAME": "employee_john",
      "EMAIL": "employee@example.com",
      "USER_TYPE": "employee"
    }
  }
}
```

---

## 🧪 **Employee API Testing Examples**

### **Test Case 1: Update Basic Info (No Photo)**

#### **cURL Command:**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "RET_NAME=Updated Retailer Name&RET_SHOP_NAME=New Shop Name&RET_MOBILE_NO=9876543210"
```

#### **Postman Body (form-data):**
```
RET_NAME: Updated Retailer Name
RET_SHOP_NAME: New Shop Name  
RET_MOBILE_NO: 9876543210
RET_EMAIL_ID: updated@example.com
RET_ADDRESS: 123 Updated Street, New Area
```

### **Test Case 2: Update with Photo Upload**

#### **cURL Command:**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_NAME=John's Updated Store" \
  -F "RET_MOBILE_NO=9123456789" \
  -F "RET_EMAIL_ID=john.updated@gmail.com" \
  -F "profileImage=@C:/path/to/retailer-photo.jpg"
```

#### **Postman Body (form-data):**
```
RET_NAME: John's Updated Store
RET_MOBILE_NO: 9123456789
RET_EMAIL_ID: john.updated@gmail.com  
RET_ADDRESS: Plot 45, Sector 12, Updated City
RET_PIN_CODE: 110020
RET_CITY: New Delhi
RET_STATE: Delhi
profileImage: [SELECT FILE - retailer-photo.jpg]
```

### **Test Case 3: Update Location & GST**

#### **cURL Command:**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_LAT=28.6139" \
  -F "RET_LONG=77.2090" \
  -F "RET_GST_NO=07AAACH7409R1ZZ" \
  -F "SHOP_OPEN_STATUS=open"
```

### **🆕 Test Case 4: Get Retailer by Phone Number (NEW)**

#### **cURL Command:**
```bash
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/9170424142123" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

#### **With Country Code:**
```bash
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/+919170424142123" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

#### **URL Encoded (with spaces):**
```bash
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/+91%209170424142123" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

#### **Expected Success Response:**
```json
{
  "success": true,
  "message": "Retailer details fetched successfully by employee",
  "data": {
    "RET_ID": 1,
    "RET_CODE": "RET001",
    "RET_TYPE": "Grocery Store",
    "RET_NAME": "Rajesh Kumar",
    "RET_SHOP_NAME": "Kumar General Store",
    "RET_MOBILE_NO": "9170424142123",
    "RET_ADDRESS": "Shop No 15, Main Market",
    "RET_PIN_CODE": "110024",
    "RET_EMAIL_ID": "rajesh@kumarstore.com",
    "RET_PHOTO": "retailer_profile_123.jpg",
    "RET_PHOTO_URL": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_123.jpg",
    "RET_COUNTRY": "India",
    "RET_STATE": "Delhi",
    "RET_CITY": "New Delhi",
    "RET_GST_NO": "07AAACH7409R1ZZ",
    "RET_LAT": "28.5355",
    "RET_LONG": "77.2503",
    "RET_DEL_STATUS": "active",
    "SHOP_OPEN_STATUS": "open",
    "BARCODE_URL": "https://example.com/barcode/RET001"
  },
  "searched_phone": "9170424142123",
  "accessed_by": "employee_john"
}
```

---

## 👨‍💼 **Admin API Testing Examples**

### **Test Case 1: Admin Update All Fields**

#### **cURL Command:**
```bash
curl -X PUT "http://localhost:3000/api/admin/edit-retailer/1" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE" \
  -F "RET_CODE=RET001" \
  -F "RET_TYPE=Grocery Store" \
  -F "RET_NAME=Rajesh Kumar" \
  -F "RET_SHOP_NAME=Kumar General Store" \
  -F "RET_MOBILE_NO=9876543210" \
  -F "RET_ADDRESS=Shop No 15, Main Market, Lajpat Nagar" \
  -F "RET_PIN_CODE=110024" \
  -F "RET_EMAIL_ID=rajesh@kumarstore.com" \
  -F "RET_COUNTRY=India" \
  -F "RET_STATE=Delhi" \
  -F "RET_CITY=New Delhi" \
  -F "RET_GST_NO=07AAACH7409R1ZZ" \
  -F "RET_LAT=28.5355" \
  -F "RET_LONG=77.2503" \
  -F "SHOP_OPEN_STATUS=open" \
  -F "BARCODE_URL=https://example.com/barcode/RET001" \
  -F "profileImage=@C:/path/to/admin-uploaded-photo.jpg"
```

#### **Postman Body (form-data):**
```
RET_CODE: RET001
RET_TYPE: Grocery Store
RET_NAME: Rajesh Kumar
RET_SHOP_NAME: Kumar General Store
RET_MOBILE_NO: 9876543210
RET_ADDRESS: Shop No 15, Main Market, Lajpat Nagar
RET_PIN_CODE: 110024
RET_EMAIL_ID: rajesh@kumarstore.com
RET_COUNTRY: India
RET_STATE: Delhi
RET_CITY: New Delhi
RET_GST_NO: 07AAACH7409R1ZZ
RET_LAT: 28.5355
RET_LONG: 77.2503
SHOP_OPEN_STATUS: open
BARCODE_URL: https://example.com/barcode/RET001
profileImage: [SELECT FILE - admin-uploaded-photo.jpg]
```

### **Test Case 2: Admin Deactivate Retailer**

#### **cURL Command:**
```bash
curl -X PUT "http://localhost:3000/api/admin/edit-retailer/1" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE" \
  -F "RET_DEL_STATUS=inactive" \
  -F "SHOP_OPEN_STATUS=closed"
```

### **🆚 Test Case 3: Admin Get Retailer by Phone (Comparison)**

#### **cURL Command:**
```bash
curl -X GET "http://localhost:3000/api/admin/get-retailer-by-phone/9170424142123" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE"
```

---

## ❌ **Error Testing Examples**

### **Test Case 1: Invalid Mobile Number**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_MOBILE_NO=123456789"  # Invalid - only 9 digits
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Invalid mobile number format"
}
```

### **Test Case 2: Invalid Email**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_EMAIL_ID=invalid-email-format"
```

### **Test Case 3: Invalid PIN Code**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_PIN_CODE=12345"  # Invalid - only 5 digits
```

### **Test Case 4: File Too Large**
```bash
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "profileImage=@large-file-over-5mb.jpg"
```

### **🆕 Test Case 5: Phone Number Not Found (NEW)**
```bash
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/9999999999" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Retailer not found with this phone number or retailer is inactive"
}
```

### **🆕 Test Case 6: Invalid Phone Format (NEW)**
```bash
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/123" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Invalid phone number format"
}
```

---

## 📋 **Complete Sample Request Bodies**

### **Employee Update - Complete Example**
```json
// Note: This is form-data format for multipart/form-data
{
  "RET_NAME": "Amit Sharma",
  "RET_SHOP_NAME": "Sharma Electronics",
  "RET_MOBILE_NO": "9123456789",
  "RET_ADDRESS": "Shop 22, Electronics Market, Nehru Place",
  "RET_PIN_CODE": "110019",
  "RET_EMAIL_ID": "amit@sharmaelectronics.com",
  "RET_CITY": "New Delhi",
  "RET_STATE": "Delhi",
  "RET_COUNTRY": "India",
  "RET_LAT": "28.5494",
  "RET_LONG": "77.2500",
  "SHOP_OPEN_STATUS": "open",
  "BARCODE_URL": "https://qr-generator.com/electronics001"
}
```

### **Admin Update - Complete Example**
```json
// Note: This is form-data format for multipart/form-data
{
  "RET_CODE": "ELEC001",
  "RET_TYPE": "Electronics",
  "RET_NAME": "Amit Sharma",
  "RET_SHOP_NAME": "Sharma Electronics",
  "RET_MOBILE_NO": "9123456789",
  "RET_ADDRESS": "Shop 22, Electronics Market, Nehru Place",
  "RET_PIN_CODE": "110019",
  "RET_EMAIL_ID": "amit@sharmaelectronics.com",
  "RET_COUNTRY": "India",
  "RET_STATE": "Delhi",
  "RET_CITY": "New Delhi",
  "RET_GST_NO": "07AAECS1234N1ZY",
  "RET_LAT": "28.5494",
  "RET_LONG": "77.2500",
  "RET_DEL_STATUS": "active",
  "SHOP_OPEN_STATUS": "open",
  "BARCODE_URL": "https://qr-generator.com/electronics001"
}
```

---

## 🔄 **Expected Success Responses**

### **Employee Update Success:**
```json
{
  "success": true,
  "message": "Retailer updated successfully by employee",
  "data": {
    "RET_ID": 1,
    "RET_CODE": "RET001",
    "RET_TYPE": "Electronics",
    "RET_NAME": "Amit Sharma",
    "RET_SHOP_NAME": "Sharma Electronics",
    "RET_MOBILE_NO": "9123456789",
    "RET_ADDRESS": "Shop 22, Electronics Market, Nehru Place",
    "RET_PIN_CODE": "110019",
    "RET_EMAIL_ID": "amit@sharmaelectronics.com",
    "RET_PHOTO": "retailer_profile_1671234567890-987654321.jpg",
    "RET_PHOTO_URL": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1671234567890-987654321.jpg",
    "RET_COUNTRY": "India",
    "RET_STATE": "Delhi",
    "RET_CITY": "New Delhi",
    "RET_GST_NO": null,
    "RET_LAT": "28.5494",
    "RET_LONG": "77.2500",
    "RET_DEL_STATUS": "active",
    "CREATED_DATE": "2023-12-01T10:30:00.000Z",
    "UPDATED_DATE": "2023-12-13T13:45:30.000Z",
    "CREATED_BY": "admin",
    "UPDATED_BY": "employee_john",
    "SHOP_OPEN_STATUS": "open",
    "BARCODE_URL": "https://qr-generator.com/electronics001"
  },
  "uploadedFile": {
    "filename": "retailer_profile_1671234567890-987654321.jpg",
    "url": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1671234567890-987654321.jpg"
  },
  "updated_by": "employee_john",
  "updated_fields": 8
}
```

---

## 🛠️ **Postman Collection Setup**

### **1. Create New Collection: "Retailer Edit APIs"**

### **2. Add Environment Variables:**
```
base_url: http://localhost:3000
employee_token: [GET FROM LOGIN]
admin_token: [GET FROM LOGIN]
retailer_id: 1
test_phone: 9170424142123
```

### **3. Pre-request Script for Authentication:**
```javascript
// Add to Headers tab
pm.request.headers.add({
    key: 'Authorization',
    value: 'Bearer ' + pm.environment.get('employee_token')
});
```

---

## 📝 **Testing Checklist**

### **Basic Functionality:**
- [ ] Employee can update retailer basic info
- [ ] Admin can update retailer basic info  
- [ ] Both can upload profile photos
- [ ] Partial updates work (only send changed fields)
- [ ] Database audit trail is working
- [ ] **🆕 Employee can get retailer by phone number**

### **Validation Testing:**
- [ ] Mobile number validation (10 digits, starts with 6-9)
- [ ] Email format validation
- [ ] PIN code validation (6 digits)
- [ ] GST number format validation
- [ ] File upload size limit (5MB)
- [ ] File type validation (images only)
- [ ] **🆕 Phone number format validation for search**

### **Authorization Testing:**
- [ ] Employee cannot access admin endpoint
- [ ] Admin cannot access employee endpoint
- [ ] Invalid tokens are rejected
- [ ] No token results in 401 error
- [ ] **🆕 Employee phone search works with employee token**
- [ ] **🆕 Admin cannot access employee phone search endpoint**

### **Error Handling:**
- [ ] Retailer not found returns 404
- [ ] Invalid retailer ID handled
- [ ] Database connection errors handled
- [ ] File upload errors handled
- [ ] **🆕 Invalid phone number handled**
- [ ] **🆕 Non-existing phone number returns 404**

---

## 💡 **Quick Testing Commands**

Replace `YOUR_TOKEN_HERE` with actual tokens from login:

```bash
# Employee: Update name and mobile
curl -X PUT "http://localhost:3000/api/employee/retailers/1/edit" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -F "RET_NAME=Test Employee Update" \
  -F "RET_MOBILE_NO=9999888877"

# Employee: Get retailer by phone (NEW)
curl -X GET "http://localhost:3000/api/employee/get-retailer-by-phone/9170424142123" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"

# Admin: Update and deactivate retailer  
curl -X PUT "http://localhost:3000/api/admin/edit-retailer/1" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE" \
  -F "RET_NAME=Test Admin Update" \
  -F "RET_DEL_STATUS=inactive"

# Admin: Get retailer by phone (Comparison)
curl -X GET "http://localhost:3000/api/admin/get-retailer-by-phone/9170424142123" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE"
```

Use these examples to thoroughly test all APIs! 🚀 