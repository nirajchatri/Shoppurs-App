import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';  // Temporarily disabled for iOS build
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;  // Temporarily disabled for iOS build
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  static BuildContext? _context;

  // Initialize FCM - Temporarily disabled for iOS build
  static Future<void> initialize() async {
    try {
      print('🔥 Notification Service: Local notifications only (Firebase disabled for iOS build)');
      
      // Initialize local notifications only
      await _initializeLocalNotifications();
      
      print('🔥 Local notifications initialized successfully');
    } catch (e) {
      print('🔥 Notification initialization failed: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔥 Local notification tapped: ${response.payload}');
      },
    );
  }

  // Stub method for getting FCM token
  static Future<String?> getFCMToken() async {
    print('🔥 FCM Token: Disabled for iOS build');
    return null;
  }

  // Getter for fcmToken (stub for iOS build)
  static String? get fcmToken => null;

  // Stub method for setting context
  static void setContext(BuildContext context) {
    _context = context;
  }

  // Show a simple local notification (can be used without Firebase)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // All other Firebase-related methods are disabled for iOS build
  // Stub implementations to prevent compilation errors
  
  static void setupMessageHandlers() {
    print('🔥 Message handlers: Disabled for iOS build');
  }
  
  static Future<void> requestNotificationPermission() async {
    print('🔥 Notification permission: Local only for iOS build');
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    print('🔥 Topic subscription: Disabled for iOS build');
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    print('🔥 Topic unsubscription: Disabled for iOS build');
  }
} 