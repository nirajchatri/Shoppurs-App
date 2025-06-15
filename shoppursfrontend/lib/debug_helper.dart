import 'services/auth_service.dart';
import 'config/api_config.dart';

class DebugHelper {
  static void logAllServiceUrls() {
    print('=== SERVICE URL VERIFICATION ===');
    print('API Config Base URL: ${ApiConfig.baseUrl}');
    print('Environment: ${ApiConfig.environmentName}');
    print('All services now use centralized ApiConfig');
    print('================================');
    
    // Print API configuration
    ApiConfig.printApiInfo();
  }

  static void clearAllAppData() async {
    final authService = AuthService();
    await authService.clearAllCache();
    print('All app data cleared!');
  }
} 