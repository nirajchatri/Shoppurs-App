# Admin API Documentation

This document provides comprehensive information about the admin-only APIs for the AnwarFood backend system.

## Authentication

All admin APIs require authentication using a JWT token with admin privileges. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

The token must belong to a user with `USER_TYPE = 'admin'` in the database.

## Admin User Setup

To create an admin user, run the following script:

```bash
node create-admin.js
```

This will create an admin user with the following credentials:
- **Email**: admin@anwarfood.com
- **Password**: admin123
- **Mobile**: 9999999999

## Base URL

All admin APIs are prefixed with `/api/admin`

---

## Product Management APIs

### 1. Add Product
**POST** `/api/admin/add-product`

Add a new product to the system.

**Request Body:**
```json
{
  "prodSubCatId": 1,
  "prodName": "Product Name",
  "prodCode": "PROD001",
  "prodDesc": "Product description",
  "prodMrp": 100.00,
  "prodSp": 90.00,
  "prodReorderLevel": "10",
  "prodQoh": "100",
  "prodHsnCode": "HSN001",
  "prodCgst": "9.00",
  "prodIgst": "18.00",
  "prodSgst": "9.00",
  "prodMfgDate": "2024-01-01",
  "prodExpiryDate": "2025-01-01",
  "prodMfgBy": "Manufacturer Name",
  "prodImage1": "image1.jpg",
  "prodImage2": "image2.jpg",
  "prodImage3": "image3.jpg",
  "prodCatId": 1,
  "isBarcodeAvailable": "Y"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product added successfully",
  "productId": 123
}
```

### 2. Edit Product
**PUT** `/api/admin/edit-product/:productId`

Update an existing product.

**Request Body:** Same as Add Product

**Response:**
```json
{
  "success": true,
  "message": "Product updated successfully"
}
```

---

## Category Management APIs

### 3. Add Category
**POST** `/api/admin/add-category`

Add a new category to the system.

**Request Body:**
```json
{
  "categoryName": "Category Name",
  "catImage": "category-image.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Category added successfully",
  "categoryId": 123
}
```

### 4. Edit Category
**PUT** `/api/admin/edit-category/:categoryId`

Update an existing category.

**Request Body:**
```json
{
  "categoryName": "Updated Category Name",
  "catImage": "updated-category-image.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Category updated successfully"
}
```

---

## User Management APIs

### 5. Fetch Users
**GET** `/api/admin/fetch-user`

Retrieve a paginated list of users.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `userType` (optional): Filter by user type (customer, admin, etc.)

**Example:** `/api/admin/fetch-user?page=1&limit=20&userType=customer`

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "USER_ID": 1,
        "USERNAME": "john_doe",
        "EMAIL": "john@example.com",
        "MOBILE": 1234567890,
        "CITY": "New York",
        "USER_TYPE": "customer",
        "CREATED_DATE": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalUsers": 50,
      "limit": 10
    }
  }
}
```

### 6. Search Users
**GET** `/api/admin/search-user`

Search users by username, email, or mobile number.

**Query Parameters:**
- `query` (required): Search term
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)

**Example:** `/api/admin/search-user?query=john&page=1&limit=10`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "USER_ID": 1,
      "USERNAME": "john_doe",
      "EMAIL": "john@example.com",
      "MOBILE": 1234567890,
      "USER_TYPE": "customer"
    }
  ],
  "searchQuery": "john"
}
```

### 7. Edit User
**PUT** `/api/admin/edit-user/:userId`

Update user information.

**Request Body:**
```json
{
  "username": "updated_username",
  "email": "updated@example.com",
  "mobile": 9876543210,
  "city": "Updated City",
  "province": "Updated Province",
  "zip": "12345",
  "address": "Updated Address",
  "userType": "customer",
  "isActive": "Y"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User updated successfully"
}
```

---

## Order Management APIs

### 8. Fetch All Orders
**GET** `/api/admin/fetch-all-orders`

Retrieve a paginated list of all orders using the `orders` and `order_items` tables.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `status` (optional): Filter by order status (pending, confirmed, processing, shipped, delivered, cancelled)
- `startDate` (optional): Filter orders from this date (YYYY-MM-DD)
- `endDate` (optional): Filter orders until this date (YYYY-MM-DD)

**Example:** `/api/admin/fetch-all-orders?page=1&limit=50&status=pending&startDate=2024-01-01&endDate=2025-12-31`

