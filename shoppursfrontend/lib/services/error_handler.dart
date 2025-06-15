import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../widgets/maintenance_popup.dart';
import '../widgets/no_internet_popup.dart';
import 'connectivity_service.dart';

class ErrorHandler {
  static bool _isMaintenancePopupShown = false;
  static bool _isNoInternetPopupShown = false;
  static BuildContext? _currentContext;

  static void setContext(BuildContext context) {
    _currentContext = context;
  }

  /// Processes HTTP response and handles errors appropriately
  static Map<String, dynamic> handleHttpResponse(
    http.Response response,
    String endpoint, {
    BuildContext? context,
  }) {
    try {
      final decodedBody = json.decode(response.body);
      
      // Success cases
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody;
      }

      // Handle different error status codes
      String userFriendlyMessage;
      switch (response.statusCode) {
        case 400:
          userFriendlyMessage = _extractUserMessage(decodedBody) ?? 
              'Invalid request. Please check your input and try again.';
          break;
        case 401:
          userFriendlyMessage = 'Your session has expired. Please login again.';
          _handleAuthenticationError(context);
          break;
        case 403:
          userFriendlyMessage = 'You don\'t have permission to perform this action.';
          break;
        case 404:
          userFriendlyMessage = 'The requested resource was not found.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          userFriendlyMessage = 'Server is temporarily unavailable. Please try again later.';
          _handleServerUnavailable(context);
          break;
        default:
          userFriendlyMessage = 'Something went wrong. Please try again.';
      }

      return {
        'success': false,
        'message': userFriendlyMessage,
        'endpoint': endpoint,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      // JSON parsing error or other issues
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'endpoint': endpoint,
        'statusCode': response.statusCode,
      };
    }
  }

  /// Handles network and connection errors
  static Future<Map<String, dynamic>> handleNetworkError(
    dynamic error,
    String endpoint, {
    BuildContext? context,
  }) async {
    String userMessage;
    
    if (error is SocketException) {
      // Check if it's a network connectivity issue
      await _handleNetworkConnectivityError(context);
      userMessage = 'Unable to connect to server. Please check your internet connection.';
    } else if (error is HttpException) {
      userMessage = 'Network error occurred. Please try again.';
    } else if (error.toString().contains('TimeoutException')) {
      userMessage = 'Request timed out. Please try again.';
      await _handleNetworkConnectivityError(context);
    } else {
      userMessage = 'Connection error. Please check your internet connection and try again.';
      await _handleNetworkConnectivityError(context);
    }

    return {
      'success': false,
      'message': userMessage,
      'endpoint': endpoint,
      'error_type': 'network',
      'technical_error': _sanitizeEndpoint(endpoint),
    };
  }

  /// Handles network connectivity errors by checking internet status
  static Future<void> _handleNetworkConnectivityError(BuildContext? context) async {
    if (context == null) return;
    
    try {
      // Check actual internet connectivity
      final connectivityStatus = await ConnectivityService.checkConnectivity();
      
      if (!connectivityStatus.hasInternet) {
        // No internet connection - show no internet popup
        _showNoInternetPopup(context);
      } else {
        // Internet available but server unreachable - show maintenance popup
        _showMaintenancePopup(context);
      }
    } catch (e) {
      // If connectivity check fails, assume no internet
      _showNoInternetPopup(context);
    }
  }

  /// Handles server unavailable scenarios (5xx errors)
  static void _handleServerUnavailable(BuildContext? context) {
    // For server errors, we know internet is working but server is down
    _showMaintenancePopup(context);
  }

  /// Creates a sanitized error message for logging/debugging
  static String _sanitizeEndpoint(String endpoint) {
    // Replace actual server details with generic localhost reference
    final baseUrl = ApiConfig.baseUrl;
    final sanitizedEndpoint = endpoint.replaceAll(baseUrl, 'localhost:3000');
    return '$sanitizedEndpoint - Error in fetching data';
  }

  /// Extracts user-friendly message from server response
  static String? _extractUserMessage(Map<String, dynamic> responseBody) {
    // Try different common message fields
    if (responseBody.containsKey('message') && responseBody['message'] is String) {
      final message = responseBody['message'] as String;
      // Don't expose technical details to users
      if (!_isTechnicalError(message)) {
        return message;
      }
    }
    
    if (responseBody.containsKey('error') && responseBody['error'] is String) {
      final error = responseBody['error'] as String;
      if (!_isTechnicalError(error)) {
        return error;
      }
    }
    
    return null;
  }

  /// Checks if error message contains technical details that shouldn't be shown to users
  static bool _isTechnicalError(String message) {
    final technicalKeywords = [
      'stack trace',
      'database',
      'sql',
      'connection string',
      'port',
      'localhost',
      'internal server error',
      'null pointer',
      'exception',
      'mongodb',
      'mysql',
      'postgresql',
    ];
    
    return technicalKeywords.any((keyword) => 
        message.toLowerCase().contains(keyword));
  }

  /// Shows no internet popup when no internet connection is detected
  static void _showNoInternetPopup(BuildContext? context) {
    if (_isNoInternetPopupShown || context == null) return;
    
    _isNoInternetPopupShown = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const NoInternetPopup(),
    );
  }

  /// Shows maintenance popup when server is unreachable but internet is available
  static void _showMaintenancePopup(BuildContext? context) {
    if (_isMaintenancePopupShown || context == null) return;
    
    _isMaintenancePopupShown = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const MaintenancePopup(),
    );
  }

  /// Handles authentication errors (token expiry, etc.)
  static void _handleAuthenticationError(BuildContext? context) {
    if (context == null) return;
    
    // Navigate to login page
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
    
    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please login again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Resets all popup states (for app restart scenarios)
  static void resetPopupStates() {
    _isMaintenancePopupShown = false;
    _isNoInternetPopupShown = false;
  }

  /// Legacy method for backward compatibility
  static void resetMaintenanceState() {
    resetPopupStates();
  }

  /// Shows a generic error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 