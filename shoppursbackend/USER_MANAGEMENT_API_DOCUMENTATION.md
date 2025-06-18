# User Management APIs Documentation

This document outlines the new user management APIs that allow administrators to create and manage Employee and Admin users from the admin dashboard. These APIs provide comprehensive user creation, retrieval, search, and status management functionality.

## Features

- **Employee User Creation**: Admin can create employee users with proper role assignment
- **Admin User Creation**: Admin can create additional admin users
- **User Details Retrieval**: Get comprehensive user information with role-specific statistics
- **User Search**: Search and filter users by name, email, mobile, or address
- **Status Management**: Activate/deactivate user accounts
- **Comprehensive Validation**: Email, mobile number, and data validation
- **Password Management**: Auto-generated passwords with secure hashing
- **Audit Trail**: Track who created and updated users

## Admin APIs for User Management

### Base URL: `/admin`

### 1. Create Employee User

**Endpoint:** `POST /admin/create-employee-user`

**Description:** Creates a new employee user in the system.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "username": "John Smith",
  "email": "john.smith@company.com",
  "mobile": "9876543210",
  "password": "employee123", // Optional, defaults to "123456"
  "city": "Mumbai",
  "province": "Maharashtra",
  "zip": "400001",
  "address": "123 Business Street",
  "photo": null, // Optional
  "fcmToken": null, // Optional
  "ulId": 2 // Optional, defaults to 2 for employees
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Employee user created successfully by admin",
  "data": {
    "user": {
      "USER_ID": 234,
      "UL_ID": 2,
      "USERNAME": "John Smith",
      "EMAIL": "john.smith@company.com",
      "MOBILE": 9876543210,
      "CITY": "Mumbai",
      "PROVINCE": "Maharashtra",
      "ZIP": "400001",
      "ADDRESS": "123 Business Street",
      "PHOTO": null,
      "FCM_TOKEN": null,
      "CREATED_DATE": "2024-01-15T10:30:00.000Z",
      "CREATED_BY": "admin_username",
      "UPDATED_DATE": "2024-01-15T10:30:00.000Z",
      "UPDATED_BY": "admin_username",
      "USER_TYPE": "employee",
      "ISACTIVE": "Y",
      "is_otp_verify": 1
    },
    "createdBy": "admin_username",
    "defaultPassword": "employee123",
    "userType": "employee"
  }
}
```

### 2. Create Admin User

**Endpoint:** `POST /admin/create-admin-user`

**Description:** Creates a new admin user in the system.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "username": "Sarah Johnson",
  "email": "sarah.johnson@company.com",
  "mobile": "9876543211",
  "password": "admin123", // Optional, defaults to "123456"
  "city": "Delhi",
  "province": "Delhi",
  "zip": "110001",
  "address": "456 Admin Plaza",
  "photo": null, // Optional
  "fcmToken": null, // Optional
  "ulId": 3 // Optional, defaults to 3 for admins
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Admin user created successfully by admin",
  "data": {
    "user": {
      "USER_ID": 235,
      "UL_ID": 3,
      "USERNAME": "Sarah Johnson",
      "EMAIL": "sarah.johnson@company.com",
      "MOBILE": 9876543211,
      "CITY": "Delhi",
      "PROVINCE": "Delhi",
      "ZIP": "110001",
      "ADDRESS": "456 Admin Plaza",
      "PHOTO": null,
      "FCM_TOKEN": null,
      "CREATED_DATE": "2024-01-15T10:35:00.000Z",
      "CREATED_BY": "admin_username",
      "UPDATED_DATE": "2024-01-15T10:35:00.000Z",
      "UPDATED_BY": "admin_username",
      "USER_TYPE": "admin",
      "ISACTIVE": "Y",
      "is_otp_verify": 1
    },
    "createdBy": "admin_username",
    "defaultPassword": "admin123",
    "userType": "admin"
  }
}
```

### 3. Get User Details

**Endpoint:** `GET /admin/get-user-details/:userId`

