import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../models/trust_charity.dart';
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

  Future<Trust> createTrust(Trust trust, {List<TrustBeneficiary>? beneficiaries, List<TrustCharity>? charities}) async {
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
        final Trust createdTrust = Trust.fromJson(inserted.first as Map<String, dynamic>);

        // Create beneficiaries if provided
        if (beneficiaries != null && beneficiaries.isNotEmpty) {
          await _createBeneficiaries(createdTrust.id!, beneficiaries, user.id);
        }

        // Create charities if provided
        if (charities != null && charities.isNotEmpty) {
          await _createCharities(createdTrust.id!, charities, user.id);
        }

        return createdTrust;
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

  Future<void> _createBeneficiaries(int trustId, List<TrustBeneficiary> beneficiaries, String uuid) async {
    final List<Map<String, dynamic>> beneficiaryPayloads = beneficiaries.map((beneficiary) {
      return {
        ...beneficiary.toJson(),
        'trust_id': trustId,
        'uuid': uuid,
      };
    }).toList();

    await _client.from('trust_beneficiary').insert(beneficiaryPayloads);
  }

  Future<void> _createCharities(int trustId, List<TrustCharity> charities, String uuid) async {
    final List<Map<String, dynamic>> charityPayloads = charities.map((charity) {
      return {
        ...charity.toJson(),
        'trust_id': trustId,
        'uuid': uuid,
      };
    }).toList();

    await _client.from('trust_charity').insert(charityPayloads);
  }

  Future<List<TrustBeneficiary>> getBeneficiariesByTrustId(int trustId) async {
    final List<dynamic> rows = await _client
        .from('trust_beneficiary')
        .select()
        .eq('trust_id', trustId)
        .order('created_at', ascending: true);

    return rows.map((e) => TrustBeneficiary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TrustCharity>> getCharitiesByTrustId(int trustId) async {
    final List<dynamic> rows = await _client
        .from('trust_charity')
        .select()
        .eq('trust_id', trustId)
        .order('created_at', ascending: true);

    return rows.map((e) => TrustCharity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrustBeneficiary> createBeneficiary(TrustBeneficiary beneficiary) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final Map<String, dynamic> payload = {
      ...beneficiary.toJson(),
      'uuid': user.id,
    };

    final List<dynamic> inserted = await _client
        .from('trust_beneficiary')
        .insert(payload)
        .select()
        .limit(1);

    return TrustBeneficiary.fromJson(inserted.first as Map<String, dynamic>);
  }

  Future<TrustBeneficiary> updateBeneficiary(int id, Map<String, dynamic> data) async {
    final List<dynamic> rows = await _client
        .from('trust_beneficiary')
        .update(data)
        .eq('id', id)
        .select()
        .limit(1);

    return TrustBeneficiary.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> deleteBeneficiary(int id) async {
    await _client.from('trust_beneficiary').delete().eq('id', id);
  }

  Future<TrustCharity> createCharity(TrustCharity charity) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final Map<String, dynamic> payload = {
      ...charity.toJson(),
      'uuid': user.id,
    };

    final List<dynamic> inserted = await _client
        .from('trust_charity')
        .insert(payload)
        .select()
        .limit(1);

    return TrustCharity.fromJson(inserted.first as Map<String, dynamic>);
  }

  Future<TrustCharity> updateCharity(int id, Map<String, dynamic> data) async {
    final List<dynamic> rows = await _client
        .from('trust_charity')
        .update(data)
        .eq('id', id)
        .select()
        .limit(1);

    return TrustCharity.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> deleteCharity(int id) async {
    await _client.from('trust_charity').delete().eq('id', id);
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


