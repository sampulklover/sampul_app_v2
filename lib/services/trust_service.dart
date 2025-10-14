import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/trust.dart';
import 'supabase_service.dart';

class TrustService {
  TrustService._();
  static final TrustService instance = TrustService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Trust>> listUserTrusts() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <Trust>[];
    final List<dynamic> rows = await _client
        .from('trust')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    // Trust.fromJson now maps doc_status → computedStatus
    return rows.map((e) => Trust.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trust> createTrust(Trust trust) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    // Ensure trust_code is present; generate if missing
    String code = (trust.trustCode ?? '').trim();
    if (code.isEmpty) {
      code = _generateTrustId();
    }

    int attempts = 0;
    while (true) {
      try {
        final Map<String, dynamic> payload = {
          ...trust.toJson(),
          'trust_code': code,
          'uuid': user.id,
        };
        final List<dynamic> inserted = await _client.from('trust').insert(payload).select().limit(1);
        return Trust.fromJson(inserted.first as Map<String, dynamic>);
      } catch (e) {
        // Retry on unique violation by generating a new code
        final String msg = e.toString().toLowerCase();
        final bool isUniqueViolation = msg.contains('duplicate key') || msg.contains('unique') || msg.contains('23505');
        if (!isUniqueViolation || attempts >= 4) {
          rethrow;
        }
        attempts += 1;
        code = _generateTrustId();
      }
    }
  }

  Future<Trust?> getTrustById(int id) async {
    final List<dynamic> rows = await _client.from('trust').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return Trust.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> deleteTrust(int id) async {
    await _client.from('trust').delete().eq('id', id);
  }

  Future<Trust> updateTrust(int id, Map<String, dynamic> data) async {
    final List<dynamic> rows = await _client
        .from('trust')
        .update(data)
        .eq('id', id)
        .select()
        .limit(1);
    return Trust.fromJson(rows.first as Map<String, dynamic>);
  }
}

String _generateTrustId() {
  final int currentYear = DateTime.now().year;
  // 10 random digits padded
  final int randomDigits = (DateTime.now().microsecondsSinceEpoch % 10000000000).toInt();
  final String padded = randomDigits.toString().padLeft(10, '0');
  return 'TRUST-$currentYear-$padded';
}


