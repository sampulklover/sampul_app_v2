/// OneSignal Configuration
/// 
/// This file contains all OneSignal-related configuration.
/// To update the App ID, modify the value below or use environment variables.
/// 
/// For production, consider using environment variables or a secure configuration.
library;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneSignalConfig {
  // ========================================
  // ONESIGNAL APP CONFIGURATION
  // ========================================
  // For production, read from environment variables loaded via flutter_dotenv
  // Get your App ID from https://onesignal.com/apps
  static String get appId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Check if OneSignal is properly configured
  static bool get isConfigured => appId.isNotEmpty;
}
