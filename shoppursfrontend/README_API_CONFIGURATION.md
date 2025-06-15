# API Configuration Guide

## Overview
This project now uses a centralized API configuration system to manage all endpoints and environment settings. This makes it easy to deploy to different environments (development, staging, production) without manually changing URLs throughout the codebase.

## Quick Environment Setup

### 1. Change Environment
Edit `lib/config/api_config.dart` and modify the `_currentEnvironment` variable:

```dart
// Change this line to switch environments
static const Environment _currentEnvironment = Environment.development;  // or staging, production, local
```

### 2. Available Environments

- **`Environment.development`** - Current setup: `http://192.168.29.96:3000`
- **`Environment.local`** - For local development: `http://localhost:3000`
- **`Environment.staging`** - For staging server: `https://staging-api.yourapp.com`
- **`Environment.production`** - For production: `https://api.yourapp.com`

### 3. Update Production URLs
Before deploying to production, update the URLs in `lib/config/api_config.dart`:

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.development: 'http://192.168.29.96:3000',
  Environment.staging: 'https://your-staging-server.com',      // ← Update this
  Environment.production: 'https://your-production-server.com', // ← Update this
  Environment.local: 'http://localhost:3000',
};
```

## Features

### ✅ **Centralized Management**
- All API endpoints are defined in one file
- Easy environment switching
- Consistent headers and authentication
- Built-in timeout configuration

### ✅ **Environment Safety**
- No hardcoded URLs in the codebase
- Clear environment indicators
- Debug information available

### ✅ **Complete Coverage**
All API endpoints are now centralized:

#### Authentication
- Login, Signup, OTP Verification
- Password Reset functionality

#### Products
- Product listings, search, details
- Barcode scanning functionality
- Category and subcategory support

#### Cart Management
- Add, remove, modify cart items
- Unit changes and quantity management
- Barcode-based cart additions

#### Orders
- Order placement and tracking
- Order history and details
- Admin and employee order management

#### User Management
- Address management
- Retailer information
- Employee functionality

## Usage Examples

### For Developers
```dart
// Instead of hardcoded URLs like this:
// Uri.parse('http://192.168.29.96:3000/api/products/search')

// Use centralized config like this:
Uri.parse(ApiConfig.productsSearch)

// For parameterized endpoints:
Uri.parse(ApiConfig.productsDetails(productId))
```

### For Deployment
1. **Development**: Keep `Environment.development`
2. **Staging**: Change to `Environment.staging` and update staging URL
3. **Production**: Change to `Environment.production` and update production URL

### Debug Information
```dart
// Call this to see current configuration
ApiConfig.printApiInfo();
```

## Files Modified

### Core Configuration
- `lib/config/api_config.dart` - Main configuration file

### Services Updated
- `lib/services/auth_service.dart`
- `lib/services/cart_service.dart`
- `lib/services/product_service.dart`
- `lib/services/order_service.dart`
- `lib/services/address_service.dart`
- All other service files

### Pages Updated
- `lib/features/cart/cart_page.dart`
- `lib/features/home/home_page.dart`
- `lib/features/product/product_list_page.dart`
- All other page files with API calls

## Benefits

1. **Easy Deployment** - Change one line to switch environments
2. **Maintainability** - All endpoints in one place
3. **Error Reduction** - No risk of missed URL updates
4. **Version Control** - Clear history of API changes
5. **Team Collaboration** - Consistent API usage across team

## Important Notes

⚠️ **Before Client Delivery:**
1. Update production URLs in `api_config.dart`
2. Set environment to `Environment.production`
3. Test all functionality
4. Verify SSL certificates for HTTPS URLs

⚠️ **Security:**
- Never commit production credentials
- Use environment variables for sensitive data
- Ensure HTTPS in production

## Troubleshooting

### If the app doesn't work after update:
1. Check that `_currentEnvironment` is set correctly
2. Verify the base URL is accessible
3. Run `ApiConfig.printApiInfo()` to debug
4. Check network connectivity
5. Verify API server is running

### Common Issues:
- **CORS errors**: Update server CORS settings
- **SSL errors**: Check certificate validity
- **Network timeout**: Adjust `ApiConfig.timeout` value

## Testing
```bash
# Test in different environments
flutter run  # Uses current environment setting

# For release testing
flutter run --release
```

---

**Note**: This configuration system ensures your app will work seamlessly across all environments without code changes. Just update the configuration and deploy! 