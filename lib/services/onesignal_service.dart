import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/onesignal_config.dart';
import '../models/app_notification.dart';
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

  static const String _notificationsStorageKey = 'in_app_notifications';
  static const int _maxStoredNotifications = 50;

  bool _initialized = false;
  String? _playerId;
  final List<AppNotification> _notifications = <AppNotification>[];
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  
  /// Check if OneSignal is initialized
  bool get isInitialized => _initialized;
  
  /// Get the current player ID (device token)
  String? get playerId => _playerId;

  /// Current in-app notification list (most recent first).
  List<AppNotification> get notifications =>
      List<AppNotification>.unmodifiable(_notifications);

  /// Stream of notifications to allow UI to react to changes.
  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;
  
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

      // Load any previously stored notifications
      await service._loadStoredNotifications();
      
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
      // Store as unread notification for in-app history
      instance._captureNotification(event.notification, markAsRead: false);
    });
    
    // Handle notification clicked/opened
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('OneSignal: Notification clicked: ${event.notification.notificationId}');
      final notification = event.notification;

      // Store as read notification in history (or mark existing as read)
      instance._captureNotification(notification, markAsRead: true);
      
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

  Future<void> _loadStoredNotifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String raw = prefs.getString(_notificationsStorageKey) ?? '';
      final List<AppNotification> stored = AppNotification.decodeList(raw);
      _notifications
        ..clear()
        ..addAll(stored);
      _emitNotifications();
    } catch (e) {
      debugPrint('OneSignal: Failed to load stored notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _notificationsStorageKey,
        AppNotification.encodeList(_notifications),
      );
    } catch (e) {
      debugPrint('OneSignal: Failed to save notifications: $e');
    }
  }

  void _emitNotifications() {
    if (_notificationsController.isClosed) return;
    _notificationsController.add(List<AppNotification>.unmodifiable(_notifications));
  }

  /// Capture a notification from OneSignal and store it locally for the
  /// in-app notifications list.
  void _captureNotification(
    OSNotification notification, {
    required bool markAsRead,
  }) {
    try {
      final String id = notification.notificationId;
      final String title = notification.title ?? '';
      final String body = notification.body ?? '';
      // SDK does not expose a sent time field directly; use "now" as
      // a reasonable approximation for when the device received it.
      final DateTime receivedAt = DateTime.now().toLocal();
      final Map<String, dynamic>? data =
          notification.additionalData?.cast<String, dynamic>();

      // If we already have this notification, just update read status.
      final int existingIndex =
          _notifications.indexWhere((n) => n.id == id && n.body == body);
      if (existingIndex != -1) {
        final existing = _notifications[existingIndex];
        final updated = existing.copyWith(
          isRead: existing.isRead || markAsRead,
        );
        _notifications[existingIndex] = updated;
      } else {
        final AppNotification item = AppNotification(
          id: id,
          title: title,
          body: body,
          receivedAt: receivedAt,
          isRead: markAsRead,
          data: data,
        );

        _notifications.insert(0, item);
        if (_notifications.length > _maxStoredNotifications) {
          _notifications.removeRange(
              _maxStoredNotifications, _notifications.length);
        }
      }

      _emitNotifications();
      // Persist in background (no need to await)
      _saveNotifications();
    } catch (e) {
      debugPrint('OneSignal: Failed to capture notification: $e');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (n.id == id && !n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
        changed = true;
      }
    }
    if (!changed) return;
    _emitNotifications();
    await _saveNotifications();
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (!n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
        changed = true;
      }
    }
    if (!changed) return;
    _emitNotifications();
    await _saveNotifications();
  }

  /// Clear the in-app notification history.
  Future<void> clearAllNotifications() async {
    if (_notifications.isEmpty) return;
    _notifications.clear();
    _emitNotifications();
    await _saveNotifications();
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
