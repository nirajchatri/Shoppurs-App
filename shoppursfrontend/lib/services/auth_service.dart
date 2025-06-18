import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'http_client.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'onboarding_completed';

  Future<Map<String, dynamic>> login(
    String phone, 
    String password, {
    BuildContext? context,
  }) async {
    try {
      final result = await HttpClient.post(
        '/api/auth/login',
        body: {
          'phone': phone,
          'password': password,
        },
        context: context,
      );

      // Check if the result contains success flag
      if (result['success'] == true || result.containsKey('token')) {
        if (result['token'] != null) {
          // Store token in both secure storage and shared preferences
          await _storage.write(key: 'token', value: result['token']);
          await _saveToken(result['token']);
          
          // Store user data if available
          if (result['user'] != null) {
            await _saveUser(User.fromJson(result['user']));
          }
        }
        return {
          'success': true,
          'message': 'Login successful',
          ...result,
        };
      } else {
        return result; // Error handled by ErrorHandler
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
      };
    }
  }

  // Password Reset Methods
  Future<Map<String, dynamic>> requestPasswordReset(
    String phone, {
    BuildContext? context,
  }) async {
    try {
      return await HttpClient.post(
        '/api/auth/request-password-reset',
        body: {'phone': phone},
        context: context,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to process password reset request. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp(
    String phone, {
    BuildContext? context,
  }) async {
    try {
      return await HttpClient.post(
        '/api/auth/resend-otp',
        body: {'phone': phone},
        context: context,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to resend OTP. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> confirmOtpForPassword(
    String phone, 
    String verificationCode, 
    String otp, {
    BuildContext? context,
  }) async {
    try {
      return await HttpClient.post(
        '/api/auth/confirm-otp-for-password',
        body: {
          'phone': phone,
          'verification_code': verificationCode,
          'otp': otp,
        },
        context: context,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'OTP verification failed. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithPhone(
    String phone, 
    String password, {
    BuildContext? context,
  }) async {
    try {
      return await HttpClient.post(
        '/api/auth/reset-password-with-phone',
        body: {
          'phone': phone,
          'password': password,
        },
        context: context,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Password reset failed. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> signup(
    Map<String, dynamic> userData, {
    BuildContext? context,
  }) async {
    try {
      final result = await HttpClient.post(
        '/api/auth/signup',
        body: userData,
        context: context,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Signup failed. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp, {
    BuildContext? context,
  }) async {
    try {
      final result = await HttpClient.post(
        '/api/auth/verify-otp',
        body: {
          'phone': phone,
          'otp': otp,
        },
        context: context,
      );

      // Handle successful verification
      if (result['success'] == true || result.containsKey('token')) {
        if (result['token'] != null) {
          await _storage.write(key: 'token', value: result['token']);
          await _saveToken(result['token']);
          
          if (result['user'] != null) {
            await _saveUser(User.fromJson(result['user']));
          }
        }
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'OTP verification failed. Please try again.',
      };
    }
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<String?> getToken() async {
    // First try to get from secure storage
    final secureToken = await _storage.read(key: 'token');
    if (secureToken != null) {
      return secureToken;
    }
    
    // Fallback to shared preferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all stored data
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await _storage.delete(key: 'token');
    // Clear all other stored data if any
    await prefs.clear();
  }

  // Onboarding methods
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Update user data in local storage
  Future<void> updateUserData({String? username}) async {
    final currentUser = await getUser();
    if (currentUser != null) {
      final updatedUser = User(
        id: currentUser.id,
        username: username ?? currentUser.username,
        email: currentUser.email,
        mobile: currentUser.mobile,
        role: currentUser.role,
      );
      await _saveUser(updatedUser);
    }
  }

  // Clear all cached data including any localhost references
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _storage.deleteAll();
    print('All cached data cleared');
  }

  // Private helper methods
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
} 