import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/customer_model.dart';
import 'auth_service.dart';

class EmployeeService {
  final AuthService _authService = AuthService();

  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    return ApiConfig.getAuthHeaders(token);
  }

  // ==================== CUSTOMER MANAGEMENT ====================

  /// Create customer with single address (Employee)
  Future<Map<String, dynamic>> createCustomer(CreateCustomerRequest request) async {
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
  Future<Map<String, dynamic>> createCustomerWithAddresses(CreateCustomerRequest request) async {
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
  Future<Map<String, dynamic>> getCustomerDetails(int customerId) async {
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
  Future<Map<String, dynamic>> searchCustomers({
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

  // ==================== ORDER MANAGEMENT ====================

  /// Get employee orders
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final uri = Uri.parse(ApiConfig.employeeOrders).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  /// Search orders
  Future<Map<String, dynamic>> searchOrders({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final uri = Uri.parse(ApiConfig.employeeOrdersSearch).replace(
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
      return data;
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConfig.employeeOrderDetails(orderId)),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error getting order details: $e');
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.put(
        Uri.parse(ApiConfig.employeeOrderStatus(orderId)),
        headers: headers,
        body: jsonEncode({'status': status}),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  /// Place order for customer
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.employeePlaceOrder),
        headers: headers,
        body: jsonEncode(orderData),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error placing order: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

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