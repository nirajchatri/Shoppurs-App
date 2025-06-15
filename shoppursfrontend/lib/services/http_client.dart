import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'error_handler.dart';

class HttpClient {
  static const String baseUrl = 'http://192.168.29.96:3000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static http.Client _client = http.Client();
  static BuildContext? _context;

  // Configure HTTP client for mobile
  static void configureClient() {
    _client = http.Client();
  }

  // Set context for error handling
  static void setContext(BuildContext context) {
    _context = context;
    ErrorHandler.setContext(context);
  }

  // GET request with proper error handling
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    BuildContext? context,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making GET request to: $uri');
    
    try {
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Use ErrorHandler to process response
      return ErrorHandler.handleHttpResponse(
        response,
        endpoint,
        context: context ?? _context,
      );
    } catch (error) {
      print('Error in GET request: $error');
      
      // Use ErrorHandler to handle network errors
      return await ErrorHandler.handleNetworkError(
        error,
        endpoint,
        context: context ?? _context,
      );
    }
  }

  // POST request with proper error handling
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    BuildContext? context,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making POST request to: $uri');
    if (body != null) {
      print('Request body: ${jsonEncode(body)}');
    }
    
    try {
      final response = await _client
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Use ErrorHandler to process response
      return ErrorHandler.handleHttpResponse(
        response,
        endpoint,
        context: context ?? _context,
      );
    } catch (error) {
      print('Error in POST request: $error');
      
      // Use ErrorHandler to handle network errors
      return await ErrorHandler.handleNetworkError(
        error,
        endpoint,
        context: context ?? _context,
      );
    }
  }

  // PUT request with proper error handling
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    BuildContext? context,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making PUT request to: $uri');
    
    try {
      final response = await _client
          .put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Use ErrorHandler to process response
      return ErrorHandler.handleHttpResponse(
        response,
        endpoint,
        context: context ?? _context,
      );
    } catch (error) {
      print('Error in PUT request: $error');
      
      // Use ErrorHandler to handle network errors
      return await ErrorHandler.handleNetworkError(
        error,
        endpoint,
        context: context ?? _context,
      );
    }
  }

  // DELETE request with proper error handling
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    BuildContext? context,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making DELETE request to: $uri');
    
    try {
      final response = await _client
          .delete(uri, headers: requestHeaders)
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Use ErrorHandler to process response
      return ErrorHandler.handleHttpResponse(
        response,
        endpoint,
        context: context ?? _context,
      );
    } catch (error) {
      print('Error in DELETE request: $error');
      
      // Use ErrorHandler to handle network errors
      return await ErrorHandler.handleNetworkError(
        error,
        endpoint,
        context: context ?? _context,
      );
    }
  }

  // Close the client
  static void close() {
    _client.close();
  }
} 