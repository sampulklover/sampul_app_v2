import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/extra_wishes.dart';
import '../models/user_profile.dart';
import '../models/wasiat_generated_document.dart';
import '../models/will.dart';
import 'supabase_service.dart';

class WasiatGeneratedDocumentService {
  WasiatGeneratedDocumentService._();
  static final WasiatGeneratedDocumentService instance =
      WasiatGeneratedDocumentService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<WasiatGeneratedDocument>> fetchHistory() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <WasiatGeneratedDocument>[];

    final List<dynamic> rows = await _client
        .from('wasiat_generated_documents')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(WasiatGeneratedDocument.fromJson)
        .toList();
  }

  Future<WasiatGeneratedDocument> createSnapshot({
    required Will will,
    required UserProfile userProfile,
    required List<Map<String, dynamic>> familyMembers,
    required List<Map<String, dynamic>> assets,
    required ExtraWishes? extraWishes,
    required int verificationId,
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final Map<String, dynamic> snapshot = <String, dynamic>{
      'generated_at': DateTime.now().toIso8601String(),
      'will': will.toJson(),
      'user_profile': userProfile.toJson(),
      'family_members': familyMembers,
      'assets': assets,
      'extra_wishes': extraWishes?.toJson(),
    };

    final Map<String, dynamic> inserted = await _client
        .from('wasiat_generated_documents')
        .insert(<String, dynamic>{
          'user_id': user.id,
          'will_id': will.id,
          'will_code': will.willCode,
          'verification_id': verificationId,
          'snapshot': snapshot,
        })
        .select()
        .single();

    return WasiatGeneratedDocument.fromJson(inserted);
  }

  /// Returns the newest verified session that has not been used by any
  /// generated wasiat document yet.
  Future<int?> pickUnusedVerifiedVerificationId({
    String? sessionPrefix,
    bool requireAfterLatestGenerated = true,
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;

    DateTime? latestGeneratedAt;
    if (requireAfterLatestGenerated) {
      final List<dynamic> latestGeneratedRows = await _client
          .from('wasiat_generated_documents')
          .select('created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (latestGeneratedRows.isNotEmpty) {
        final String? createdAtRaw =
            (latestGeneratedRows.first as Map<String, dynamic>)['created_at']
                ?.toString();
        if (createdAtRaw != null) {
          latestGeneratedAt = DateTime.tryParse(createdAtRaw);
        }
      }
    }

    final List<dynamic> verificationRows = await _client
        .from('verification')
        .select('id,status,created_at,session_id')
        .eq('uuid', user.id)
        .inFilter('status', <String>['verified', 'approved', 'accepted'])
        .order('created_at', ascending: false);

    if (verificationRows.isEmpty) return null;

    final List<int> candidateIds = verificationRows
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> row) {
          if (sessionPrefix != null && sessionPrefix.isNotEmpty) {
            final String sessionId = row['session_id']?.toString() ?? '';
            if (!sessionId.startsWith(sessionPrefix)) return false;
          }
          if (latestGeneratedAt == null) return true;
          final String? createdAtRaw = row['created_at']?.toString();
          if (createdAtRaw == null) return false;
          final DateTime? createdAt = DateTime.tryParse(createdAtRaw);
          if (createdAt == null) return false;
          return createdAt.isAfter(latestGeneratedAt);
        })
        .map((Map<String, dynamic> row) => row['id'])
        .whereType<num>()
        .map((num id) => id.toInt())
        .toList();
    if (candidateIds.isEmpty) return null;

    final List<dynamic> usedRows = await _client
        .from('wasiat_generated_documents')
        .select('verification_id')
        .eq('user_id', user.id)
        .inFilter('verification_id', candidateIds);

    final Set<int> usedIds = usedRows
        .map((dynamic row) => (row as Map<String, dynamic>)['verification_id'])
        .whereType<num>()
        .map((num id) => id.toInt())
        .toSet();

    for (final int id in candidateIds) {
      if (!usedIds.contains(id)) return id;
    }
    return null;
  }
}

