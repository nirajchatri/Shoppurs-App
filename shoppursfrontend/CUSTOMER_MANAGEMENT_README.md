# Customer Management System

This document outlines the new comprehensive customer management system that allows administrators and employees to create and manage customers from their respective dashboards.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Files Created/Modified](#files-createdmodified)
- [API Integration](#api-integration)
- [Screen Flow](#screen-flow)
- [Navigation Integration](#navigation-integration)
- [Usage Instructions](#usage-instructions)
- [Role-Based Access](#role-based-access)
- [Key Components](#key-components)

## 🔍 Overview

The customer management system provides a complete solution for admin and employee users to:
- **Create customers** with single or multiple addresses
- **Search and manage** existing customers
- **View detailed customer information** including addresses and order history
- **Automatic retailer profile creation** with QR code generation
- **Role-based access control** for admin and employee users

## ✨ Features

### Core Features
- ✅ **Customer Creation**: Single and multiple address support
- ✅ **Automatic Retailer Creation**: Every customer gets a retailer profile
- ✅ **QR Code Generation**: Unique QR codes for retailer identification
- ✅ **Address Management**: Multiple address support with default selection
- ✅ **Customer Search**: Search by name, mobile, email, or city
- ✅ **Customer Details**: Comprehensive view with order summary
- ✅ **Role-based Access**: Admin and employee permissions
- ✅ **Data Validation**: Mobile, email, and pincode validation
- ✅ **Password Management**: Auto-generated secure passwords

### UI/UX Features
- 🎨 **Modern Design**: Consistent with app theme (Color: #9B1B1B)
- 📱 **Responsive Layout**: Works across different screen sizes
- 🔄 **Loading States**: Proper loading indicators
- ❌ **Error Handling**: Comprehensive error messages
- 🔍 **Search Functionality**: Real-time search with debouncing
- 📄 **Pagination**: Efficient data loading
- 🎯 **Role-specific UI**: Different messaging for admin vs employee

## 🏗️ Architecture

### Model Layer
```
models/
├── customer_model.dart          # Customer data structures
├── address_model.dart           # Address data structures (existing)
└── user_model.dart             # User data structures (existing)
```

### Service Layer
```
services/
├── customer_service.dart       # Universal customer management
├── admin_service.dart          # Extended admin functionality
├── employee_service.dart       # Employee-specific operations
└── auth_service.dart          # Authentication (existing)
```

### UI Layer
```
features/
├── admin/
│   ├── customer_management_page.dart    # Search & manage customers
│   ├── create_customer_page.dart        # Create new customers
│   └── customer_details_page.dart       # View customer details
└── common/
    └── customer_management_hub.dart     # Main entry point
```

## 📁 Files Created/Modified

### New Files Created
1. **`lib/models/customer_model.dart`**
   - Customer data model
   - CustomerAddress model
   - CustomerOrderSummary model
   - CreateCustomerRequest model
   - CustomerAddressRequest model

2. **`lib/services/customer_service.dart`**
   - Universal customer service with role detection
   - CRUD operations for customers
   - Search functionality
   - Validation helpers

3. **`lib/services/employee_service.dart`**
   - Employee-specific customer operations
   - Order management for employees
   - Validation utilities

4. **`lib/features/admin/customer_management_page.dart`**
   - Customer search and listing
   - Pagination support
   - Customer card UI components

5. **`lib/features/admin/create_customer_page.dart`**
   - Customer creation form
   - Single/multiple address modes
   - Dynamic address form management
   - Comprehensive validation

6. **`lib/features/admin/customer_details_page.dart`**
   - Detailed customer view
   - Address management display
   - Order summary statistics
   - Customer information cards

7. **`lib/features/common/customer_management_hub.dart`**
   - Main entry point for customer management
   - Role-based access control
   - Feature overview dashboard
   - Navigation hub

### Modified Files
1. **`lib/config/api_config.dart`**
   - Added customer management endpoints
   - Admin customer APIs
   - Employee customer APIs

2. **`lib/services/admin_service.dart`**
   - Extended with customer management methods
   - Updated to use ApiConfig
   - Added employee management functions

## 🔌 API Integration

### Admin Endpoints
```dart
// Customer Management
ApiConfig.adminCreateCustomer
ApiConfig.adminCreateCustomerWithAddresses
ApiConfig.adminGetCustomerDetails(customerId)
ApiConfig.adminSearchCustomers
```

### Employee Endpoints
```dart
// Customer Management
ApiConfig.employeeCreateCustomer
ApiConfig.employeeCreateCustomerWithAddresses
ApiConfig.employeeGetCustomerDetails(customerId)
ApiConfig.employeeSearchCustomers
```

### Request/Response Format
All APIs follow the documented format from the API documentation:
- **Create Customer**: POST with customer data
- **Search Customers**: GET with query parameters
- **Get Details**: GET with customer ID
- **Response**: Standardized success/error format

## 📱 Screen Flow

### Main Flow
1. **Customer Management Hub** (Entry Point)
   - Role-based welcome screen
   - Feature overview
   - Quick navigation

2. **Customer Management Page** (Search & List)
   - Search customers
   - View customer list
   - Navigate to details

3. **Create Customer Page** (Creation)
   - Choose single/multiple addresses
   - Fill customer information
   - Add address details
   - Submit and create

4. **Customer Details Page** (Details)
   - View customer information
   - See all addresses
   - Check order summary
   - Retailer information

### Navigation Flow
```
Customer Management Hub
├── Search & Manage Customers → Customer Management Page
│                               ├── Customer Details Page
│                               └── Create Customer Page
└── Create New Customer → Create Customer Page
```

## 🧭 Navigation Integration

### Option 1: Add to Admin/Employee Dashboard
```dart
// In admin/employee dashboard
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CustomerManagementHub(),
    ),
  ),
  child: Text('Customer Management'),
)
```

### Option 2: Add to Navigation Menu
```dart
// In navigation drawer or menu
ListTile(
  leading: Icon(Icons.people),
  title: Text('Customer Management'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CustomerManagementHub(),
    ),
  ),
)
```

### Option 3: Add to Bottom Navigation
```dart
// In bottom navigation bar (for admin/employee)
BottomNavigationBarItem(
  icon: Icon(Icons.people),
  label: 'CUSTOMERS',
)
```

## 📖 Usage Instructions

### For Administrators

1. **Access Customer Management**
   - Navigate to Customer Management Hub
   - View overview dashboard
   - Choose desired action

2. **Create New Customer**
   - Click "Create New Customer"
   - Fill in basic information
   - Choose single or multiple addresses
   - Add address details
   - Submit to create customer and retailer

3. **Search & Manage Customers**
   - Click "Search & Manage Customers"
   - Enter search query (name, mobile, email, city)
   - Browse results with pagination
   - Click customer to view details

4. **View Customer Details**
   - See complete customer information
   - View all addresses
   - Check order summary
   - See retailer information

### For Employees

Same functionality as administrators with:
- Employee-specific messaging
- Employee role tracking in API calls
- Employee dashboard integration

### Key Interactions

- **Search**: Real-time search with 500ms debouncing
- **Pagination**: Load more results as needed
- **Validation**: Real-time form validation
- **Error Handling**: Clear error messages and retry options
- **Loading States**: Visual feedback during operations

## 🔐 Role-Based Access

### Access Control
```dart
// Automatic role detection
final user = await _authService.getUser();
final role = user?.role.toLowerCase();

// Role-based API calls
if (role == 'admin') {
  // Use admin endpoints
} else if (role == 'employee') {
  // Use employee endpoints
} else {
  // Access denied
}
```

### Permissions
- **Admin**: Full access to all customer management features
- **Employee**: Full access to all customer management features
- **Customer**: No access (shows access denied screen)
- **Guest**: No access (redirected to login)

## 🔧 Key Components

### Models
- **Customer**: Main customer data structure
- **CustomerAddress**: Address information
- **CustomerOrderSummary**: Order statistics
- **CreateCustomerRequest**: API request format

### Services
- **CustomerService**: Universal service with role detection
- **AdminService**: Extended admin functionality
- **EmployeeService**: Employee-specific operations

### UI Components
- **CustomerManagementHub**: Main entry point
- **CustomerManagementPage**: Search and list
- **CreateCustomerPage**: Customer creation with forms
- **CustomerDetailsPage**: Detailed customer view

### Widgets
- **AddressForm**: Dynamic address form management
- **CustomerCard**: Customer display component
- **StatCard**: Statistics display
- **FeatureCard**: Feature overview cards

## 🎯 Features Implementation Status

- ✅ **Customer Creation**: Single and multiple addresses
- ✅ **Customer Search**: Comprehensive search functionality
- ✅ **Customer Details**: Complete information display
- ✅ **Role-based Access**: Admin and employee permissions
- ✅ **Address Management**: Multiple address support
- ✅ **Validation**: Mobile, email, pincode validation
- ✅ **Error Handling**: Comprehensive error management
- ✅ **Loading States**: Proper loading indicators
- ✅ **Pagination**: Efficient data loading
- ✅ **API Integration**: Complete backend integration

## 🚀 Next Steps

1. **Integration**: Add navigation from main app screens
2. **Testing**: Test with real backend APIs
3. **Enhancement**: Add customer editing functionality
4. **Statistics**: Implement real-time customer statistics
5. **Notifications**: Add success/error notifications
6. **Optimization**: Performance improvements for large datasets

## 📞 Support

For questions or issues with the customer management system:
1. Check API documentation for backend requirements
2. Verify user roles and permissions
3. Test API endpoints independently
4. Review error messages for debugging
5. Check network connectivity and API availability

---

**Note**: This system requires the backend APIs to be implemented according to the provided API documentation. Ensure all endpoints are available and properly configured before using the customer management features. 