import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class RetailerService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<String?> _getUserRole() async {
    try {
      final user = await _authService.getUser();
      return user?.role.toLowerCase();
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get retailers for employee with pagination
  Future<Map<String, dynamic>> getRetailers({
    int page = 1,
    int limit = 10,
    String status = 'active',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/retailers')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
      });

      print('Fetching retailers from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailers response status: ${response.statusCode}');
      print('Retailers response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailers');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailers. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailers: $e');
      rethrow;
    }
  }

  // Search retailers with role-based endpoint
  Future<List<Map<String, dynamic>>> searchRetailers(String query) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final userRole = await _getUserRole();
      
      // Use admin endpoint for admin users, employee endpoint for others
      final uri = Uri.parse(userRole == 'admin' 
          ? ApiConfig.retailersSearch 
          : '${ApiConfig.baseUrl}/api/employee/retailers/search')
          .replace(queryParameters: {'query': query});

      print('User role: $userRole');
      print('Searching retailers with query: $query');
      print('Search URL: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Both admin and employee endpoints return data directly as array
            return (data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to search retailers');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to search retailers. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in searchRetailers: $e');
      rethrow;
    }
  }

  // Store selected retailer phone number
  Future<void> storeSelectedRetailerPhone(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_retailer_phone', phoneNumber);
      print('Stored retailer phone: $phoneNumber');
    } catch (e) {
      print('Error storing retailer phone: $e');
      throw Exception('Failed to store retailer information');
    }
  }

  // Store selected retailer shop name
  Future<void> storeSelectedRetailerShopName(String shopName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_retailer_shop_name', shopName);
      print('Stored retailer shop name: $shopName');
    } catch (e) {
      print('Error storing retailer shop name: $e');
      throw Exception('Failed to store retailer shop name');
    }
  }

  // Get stored retailer phone number
  Future<String?> getSelectedRetailerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_retailer_phone');
    } catch (e) {
      print('Error getting retailer phone: $e');
      return null;
    }
  }

  // Get stored retailer shop name
  Future<String?> getSelectedRetailerShopName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_retailer_shop_name');
    } catch (e) {
      print('Error getting retailer shop name: $e');
      return null;
    }
  }

  // Clear stored retailer phone number
  Future<void> clearSelectedRetailerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_retailer_phone');
      print('Cleared stored retailer phone');
    } catch (e) {
      print('Error clearing retailer phone: $e');
    }
  }

  // Clear stored retailer shop name
  Future<void> clearSelectedRetailerShopName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_retailer_shop_name');
      print('Cleared stored retailer shop name');
    } catch (e) {
      print('Error clearing retailer shop name: $e');
    }
  }

  // Get retailer list with role-based endpoint
  Future<Map<String, dynamic>> getRetailerList({
    int page = 1,
    int limit = 5,
    String status = 'active',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final userRole = await _getUserRole();
      
      // Use admin endpoint for admin users, employee endpoint for others
      final uri = Uri.parse(userRole == 'admin' 
          ? ApiConfig.retailersList
          : '${ApiConfig.baseUrl}/api/employee/retailers')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
      });

      print('User role: $userRole');
      print('Fetching retailer list from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailer list response status: ${response.statusCode}');
      print('Retailer list response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Handle different response structures based on role
          if (userRole == 'admin') {
            // Admin endpoint - normalize the response structure
            return {
              'retailers': (data['data'] as List).cast<Map<String, dynamic>>(),
              'pagination': data['pagination'] ?? {
                'currentPage': 1,
                'totalPages': 1,
                'totalCount': (data['data'] as List).length,
              },
            };
          } else {
            // Employee endpoint returns proper structure
            return {
              'retailers': (data['data']['retailers'] as List).cast<Map<String, dynamic>>(),
              'pagination': data['data']['pagination'] ?? {},
            };
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer list');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailer list. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailerList: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRetailerDetails(int retailerId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/retailers/admin/retailer-details/$retailerId');

      print('Fetching retailer details from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailer details response status: ${response.statusCode}');
      print('Retailer details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer details');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailer details. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailerDetails: $e');
      rethrow;
    }
  }

  // Get retailer by phone number from QR code
  Future<Map<String, dynamic>> getRetailerByPhone(String phone) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(ApiConfig.retailerByPhone(phone));

      print('Fetching retailer by phone: $phone');
      print('API URL: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailer by phone response status: ${response.statusCode}');
      print('Retailer by phone response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer by phone');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailer by phone. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailerByPhone: $e');
      rethrow;
    }
  }
} 