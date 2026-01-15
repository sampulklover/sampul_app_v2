class Verification {
  final int? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String serviceName;
  final String uuid;
  final String sessionId;
  final String? diditSessionId;
  final String? status;
  final String? verificationUrl;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  Verification({
    this.id,
    this.createdAt,
    this.updatedAt,
    required this.serviceName,
    required this.uuid,
    required this.sessionId,
    this.diditSessionId,
    this.status,
    this.verificationUrl,
    this.completedAt,
    this.expiresAt,
    this.errorMessage,
    this.metadata,
  });

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      id: (json['id'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      serviceName: json['service_name'] as String,
      uuid: json['uuid'] as String,
      sessionId: json['session_id'] as String,
      diditSessionId: json['didit_session_id'] as String?,
      status: json['status'] as String?,
      verificationUrl: json['verification_url'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      'service_name': serviceName,
      'uuid': uuid,
      'session_id': sessionId,
      if (diditSessionId != null) 'didit_session_id': diditSessionId,
      if (status != null) 'status': status,
      if (verificationUrl != null) 'verification_url': verificationUrl,
      if (completedAt != null) 'completed_at': completedAt?.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt?.toIso8601String(),
      if (errorMessage != null) 'error_message': errorMessage,
      if (metadata != null) 'metadata': metadata,
    };
  }

  Verification copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceName,
    String? uuid,
    String? sessionId,
    String? diditSessionId,
    String? status,
    String? verificationUrl,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Verification(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceName: serviceName ?? this.serviceName,
      uuid: uuid ?? this.uuid,
      sessionId: sessionId ?? this.sessionId,
      diditSessionId: diditSessionId ?? this.diditSessionId,
      status: status ?? this.status,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if verification is completed (either verified or rejected)
  bool get isCompleted => status == 'verified' || status == 'rejected';

  /// Check if verification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if verification is active (not completed and not expired)
  bool get isActive => !isCompleted && !isExpired;
}











