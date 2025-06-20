# Customer Creation APIs Documentation

This document outlines the new customer creation APIs that allow administrators and employees to create customers from their respective dashboards. When creating a customer, the system automatically creates a retailer profile as well, similar to the existing customer signup and OTP verification process.

## Features

- **Automatic Retailer Creation**: Every customer automatically gets a retailer profile
- **QR Code Generation**: Each retailer gets a unique QR code for identification
- **Address Management**: Support for single and multiple address creation
- **Role-based Access**: Both admin and employees can create customers
- **Password Management**: Auto-generated passwords with secure hashing
- **Comprehensive Validation**: Mobile number, email, and data validation
- **Store Management**: Mandatory store name for retailer profile creation

## Admin APIs

### Base URL: `/admin`

### 1. Create Customer (Single Address)

**Endpoint:** `POST /admin/create-customer`

**Description:** Creates a new customer with a single address and automatically creates a retailer profile.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "username": "John Doe",
  "email": "john@example.com", // Optional, auto-generated if not provided
  "mobile": "9876543210",
  "password": "123456", // Optional, defaults to "123456"
  "storeName": "John's General Store", // Mandatory
  "city": "Mumbai",
  "province": "Maharashtra", 
  "zip": "400001",
  "address": "123 Main Street",
  
  // Address Details (Optional - if different from basic info)
  "addressDetails": "456 Detailed Address",
  "addressCity": "Mumbai",
  "addressState": "Maharashtra",
  "addressCountry": "India",
  "addressPincode": "400001",
  "landmark": "Near City Mall",
  "addressType": "Home", // Home, Work, Other
  "isDefaultAddress": true,
  
  // Retailer Location (Optional)
  "lat": "19.0760", // Optional
  "long": "72.8777" // Optional
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Customer and retailer profile created successfully by admin",
  "data": {
    "customer": {
      "USER_ID": 123,
      "USERNAME": "John Doe",
      "EMAIL": "john@example.com",
      "MOBILE": 9876543210,
      "RET_ID": 45,
      "RET_CODE": "RET045",
      "RET_TYPE": "Grocery",
      "RET_NAME": "John Doe",
      "RET_SHOP_NAME": "John's General Store",
      "RET_MOBILE_NO": 9876543210,
      "RET_ADDRESS": "123 Main Street",
      "RET_PIN_CODE": "400001",
      "RET_EMAIL_ID": "john@example.com",
      "RET_COUNTRY": "India",
      "RET_STATE": "Maharashtra",
      "RET_CITY": "Mumbai",
      "RET_LAT": "19.0760",
      "RET_LONG": "72.8777",
      "BARCODE_URL": "qr_9876543210_1703123456789.png"
    },
    "addresses": [
      {
        "ADDRESS_ID": 1,
        "USER_ID": 123,
        "ADDRESS": "456 Detailed Address",
        "CITY": "Mumbai",
        "STATE": "Maharashtra",
        "COUNTRY": "India",
        "PINCODE": "400001",
        "IS_DEFAULT": 1
      }
    ],
    "createdBy": "admin_username",
    "defaultPassword": "123456"
  }
}
```

### 2. Create Customer with Multiple Addresses

**Endpoint:** `POST /admin/create-customer-with-addresses`

**Description:** Creates a new customer with multiple addresses and automatically creates a retailer profile.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "username": "Jane Smith",
  "email": "jane@example.com",
  "mobile": "9876543211",
  "password": "123456",
  "storeName": "Jane's Corner Shop", // Mandatory
  "city": "Mumbai",
  "province": "Maharashtra",
  "zip": "400002",
  "address": "789 Primary Street",
  
  "addresses": [
    {
      "address": "789 Home Address",
      "city": "Mumbai",
      "state": "Maharashtra", 
      "country": "India",
      "pincode": "400002",
      "landmark": "Near Station",
      "addressType": "Home",
      "isDefault": true
    },
    {
      "address": "321 Office Address",
      "city": "Mumbai",
      "state": "Maharashtra",
      "country": "India", 
      "pincode": "400003",
      "landmark": "Business District",
      "addressType": "Work",
      "isDefault": false
    }
  ],
  
  "lat": "19.0760", // Optional
  "long": "72.8777" // Optional
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Customer with multiple addresses and retailer profile created successfully by admin",
  "data": {
    "customer": {
      "USER_ID": 124,
      "USERNAME": "Jane Smith",
      "EMAIL": "jane@example.com",
      "MOBILE": 9876543211,
      "RET_ID": 46,
      "RET_CODE": "RET046",
      "RET_TYPE": "Grocery",
      "RET_NAME": "Jane Smith",
      "RET_SHOP_NAME": "Jane's Corner Shop",
      "RET_MOBILE_NO": 9876543211,
      "RET_ADDRESS": "789 Primary Street",
      "RET_PIN_CODE": "400002",
      "RET_EMAIL_ID": "jane@example.com",
      "RET_COUNTRY": "India",
      "RET_STATE": "Maharashtra",
      "RET_CITY": "Mumbai",
      "RET_LAT": "19.0760",
      "RET_LONG": "72.8777",
      "BARCODE_URL": "qr_9876543211_1703123456789.png"
    },
    "addresses": [
      {
        "ADDRESS_ID": 2,
        "ADDRESS": "789 Home Address",
        "IS_DEFAULT": 1,
        "ADDRESS_TYPE": "Home"
      },
      {
        "ADDRESS_ID": 3,
        "ADDRESS": "321 Office Address", 
        "IS_DEFAULT": 0,
        "ADDRESS_TYPE": "Work"
      }
    ],
    "createdBy": "admin_username",
    "defaultPassword": "123456"
  }
}
```

