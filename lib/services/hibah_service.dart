import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/hibah.dart';
import 'supabase_service.dart';

class HibahService {
  HibahService._();
  static final HibahService instance = HibahService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Hibah>> listUserHibahs() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <Hibah>[];
    final List<dynamic> rows = await _client
        .from('hibah')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    // Hibah.fromJson now maps doc_status → computedStatus
    return rows.map((e) => Hibah.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Hibah> createHibah(Hibah hibah) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    // Ensure hibah_code is present; generate if missing
    String code = (hibah.hibahCode ?? '').trim();
    if (code.isEmpty) {
      code = _generateHibahId();
    }

    int attempts = 0;
    while (true) {
      try {
        final Map<String, dynamic> payload = {
          ...hibah.toJson(),
          'hibah_code': code,
          'uuid': user.id,
        };
        final List<dynamic> inserted = await _client.from('hibah').insert(payload).select().limit(1);
        return Hibah.fromJson(inserted.first as Map<String, dynamic>);
      } catch (e) {
        // Retry on unique violation by generating a new code
        final String msg = e.toString().toLowerCase();
        final bool isUniqueViolation = msg.contains('duplicate key') || msg.contains('unique') || msg.contains('23505');
        if (!isUniqueViolation || attempts >= 4) {
          rethrow;
        }
        attempts += 1;
        code = _generateHibahId();
      }
    }
  }

  Future<Hibah?> getHibahById(int id) async {
    final List<dynamic> rows = await _client.from('hibah').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return Hibah.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> deleteHibah(int id) async {
    await _client.from('hibah').delete().eq('id', id);
  }

  Future<Hibah> updateHibah(int id, Map<String, dynamic> data) async {
    final List<dynamic> rows = await _client
        .from('hibah')
        .update(data)
        .eq('id', id)
        .select()
        .limit(1);
    return Hibah.fromJson(rows.first as Map<String, dynamic>);
  }
}

String _generateHibahId() {
  final int currentYear = DateTime.now().year;
  // 10 random digits padded
  final int randomDigits = (DateTime.now().microsecondsSinceEpoch % 10000000000).toInt();
  final String padded = randomDigits.toString().padLeft(10, '0');
  return 'HIBAH-$currentYear-$padded';
}


