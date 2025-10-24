enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isTyping;
  final bool isStreaming;
  final bool hasError;
  final String? errorMessage;
  final bool isRegenerating;
  final String? senderId;
  final MessageType messageType;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final bool? userFeedback; // true = liked, false = disliked, null = no feedback

  ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.isTyping = false,
    this.isStreaming = false,
    this.hasError = false,
    this.errorMessage,
    this.isRegenerating = false,
    this.senderId,
    this.messageType = MessageType.text,
    this.isEdited = false,
    this.editedAt,
    this.replyToMessageId,
    this.userFeedback,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    bool? isTyping,
    bool? isStreaming,
    bool? hasError,
    String? errorMessage,
    bool? isRegenerating,
    String? senderId,
    MessageType? messageType,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToMessageId,
    bool? userFeedback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      isStreaming: isStreaming ?? this.isStreaming,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
      'isStreaming': isStreaming,
      'hasError': hasError,
      'errorMessage': errorMessage,
      'isRegenerating': isRegenerating,
      'senderId': senderId,
      'messageType': messageType.name,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'replyToMessageId': replyToMessageId,
      'userFeedback': userFeedback,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isFromUser: json['is_from_user'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      isTyping: json['is_typing'] ?? false,
      isStreaming: json['is_streaming'] ?? false,
      hasError: json['has_error'] ?? false,
      errorMessage: json['error_message'],
      isRegenerating: json['is_regenerating'] ?? false,
      senderId: json['sender_id'],
      messageType: MessageType.values.firstWhere(
        (e) => e.name == (json['message_type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      replyToMessageId: json['reply_to_message_id'],
      userFeedback: json['user_feedback'],
    );
  }
}
