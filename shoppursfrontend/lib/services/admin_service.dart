import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/customer_model.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int limit = 10,
    String userType = 'customer',
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/fetch-user?page=$page&limit=$limit&userType=$userType'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/update-user-status/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // ==================== CUSTOMER MANAGEMENT ====================

  /// Create customer with single address
  Future<Map<String, dynamic>> createCustomer(CreateCustomerRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateCustomer),
        headers: ApiConfig.getAuthHeaders(token),
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

  /// Create customer with multiple addresses
  Future<Map<String, dynamic>> createCustomerWithAddresses(CreateCustomerRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateCustomerWithAddresses),
        headers: ApiConfig.getAuthHeaders(token),
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

  /// Get customer details by ID
  Future<Map<String, dynamic>> getCustomerDetails(int customerId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse(ApiConfig.adminGetCustomerDetails(customerId)),
        headers: ApiConfig.getAuthHeaders(token),
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

  /// Search customers
  Future<Map<String, dynamic>> searchCustomers({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final uri = Uri.parse(ApiConfig.adminSearchCustomers).replace(
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.getAuthHeaders(token),
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

  // ==================== EMPLOYEE MANAGEMENT ====================

  /// Get list of employees
  Future<Map<String, dynamic>> getEmployees() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse(ApiConfig.adminEmployees),
        headers: ApiConfig.getAuthHeaders(token),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
  }
} 