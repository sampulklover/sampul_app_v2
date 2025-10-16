class AftercareTask {
  final int? id;
  final String uuid;
  final String task;
  final bool isCompleted;
  final bool isPinned;
  final DateTime createdAt;
  final int? sortIndex;

  AftercareTask({
    this.id,
    required this.uuid,
    required this.task,
    this.isCompleted = false,
    this.isPinned = false,
    required this.createdAt,
    this.sortIndex,
  });

  factory AftercareTask.fromJson(Map<String, dynamic> json) {
    return AftercareTask(
      id: json['id'] as int?,
      uuid: json['uuid'] as String,
      task: json['task'] as String,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      isPinned: (json['is_pinned'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sortIndex: json['sort_index'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'task': task,
      'is_completed': isCompleted,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'sort_index': sortIndex,
    };
  }

  AftercareTask copyWith({
    int? id,
    String? uuid,
    String? task,
    bool? isCompleted,
    bool? isPinned,
    DateTime? createdAt,
    int? sortIndex,
  }) {
    return AftercareTask(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }
}


