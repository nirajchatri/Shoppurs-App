import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({Key? key}) : super(key: key);

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Initialize notification service and get FCM token
    try {
      await NotificationService.initialize();
      final fcmToken = NotificationService.fcmToken;
      print('🔥 FCM Token in StartupPage: $fcmToken');
    } catch (e) {
      print('🔥 Error initializing notifications: $e');
    }
    
    final token = await _authService.getToken();
    final isOnboardingCompleted = await _authService.isOnboardingCompleted();
    
    if (token != null && token.isNotEmpty) {
      // User has a valid token, go to home
      Navigator.pushReplacementNamed(context, '/home');
    } else if (isOnboardingCompleted) {
      // User has completed onboarding but no token, go to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // First time user, show onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
} 