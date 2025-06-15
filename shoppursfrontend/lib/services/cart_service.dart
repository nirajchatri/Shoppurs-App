import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
    required int unitId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse(ApiConfig.cartAdd),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
          'unitId': unitId,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Future<Map<String, dynamic>> getCartCount() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse(ApiConfig.cartCount),
        headers: ApiConfig.getAuthHeaders(token),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get cart count');
      }
    } catch (e) {
      throw Exception('Error getting cart count: $e');
    }
  }
} 