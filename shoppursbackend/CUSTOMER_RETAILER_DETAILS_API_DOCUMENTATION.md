# Customer with Retailer Details Management API Documentation

This document provides comprehensive information about the Customer with Retailer Details Management APIs for both Admin and Employee access levels.

## Table of Contents
- [Overview](#overview)
- [Authentication](#authentication)
- [Base URLs](#base-urls)
- [Database Relationships](#database-relationships)
- [API Endpoints](#api-endpoints)
  - [Get Customers with Retailer Details (with Pagination)](#get-customers-with-retailer-details-with-pagination)
  - [Search Customers with Retailer Details](#search-customers-with-retailer-details)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [Query Parameters](#query-parameters)
- [Examples](#examples)

## Overview

The Customer with Retailer Details Management API allows administrators and employees to:
- View paginated lists of customers with their associated retailer information
- Filter customers by various criteria (user type, active status, location, retailer status)
- Search customers and retailers by multiple fields
- Access comprehensive customer and retailer data in a single response

The API provides identical functionality for both admin and employee roles, with different access endpoints and response metadata.

## Authentication

All endpoints require authentication via JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

**Admin Access:** Requires admin-level authentication
**Employee Access:** Requires employee-level authentication

## Base URLs

- **Admin APIs:** `/api/admin/`
- **Employee APIs:** `/api/employee/`

## Database Relationships

The API joins two main tables using mobile number as the common link:

### Primary Table: `user_info`
```sql
USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, 
ADDRESS, PHOTO, FCM_TOKEN, CREATED_DATE, CREATED_BY, UPDATED_DATE, UPDATED_BY, 
USER_TYPE, ISACTIVE, is_otp_verify
```

### Related Table: `retailer_info`
```sql
RET_ID, RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, RET_ADDRESS, 
RET_PIN_CODE, RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY, 
RET_GST_NO, RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE, 
CREATED_BY, UPDATED_BY, SHOP_OPEN_STATUS, BARCODE_URL
```

### Join Relationship
```sql
LEFT JOIN retailer_info r ON user_info.MOBILE = r.RET_MOBILE_NO
```

## API Endpoints

### Get Customers with Retailer Details (with Pagination)

Retrieves a paginated list of customers with their associated retailer information.

#### Admin Endpoint
```
GET /api/admin/customers-with-retailer-details
```

#### Employee Endpoint
```
GET /api/employee/customers-with-retailer-details
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number for pagination |
| `limit` | integer | No | 10 | Number of items per page |
| `userType` | string | No | "customer" | Filter by user type |
| `isActive` | string | No | "Y" | Filter by user active status |
| `city` | string | No | null | Filter by city (user or retailer) |
| `state` | string | No | null | Filter by state (user or retailer) |
| `country` | string | No | null | Filter by retailer country |
| `retStatus` | string | No | null | Filter by retailer status |
| `search` | string | No | null | Search across multiple fields |

#### Response Format

```json
{
  "success": true,
  "message": "Customers with retailer details fetched successfully",
  "data": {
    "customers": [
      {
        "USER_ID": 1,
        "UL_ID": 1,
        "USERNAME": "John Doe",
        "EMAIL": "john@example.com",
        "MOBILE": "9876543210",
        "USER_CITY": "Mumbai",
        "USER_PROVINCE": "Maharashtra",
        "USER_ZIP": "400001",
        "USER_ADDRESS": "123 Main Street",
        "USER_PHOTO": "user_photo.jpg",
        "FCM_TOKEN": "fcm_token_value",
        "USER_CREATED_DATE": "2024-01-15T10:30:00.000Z",
        "USER_CREATED_BY": "admin",
        "USER_UPDATED_DATE": "2024-01-15T10:30:00.000Z",
        "USER_UPDATED_BY": "admin",
        "USER_TYPE": "customer",
        "USER_ISACTIVE": "Y",
        "is_otp_verify": 1,
        "RET_ID": 5,
        "RET_CODE": "RET001",
        "RET_TYPE": "Grocery",
        "RET_NAME": "John Doe",
        "RET_SHOP_NAME": "Doe's Grocery Store",
        "RET_MOBILE_NO": "9876543210",
        "RET_ADDRESS": "123 Shop Street",
        "RET_PIN_CODE": 400001,
        "RET_EMAIL_ID": "shop@example.com",
        "RET_PHOTO": "retailer_photo.jpg",
        "RET_COUNTRY": "India",
        "RET_STATE": "Maharashtra",
        "RET_CITY": "Mumbai",
        "RET_GST_NO": "27AAPFU0939F1ZV",
        "RET_LAT": "19.0760",
        "RET_LONG": "72.8777",
        "RET_DEL_STATUS": "active",
        "RET_CREATED_DATE": "2024-01-15T10:30:00.000Z",
        "RET_UPDATED_DATE": "2024-01-15T10:30:00.000Z",
        "RET_CREATED_BY": "admin",
        "RET_UPDATED_BY": "admin",
        "SHOP_OPEN_STATUS": "open",
        "BARCODE_URL": "https://example.com/barcode.png"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCustomers": 47,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "userType": "customer",
      "isActive": "Y",
      "city": null,
      "state": null,
      "country": null,
      "retStatus": null,
      "search": null
    }
  },
  "accessedBy": "employee_user",     // Only in employee response
  "accessedByRole": "employee"       // Only in employee response
}
```

### Search Customers with Retailer Details

Searches customers and their retailer information by multiple fields with pagination.

#### Admin Endpoint
```
GET /api/admin/search-customers-with-retailer-details
```

#### Employee Endpoint
```
GET /api/employee/search-customers-with-retailer-details
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | **Yes** | - | Search term to look for |
| `page` | integer | No | 1 | Page number for pagination |
| `limit` | integer | No | 10 | Number of items per page |

#### Search Fields

The search functionality looks for the query term in the following fields:

**User Fields:**
- `USERNAME` (Customer Name)
- `EMAIL` (Customer Email)
- `MOBILE` (Customer Mobile)
- `ADDRESS` (Customer Address)
- `CITY` (Customer City)

**Retailer Fields:**
- `RET_NAME` (Retailer Name)
- `RET_SHOP_NAME` (Shop Name)
- `RET_ADDRESS` (Retailer Address)
- `RET_CITY` (Retailer City)
- `RET_CODE` (Retailer Code)

#### Search Ranking

Results are ranked by relevance:
1. **Exact matches** (username, mobile, or retailer name)
2. **Prefix matches** (starts with query)
3. **Partial matches** (contains query)

#### Response Format

```json
{
  "success": true,
  "message": "Customers with retailer details search completed",
  "data": {
    "customers": [
      {
        "USER_ID": 1,
        "USERNAME": "John Doe",
        // ... all customer and retailer fields
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalCustomers": 15,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "searchQuery": "john"
  },
  "searchedBy": "employee_user",  // Only in employee response
  "searchedByRole": "employee"    // Only in employee response
}
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "message": "Descriptive success message",
  "data": {
    // Response data object
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

## Error Handling

### Common HTTP Status Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 400 | Bad Request (missing required parameters) |
| 401 | Unauthorized (invalid or missing authentication) |
| 403 | Forbidden (insufficient permissions) |
| 500 | Internal Server Error |

### Common Error Scenarios

1. **Missing Search Query (400)**
```json
{
  "success": false,
  "message": "Search query is required"
}
```

2. **Authentication Required (401)**
```json
{
  "success": false,
  "message": "Authentication required"
}
```

3. **Database Error (500)**
```json
{
  "success": false,
  "message": "Error fetching customers with retailer details",
  "error": "Database connection failed"
}
```

## Query Parameters

### Pagination Parameters

- **page**: Page number (starts from 1)
- **limit**: Items per page (recommended: 10-50)

### Filter Parameters

- **userType**: Filter by user type (default: "customer")
- **isActive**: Filter by user active status (default: "Y")
- **city**: Filter by city (searches both user and retailer cities)
- **state**: Filter by state (searches both user province and retailer state)
- **country**: Filter by retailer country
- **retStatus**: Filter by retailer status ("active", "inactive")
- **search**: Multi-field search term

### Parameter Validation

- `page` must be a positive integer
- `limit` must be between 1 and 100
- String parameters are case-sensitive
- Invalid parameters are ignored with defaults applied

## Examples

### Example 1: Get First Page of Active Customers

**Request:**
```
GET /api/admin/customers-with-retailer-details?page=1&limit=10&isActive=Y
```

**Response:**
```json
{
  "success": true,
  "message": "Customers with retailer details fetched successfully",
  "data": {
    "customers": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCustomers": 47,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "userType": "customer",
      "isActive": "Y",
      "city": null,
      "state": null,
      "country": null,
      "retStatus": null,
      "search": null
    }
  }
}
```

### Example 2: Filter by Location

**Request:**
```
GET /api/admin/customers-with-retailer-details?city=Mumbai&state=Maharashtra&page=1&limit=20
```

### Example 3: Search for Specific Customer/Retailer

**Request:**
```
GET /api/admin/search-customers-with-retailer-details?query=john&page=1&limit=10
```

### Example 4: Employee Access with Filters

**Request:**
```
GET /api/employee/customers-with-retailer-details?country=India&retStatus=active&page=2&limit=15
```

**Response:** (Includes additional metadata)
```json
{
  "success": true,
  "message": "Customers with retailer details fetched successfully by employee",
  "data": {
    // ... same data structure
  },
  "accessedBy": "employee_username",
  "accessedByRole": "employee"
}
```

### Example 5: Combined Search and Filtering

**Request:**
```
GET /api/admin/customers-with-retailer-details?state=Maharashtra&isActive=Y&search=grocery&page=1&limit=25
```

## Data Relationships and Notes

### User-Retailer Relationship

- **One-to-One**: Each user can have at most one associated retailer profile
- **Optional**: Users may exist without retailer profiles (LEFT JOIN used)
- **Link Field**: `user_info.MOBILE = retailer_info.RET_MOBILE_NO`

### Field Prefixing

To avoid naming conflicts, fields are prefixed in the response:
- **User fields**: Prefixed with `USER_` (e.g., `USER_CITY`, `USER_CREATED_DATE`)
- **Retailer fields**: Prefixed with `RET_` (e.g., `RET_CITY`, `RET_CREATED_DATE`)
- **Special cases**: `USER_ISACTIVE`, `is_otp_verify` remain as-is for clarity

### Null Handling

- When a user has no associated retailer, all retailer fields will be `null`
- This is normal behavior due to the LEFT JOIN relationship
- Use the presence of `RET_ID` to determine if retailer data exists

## Implementation Notes

### Performance Considerations

1. **Indexing**: Ensure indexes on `MOBILE` and `RET_MOBILE_NO` fields
2. **Pagination**: Always use pagination for large datasets
3. **Limit Control**: Maximum limit enforced to prevent performance issues
4. **Join Optimization**: LEFT JOIN allows efficient querying of users with optional retailer data

### Security Features

1. **Authentication**: JWT token required for all requests
2. **Authorization**: Role-based access control (admin/employee)
3. **Input Validation**: All parameters validated and sanitized
4. **SQL Injection Prevention**: Parameterized queries used throughout

### Data Consistency

1. **Default Filters**: Active customers shown by default
2. **Sorting**: Results sorted by user creation date (newest first)
3. **Field Mapping**: Database field names preserved with prefixing
4. **Null Safety**: Proper handling of missing retailer relationships

This API provides comprehensive access to customer data with their associated retailer information, enabling efficient customer relationship management and business intelligence for both administrative and operational use cases. 