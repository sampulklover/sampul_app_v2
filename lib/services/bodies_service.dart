import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/body.dart';
import 'supabase_service.dart';

class BodiesService {
  BodiesService._();
  static final BodiesService instance = BodiesService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<BodyItem>> listActiveBodies() async {
    final List<dynamic> rows = await _client
        .from('bodies')
        .select('id, name, category, icon, active')
        .eq('active', true)
        .order('featured', ascending: false)
        .order('name', ascending: true);
    return rows.map((e) => BodyItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}


