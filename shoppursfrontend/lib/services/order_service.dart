import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;

class OrderService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getOrders() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/details/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> adminGetOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/get-order-details/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> adminUpdateOrderStatus(int orderId, String status, {String? notes}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/edit-order-status/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'orderNotes': notes ?? '',
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/cancel/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminOrders(String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/fetch-all-orders?status=$status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch admin orders');
      }
    } catch (e) {
      throw Exception('Error fetching admin orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> adminSearchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/search-orders?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getEmployeeOrders() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/employee/orders?status=confirmed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch employee orders');
      }
    } catch (e) {
      throw Exception('Error fetching employee orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> employeeSearchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/employee/orders/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']['orders']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> employeeGetOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/employee/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> employeeUpdateOrderStatus(int orderId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/api/employee/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> employeeUpdateOrderStatusWithLocation(int orderId, String status, double? lat, double? long) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final requestBody = <String, dynamic>{
        'status': status,
      };

      // Add location if available
      if (lat != null && long != null) {
        requestBody['lat'] = lat;
        requestBody['long'] = long;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/employee/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> employeeUpdateOrderStatusWithImage(int orderId, String status, dynamic paymentImage, {double? lat, double? long}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/employee/orders/$orderId/status'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['status'] = status;
      
      // Add location fields if available
      if (lat != null && long != null) {
        request.fields['lat'] = lat.toString();
        request.fields['long'] = long.toString();
      }

      // Add the payment image with proper MIME type
      if (paymentImage != null) {
        http.MultipartFile multipartFile;
        
        if (paymentImage is XFile) {
          // For web
          final bytes = await paymentImage.readAsBytes();
          final fileName = paymentImage.name.isNotEmpty ? paymentImage.name : 'payment_image.jpg';
          
          multipartFile = http.MultipartFile.fromBytes(
            'paymentImage',
            bytes,
            filename: fileName,
            contentType: MediaType('image', _getImageExtension(fileName)),
          );
        } else if (paymentImage is File) {
          // For mobile
          final fileName = paymentImage.path.split('/').last;
          final extension = _getImageExtension(fileName);
          
          multipartFile = await http.MultipartFile.fromPath(
            'paymentImage',
            paymentImage.path,
            filename: fileName,
            contentType: MediaType('image', extension),
          );
        } else {
          throw Exception('Invalid image format');
        }
        
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  String _getImageExtension(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default to jpeg
    }
  }
} 