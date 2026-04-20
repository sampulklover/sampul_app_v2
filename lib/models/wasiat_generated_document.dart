class WasiatGeneratedDocument {
  final String id;
  final String userId;
  final int? willId;
  final int? verificationId;
  final String? willCode;
  final DateTime? createdAt;
  final Map<String, dynamic> snapshot;

  const WasiatGeneratedDocument({
    required this.id,
    required this.userId,
    required this.snapshot,
    this.willId,
    this.verificationId,
    this.willCode,
    this.createdAt,
  });

  factory WasiatGeneratedDocument.fromJson(Map<String, dynamic> json) {
    final dynamic rawSnapshot = json['snapshot'];
    final Map<String, dynamic> snapshot = rawSnapshot is Map<String, dynamic>
        ? rawSnapshot
        : rawSnapshot is Map
            ? Map<String, dynamic>.from(rawSnapshot)
            : <String, dynamic>{};

    return WasiatGeneratedDocument(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      willId: (json['will_id'] as num?)?.toInt(),
      verificationId: (json['verification_id'] as num?)?.toInt(),
      willCode: json['will_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      snapshot: snapshot,
    );
  }
}

