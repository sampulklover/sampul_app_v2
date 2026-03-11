import '../models/ai_chat_qna.dart';
import '../services/supabase_service.dart';

class AiChatQnaService {
  AiChatQnaService._();
  static final AiChatQnaService instance = AiChatQnaService._();

  // Simple cache for active Q&A pairs to avoid hitting Supabase on every message
  List<AiChatQna>? _cachedActiveQna;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get active Q&A pairs for AI context.
  /// Optionally provide a [limit] and a simple [searchQuery] (matches question/answer).
  Future<List<AiChatQna>> getActiveQna({int limit = 5, String? searchQuery}) async {
    // Return cache if still fresh and no search query is used
    if (searchQuery == null &&
        _cachedActiveQna != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedActiveQna!.take(limit).toList();
    }

    try {
      // Very simple text search if provided
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final response = await SupabaseService.instance.client
            .from('ai_chat_qna')
            .select()
            .eq('is_active', true)
            .or('question.ilike.%$q%,answer.ilike.%$q%')
            .order('created_at', ascending: false)
            .limit(limit);

        final items = (response as List)
            .map((json) => AiChatQna.fromJson(json as Map<String, dynamic>))
            .toList();

        return items;
      }

      final response = await SupabaseService.instance.client
          .from('ai_chat_qna')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      final items = (response as List)
          .map((json) => AiChatQna.fromJson(json))
          .toList();

      if (searchQuery == null) {
        _cachedActiveQna = items;
        _cacheTimestamp = DateTime.now();
      }

      return items;
    } catch (e) {
      // On error, just return empty list so chat still works without Q&A
      return const [];
    }
  }

  /// ADMIN: Get all Q&A entries (no filters). Rely on RLS for access control.
  Future<List<AiChatQna>> getAllQna() async {
    try {
      final response = await SupabaseService.instance.client
          .from('ai_chat_qna')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AiChatQna.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch AI Q&A: $e');
    }
  }

  /// ADMIN: Create a new Q&A entry.
  Future<AiChatQna> createQna({
    required String question,
    required String answer,
    List<String>? tags,
    bool isActive = true,
  }) async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final insertData = <String, dynamic>{
        'question': question,
        'answer': answer,
        'is_active': isActive,
        'created_by': currentUser.id,
      };

      if (tags != null && tags.isNotEmpty) {
        insertData['tags'] = tags;
      }

      final response = await SupabaseService.instance.client
          .from('ai_chat_qna')
          .insert(insertData)
          .select()
          .single();

      _invalidateCache();

      return AiChatQna.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create AI Q&A: $e');
    }
  }

  /// ADMIN: Update an existing Q&A entry.
  Future<AiChatQna> updateQna({
    required String id,
    String? question,
    String? answer,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (question != null) updates['question'] = question;
      if (answer != null) updates['answer'] = answer;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await SupabaseService.instance.client
          .from('ai_chat_qna')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      _invalidateCache();

      return AiChatQna.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update AI Q&A: $e');
    }
  }

  /// ADMIN: Delete a Q&A entry.
  Future<void> deleteQna(String id) async {
    try {
      await SupabaseService.instance.client
          .from('ai_chat_qna')
          .delete()
          .eq('id', id);

      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to delete AI Q&A: $e');
    }
  }

  /// Clear cached Q&A (useful for tests or forced refresh).
  void clearCache() {
    _invalidateCache();
  }

  void _invalidateCache() {
    _cachedActiveQna = null;
    _cacheTimestamp = null;
  }
}

