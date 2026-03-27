import '../services/supabase_service.dart';

/// App roles stored in table `public.roles` (enum `user_roles` in Postgres).
class StaffAccess {
  const StaffAccess({
    required this.isAdmin,
    required this.canManageAppContent,
  });

  final bool isAdmin;

  /// Admin or marketing — AI settings, Q&A, resources, learning content.
  final bool canManageAppContent;
}

class AdminUtils {
  static const String roleAdmin = 'admin';
  static const String roleMarketing = 'marketing';

  static String? normalizeRoleKey(String? raw) {
    if (raw == null) return null;
    final String s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == roleAdmin || s == roleMarketing) return s;
    return null;
  }

  static Future<StaffAccess> getStaffAccess() async {
    final String? role = await getUserRole();
    final String? r = normalizeRoleKey(role ?? '');
    final bool isAdmin = r == roleAdmin;
    final bool canContent = isAdmin || r == roleMarketing;
    return StaffAccess(isAdmin: isAdmin, canManageAppContent: canContent);
  }

  /// Admin only — assign marketing/admin, team list.
  static Future<bool> canManageTeamRoles() async => isAdmin();

  /// Admin or marketing — in-app content and AI tools.
  static Future<bool> canManageAppContent() async {
    final String? r = normalizeRoleKey(await getUserRole());
    return r == roleAdmin || r == roleMarketing;
  }

  static Future<bool> isMarketing() async {
    final String? r = normalizeRoleKey(await getUserRole());
    return r == roleMarketing;
  }

  /// Whether the current user is an admin
  static Future<bool> isAdmin() async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        return false;
      }

      final response = await SupabaseService.instance.client
          .from('roles')
          .select('role')
          .eq('uuid', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      final role = response['role']?.toString();
      return normalizeRoleKey(role) == roleAdmin;
    } catch (e) {
      return false;
    }
  }

  /// Row in `roles` for this user, if any (elevated access).
  static Future<String?> getUserRole() async {
    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        return null;
      }

      final response = await SupabaseService.instance.client
          .from('roles')
          .select('role')
          .eq('uuid', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response['role']?.toString();
    } catch (e) {
      return null;
    }
  }
}
