import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/extra_wishes.dart';
import 'supabase_service.dart';

class ExtraWishesService {
  ExtraWishesService._();
  static final ExtraWishesService instance = ExtraWishesService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<ExtraWishes?> getForCurrentUser() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;
    final List<dynamic> rows = await _client
        .from('extra_wishes')
        .select()
        .eq('uuid', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    return ExtraWishes.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<ExtraWishes> upsertForCurrentUser(ExtraWishes wishes) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    final Map<String, dynamic> payload = wishes.toJson();
    payload['uuid'] = user.id; // enforce current user

    final List<dynamic> rows = await _client
        .from('extra_wishes')
        .upsert(payload, onConflict: 'uuid')
        .select()
        .limit(1);
    return ExtraWishes.fromJson(rows.first as Map<String, dynamic>);
  }
}


