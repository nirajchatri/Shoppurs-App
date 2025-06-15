import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class SettingsService {
  final storage = SecureStorage();

  Future<Map<String, dynamic>> getAppSupport() async {
    final token = await storage.getToken();
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/settings/app-support'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load support details');
    }
  }

  Future<String> getAppName() async {
    final token = await storage.getToken();
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/settings/app-name'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['app_name'];
    } else {
      throw Exception('Failed to load app name');
    }
  }

  Future<Map<String, dynamic>> getBankDetails() async {
    final token = await storage.getToken();
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/settings/app-bank-details'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load bank details');
    }
  }
} 