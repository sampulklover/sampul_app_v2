import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AiKbSearchResult {
  final String entryId;
  final String? product;
  final String? language;
  final String? category;
  final String? question;
  final String answer;
  final List<String> tags;
  final double score;

  AiKbSearchResult({
    required this.entryId,
    required this.answer,
    required this.tags,
    required this.score,
    this.product,
    this.language,
    this.category,
    this.question,
  });

  factory AiKbSearchResult.fromJson(Map<String, dynamic> json) {
    return AiKbSearchResult(
      entryId: (json['entry_id'] as String?) ?? '',
      product: json['product'] as String?,
      language: json['language'] as String?,
      category: json['category'] as String?,
      question: json['question'] as String?,
      answer: (json['answer'] as String?) ?? '',
      tags: ((json['tags'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AiKbService {
  static final AiKbService instance = AiKbService._();
  AiKbService._();

  Future<List<String>> getSuggestedQuestions({
    String? product,
    String? language,
    int limit = 6,
  }) async {
    try {
      final rows = await SupabaseService.instance.client
          .from('ai_kb_entries')
          .select('question, priority, updated_at')
          .eq('is_active', true)
          .not('question', 'is', null)
          .neq('question', '')
          .match({
            if (product != null) 'product': product,
            if (language != null) 'language': language,
          })
          .order('priority', ascending: false)
          .order('updated_at', ascending: false)
          .limit(limit);

      return rows
          .whereType<Map<String, dynamic>>()
          .map((r) => (r['question'] as String?)?.trim() ?? '')
          .where((q) => q.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('AiKbService.getSuggestedQuestions error: $e');
      return const <String>[];
    }
  }

  Future<List<String>> getRelatedQuestionsForMatches({
    required List<AiKbSearchResult> matches,
    int limit = 6,
  }) async {
    if (matches.isEmpty) return const <String>[];

    final top = matches.first;
    final product = top.product;
    final language = top.language;
    final category = top.category;
    final excludeIds = matches.map((m) => m.entryId).where((id) => id.isNotEmpty).toSet();

    try {
      var query = SupabaseService.instance.client
          .from('ai_kb_entries')
          .select('id, question, priority, updated_at')
          .eq('is_active', true)
          .not('question', 'is', null)
          .neq('question', '');

      if (product != null && product.trim().isNotEmpty) {
        query = query.eq('product', product);
      }
      if (language != null && language.trim().isNotEmpty) {
        query = query.eq('language', language);
      }
      if (category != null && category.trim().isNotEmpty) {
        query = query.eq('category', category);
      }

      final rows = await query
          .order('priority', ascending: false)
          .order('updated_at', ascending: false)
          .limit(20);

      final questions = <String>[];
      for (final r in rows.whereType<Map<String, dynamic>>()) {
        final id = (r['id'] as String?) ?? '';
        if (id.isNotEmpty && excludeIds.contains(id)) continue;
        final q = (r['question'] as String?)?.trim() ?? '';
        if (q.isEmpty) continue;
        questions.add(q);
        if (questions.length >= limit) break;
      }

      return questions;
    } catch (e) {
      debugPrint('AiKbService.getRelatedQuestionsForMatches error: $e');
      return const <String>[];
    }
  }

  Future<List<AiKbSearchResult>> searchKeyword({
    required String queryText,
    String? product,
    String? language,
    int limit = 4,
  }) async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'ai_kb_search_keyword',
        params: <String, dynamic>{
          'query_text': queryText,
          'query_product': product,
          'query_language': language,
          'match_count': limit,
        },
      );

      if (response is! List) {
        return const <AiKbSearchResult>[];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(AiKbSearchResult.fromJson)
          .where((r) => r.answer.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('AiKbService.searchKeyword error: $e');
      return const <AiKbSearchResult>[];
    }
  }

  /// Converts KB matches into a compact prompt snippet.
  /// Keep this short: it’s designed to reduce token usage.
  String buildKbContext(List<AiKbSearchResult> matches) {
    if (matches.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Sampul knowledge base (use these when relevant):');

    for (final m in matches) {
      final q = (m.question ?? '').trim();
      final a = m.answer.trim();
      if (a.isEmpty) continue;

      if (q.isNotEmpty) {
        buffer.writeln('Q: $q');
      }
      buffer.writeln('A: $a');
      buffer.writeln('');
    }

    return buffer.toString().trim();
  }
}

