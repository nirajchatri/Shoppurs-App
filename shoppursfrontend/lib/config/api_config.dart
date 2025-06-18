class ApiConfig {
  // =============================================================================
  // ENVIRONMENT CONFIGURATION
  // =============================================================================
  // Change this to switch between environments
  static const Environment _currentEnvironment = Environment.development;
  
  // Environment-specific URLs
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://192.168.29.96:3000',
    Environment.staging: 'https://staging-api.yourapp.com',
    Environment.production: 'https://api.yourapp.com',
    Environment.local: 'http://localhost:3000',
  };
  
  // Get the current base URL
  static String get baseUrl => _baseUrls[_currentEnvironment]!;
  
  // =============================================================================
  // AUTHENTICATION ENDPOINTS
  // =============================================================================
  static String get authLogin => '$baseUrl/api/auth/login';
  static String get authSignup => '$baseUrl/api/auth/signup';
  static String get authVerifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get authRequestPasswordReset => '$baseUrl/api/auth/request-password-reset';
  static String get authResendOtp => '$baseUrl/api/auth/resend-otp';
  static String get authConfirmOtpForPassword => '$baseUrl/api/auth/confirm-otp-for-password';
  static String get authResetPasswordWithPhone => '$baseUrl/api/auth/reset-password-with-phone';
  
  // =============================================================================
  // CATEGORY ENDPOINTS
  // =============================================================================
  static String get categoriesList => '$baseUrl/api/categories/list';
  
  // =============================================================================
  // PRODUCT ENDPOINTS
  // =============================================================================
  static String get productsList => '$baseUrl/api/products/list';
  static String get productsSearch => '$baseUrl/api/products/search';
  static String get productsGetByBarcode => '$baseUrl/api/products/get-by-barcode';
  static String productsByCategory(int categoryId) => '$baseUrl/api/products/category/$categoryId';
  static String productsBySubCategory(int subCategoryId) => '$baseUrl/api/products/subcategory/$subCategoryId';
  static String productsDetails(int productId) => '$baseUrl/api/products/details/$productId';
  
  // =============================================================================
  // CART ENDPOINTS
  // =============================================================================
  static String get cartAdd => '$baseUrl/api/cart/add';
  static String get cartAddAuto => '$baseUrl/api/cart/add-auto';
  static String get cartAddByBarcode => '$baseUrl/api/cart/add-by-barcode';
  static String get cartFetch => '$baseUrl/api/cart/fetch';
  static String get cartCount => '$baseUrl/api/cart/count';
  static String get cartEditUnit => '$baseUrl/api/cart/edit-unit';
  static String get cartIncreaseQuantity => '$baseUrl/api/cart/increase-quantity';
  static String get cartDecreaseQuantity => '$baseUrl/api/cart/decrease-quantity';
  static String get cartPlaceOrder => '$baseUrl/api/cart/place-order';
  
  // =============================================================================
  // ADDRESS ENDPOINTS
  // =============================================================================
  static String get addressList => '$baseUrl/api/address/list';
  static String get addressAdd => '$baseUrl/api/address/add';
  static String get addressDefault => '$baseUrl/api/address/default';
  static String addressEdit(int addressId) => '$baseUrl/api/address/edit/$addressId';
  
  // =============================================================================
  // ORDER ENDPOINTS
  // =============================================================================
  static String get ordersList => '$baseUrl/api/orders/list';
  static String get ordersSearch => '$baseUrl/api/orders/search';
  static String ordersDetails(int orderId) => '$baseUrl/api/orders/details/$orderId';
  static String ordersCancel(int orderId) => '$baseUrl/api/orders/cancel/$orderId';
  
  // =============================================================================
  // ADMIN ENDPOINTS
  // =============================================================================
  static String get adminEmployees => '$baseUrl/api/admin/employees';
  static String get adminFetchAllOrders => '$baseUrl/api/admin/fetch-all-orders';
  static String get adminSearchOrders => '$baseUrl/api/admin/search-orders';
  static String get adminAddProduct => '$baseUrl/api/admin/add-product';
  static String adminGetOrderDetails(int orderId) => '$baseUrl/api/admin/get-order-details/$orderId';
  static String adminEditOrderStatus(int orderId) => '$baseUrl/api/admin/edit-order-status/$orderId';
  static String adminEditProduct(int productId) => '$baseUrl/api/admin/edit-product/$productId';
  static String adminEmployeeOrders(int userId) => '$baseUrl/api/admin/employee-orders/$userId';
  
  // Customer Management by Admin
  static String get adminCreateCustomer => '$baseUrl/api/admin/create-customer';
  static String get adminCreateCustomerWithAddresses => '$baseUrl/api/admin/create-customer-with-addresses';
  static String get adminSearchCustomers => '$baseUrl/api/admin/search-customers';
  static String adminGetCustomerDetails(int customerId) => '$baseUrl/api/admin/get-customer-details/$customerId';
  
  // User Management by Admin
  static String get adminCreateEmployeeUser => '$baseUrl/api/admin/create-employee-user';
  static String get adminCreateAdminUser => '$baseUrl/api/admin/create-admin-user';
  static String get adminSearchAdminEmployeeUsers => '$baseUrl/api/admin/search-admin-employee-users';
  static String adminGetUserDetails(int userId) => '$baseUrl/api/admin/get-user-details/$userId';
  static String adminUpdateUserStatus(int userId) => '$baseUrl/api/admin/update-user-status/$userId';
  
  // =============================================================================
  // EMPLOYEE ENDPOINTS
  // =============================================================================
  static String get employeeOrders => '$baseUrl/api/employee/orders';
  static String get employeeOrdersSearch => '$baseUrl/api/employee/orders/search';
  static String get employeePlaceOrder => '$baseUrl/api/employee/place-order';
  static String employeeOrderDetails(int orderId) => '$baseUrl/api/employee/orders/$orderId';
  static String employeeOrderStatus(int orderId) => '$baseUrl/api/employee/orders/$orderId/status';
  
  // Customer Management by Employee
  static String get employeeCreateCustomer => '$baseUrl/api/employee/create-customer';
  static String get employeeCreateCustomerWithAddresses => '$baseUrl/api/employee/create-customer-with-addresses';
  static String get employeeSearchCustomers => '$baseUrl/api/employee/search-customers';
  static String employeeGetCustomerDetails(int customerId) => '$baseUrl/api/employee/get-customer-details/$customerId';
  
  // =============================================================================
  // RETAILER ENDPOINTS
  // =============================================================================
  static String get retailersMyRetailer => '$baseUrl/api/retailers/my-retailer';
  static String get retailersSearch => '$baseUrl/api/retailers/search';
  static String get retailersList => '$baseUrl/api/retailers/list';
  static String retailerDetails(int retailerId) => '$baseUrl/api/retailers/details/$retailerId';
  static String retailerByPhone(String phone) => '$baseUrl/api/admin/get-retailer-by-phone/$phone';
  
  // =============================================================================
  // BRAND ENDPOINTS
  // =============================================================================
  static String get brands => '$baseUrl/api/brands';
  
  // =============================================================================
  // ADVERTISING ENDPOINTS
  // =============================================================================
  static String get advertising => '$baseUrl/api/advertising';
  
  // =============================================================================
  // FILE UPLOAD ENDPOINTS
  // =============================================================================
  static String retailerPhoto(String photoName) => '$baseUrl/uploads/retailers/profiles/$photoName';
  
  // =============================================================================
  // CONFIGURATION
  // =============================================================================
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  // Test connectivity
  static String get healthCheckUrl => '$baseUrl/health';
  
  // Get current environment info
  static Environment get currentEnvironment => _currentEnvironment;
  static String get environmentName => _currentEnvironment.toString().split('.').last;
  
  // Debug info
  static void printApiInfo() {
    print('=== API CONFIGURATION ===');
    print('Environment: ${environmentName.toUpperCase()}');
    print('Base URL: $baseUrl');
    print('Timeout: ${timeout.inSeconds} seconds');
    print('Health Check: $healthCheckUrl');
    print('========================');
  }
}

// =============================================================================
// ENVIRONMENT ENUM
// =============================================================================
enum Environment {
  development,
  staging,
  production,
  local,
} 