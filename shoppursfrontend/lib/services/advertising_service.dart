import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'http_client.dart';

class AdvertisingService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAdvertising({BuildContext? context}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.get(
        '/api/settings/advertising',
        token: token,
        context: context,
      );

      if (result['success'] == true) {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(result['data'] ?? []),
          'message': 'Advertising data loaded successfully',
        };
      } else {
        return result; // Error already handled by ErrorHandler
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load advertising data. Please try again.',
      };
    }
  }
} 