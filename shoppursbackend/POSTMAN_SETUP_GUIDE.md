# Postman Setup Guide for AnwarFood Admin APIs

This guide will help you set up and use the Postman collection for testing all admin APIs.

## 📁 **Files Provided**

- `AnwarFood_Admin_APIs.postman_collection.json` - Complete Postman collection with all 13 admin APIs
- `ADMIN_API_DOCUMENTATION.md` - Detailed API documentation

## 🚀 **Quick Setup**

### Step 1: Import the Collection

1. Open Postman
2. Click on **Import** button (top left)
3. Drag and drop `AnwarFood_Admin_APIs.postman_collection.json` file
4. Click **Import**

### Step 2: Set Environment Variables

1. Click on **Environments** in the sidebar
2. Create a new environment called "AnwarFood Admin"
3. Add the following variables:

| Variable Name | Initial Value | Current Value |
|---------------|---------------|---------------|
| `base_url` | `http://localhost:3000` | `http://localhost:3000` |
| `admin_token` | *(leave empty)* | *(leave empty)* |
| `product_id` | `1` | `1` |
| `category_id` | `1` | `1` |
| `user_id` | `1` | `1` |
| `order_id` | `1` | `1` |
| `retailer_id` | `1` | `1` |

4. **Important**: Change `base_url` to your actual server URL if different

### Step 3: Select Environment

- In the top-right corner of Postman, select "AnwarFood Admin" environment

## 🔐 **Authentication Setup**

### Get Admin Token

1. **Start your server** first:
   ```bash
   cd anwarfoodbackend
   npm start
   # or
   npm run dev
   ```

2. **Run Admin Login** request:
   - Go to `Authentication` → `Admin Login`
   - The request is pre-configured with admin credentials:
     ```json
     {
       "phone": "9999999999",
       "password": "admin123"
     }
     ```
   - Click **Send**
   - ✅ **Token will be automatically saved** to `admin_token` environment variable

3. **Verify Token**: Check that `admin_token` variable now contains the JWT token

## 📋 **Collection Structure**

The collection is organized into 6 main folders:

### 1. **Authentication**
- `Admin Login` - Get JWT token (auto-saves to environment)

### 2. **Product Management**
- `Add Product` - Create new products
- `Edit Product` - Update existing products

### 3. **Category Management**
- `Add Category` - Create new categories
- `Edit Category` - Update existing categories

### 4. **User Management**
- `Fetch Users` - Get paginated user list with filters
- `Search Users` - Search users by name, email, or mobile
- `Edit User` - Update user information

### 5. **Order Management**
- `Fetch All Orders` - Get all orders with pagination and filters (uses orders table)
- `Get Order Details` - Get detailed order information with items
- `Edit Order Status` - Update order status and notes

### 6. **Retailer Management**
- `Get All Retailers` - List all retailers with pagination
- `Add Retailer` - Create new retailers
- `Edit Retailer` - Update retailer information
- `Get Single Retailer Details` - Get specific retailer details

## ⚡ **Quick Testing Guide**

### Test Sequence:

1. **Login First**:
   ```
   Authentication → Admin Login
   ```

2. **Test Category APIs**:
   ```
   Category Management → Add Category
   Category Management → Edit Category (update category_id variable)
   ```

3. **Test Product APIs**:
   ```
   Product Management → Add Product
   Product Management → Edit Product (update product_id variable)
   ```

4. **Test User APIs**:
   ```
   User Management → Fetch Users
   User Management → Search Users
   User Management → Edit User (update user_id variable)
   ```

5. **Test Order APIs**:
   ```
   Order Management → Fetch All Orders
   Order Management → Get Order Details (update order_id variable)
   Order Management → Edit Order Status (update order_id variable)
   ```

6. **Test Retailer APIs**:
   ```
   Retailer Management → Get All Retailers
   Retailer Management → Add Retailer
   Retailer Management → Edit Retailer (update retailer_id variable)
   Retailer Management → Get Single Retailer Details
   ```

## 🔧 **Customizing Variables**

### Update IDs for Testing:

After creating resources, update these variables with actual IDs:

```javascript
// In Postman Environment Variables:
product_id: "123"      // Replace with actual product ID after creation
category_id: "456"     // Replace with actual category ID after creation  
user_id: "789"         // Replace with actual user ID for testing
order_id: "101"        // Replace with actual order ID for testing
retailer_id: "202"     // Replace with actual retailer ID after creation
```

### Change Base URL:

For production or different environments:
```javascript
base_url: "https://your-production-url.com"
base_url: "http://your-staging-url.com:8080"
```

## 📝 **Sample Test Data**

### Product Data:
```json
{
  "prodName": "Test Product",
  "prodCode": "TEST001",
  "prodDesc": "Test product description",
  "prodMrp": 100.00,
  "prodSp": 85.00,
  "prodCatId": 1
}
```

### Category Data:
```json
{
  "categoryName": "Test Category",
  "catImage": "test-category.jpg"
}
```

### Retailer Data:
```json
{
  "retName": "Test Retailer",
  "retShopName": "Test Shop",
  "retMobileNo": 9876543210,
  "retEmailId": "test@retailer.com"
}
```

## 🐛 **Troubleshooting**

### Common Issues:

1. **401 Unauthorized**:
   - Run Admin Login first
   - Check if `admin_token` variable is set
   - Verify admin user exists in database

2. **403 Forbidden**:
   - User doesn't have admin role
   - Check USER_TYPE in database = 'admin'

3. **404 Not Found**:
   - Check base_url is correct
   - Verify server is running
   - Check API endpoint paths

4. **500 Internal Server Error**:
   - Check server logs
   - Verify database connection
   - Check request body format

### Debug Steps:

1. **Check Environment**: Ensure "AnwarFood Admin" environment is selected
2. **Verify Variables**: Check that all variables have correct values
3. **Test Login**: Always run Admin Login first
4. **Check Server**: Ensure backend server is running
5. **Database**: Verify admin user exists with correct role

## 📊 **Response Examples**

### Successful Response:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

## 🔄 **Advanced Usage**

### Test Scripts:

The collection includes automatic token handling:
- Login automatically saves token to environment
- All admin requests use the saved token
- No manual token copying required

### Bulk Testing:

1. Use **Collection Runner** for automated testing
2. Set up **Test Scripts** for validation
3. Create **Data Files** for multiple test cases

## 📞 **Support**

If you encounter issues:

1. Check the server console for error logs
2. Verify database connection
3. Ensure all required fields are provided
4. Check API documentation for correct request format

---

**Happy Testing! 🚀**

All admin APIs are now ready for testing with proper authentication and sample data. 