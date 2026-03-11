class AiChatQna {
  final String id;
  final String question;
  final String answer;
  final List<String> tags;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;

  AiChatQna({
    required this.id,
    required this.question,
    required this.answer,
    List<String>? tags,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  }) : tags = tags ?? const [];

  factory AiChatQna.fromJson(Map<String, dynamic> json) {
    return AiChatQna(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'tags': tags,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}

