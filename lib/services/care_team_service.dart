import '../models/care_team_member.dart';
import 'supabase_service.dart';

class CareTeamService {
  static CareTeamService? _instance;
  static CareTeamService get instance => _instance ??= CareTeamService._();

  CareTeamService._();

  final SupabaseService _supabase = SupabaseService.instance;

  /// Fetch all active care team members from the database
  Future<List<CareTeamMember>> listActiveMembers() async {
    try {
      final List<dynamic> rows = await _supabase.client
          .from('care_team')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      
      return rows
          .map((e) => CareTeamMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if table doesn't exist yet or on error
      return <CareTeamMember>[];
    }
  }

  /// Fetch all care team members (including inactive)
  Future<List<CareTeamMember>> listAllMembers() async {
    try {
      final List<dynamic> rows = await _supabase.client
          .from('care_team')
          .select()
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      
      return rows
          .map((e) => CareTeamMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return <CareTeamMember>[];
    }
  }
}












