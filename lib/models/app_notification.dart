import 'dart:convert';

/// Lightweight in-app representation of a push notification.
///
/// These are stored locally so users can see a simple history
/// of important messages that were sent to their device.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isRead,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  static List<AppNotification> decodeList(String raw) {
    if (raw.trim().isEmpty) return const <AppNotification>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <AppNotification>[];
    }
  }

  static String encodeList(List<AppNotification> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
  }
}

