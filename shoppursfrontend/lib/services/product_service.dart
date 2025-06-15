import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';

class ProductService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getProductsByCategory(
    int categoryId, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.get(
        '/api/products/category/$categoryId',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> productsJson = result['data'];
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        return {
          'success': true,
          'data': products,
          'message': 'Products loaded successfully',
        };
      } else {
        return result; // Error already handled by ErrorHandler
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load products. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getProductsBySubCategory(
    int subCategoryId, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.get(
        '/api/products/subcategory/$subCategoryId',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> productsJson = result['data'];
        final products = productsJson.map((json) => Product.fromJson(json)).toList();
        return {
          'success': true,
          'data': products,
          'message': 'Products loaded successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load products. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getProductDetails(
    int productId, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.get(
        '/api/products/details/$productId',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] != null) {
        final product = Product.fromJson(result['data']);
        return {
          'success': true,
          'data': product,
          'message': 'Product details loaded successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load product details. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> searchProducts(
    String query, {
    int? subcategoryId,
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      String endpoint = '/api/products/search?query=$query';
      if (subcategoryId != null) {
        endpoint += '&subcategoryId=$subcategoryId';
      }

      final result = await HttpClient.get(
        endpoint,
        token: token,
        context: context,
      );

      if (result['success'] == true) {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(result['data'] ?? []),
          'message': 'Search completed successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Search failed. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    int productId,
    Map<String, dynamic> productData, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.put(
        '/api/admin/edit-product/$productId',
        token: token,
        body: productData,
        context: context,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update product. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> productData, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.post(
        '/api/admin/add-product',
        token: token,
        body: productData,
        context: context,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add product. Please try again.',
      };
    }
  }

  // Legacy method kept for compatibility with multipart file uploads
  Future<Map<String, dynamic>> addProductWithImages(
    Map<String, dynamic> productData, 
    Map<String, File> files, {
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${HttpClient.baseUrl}/api/admin/add-product'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add image files with proper content type
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        // Get file extension
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Determine content type based on file extension
        String contentType = 'image/jpeg'; // default
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
        
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );
        
        request.files.add(multipartFile);
      }

      print('Sending multipart request with fields: ${request.fields.keys.toList()}');
      print('Sending files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})').toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
          'message': 'Product added successfully with images',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add product with images',
        };
      }
    } catch (e) {
      print('Error in addProductWithImages: $e');
      return {
        'success': false,
        'message': 'Failed to add product with images. Please try again.',
      };
    }
  }

  // Method for updating product with images
  Future<Map<String, dynamic>> updateProductWithImages(
    int productId,
    Map<String, dynamic> productData, 
    Map<String, File> files, {
    List<int>? removeImages,
    BuildContext? context,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${HttpClient.baseUrl}/api/admin/edit-product/$productId'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add images to remove if any
      if (removeImages != null && removeImages.isNotEmpty) {
        request.fields['removeImages'] = jsonEncode(removeImages);
      }

      // Add image files with proper content type
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        // Get file extension
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Determine content type based on file extension
        String contentType = 'image/jpeg'; // default
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
        
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );
        
        request.files.add(multipartFile);
      }

      print('Updating product $productId with fields: ${request.fields.keys.toList()}');
      print('Sending files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})').toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
          'message': 'Product updated successfully with images',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product with images',
        };
      }
    } catch (e) {
      print('Error in updateProductWithImages: $e');
      return {
        'success': false,
        'message': 'Failed to update product with images. Please try again.',
      };
    }
  }
} 