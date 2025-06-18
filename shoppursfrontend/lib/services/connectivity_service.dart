import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConnectivityService {
  static const String baseUrl = 'http://192.168.29.96:3000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Check if API server is reachable
  static Future<bool> isApiServerReachable() async {
    try {
      print('Checking API server connectivity...');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      print('API Health Check Response: ${response.statusCode}');
      print('API Health Check Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('API server not reachable: $e');
      return false;
    }
  }

  // Comprehensive connectivity check
  static Future<ConnectivityStatus> checkConnectivity() async {
    print('=== CONNECTIVITY CHECK ===');
    
    // Check internet connection
    final hasInternet = await hasInternetConnection();
    print('Internet Connection: ${hasInternet ? "✅ Available" : "❌ Not Available"}');
    
    if (!hasInternet) {
      return ConnectivityStatus(
        hasInternet: false,
        isApiReachable: false,
        message: 'No internet connection. Please check your network settings.',
      );
    }

    // Check API server
    final isApiReachable = await isApiServerReachable();
    print('API Server: ${isApiReachable ? "✅ Reachable" : "❌ Not Reachable"}');
    
    if (!isApiReachable) {
      return ConnectivityStatus(
        hasInternet: true,
        isApiReachable: false,
        message: 'Cannot connect to AnwarFood servers. Please try again later.',
      );
    }

    print('✅ All connectivity checks passed');
    return ConnectivityStatus(
      hasInternet: true,
      isApiReachable: true,
      message: 'Connected successfully',
    );
  }

  // Test specific endpoint
  static Future<bool> testEndpoint(String endpoint) async {
    try {
      print('Testing endpoint: $baseUrl$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      print('Endpoint test result: ${response.statusCode}');
      return response.statusCode < 500; // Accept 4xx errors as "reachable"
    } catch (e) {
      print('Endpoint test failed: $e');
      return false;
    }
  }
}

class ConnectivityStatus {
  final bool hasInternet;
  final bool isApiReachable;
  final String message;

  ConnectivityStatus({
    required this.hasInternet,
    required this.isApiReachable,
    required this.message,
  });

  bool get isFullyConnected => hasInternet && isApiReachable;
} 