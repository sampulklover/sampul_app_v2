import 'package:flutter/foundation.dart';

import '../models/remote_notification.dart';
import 'supabase_service.dart';

/// Service for working with backend-stored notifications.
///
/// This assumes a Supabase table `notifications` with columns:
/// - id (primary key, text/uuid/bigint)
/// - user_id (uuid, references auth.users.id)
/// - title (text)
/// - body (text)
/// - type (text, optional)
/// - data (jsonb, optional)
/// - created_at (timestamptz, default now())
/// - read_at (timestamptz, nullable)
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  /// Fetch a page of notifications for the current user.
  ///
  /// Newest first. Use [offset] for simple pagination.
  Future<List<RemoteNotification>> listUserNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return const <RemoteNotification>[];

    try {
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows
          .cast<Map<String, dynamic>>()
          .map(RemoteNotification.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('NotificationService: Failed to list notifications: $e');
      return const <RemoteNotification>[];
    }
  }

  /// Create a new notification for the current user.
  Future<void> createNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.instance.client.from('notifications').insert(<String, Object?>{
        'user_id': user.id,
        'title': title,
        'body': body,
        if (type != null) 'type': type,
        if (data != null) 'data': data,
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to create notification: $e');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.instance.client.from('notifications').update(
        <String, Object>{
          'read_at': DateTime.now().toUtc().toIso8601String(),
        },
      ).match(
        <String, Object>{
          'id': id,
          'user_id': user.id,
        },
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to mark as read: $e');
    }
  }

  /// Mark all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.instance.client.from('notifications').update(
        <String, Object>{
          'read_at': DateTime.now().toUtc().toIso8601String(),
        },
      ).eq('user_id', user.id).isFilter('read_at', null);
    } catch (e) {
      debugPrint('NotificationService: Failed to mark all as read: $e');
    }
  }

  /// Permanently delete all notifications for the current user.
  Future<void> clearAll() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('NotificationService: Failed to clear notifications: $e');
    }
  }

  /// Permanently delete a single notification by id.
  Future<void> deleteNotification(String id) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.instance.client
          .from('notifications')
          .delete()
          .match(<String, Object>{
        'id': id,
        'user_id': user.id,
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to delete notification: $e');
    }
  }
}