### 3. Get Customer Details

**Endpoint:** `GET /admin/get-customer-details/:customerId`

**Description:** Retrieves comprehensive customer details including addresses and order summary.

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer details fetched successfully",
  "data": {
    "customer": {
      "USER_ID": 123,
      "USERNAME": "John Doe",
      "EMAIL": "john@example.com",
      "MOBILE": 9876543210,
      "RET_ID": 45,
      "RET_CODE": "RET045",
      "RET_TYPE": "Grocery",
      "RET_NAME": "John Doe",
      "RET_SHOP_NAME": "John's General Store",
      "RET_MOBILE_NO": 9876543210,
      "RET_ADDRESS": "123 Main Street",
      "RET_PIN_CODE": "400001",
      "RET_EMAIL_ID": "john@example.com",
      "RET_COUNTRY": "India",
      "RET_STATE": "Maharashtra",
      "RET_CITY": "Mumbai",
      "RET_LAT": "19.0760",
      "RET_LONG": "72.8777",
      "BARCODE_URL": "qr_9876543210_1703123456789.png"
    },
    "addresses": [...],
    "orderSummary": {
      "total_orders": 5,
      "completed_orders": 3,
      "pending_orders": 2,
      "cancelled_orders": 0,
      "total_order_value": 2500.00
    }
  }
}
```

### 4. Search Customers

**Endpoint:** `GET /admin/search-customers?query=<search_term>&page=1&limit=10`

**Description:** Search customers by name, email, mobile, city, or address.

**Query Parameters:**
- `query` (required): Search term
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customers search completed",
  "data": {
    "customers": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCustomers": 50,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "searchQuery": "john"
  }
}
```

## Employee APIs

### Base URL: `/employee`

The employee APIs provide the same functionality as admin APIs but with employee role tracking.

### 1. Create Customer (Single Address)

**Endpoint:** `POST /employee/create-customer`

Same request/response structure as admin, but with `"createdByRole": "employee"` in the response.

### 2. Create Customer with Multiple Addresses

**Endpoint:** `POST /employee/create-customer-with-addresses`

Same request/response structure as admin, but with `"createdByRole": "employee"` in the response.

### 3. Get Customer Details

**Endpoint:** `GET /employee/get-customer-details/:customerId`

Same functionality as admin with additional fields:
```json
{
  "success": true,
  "message": "Customer details fetched successfully by employee",
  "data": { ... },
  "accessedBy": "employee_username",
  "accessedByRole": "employee"
}
```

### 4. Search Customers

**Endpoint:** `GET /employee/search-customers?query=<search_term>&page=1&limit=10`

Same functionality as admin with additional fields:
```json
{
  "success": true,
  "message": "Customers search completed by employee",
  "data": { ... },
  "searchedBy": "employee_username",
  "searchedByRole": "employee"
}
```

## Automatic Features

### 1. Retailer Profile Creation

