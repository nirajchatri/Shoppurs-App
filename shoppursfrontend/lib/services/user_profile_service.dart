import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import 'auth_service.dart';

class UserProfileService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']['profile'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    File? profilePhoto,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.baseUrl}/api/users/update-profile'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add username field
      request.fields['username'] = username;

      // Add profile photo if provided
      if (profilePhoto != null) {
        // Validate file extension
        final extension = path.extension(profilePhoto.path).toLowerCase();
        final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        
        if (!allowedExtensions.contains(extension)) {
          throw Exception('Only image files (JPG, PNG, GIF, WEBP) are allowed');
        }

        // Check file size (limit to 5MB)
        final fileSize = await profilePhoto.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
        if (fileSize > maxSizeInBytes) {
          throw Exception('Image file size must be less than 5MB');
        }

        // Get proper content type based on extension
        String contentType;
        switch (extension) {
          case '.jpg':
          case '.jpeg':
            contentType = 'image/jpeg';
            break;
          case '.png':
            contentType = 'image/png';
            break;
          case '.gif':
            contentType = 'image/gif';
            break;
          case '.webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }

        // Create multipart file with proper content type
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePhoto',
            profilePhoto.path,
            contentType: http_parser.MediaType.parse(contentType),
          ),
        );
      }

      print('=== PROFILE UPDATE REQUEST ===');
      print('URL: ${request.url}');
      print('Method: ${request.method}');
      print('Headers: ${request.headers}');
      print('Fields: ${request.fields}');
      if (request.files.isNotEmpty) {
        for (var file in request.files) {
          print('File field: ${file.field}');
          print('File filename: ${file.filename}');
          print('File contentType: ${file.contentType}');
          print('File length: ${file.length}');
        }
      }
      print('===============================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('=== PROFILE UPDATE RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('===============================');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        // Include more detailed error information
        final errorMessage = data['message'] ?? 'Failed to update profile';
        print('Update profile error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
} 