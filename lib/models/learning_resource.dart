class LearningResource {
  final String id;
  final String resourceType; // 'podcast' or 'guide'
  final String category; // e.g. 'trusts_wills', 'estate_planning'
  final String title;
  final String? durationLabel;
  final String? authorName;
  final DateTime? publishedAt;
  final String? body;
  final String? videoUrl;
  final String? imageUrl; // Image URL for guides (thumbnail/cover image)
  final bool isPublished;
  final int? sortIndex;

  LearningResource({
    required this.id,
    required this.resourceType,
    required this.category,
    required this.title,
    this.durationLabel,
    this.authorName,
    this.publishedAt,
    this.body,
    this.videoUrl,
    this.imageUrl,
    this.isPublished = true,
    this.sortIndex,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'] as String,
      resourceType: json['resource_type'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      durationLabel: json['duration_label'] as String?,
      authorName: json['author_name'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      body: json['body'] as String?,
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
      isPublished: (json['is_published'] as bool?) ?? true,
      sortIndex: json['sort_index'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'resource_type': resourceType,
      'category': category,
      'title': title,
      'duration_label': durationLabel,
      'author_name': authorName,
      'published_at': publishedAt?.toIso8601String(),
      'body': body,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'is_published': isPublished,
      'sort_index': sortIndex,
    };
  }

  LearningResource copyWith({
    String? id,
    String? resourceType,
    String? category,
    String? title,
    String? durationLabel,
    String? authorName,
    DateTime? publishedAt,
    String? body,
    String? videoUrl,
    String? imageUrl,
    bool? isPublished,
    int? sortIndex,
  }) {
    return LearningResource(
      id: id ?? this.id,
      resourceType: resourceType ?? this.resourceType,
      category: category ?? this.category,
      title: title ?? this.title,
      durationLabel: durationLabel ?? this.durationLabel,
      authorName: authorName ?? this.authorName,
      publishedAt: publishedAt ?? this.publishedAt,
      body: body ?? this.body,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublished: isPublished ?? this.isPublished,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }
}