When a customer is created, the system automatically:
- Generates a unique retailer code (RET001, RET002, etc.)
- Creates a retailer profile in `retailer_info` table with complete information:
  - `RET_NAME`: Customer's username
  - `RET_SHOP_NAME`: Mandatory store name provided during creation
  - `RET_TYPE`: Set as "Grocery"
  - `RET_MOBILE_NO`: Customer's mobile number
  - `RET_ADDRESS`: Customer's primary address
  - `RET_EMAIL_ID`: Customer's email
  - `RET_COUNTRY`, `RET_STATE`, `RET_CITY`: Location details
  - `RET_LAT`, `RET_LONG`: Optional coordinates if provided
  - `BARCODE_URL`: Generated QR code filename
- Generates a QR code for the retailer's mobile number
- Stores QR code in `/uploads/retailers/qrcode/` directory

### 2. Address Management

- Supports both single and multiple address creation
- First address or explicitly marked address becomes default
- Addresses are linked to customer via `USER_ID`
- Address validation for required fields

### 3. Security Features

- Mobile number format validation (10 digits starting with 6-9)
- Email format validation
- Password hashing using bcryptjs
- Duplicate customer prevention (email/mobile check)
- Transaction rollback on errors

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Username, mobile number, and store name are required"
}
```

### 400 Bad Request - Duplicate Customer
```json
{
  "success": false,
  "message": "Customer already exists with this email or mobile number"
}
```

### 400 Bad Request - Missing Store Name
```json
{
  "success": false,
  "message": "Store name is required for retailer profile creation"
}
```

### 400 Bad Request - Invalid Mobile
```json
{
  "success": false,
  "message": "Invalid mobile number format"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Customer not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Error creating customer",
  "error": "Detailed error message"
}
```

## Database Changes

### Tables Modified

1. **user_info**: Customer information storage
2. **customer_address**: Customer addresses (new/existing table)
3. **retailer_info**: Auto-created retailer profiles with complete structure:
   - `RET_ID`: Primary key
   - `RET_CODE`: Unique retailer code (RET001, RET002, etc.)
   - `RET_TYPE`: Retailer type (default: "Grocery")
   - `RET_NAME`: Retailer name (customer's username)
   - `RET_SHOP_NAME`: Store name (mandatory field)
   - `RET_MOBILE_NO`: Mobile number
   - `RET_ADDRESS`: Primary address
   - `RET_PIN_CODE`: PIN code
   - `RET_EMAIL_ID`: Email address
   - `RET_PHOTO`: Profile photo (optional)
   - `RET_COUNTRY`: Country
   - `RET_STATE`: State
   - `RET_CITY`: City
   - `RET_GST_NO`: GST number (optional)
   - `RET_LAT`: Latitude (optional)
   - `RET_LONG`: Longitude (optional)
   - `RET_DEL_STATUS`: Deletion status
   - `CREATED_DATE`: Creation timestamp
   - `UPDATED_DATE`: Update timestamp
   - `CREATED_BY`: Created by user
   - `UPDATED_BY`: Updated by user
   - `SHOP_OPEN_STATUS`: Shop open status
   - `BARCODE_URL`: QR code filename

### New Fields Used

- `is_otp_verify`: Set to 1 for admin/employee created customers
- `CREATED_BY`: Tracks who created the customer
- `BARCODE_URL`: QR code filename for retailer
- `RET_SHOP_NAME`: Mandatory store name for retailer profile

## Testing Examples

### Create Customer with Postman

1. Set authorization header with admin/employee token
2. Use POST method with appropriate endpoint
3. Send JSON payload with required fields (including store name)
4. Verify customer and retailer creation in response

### Verify QR Code Generation

1. Check `/uploads/retailers/qrcode/` directory
2. QR code filename format: `qr_{mobile}_{timestamp}.png`
3. QR code content: `+91{mobile_number}`

## Benefits

1. **Streamlined Process**: One API call creates both customer and retailer
2. **Data Consistency**: Automatic retailer code generation ensures uniqueness
3. **Role Tracking**: Clear audit trail of who created each customer
4. **Address Flexibility**: Support for multiple addresses per customer
5. **Integration Ready**: QR codes enable easy mobile app integration
6. **Security**: Proper validation and error handling
7. **Store Management**: Mandatory store name ensures complete retailer profiles

## Deployment Notes

1. Ensure `qrcode` npm package is installed
2. Verify upload directories exist with proper permissions
3. Test QR code generation functionality
4. Validate database permissions for all tables
5. Test with both admin and employee tokens
6. Validate store name requirement in API implementations

This comprehensive customer creation system provides a robust foundation for managing customers while automatically maintaining complete retailer profiles with store information for seamless integration with existing order and payment systems.