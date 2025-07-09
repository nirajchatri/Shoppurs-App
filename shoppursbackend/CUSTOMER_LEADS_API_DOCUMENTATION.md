# Customer Leads Management API Documentation

This document provides comprehensive information about the Customer Leads Management APIs for both Admin and Employee access levels.

## Table of Contents
- [Overview](#overview)
- [Authentication](#authentication)
- [Base URLs](#base-urls)
- [API Endpoints](#api-endpoints)
  - [Get Customer Leads (with Pagination)](#get-customer-leads-with-pagination)
  - [Search Customer Leads](#search-customer-leads)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [Query Parameters](#query-parameters)
- [Examples](#examples)

## Overview

The Customer Leads Management API allows administrators and employees to:
- View paginated lists of customer leads
- Filter leads by various criteria (type, status, city, state)
- Search leads by multiple fields
- Access detailed lead information

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

## Database Table Structure

The API accesses the `cust_lead` table with the following structure:

```sql
CREATE TABLE cust_lead (
  CUSTLD_ID bigint NOT NULL AUTO_INCREMENT,
  CUSTLD_TYPE varchar(100) DEFAULT NULL,
  CUSTLD_NAME varchar(200) NOT NULL,
  CUSTLD_SHOP_NAME varchar(200) DEFAULT 'A',
  CUSTLD_MOBILE_NO bigint NOT NULL,
  CUSTLD_ADDRESS varchar(200) NOT NULL,
  CUSTLD_PIN_CODE int NOT NULL,
  CUSTLD_EMAIL_ID varchar(200) NULL,
  CUSTLD_COUNTRY varchar(200) NULL,
  CUSTLD_STATE varchar(200) NULL,
  CUSTLD_CITY varchar(200) NULL,
  CUSTLD_GST_NO varchar(200) DEFAULT NULL,
  CUSTLD_DEL_STATUS varchar(200) NOT NULL DEFAULT 'active',
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  PRIMARY KEY (CUSTLD_ID)
)
```

## API Endpoints

### Get Customer Leads (with Pagination)

Retrieves a paginated list of customer leads with optional filtering.

#### Admin Endpoint
```
GET /api/admin/customer-leads
```

#### Employee Endpoint
```
GET /api/employee/customer-leads
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number for pagination |
| `limit` | integer | No | 10 | Number of items per page |
| `type` | string | No | null | Filter by customer lead type |
| `status` | string | No | "active" | Filter by lead status |
| `city` | string | No | null | Filter by city |
| `state` | string | No | null | Filter by state |
| `search` | string | No | null | Search across multiple fields |

#### Response Format

```json
{
  "success": true,
  "message": "Customer leads fetched successfully",
  "data": {
    "leads": [
      {
        "CUSTLD_ID": 1,
        "CUSTLD_TYPE": "Grocery",
        "CUSTLD_NAME": "John Doe",
        "CUSTLD_SHOP_NAME": "Doe's Store",
        "CUSTLD_MOBILE_NO": 9876543210,
        "CUSTLD_ADDRESS": "123 Main Street",
        "CUSTLD_PIN_CODE": 123456,
        "CUSTLD_EMAIL_ID": "john@example.com",
        "CUSTLD_COUNTRY": "India",
        "CUSTLD_STATE": "Maharashtra",
        "CUSTLD_CITY": "Mumbai",
        "CUSTLD_GST_NO": "27AAPFU0939F1ZV",
        "CUSTLD_DEL_STATUS": "active",
        "CREATED_DATE": "2024-01-15T10:30:00.000Z",
        "UPDATED_DATE": "2024-01-15T10:30:00.000Z",
        "CREATED_BY": "admin",
        "UPDATED_BY": "admin"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalLeads": 47,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "type": null,
      "status": "active",
      "city": null,
      "state": null,
      "search": null
    }
  },
  "accessedBy": "admin_user",     // Only in employee response
  "accessedByRole": "employee"    // Only in employee response
}
```

### Search Customer Leads

Searches customer leads by multiple fields with pagination.

#### Admin Endpoint
```
GET /api/admin/search-customer-leads
```

#### Employee Endpoint
```
GET /api/employee/search-customer-leads
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | **Yes** | - | Search term to look for |
| `page` | integer | No | 1 | Page number for pagination |
| `limit` | integer | No | 10 | Number of items per page |

#### Search Fields

The search functionality looks for the query term in the following fields:
- `CUSTLD_NAME` (Customer Name)
- `CUSTLD_SHOP_NAME` (Shop Name)
- `CUSTLD_MOBILE_NO` (Mobile Number)
- `CUSTLD_EMAIL_ID` (Email Address)
- `CUSTLD_ADDRESS` (Address)
- `CUSTLD_CITY` (City)
- `CUSTLD_STATE` (State)

#### Search Ranking

Results are ranked by relevance:
1. **Exact matches** (name or mobile)
2. **Prefix matches** (starts with query)
3. **Partial matches** (contains query)

#### Response Format

```json
{
  "success": true,
  "message": "Customer leads search completed",
  "data": {
    "leads": [
      {
        "CUSTLD_ID": 1,
        "CUSTLD_TYPE": "Grocery",
        "CUSTLD_NAME": "John Doe",
        // ... other fields
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalLeads": 15,
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
  "message": "Error fetching customer leads",
  "error": "Database connection failed"
}
```

## Query Parameters

### Pagination Parameters

- **page**: Page number (starts from 1)
- **limit**: Items per page (recommended: 10-50)

### Filter Parameters

- **type**: Filter by lead type (e.g., "Grocery", "Retail")
- **status**: Filter by status ("active", "inactive")
- **city**: Filter by city name
- **state**: Filter by state name
- **search**: Multi-field search term

### Parameter Validation

- `page` must be a positive integer
- `limit` must be between 1 and 100
- String parameters are case-sensitive
- Invalid parameters are ignored with defaults applied

## Examples

### Example 1: Get First Page of Active Leads

**Request:**
```
GET /api/admin/customer-leads?page=1&limit=10&status=active
```

**Response:**
```json
{
  "success": true,
  "message": "Customer leads fetched successfully",
  "data": {
    "leads": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalLeads": 47,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "type": null,
      "status": "active",
      "city": null,
      "state": null,
      "search": null
    }
  }
}
```

### Example 2: Filter by City and Type

**Request:**
```
GET /api/admin/customer-leads?city=Mumbai&type=Grocery&page=1&limit=20
```

### Example 3: Search for Specific Customer

**Request:**
```
GET /api/admin/search-customer-leads?query=john&page=1&limit=10
```

### Example 4: Employee Access

**Request:**
```
GET /api/employee/customer-leads?page=2&limit=15
```

**Response:** (Includes additional metadata)
```json
{
  "success": true,
  "message": "Customer leads fetched successfully by employee",
  "data": {
    // ... same data structure
  },
  "accessedBy": "employee_username",
  "accessedByRole": "employee"
}
```

### Example 5: Combined Filtering

**Request:**
```
GET /api/admin/customer-leads?state=Maharashtra&status=active&search=grocery&page=1&limit=25
```

## Implementation Notes

### Performance Considerations

1. **Pagination**: Always use pagination for large datasets
2. **Indexing**: Ensure database indexes on frequently filtered columns
3. **Limit Control**: Maximum limit is enforced to prevent performance issues
4. **Search Optimization**: Search uses LIKE operations; consider full-text search for large datasets

### Security Features

1. **Authentication**: JWT token required for all requests
2. **Authorization**: Role-based access control
3. **Input Validation**: All parameters are validated and sanitized
4. **SQL Injection Prevention**: Parameterized queries used throughout

### Data Consistency

1. **Default Status**: Only "active" leads shown by default
2. **Sorting**: Results sorted by creation date (newest first)
3. **Field Mapping**: Database field names preserved in response
4. **Null Handling**: Null values returned as null in JSON

This API provides comprehensive access to customer lead data with robust filtering, searching, and pagination capabilities for both administrative and employee use cases. 