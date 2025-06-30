import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/customer_lead_model.dart';
import '../services/auth_service.dart';

class CustomerLeadService {
  final AuthService _authService = AuthService();

  /// Get authorization headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }
    return ApiConfig.getAuthHeaders(token);
  }

  /// Get user role
  Future<String?> _getUserRole() async {
    final user = await _authService.getUser();
    return user?.role.toLowerCase();
  }

  // ==================== CUSTOMER LEADS FETCHING ====================

  /// Get Customer Leads with Pagination
  Future<CustomerLeadResponse> getCustomerLeads({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
    String? city,
    String? state,
    String? search,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final userRole = await _getUserRole();
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      // Choose appropriate endpoint based on user role
      String endpoint;
      if (userRole == 'admin') {
        endpoint = ApiConfig.adminCustomerLeads;
      } else if (userRole == 'employee') {
        endpoint = ApiConfig.employeeCustomerLeads;
      } else {
        throw Exception('Unauthorized access. Admin or Employee role required.');
      }
      
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return CustomerLeadResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch customer leads');
      }
    } catch (e) {
      throw Exception('Error fetching customer leads: $e');
    }
  }

  /// Search Customer Leads
  Future<CustomerLeadResponse> searchCustomerLeads({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (query.trim().isEmpty) {
        throw Exception('Search query is required');
      }

      final headers = await _getAuthHeaders();
      final userRole = await _getUserRole();
      
      // Build query parameters
      final queryParams = <String, String>{
        'query': query.trim(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Choose appropriate endpoint based on user role
      String endpoint;
      if (userRole == 'admin') {
        endpoint = ApiConfig.adminSearchCustomerLeads;
      } else if (userRole == 'employee') {
        endpoint = ApiConfig.employeeSearchCustomerLeads;
      } else {
        throw Exception('Unauthorized access. Admin or Employee role required.');
      }
      
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return CustomerLeadResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to search customer leads');
      }
    } catch (e) {
      throw Exception('Error searching customer leads: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Validate pagination parameters
  bool isValidPage(int page) {
    return page > 0;
  }

  /// Validate limit parameter
  bool isValidLimit(int limit) {
    return limit > 0 && limit <= 100;
  }

  /// Get lead type display text
  String getLeadTypeDisplayText(String? type) {
    if (type == null || type.isEmpty) return 'General';
    
    switch (type.toLowerCase()) {
      case 'grocery':
        return 'Grocery Store';
      case 'retail':
        return 'Retail Shop';
      case 'wholesale':
        return 'Wholesale Business';
      case 'restaurant':
        return 'Restaurant';
      case 'cafe':
        return 'Cafe';
      default:
        return type;
    }
  }

  /// Get status color
  Map<String, dynamic> getStatusColor(bool isActive) {
    return {
      'color': isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      'backgroundColor': isActive 
          ? const Color(0xFF4CAF50).withOpacity(0.1) 
          : const Color(0xFFF44336).withOpacity(0.1),
    };
  }

  /// Format address for display
  String formatAddress(CustomerLead lead) {
    final parts = <String>[];
    
    if (lead.custldAddress.isNotEmpty) parts.add(lead.custldAddress);
    if (lead.custldCity != null && lead.custldCity!.isNotEmpty) parts.add(lead.custldCity!);
    if (lead.custldState != null && lead.custldState!.isNotEmpty) parts.add(lead.custldState!);
    if (lead.custldPinCode > 0) parts.add(lead.custldPinCode.toString());
    
    return parts.join(', ');
  }

  /// Format mobile number for display
  String formatMobileNumber(int mobile) {
    if (mobile == 0) return 'No mobile';
    return '+91 $mobile';
  }

  /// Check if current user can access customer leads
  Future<bool> canAccessCustomerLeads() async {
    try {
      final user = await _authService.getUser();
      final role = user?.role.toLowerCase();
      return role == 'admin' || role == 'employee';
    } catch (e) {
      return false;
    }
  }

  /// Get available filter options
  Map<String, List<String>> getFilterOptions() {
    return {
      'types': [
        'Grocery',
        'Retail',
        'Wholesale',
        'Restaurant',
        'Cafe',
        'Medical',
        'Electronics',
        'Clothing',
        'General',
      ],
      'statuses': [
        'active',
        'inactive',
      ],
    };
  }

  /// Validate search query
  String? validateSearchQuery(String query) {
    if (query.trim().isEmpty) {
      return 'Search query cannot be empty';
    }
    
    if (query.trim().length < 2) {
      return 'Search query must be at least 2 characters long';
    }
    
    return null; // No validation errors
  }

  /// Parse CustomerLead from API response
  CustomerLead parseCustomerLead(Map<String, dynamic> leadData) {
    return CustomerLead.fromJson(leadData);
  }

  /// Get lead priority based on type and status
  int getLeadPriority(CustomerLead lead) {
    int priority = 0;
    
    // Status priority
    if (lead.isActive) priority += 10;
    
    // Type priority
    switch (lead.custldType?.toLowerCase()) {
      case 'wholesale':
        priority += 5;
        break;
      case 'grocery':
      case 'retail':
        priority += 3;
        break;
      case 'restaurant':
      case 'cafe':
        priority += 2;
        break;
      default:
        priority += 1;
    }
    
    return priority;
  }
} 