**Response:**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "ORDER_ID": 1,
        "ORDER_NUMBER": "ORD-2024-001",
        "USER_ID": 123,
        "ORDER_TOTAL": 500.00,
        "ORDER_STATUS": "pending",
        "DELIVERY_ADDRESS": "123 Main St",
        "DELIVERY_CITY": "New York",
        "DELIVERY_STATE": "NY",
        "DELIVERY_COUNTRY": "USA",
        "DELIVERY_PINCODE": "10001",
        "DELIVERY_LANDMARK": "Near Central Park",
        "PAYMENT_METHOD": "cod",
        "ORDER_NOTES": "Customer notes",
        "CREATED_DATE": "2024-01-01T00:00:00.000Z",
        "UPDATED_DATE": "2024-01-01T00:00:00.000Z",
        "CUSTOMER_NAME": "John Doe",
        "CUSTOMER_EMAIL": "john@example.com",
        "CUSTOMER_MOBILE": 1234567890,
        "TOTAL_ITEMS": 3
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 10,
      "totalOrders": 200,
      "limit": 20
    }
  }
}
```

### 9. Get Order Details
**GET** `/api/admin/get-order-details/:orderId`

Get detailed information about a specific order including customer details and all order items.

**Response:**
```json
{
  "success": true,
  "data": {
    "ORDER_ID": 1,
    "ORDER_NUMBER": "ORD-2024-001",
    "USER_ID": 123,
    "ORDER_TOTAL": 500.00,
    "ORDER_STATUS": "pending",
    "DELIVERY_ADDRESS": "123 Main St",
    "DELIVERY_CITY": "New York",
    "DELIVERY_STATE": "NY",
    "DELIVERY_COUNTRY": "USA",
    "DELIVERY_PINCODE": "10001",
    "DELIVERY_LANDMARK": "Near Central Park",
    "PAYMENT_METHOD": "cod",
    "ORDER_NOTES": "Customer notes",
    "CREATED_DATE": "2024-01-01T00:00:00.000Z",
    "UPDATED_DATE": "2024-01-01T00:00:00.000Z",
    "CUSTOMER_NAME": "John Doe",
    "CUSTOMER_EMAIL": "john@example.com",
    "CUSTOMER_MOBILE": 1234567890,
    "CUSTOMER_ADDRESS": "Customer's registered address",
    "ORDER_ITEMS": [
      {
        "ORDER_ITEM_ID": 1,
        "PROD_ID": 101,
        "UNIT_ID": 1,
        "QUANTITY": 2,
        "UNIT_PRICE": 100.00,
        "TOTAL_PRICE": 200.00,
        "PROD_NAME": "Sample Product",
        "PROD_CODE": "PROD001",
        "PROD_DESC": "Product description",
        "PROD_IMAGE_1": "product-image.jpg"
      }
    ]
  }
}
```

### 10. Edit Order Status
**PUT** `/api/admin/edit-order-status/:orderId`

Update order status and notes.

**Request Body:**
```json
{
  "status": "confirmed",
  "orderNotes": "Order confirmed and being processed"
}
```

**Valid Status Values:**
- `pending`
- `confirmed`
- `processing`
- `shipped`
- `delivered`
- `cancelled`

**Response:**
```json
{
  "success": true,
  "message": "Order status updated successfully"
}
```

---

## Retailer Management APIs

### 11. Get All Retailers
**GET** `/api/admin/get-all-retailer-list`

Retrieve a paginated list of all retailers.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `status` (optional): Filter by retailer status (active, inactive)

**Example:** `/api/admin/get-all-retailer-list?page=1&limit=20&status=active`

**Response:**
```json
{
  "success": true,
  "data": {
    "retailers": [
      {
        "RET_ID": 1,
        "RET_CODE": "RET001",
        "RET_NAME": "Retailer Name",
        "RET_SHOP_NAME": "Shop Name",
        "RET_MOBILE_NO": 1234567890,
        "RET_EMAIL_ID": "retailer@example.com",
        "RET_CITY": "City Name",
        "RET_DEL_STATUS": "active"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalRetailers": 50,
      "limit": 10
    }
  }
}
```

### 12. Add Retailer
**POST** `/api/admin/add-retailer`

Add a new retailer to the system.

**Request Body:**
```json
{
  "retCode": "RET001",
  "retType": "distributor",
  "retName": "Retailer Name",
  "retShopName": "Shop Name",
  "retMobileNo": 1234567890,
  "retAddress": "Retailer Address",
  "retPinCode": 123456,
  "retEmailId": "retailer@example.com",
  "retPhoto": "retailer-photo.jpg",
  "retCountry": "India",
  "retState": "State Name",
  "retCity": "City Name",
  "retGstNo": "GST123456789",
  "retLat": "12.9716",
  "retLong": "77.5946"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Retailer added successfully",
  "retailerId": 123
}
```

### 13. Edit Retailer
**PUT** `/api/admin/edit-retailer/:retailerId`

Update retailer information.

**Request Body:** Same as Add Retailer, plus:
```json
{
  "retDelStatus": "active",
  "shopOpenStatus": "1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Retailer updated successfully"
}
```

### 14. Get Single Retailer Details
**GET** `/api/admin/get-details-single-retailer/:retailerId`

Get detailed information about a specific retailer.

**Response:**
```json
{
  "success": true,
  "data": {
    "RET_ID": 1,
    "RET_CODE": "RET001",
    "RET_TYPE": "distributor",
    "RET_NAME": "Retailer Name",
    "RET_SHOP_NAME": "Shop Name",
    "RET_MOBILE_NO": 1234567890,
    "RET_ADDRESS": "Retailer Address",
    "RET_PIN_CODE": 123456,
    "RET_EMAIL_ID": "retailer@example.com",
    "RET_COUNTRY": "India",
    "RET_STATE": "State Name",
    "RET_CITY": "City Name",
    "RET_GST_NO": "GST123456789",
    "RET_LAT": "12.9716",
    "RET_LONG": "77.5946",
    "RET_DEL_STATUS": "active",
    "SHOP_OPEN_STATUS": "1",
    "CREATED_DATE": "2024-01-01T00:00:00.000Z"
  }
}
```

---

## Error Responses

All APIs return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (if available)"
}
```

Common HTTP status codes:
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User doesn't have admin privileges
- `404 Not Found`: Resource not found
- `400 Bad Request`: Invalid request data
- `500 Internal Server Error`: Server error

---

## Testing the APIs

1. First, create an admin user using the script:
   ```bash
   node create-admin.js
   ```

2. Login to get a JWT token:
   ```bash
   POST /api/auth/login
   {
     "phone": "9999999999",
     "password": "admin123"
   }
   ```

3. Use the returned token in the Authorization header for all admin API calls:
   ```
   Authorization: Bearer <your-jwt-token>
   ```

## Security Notes

- All admin APIs are protected by admin middleware
- JWT tokens must be valid and belong to users with admin role
- Sensitive operations are logged with the admin username
- Database queries use parameterized statements to prevent SQL injection 