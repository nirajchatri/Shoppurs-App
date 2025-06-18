import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/customer_model.dart';
import 'auth_service.dart';

class CustomerService {
  final AuthService _authService = AuthService();

  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    return ApiConfig.getAuthHeaders(token);
  }

  // ==================== ADMIN CUSTOMER MANAGEMENT ====================

  /// Create customer with single address (Admin)
  Future<Map<String, dynamic>> createCustomerByAdmin(CreateCustomerRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateCustomer),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create customer');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  /// Create customer with multiple addresses (Admin)
  Future<Map<String, dynamic>> createCustomerWithAddressesByAdmin(CreateCustomerRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateCustomerWithAddresses),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create customer with addresses');
      }
    } catch (e) {
      throw Exception('Error creating customer with addresses: $e');
    }
  }

  /// Get customer details by ID (Admin)
  Future<Map<String, dynamic>> getCustomerDetailsByAdmin(int customerId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConfig.adminGetCustomerDetails(customerId)),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get customer details');
      }
    } catch (e) {
      throw Exception('Error getting customer details: $e');
    }
  }

  /// Search customers (Admin)
  Future<Map<String, dynamic>> searchCustomersByAdmin({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final uri = Uri.parse(ApiConfig.adminSearchCustomers).replace(
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to search customers');
      }
    } catch (e) {
      throw Exception('Error searching customers: $e');
    }
  }

  // ==================== EMPLOYEE CUSTOMER MANAGEMENT ====================

  /// Create customer with single address (Employee)
  Future<Map<String, dynamic>> createCustomerByEmployee(CreateCustomerRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.employeeCreateCustomer),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create customer');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  /// Create customer with multiple addresses (Employee)
  Future<Map<String, dynamic>> createCustomerWithAddressesByEmployee(CreateCustomerRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.employeeCreateCustomerWithAddresses),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create customer with addresses');
      }
    } catch (e) {
      throw Exception('Error creating customer with addresses: $e');
    }
  }

  /// Get customer details by ID (Employee)
  Future<Map<String, dynamic>> getCustomerDetailsByEmployee(int customerId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConfig.employeeGetCustomerDetails(customerId)),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to get customer details');
      }
    } catch (e) {
      throw Exception('Error getting customer details: $e');
    }
  }

  /// Search customers (Employee)
  Future<Map<String, dynamic>> searchCustomersByEmployee({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final uri = Uri.parse(ApiConfig.employeeSearchCustomers).replace(
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to search customers');
      }
    } catch (e) {
      throw Exception('Error searching customers: $e');
    }
  }

  // ==================== ROLE-AGNOSTIC METHODS ====================

  /// Create customer (automatically determines if admin or employee based on user role)
  Future<Map<String, dynamic>> createCustomer(CreateCustomerRequest request) async {
    final user = await _authService.getUser();
    final role = user?.role.toLowerCase();
    
    if (role == 'admin') {
      return await createCustomerByAdmin(request);
    } else if (role == 'employee') {
      return await createCustomerByEmployee(request);
    } else {
      throw Exception('Unauthorized: Only admin and employee can create customers');
    }
  }

  /// Create customer with multiple addresses (automatically determines role)
  Future<Map<String, dynamic>> createCustomerWithAddresses(CreateCustomerRequest request) async {
    final user = await _authService.getUser();
    final role = user?.role.toLowerCase();
    
    if (role == 'admin') {
      return await createCustomerWithAddressesByAdmin(request);
    } else if (role == 'employee') {
      return await createCustomerWithAddressesByEmployee(request);
    } else {
      throw Exception('Unauthorized: Only admin and employee can create customers');
    }
  }

  /// Get customer details (automatically determines role)
  Future<Map<String, dynamic>> getCustomerDetails(int customerId) async {
    final user = await _authService.getUser();
    final role = user?.role.toLowerCase();
    
    if (role == 'admin') {
      return await getCustomerDetailsByAdmin(customerId);
    } else if (role == 'employee') {
      return await getCustomerDetailsByEmployee(customerId);
    } else {
      throw Exception('Unauthorized: Only admin and employee can view customer details');
    }
  }

  /// Search customers (automatically determines role)
  Future<Map<String, dynamic>> searchCustomers({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    final user = await _authService.getUser();
    final role = user?.role.toLowerCase();
    
    if (role == 'admin') {
      return await searchCustomersByAdmin(query: query, page: page, limit: limit);
    } else if (role == 'employee') {
      return await searchCustomersByEmployee(query: query, page: page, limit: limit);
    } else {
      throw Exception('Unauthorized: Only admin and employee can search customers');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Parse customer from API response
  Customer parseCustomer(Map<String, dynamic> customerData) {
    return Customer.fromJson(customerData);
  }

  /// Parse customer address from API response
  CustomerAddress parseCustomerAddress(Map<String, dynamic> addressData) {
    return CustomerAddress.fromJson(addressData);
  }

  /// Parse customer order summary from API response
  CustomerOrderSummary parseOrderSummary(Map<String, dynamic> summaryData) {
    return CustomerOrderSummary.fromJson(summaryData);
  }

  /// Validate mobile number format
  bool isValidMobile(String mobile) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(mobile);
  }

  /// Validate email format
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  /// Validate pincode format
  bool isValidPincode(String pincode) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(pincode);
  }
} 