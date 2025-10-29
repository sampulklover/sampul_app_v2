enum ParticipantRole { admin, member }

class ChatParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isActive;
  final ParticipantRole role;

  ChatParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.lastReadAt,
    this.isActive = true,
    this.role = ParticipantRole.member,
  });

  ChatParticipant copyWith({
    String? id,
    String? conversationId,
    String? userId,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool? isActive,
    ParticipantRole? role,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'userId': userId,
      'joinedAt': joinedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'isActive': isActive,
      'role': role.name,
    };
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      conversationId: json['conversationId'],
      userId: json['userId'],
      joinedAt: DateTime.parse(json['joinedAt']),
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt']) : null,
      isActive: json['isActive'] ?? true,
      role: ParticipantRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ParticipantRole.member,
      ),
    );
  }
}
