import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  static BuildContext? _context;

  // Initialize FCM
  static Future<void> initialize() async {
    try {
      print('🔥 Firebase Messaging: Initializing...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔥 Firebase Messaging: Permission granted: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔥 Firebase Messaging: User granted permission');
        print('✅ NOTIFICATIONS ENABLED - You can now receive push notifications!');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('🔥 Firebase Messaging: User granted provisional permission');
        print('⚠️  NOTIFICATIONS PROVISIONAL - Limited notification access');
      } else {
        print('🔥 Firebase Messaging: User declined or has not accepted permission');
        print('❌ NOTIFICATIONS DISABLED - Please enable notifications in device settings');
      }

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      print('🔥 Firebase Messaging: Initialization complete');
      print('=' * 80);
    } catch (e) {
      print('🔥 Firebase Messaging Error: Failed to initialize - $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('🔥 Local notification tapped: ${response.payload}');
          _handleLocalNotificationTap(response.payload);
        },
      );
      
      print('🔥 Local notifications initialized');
    } catch (e) {
      print('🔥 Local notifications error: $e');
    }
  }

  // Set context for showing in-app notifications
  static void setContext(BuildContext context) {
    _context = context;
  }

  // Handle local notification tap
  static void _handleLocalNotificationTap(String? payload) {
    print('🔥 Local notification tapped with payload: $payload');
    // Handle navigation or actions based on payload
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationData(data);
      } catch (e) {
        print('🔥 Error parsing notification payload: $e');
      }
    }
  }

  // Handle notification data for navigation
  static void _handleNotificationData(Map<String, dynamic> data) {
    print('🔥 Handling notification data: $data');
    
    if (data.containsKey('screen') && _context != null) {
      String screen = data['screen'];
      switch (screen) {
        case 'orders':
          Navigator.pushNamed(_context!, '/orders');
          break;
        case 'products':
          Navigator.pushNamed(_context!, '/product-list');
          break;
        case 'notifications':
          Navigator.pushNamed(_context!, '/notifications');
          break;
        case 'cart':
          Navigator.pushNamed(_context!, '/cart');
          break;
        default:
          print('🔥 Unknown screen: $screen');
      }
    }
  }

  // Get FCM Token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        print('=' * 80);
        print('📱 FCM TOKEN FOR TESTING:');
        print('=' * 80);
        print(_fcmToken);
        print('=' * 80);
        print('💡 COPY THE TOKEN ABOVE TO SEND TEST NOTIFICATIONS');
        print('🔗 Use Firebase Console or your backend to send notifications');
        print('=' * 80);
        
        // Optional: Copy to clipboard for easy access
        if (!kIsWeb) {
          try {
            Clipboard.setData(ClipboardData(text: _fcmToken!));
            print('📋 FCM Token copied to clipboard automatically!');
          } catch (e) {
            print('📋 Could not copy to clipboard: $e');
          }
        }
      } else {
        print('🔥 FCM Token: Failed to get token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // TODO: Send the new token to your server
      });
    } catch (e) {
      print('🔥 FCM Token Error: $e');
    }
  }

  // Setup message handlers
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔥 Foreground Message: ${message.notification?.title}');
      print('🔥 Foreground Message Body: ${message.notification?.body}');
      print('🔥 Foreground Message Data: ${message.data}');
      
      // Show notification dialog or snackbar when app is active
      _showForegroundNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔥 Background Message Tapped: ${message.notification?.title}');
      print('🔥 Background Message Data: ${message.data}');
      
      // Navigate to specific screen based on notification data
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔥 Terminated Message: ${message.notification?.title}');
        print('🔥 Terminated Message Data: ${message.data}');
        
        // Navigate to specific screen based on notification data
        _handleNotificationTap(message);
      }
    });
  }

  // Show notification when app is in foreground
  static void _showForegroundNotification(RemoteMessage message) {
    print('🔥 Showing foreground notification: ${message.notification?.title}');
    
    // Show local notification only (system tray)
    _showLocalNotification(message);
    
    // Note: In-app snackbar removed as requested
    print('🔥 Foreground notification displayed in system tray only');
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'Default notification channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF9B1B1B),
      );
      
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      final String payload = jsonEncode(message.data);
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? 'You have a new message',
        notificationDetails,
        payload: payload,
      );
      
      print('🔥 Local notification displayed');
    } catch (e) {
      print('🔥 Error showing local notification: $e');
    }
  }

  // Show in-app notification (dialog or snackbar)
  static void _showInAppNotification(RemoteMessage message) {
    if (_context == null) {
      print('🔥 Context not available for in-app notification');
      return;
    }
    
    try {
      // Show as a snackbar (less intrusive)
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'New Notification',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (message.notification?.body != null)
                Text(
                  message.notification!.body!,
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF9B1B1B),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              _handleNotificationData(message.data);
            },
          ),
        ),
      );
      
      print('🔥 In-app notification displayed');
    } catch (e) {
      print('🔥 Error showing in-app notification: $e');
      
      // Fallback: Show as dialog
      _showNotificationDialog(message);
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔥 Handling notification tap: ${message.data}');
    
    // Example: Navigate based on notification data
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      switch (screen) {
        case 'orders':
          // Navigate to orders page
          print('🔥 Navigating to orders');
          break;
        case 'products':
          // Navigate to products page
          print('🔥 Navigating to products');
          break;
        case 'notifications':
          // Navigate to notifications page
          print('🔥 Navigating to notifications');
          break;
        default:
          print('🔥 Unknown screen: $screen');
      }
    }
  }

  // Get current FCM token
  static String? get fcmToken => _fcmToken;

  // Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('🔥 Subscribed to topic: $topic');
    } catch (e) {
      print('🔥 Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('🔥 Unsubscribed from topic: $topic');
    } catch (e) {
      print('🔥 Error unsubscribing from topic $topic: $e');
    }
  }

  // Show notification dialog in foreground
  static void _showNotificationDialog(RemoteMessage message) {
    if (_context == null) {
      print('🔥 Context not available for notification dialog');
      return;
    }
    
    try {
      showDialog(
        context: _context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications, color: Color(0xFF9B1B1B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.notification?.title ?? 'New Notification',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.notification?.body != null)
                  Text(
                    message.notification!.body!,
                    style: const TextStyle(fontSize: 14),
                  ),
                if (message.data.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Additional Data:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    message.data.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
              if (message.data.containsKey('screen'))
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleNotificationData(message.data);
                  },
                  child: const Text('Open'),
                ),
            ],
          );
        },
      );
      
      print('🔥 Notification dialog displayed');
    } catch (e) {
      print('🔥 Error showing notification dialog: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('🔥 All notifications cleared');
    } catch (e) {
      print('🔥 Error clearing notifications: $e');
    }
  }

  // Test notification (for debugging)
  static Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'test_channel',
        'Test Channel',
        channelDescription: 'Test notification channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF9B1B1B),
      );
      
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Test Notification',
        'This is a test notification to verify foreground notifications work!',
        notificationDetails,
        payload: jsonEncode({'screen': 'notifications', 'type': 'test'}),
      );
      
      print('🔥 Test notification sent');
    } catch (e) {
      print('🔥 Error showing test notification: $e');
    }
  }
} 