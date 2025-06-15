import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import 'auth_service.dart';
import 'http_client.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getCategories({BuildContext? context}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to continue',
        };
      }

      final result = await HttpClient.get(
        '/api/categories/list',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> categoriesJson = result['data'];
        final categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
        return {
          'success': true,
          'data': categories,
          'message': 'Categories loaded successfully',
        };
      } else {
        return result; // Error already handled by ErrorHandler
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load categories. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getSubCategories(
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
        '/api/categories/$categoryId/subcategories',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] is List) {
        final subcategories = List<Map<String, dynamic>>.from(result['data'].map((x) => {
          'id': x['SUB_CATEGORY_ID'],
          'name': x['SUB_CATEGORY_NAME'],
          'catId': x['SUB_CATEGORY_CAT_ID'],
          'image': x['SUB_CAT_IMAGE'],
        }));
        return {
          'success': true,
          'data': subcategories,
          'message': 'Subcategories loaded successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load subcategories. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getSubCategoriesByCategoryId(
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
        '/api/categories/$categoryId/subcategories',
        token: token,
        context: context,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> subCategoriesJson = result['data'];
        final subcategories = subCategoriesJson.map((json) => SubCategory.fromJson(json)).toList();
        return {
          'success': true,
          'data': subcategories,
          'message': 'Subcategories loaded successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to load subcategories. Please try again.',
      };
    }
  }
} 