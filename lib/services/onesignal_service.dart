import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/onesignal_config.dart';
import 'supabase_service.dart';

/// OneSignal Service
/// 
/// Handles push notification initialization, subscription, and notification handling.
/// This service manages:
/// - OneSignal SDK initialization
/// - User subscription and device token management
/// - Notification received/opened handlers
/// - Integration with Supabase for storing player IDs
class OneSignalService {
  static OneSignalService? _instance;
  static OneSignalService get instance => _instance ??= OneSignalService._();
  
  OneSignalService._();
  
  bool _initialized = false;
  String? _playerId;
  
  /// Check if OneSignal is initialized
  bool get isInitialized => _initialized;
  
  /// Get the current player ID (device token)
  String? get playerId => _playerId;
  
  /// Initialize OneSignal SDK
  /// 
  /// This should be called early in the app lifecycle, typically in main().
  /// It sets up notification handlers and requests permission for notifications.
  static Future<void> initialize() async {
    if (!OneSignalConfig.isConfigured) {
      debugPrint('OneSignal: App ID not configured. Skipping initialization.');
      return;
    }
    
    try {
      final service = instance;
      
      // Set App ID
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(OneSignalConfig.appId);
      
      // Request permission for notifications
      OneSignal.Notifications.requestPermission(true);
      
      // Set up notification handlers
      _setupNotificationHandlers();
      
      // Get initial player ID
      await service._getPlayerId();
      
      service._initialized = true;
      debugPrint('OneSignal: Initialized successfully');
    } catch (e) {
      debugPrint('OneSignal: Initialization failed: $e');
    }
  }
  
  /// Set up notification event handlers
  static void _setupNotificationHandlers() {
    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('OneSignal: Notification received in foreground: ${event.notification.notificationId}');
      // You can modify the notification here before it's displayed
      // event.notification.additionalData = {'custom_key': 'custom_value'};
    });
    
    // Handle notification clicked/opened
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('OneSignal: Notification clicked: ${event.notification.notificationId}');
      final notification = event.notification;
      
      // Handle notification data
      if (notification.additionalData != null) {
        debugPrint('OneSignal: Additional data: ${notification.additionalData}');
        // You can navigate to specific screens based on notification data here
        _handleNotificationData(notification.additionalData);
      }
    });
  }
  
  /// Handle notification data and navigate accordingly
  static void _handleNotificationData(Map<String, dynamic>? data) {
    if (data == null) return;
    
    // Example: Handle different notification types
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    
    if (type != null) {
      debugPrint('OneSignal: Handling notification type: $type, id: $id');
      // You can add navigation logic here based on notification type
      // For example:
      // if (type == 'chat') {
      //   // Navigate to chat screen
      // } else if (type == 'will') {
      //   // Navigate to will screen
      // }
    }
  }
  
  /// Get the current player ID (device token)
  Future<void> _getPlayerId() async {
    try {
      final deviceState = await OneSignal.User.pushSubscription.id;
      if (deviceState != null) {
        _playerId = deviceState;
        debugPrint('OneSignal: Player ID: $_playerId');
        
        // Store player ID in Supabase if user is authenticated
        await _storePlayerIdInSupabase(_playerId!);
      }
    } catch (e) {
      debugPrint('OneSignal: Failed to get player ID: $e');
    }
  }
  
  /// Store player ID in Supabase for the current user
  Future<void> _storePlayerIdInSupabase(String playerId) async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        debugPrint('OneSignal: User not authenticated, skipping player ID storage');
        return;
      }
      
      // Update accounts table with player ID
      // Using upsert to handle cases where account doesn't exist yet
      await SupabaseService.instance.client
          .from('accounts')
          .upsert({
            'uuid': user.id,
            'onesignal_player_id': playerId,
          }, onConflict: 'uuid');
      
      debugPrint('OneSignal: Player ID stored in accounts table for user ${user.id}');
    } catch (e) {
      debugPrint('OneSignal: Failed to store player ID in Supabase: $e');
    }
  }
  
  /// Set user ID for OneSignal (for targeting specific users)
  /// 
  /// This associates the OneSignal player with a user ID from your system.
  /// Useful for sending targeted notifications to specific users.
  Future<void> setUserId(String userId) async {
    try {
      await OneSignal.User.addAlias('user_id', userId);
      debugPrint('OneSignal: User ID set: $userId');
    } catch (e) {
      debugPrint('OneSignal: Failed to set user ID: $e');
    }
  }
  
  /// Clear user ID (on logout)
  Future<void> clearUserId() async {
    try {
      await OneSignal.User.removeAlias('user_id');
      debugPrint('OneSignal: User ID cleared');
    } catch (e) {
      debugPrint('OneSignal: Failed to clear user ID: $e');
    }
  }
  
  /// Set user tags for segmentation
  /// 
  /// Tags allow you to segment users and send targeted notifications.
  /// Example: setTags({'subscription_type': 'premium', 'language': 'en'})
  Future<void> setTags(Map<String, String> tags) async {
    try {
      await OneSignal.User.addTags(tags);
      debugPrint('OneSignal: Tags set: $tags');
    } catch (e) {
      debugPrint('OneSignal: Failed to set tags: $e');
    }
  }
  
  /// Remove user tags
  Future<void> removeTags(List<String> tagKeys) async {
    try {
      await OneSignal.User.removeTags(tagKeys);
      debugPrint('OneSignal: Tags removed: $tagKeys');
    } catch (e) {
      debugPrint('OneSignal: Failed to remove tags: $e');
    }
  }
  
  /// Send a test notification (for development)
  /// 
  /// Note: This requires OneSignal REST API access. For production,
  /// use the OneSignal dashboard or your backend to send notifications.
  Future<void> sendTestNotification() async {
    if (_playerId == null) {
      debugPrint('OneSignal: Player ID not available');
      return;
    }
    
    debugPrint('OneSignal: Test notification would be sent to: $_playerId');
    debugPrint('OneSignal: Use OneSignal dashboard or REST API to send notifications');
  }
  
  /// Get current subscription status
  Future<bool> isSubscribed() async {
    try {
      final subscription = await OneSignal.User.pushSubscription.optedIn;
      return subscription ?? false;
    } catch (e) {
      debugPrint('OneSignal: Failed to get subscription status: $e');
      return false;
    }
  }
  
  /// Opt in to push notifications
  Future<void> optIn() async {
    try {
      await OneSignal.User.pushSubscription.optIn();
      await _getPlayerId();
      debugPrint('OneSignal: User opted in to notifications');
    } catch (e) {
      debugPrint('OneSignal: Failed to opt in: $e');
    }
  }
  
  /// Opt out of push notifications
  Future<void> optOut() async {
    try {
      await OneSignal.User.pushSubscription.optOut();
      debugPrint('OneSignal: User opted out of notifications');
    } catch (e) {
      debugPrint('OneSignal: Failed to opt out: $e');
    }
  }
}
