import '../models/learning_resource.dart';
import 'supabase_service.dart';

class LearningResourcesService {
  LearningResourcesService._();

  static LearningResourcesService? _instance;
  static LearningResourcesService get instance =>
      _instance ??= LearningResourcesService._();

  final SupabaseService _supabase = SupabaseService.instance;

  /// Public: list only published resources for the app UI.
  Future<List<LearningResource>> listPublishedResources() async {
    final List<dynamic> rows = await _supabase.client
        .from('learning_resources')
        .select()
        .eq('is_published', true)
        .order('resource_type', ascending: true)
        .order('category', ascending: true)
        .order('sort_index', ascending: true)
        .order('published_at', ascending: false);

    return rows
        .map((e) => LearningResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: list all resources (published and drafts).
  Future<List<LearningResource>> listAllResources() async {
    final List<dynamic> rows = await _supabase.client
        .from('learning_resources')
        .select()
        .order('resource_type', ascending: true)
        .order('category', ascending: true)
        .order('sort_index', ascending: true)
        .order('published_at', ascending: false);

    return rows
        .map((e) => LearningResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: create a new resource.
  Future<LearningResource> createResource({
    required String resourceType,
    required String category,
    required String title,
    String? durationLabel,
    String? authorName,
    DateTime? publishedAt,
    String? body,
    String? videoUrl,
    String? imageUrl,
    bool isPublished = true,
    int? sortIndex,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'resource_type': resourceType,
      'category': category,
      'title': title,
      if (durationLabel != null) 'duration_label': durationLabel,
      if (authorName != null) 'author_name': authorName,
      if (publishedAt != null) 'published_at': publishedAt.toIso8601String(),
      if (body != null) 'body': body,
      if (videoUrl != null) 'video_url': videoUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_published': isPublished,
      if (sortIndex != null) 'sort_index': sortIndex,
    };

    final Map<String, dynamic> row = await _supabase.client
        .from('learning_resources')
        .insert(data)
        .select()
        .single();

    return LearningResource.fromJson(row);
  }

  /// Admin: update an existing resource by id.
  Future<LearningResource> updateResource({
    required String id,
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
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (resourceType != null) data['resource_type'] = resourceType;
    if (category != null) data['category'] = category;
    if (title != null) data['title'] = title;
    if (durationLabel != null) data['duration_label'] = durationLabel;
    if (authorName != null) data['author_name'] = authorName;
    if (publishedAt != null) {
      data['published_at'] = publishedAt.toIso8601String();
    }
    if (body != null) data['body'] = body;
    if (videoUrl != null) data['video_url'] = videoUrl;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (isPublished != null) data['is_published'] = isPublished;
    if (sortIndex != null) data['sort_index'] = sortIndex;

    final Map<String, dynamic> row = await _supabase.client
        .from('learning_resources')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return LearningResource.fromJson(row);
  }

  /// Admin: delete a resource by id.
  Future<void> deleteResource(String id) async {
    await _supabase.client
        .from('learning_resources')
        .delete()
        .eq('id', id);
  }
}