**Description:** Retrieves comprehensive user details for admin or employee users, including role-specific statistics.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "User details fetched successfully",
  "data": {
    "user": {
      "USER_ID": 234,
      "UL_ID": 2,
      "USERNAME": "John Smith",
      "EMAIL": "john.smith@company.com",
      "MOBILE": 9876543210,
      "CITY": "Mumbai",
      "PROVINCE": "Maharashtra",
      "ZIP": "400001",
      "ADDRESS": "123 Business Street",
      "PHOTO": null,
      "FCM_TOKEN": null,
      "CREATED_DATE": "2024-01-15T10:30:00.000Z",
      "CREATED_BY": "admin_username",
      "UPDATED_DATE": "2024-01-15T10:30:00.000Z",
      "UPDATED_BY": "admin_username",
      "USER_TYPE": "employee",
      "ISACTIVE": "Y",
      "is_otp_verify": 1
    },
    "employeeStats": {
      "orders_created": 25,
      "total_sales_value": 45000.00,
      "total_dwr_entries": 15,
      "completed_days": 12
    }
  }
}
```

**Note:** `employeeStats` is only included for employee users, null for admin users.

### 4. Search Admin/Employee Users

**Endpoint:** `GET /admin/search-admin-employee-users?query=<search_term>&userType=<type>&page=1&limit=10`

**Description:** Search admin and employee users by name, email, mobile, city, or address with optional user type filtering.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `query` (required): Search term
- `userType` (optional): Filter by 'admin' or 'employee' (default: shows both)
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)

**Success Response (200):**
```json
{
  "success": true,
  "message": "Admin/Employee users search completed",
  "data": {
    "users": [
      {
        "USER_ID": 234,
        "UL_ID": 2,
        "USERNAME": "John Smith",
        "EMAIL": "john.smith@company.com",
        "MOBILE": 9876543210,
        "CITY": "Mumbai",
        "PROVINCE": "Maharashtra",
        "ADDRESS": "123 Business Street",
        "CREATED_DATE": "2024-01-15T10:30:00.000Z",
        "USER_TYPE": "employee",
        "ISACTIVE": "Y",
        "CREATED_BY": "admin_username",
        "is_otp_verify": 1
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalUsers": 25,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "searchQuery": "john",
    "userTypeFilter": "employee"
  }
}
```

### 5. Update User Status

**Endpoint:** `PUT /admin/update-user-status/:userId`

**Description:** Activate or deactivate admin/employee user accounts.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "isActive": "N" // "Y" to activate, "N" to deactivate
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "User deactivated successfully",
  "data": {
    "user": {
      "USER_ID": 234,
      "USERNAME": "John Smith",
      "EMAIL": "john.smith@company.com",
      "MOBILE": 9876543210,
      "USER_TYPE": "employee",
      "ISACTIVE": "N",
      "UPDATED_DATE": "2024-01-15T11:00:00.000Z"
    },
    "updatedBy": "admin_username"
  }
}
```

## Database Schema

### user_info Table Fields Used

The APIs interact with the following fields in the `user_info` table:

```sql
USER_ID         - Auto-incrementing primary key
UL_ID           - User level ID (2 for employees, 3 for admins)
USERNAME        - Full name of the user
EMAIL           - Email address (validated)
MOBILE          - Mobile number (validated, 10 digits starting with 6-9)
PASSWORD        - Hashed password using bcryptjs
CITY            - City name
PROVINCE        - State/Province name
ZIP             - ZIP/Postal code
ADDRESS         - Full address
PHOTO           - Profile photo filename (optional)
FCM_TOKEN       - Firebase Cloud Messaging token (optional)
CREATED_DATE    - Auto-set to current timestamp
CREATED_BY      - Username of admin who created the user
UPDATED_DATE    - Auto-updated on changes
UPDATED_BY      - Username of admin who last updated
USER_TYPE       - 'employee' or 'admin'
ISACTIVE        - 'Y' for active, 'N' for inactive
is_otp_verify   - Set to 1 (users created by admin don't need OTP)
```

## Validation Rules

### Required Fields
- **Employee/Admin Creation**: `username`, `email`, `mobile`
- **Status Update**: `isActive`

### Format Validation
- **Mobile**: 10 digits starting with 6-9 (Indian mobile format)
- **Email**: Standard email format validation
- **Password**: Minimum 6 characters (if provided)
- **isActive**: Must be 'Y' or 'N'

### Business Rules
- **Duplicate Prevention**: Email and mobile must be unique across all users
- **Self-Protection**: Admins cannot deactivate their own account
- **Role Restriction**: Only admin and employee users can be managed through these APIs

## Error Responses

### 400 Bad Request - Missing Fields
```json
{
  "success": false,
  "message": "Username, email, and mobile number are required"
}
```

### 400 Bad Request - Invalid Mobile
```json
{
  "success": false,
  "message": "Invalid mobile number format"
}
```

### 400 Bad Request - Invalid Email
```json
{
  "success": false,
  "message": "Invalid email format"
}
```

### 400 Bad Request - Duplicate User
```json
{
  "success": false,
  "message": "User already exists with this email or mobile number"
}
```

### 400 Bad Request - Self Deactivation
```json
{
  "success": false,
  "message": "You cannot deactivate your own account"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "User not found or not an admin/employee"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Error creating employee user",
  "error": "Detailed error message"
}
```

## Security Features

### Authentication & Authorization
- **Admin-Only Access**: All endpoints require admin authentication
- **Role Verification**: User creation restricted to admin role
- **Token Validation**: JWT token validation on all requests

### Data Protection
- **Password Hashing**: All passwords hashed using bcryptjs
- **Password Exclusion**: User details responses exclude password field
- **Input Sanitization**: All inputs validated and sanitized

### Audit Trail
- **Creation Tracking**: `CREATED_BY` field tracks who created each user
- **Update Tracking**: `UPDATED_BY` field tracks who made changes
- **Timestamp Management**: Automatic `CREATED_DATE` and `UPDATED_DATE`

## Testing Examples

### Create Employee User
```bash
curl -X POST "http://localhost:3000/admin/create-employee-user" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "username": "Test Employee",
    "email": "test.employee@company.com",
    "mobile": "9876543210",
    "city": "Mumbai",
    "province": "Maharashtra",
    "zip": "400001",
    "address": "Test Address"
  }'
```

### Search Users
```bash
curl -X GET "http://localhost:3000/admin/search-admin-employee-users?query=test&userType=employee" \
  -H "Authorization: Bearer <admin_token>"
```

### Deactivate User
```bash
curl -X PUT "http://localhost:3000/admin/update-user-status/234" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{"isActive": "N"}'
```

## Use Cases

### Employee Management
1. **Onboarding**: Create employee accounts during hiring process
2. **Role Assignment**: Assign appropriate user levels and permissions
3. **Status Management**: Activate/deactivate accounts as needed
4. **Performance Tracking**: View employee statistics (orders, DWR entries)

### Admin Management
1. **Admin Creation**: Create additional admin accounts for management
2. **Delegation**: Enable multiple admins to manage the system
3. **Access Control**: Manage admin access and permissions

### User Lifecycle
1. **Creation**: Admin creates user with default password
2. **Activation**: User account is immediately active
3. **Usage**: User can login with provided credentials
4. **Management**: Admin can search, view, and manage users
5. **Deactivation**: Admin can deactivate accounts when needed

## Integration Notes

### Frontend Integration
- **User Creation Forms**: Build forms with proper validation
- **User Lists**: Display paginated user lists with search
- **Status Management**: Toggle switches for activate/deactivate
- **Statistics Display**: Show employee performance metrics

### Password Management
- **Default Passwords**: Inform users of their default passwords
- **Password Reset**: Implement password change functionality
- **Security Notices**: Prompt users to change default passwords

### Notification System
- **Creation Alerts**: Notify users when accounts are created
- **Status Changes**: Alert users when accounts are activated/deactivated
- **Email Integration**: Send welcome emails with login credentials

This comprehensive user management system provides administrators with powerful tools to create and manage employee and admin users while maintaining security, audit trails, and proper validation throughout the user lifecycle. 