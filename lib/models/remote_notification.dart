/// Backend-stored notification record.
///
/// These come from Supabase (e.g. a `notifications` table) and represent
/// the source of truth for notifications shown in the app.
class RemoteNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? type;
  final Map<String, dynamic>? data;

  const RemoteNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.type,
    this.data,
  });

  bool get isRead => readAt != null;

  factory RemoteNotification.fromJson(Map<String, dynamic> json) {
    return RemoteNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'] as String? ?? ''),
      type: json['type'] as String?,
      data: json['data'] is Map ? (json['data'] as Map).cast<String, dynamic>() : null,
    );
  }
}

