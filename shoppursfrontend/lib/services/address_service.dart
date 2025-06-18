import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import 'auth_service.dart';

class AddressService {
  static const String baseUrl = 'http://192.168.29.96:3000';
  final AuthService _authService = AuthService();

  Future<List<Address>> getAddresses() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('http://192.168.29.96:3000/api/address/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> addressesJson = data['data'];
        return addressesJson.map((json) => Address.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load addresses');
      }
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  Future<Map<String, dynamic>> addAddress({
    required String address,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String addressType,
    required bool isDefault,
    String? landmark,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('http://192.168.29.96:3000/api/address/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'address': address,
          'city': city,
          'state': state,
          'country': country,
          'pincode': pincode,
          'addressType': addressType,
          'isDefault': isDefault,
          'lat': latitude,
          'long': longitude,
          if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<Map<String, dynamic>> editAddress({
    required int addressId,
    required String address,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String addressType,
    required bool isDefault,
    String? landmark,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('http://192.168.29.96:3000/api/address/edit/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'address': address,
          'city': city,
          'state': state,
          'country': country,
          'pincode': pincode,
          'addressType': addressType,
          'isDefault': isDefault,
          'lat': latitude,
          'long': longitude,
          if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to edit address');
      }
    } catch (e) {
      throw Exception('Failed to edit address: $e');
    }
  }

  Future<Address?> getDefaultAddress() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse('http://192.168.29.96:3000/api/address/default'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      return Address.fromJson(data['data']);
    }
    return null;
  }
} 