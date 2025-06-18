import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_management_model.dart';
import '../services/auth_service.dart';

class UserManagementService {
  final AuthService _authService = AuthService();

  /// Get authorization headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }
    return ApiConfig.getAuthHeaders(token);
  }

  // ==================== USER CREATION ====================

  /// Create Employee User
  Future<Map<String, dynamic>> createEmployeeUser(CreateUserRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateEmployeeUser),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create employee user');
      }
    } catch (e) {
      throw Exception('Error creating employee user: $e');
    }
  }

  /// Create Admin User
  Future<Map<String, dynamic>> createAdminUser(CreateUserRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse(ApiConfig.adminCreateAdminUser),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create admin user');
      }
    } catch (e) {
      throw Exception('Error creating admin user: $e');
    }
  }

  // ==================== USER RETRIEVAL ====================

  /// Get User Details
  Future<UserDetailsResponse> getUserDetails(int userId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConfig.adminGetUserDetails(userId)),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return UserDetailsResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get user details');
      }
    } catch (e) {
      throw Exception('Error getting user details: $e');
    }
  }

  /// Search Admin/Employee Users
  Future<UserSearchResponse> searchUsers({
    required String query,
    String? userType,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final queryParams = {
        'query': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (userType != null && userType.isNotEmpty) {
        queryParams['userType'] = userType;
      }
      
      final uri = Uri.parse(ApiConfig.adminSearchAdminEmployeeUsers).replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return UserSearchResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search users');
      }
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // ==================== USER STATUS MANAGEMENT ====================

  /// Update User Status (Activate/Deactivate)
  Future<Map<String, dynamic>> updateUserStatus(int userId, bool isActive) async {
    try {
      final headers = await _getAuthHeaders();
      
      final request = UpdateUserStatusRequest(
        isActive: isActive ? 'Y' : 'N',
      );
      
      final response = await http.put(
        Uri.parse(ApiConfig.adminUpdateUserStatus(userId)),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update user status');
      }
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Validate mobile number format (Indian format: 10 digits starting with 6-9)
  bool isValidMobile(String mobile) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(mobile);
  }

  /// Validate email format
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  /// Validate password strength (minimum 6 characters)
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate required fields for user creation
  String? validateUserCreationFields(CreateUserRequest request) {
    if (request.username.trim().isEmpty) {
      return 'Username is required';
    }
    
    if (request.email.trim().isEmpty) {
      return 'Email is required';
    }
    
    if (!isValidEmail(request.email)) {
      return 'Invalid email format';
    }
    
    if (request.mobile.trim().isEmpty) {
      return 'Mobile number is required';
    }
    
    if (!isValidMobile(request.mobile)) {
      return 'Invalid mobile number format. Please enter 10 digits starting with 6-9';
    }
    
    if (request.password != null && request.password!.isNotEmpty) {
      if (!isValidPassword(request.password!)) {
        return 'Password must be at least 6 characters long';
      }
    }
    
    if (request.city.trim().isEmpty) {
      return 'City is required';
    }
    
    if (request.province.trim().isEmpty) {
      return 'Province/State is required';
    }
    
    if (request.zip.trim().isEmpty) {
      return 'ZIP/Postal code is required';
    }
    
    if (request.address.trim().isEmpty) {
      return 'Address is required';
    }
    
    return null; // No validation errors
  }

  /// Parse CreateUserResponse from API response
  CreateUserResponse parseCreateUserResponse(Map<String, dynamic> data) {
    return CreateUserResponse.fromJson(data);
  }

  /// Parse UserManagementUser from API response
  UserManagementUser parseUser(Map<String, dynamic> userData) {
    return UserManagementUser.fromJson(userData);
  }

  /// Get user role display text
  String getUserRoleDisplayText(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Employee';
      default:
        return userType;
    }
  }

  /// Get user level ID for user type
  int getUserLevelId(String userType) {
    switch (userType.toLowerCase()) {
      case 'employee':
        return 2;
      case 'admin':
        return 3;
      default:
        return 2; // Default to employee
    }
  }

  /// Format mobile number for display
  String formatMobileNumber(int mobile) {
    return '+91 $mobile';
  }

  /// Format user address for display
  String formatUserAddress(UserManagementUser user) {
    return '${user.address}, ${user.city}, ${user.province} - ${user.zip}';
  }

  /// Get user status text
  String getUserStatusText(bool isActive) {
    return isActive ? 'Active' : 'Inactive';
  }

  /// Get user status color
  Map<String, dynamic> getUserStatusColor(bool isActive) {
    return {
      'color': isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      'backgroundColor': isActive 
          ? const Color(0xFF4CAF50).withOpacity(0.1) 
          : const Color(0xFFF44336).withOpacity(0.1),
    };
  }

  /// Check if current user can manage other users
  Future<bool> canManageUsers() async {
    try {
      final user = await _authService.getUser();
      return user?.role.toLowerCase() == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Generate default password suggestions
  List<String> generatePasswordSuggestions() {
    return [
      'admin123',
      'employee123',
      'user123456',
      'temp123',
      'welcome123',
    ];
  }
} 