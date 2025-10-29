enum ConversationType { ai, user, group }

class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final ConversationType conversationType;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    this.avatarUrl = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.conversationType = ConversationType.ai,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  ChatConversation copyWith({
    String? id,
    String? name,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? avatarUrl,
    int? unreadCount,
    bool? isOnline,
    ConversationType? conversationType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      conversationType: conversationType ?? this.conversationType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'avatarUrl': avatarUrl,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'conversationType': conversationType.name,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      name: json['name'],
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time']),
      avatarUrl: json['avatar_url'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
      conversationType: ConversationType.values.firstWhere(
        (e) => e.name == (json['conversation_type'] ?? 'ai'),
        orElse: () => ConversationType.ai,
      ),
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
