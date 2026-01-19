class CareTeamMember {
  final int id;
  final String name;
  final String? imageUrl;
  final String bio;
  final String bookingUrl;
  final bool isActive;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CareTeamMember({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.bio,
    required this.bookingUrl,
    this.isActive = true,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory CareTeamMember.fromJson(Map<String, dynamic> json) {
    return CareTeamMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      bio: json['bio'] as String,
      bookingUrl: json['booking_url'] as String,
      isActive: (json['is_active'] as bool?) ?? true,
      sortOrder: json['sort_order'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'bio': bio,
      'booking_url': bookingUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}












