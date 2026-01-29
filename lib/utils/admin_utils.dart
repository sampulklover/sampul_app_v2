import '../services/supabase_service.dart';

class AdminUtils {
  /// Check if the current user is an admin
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

      final role = response['role'] as String;
      return role.toLowerCase() == 'admin';
    } catch (e) {
      // If there's an error, assume not admin for security
      return false;
    }
  }

  /// Get the current user's role
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

      return response['role'] as String;
    } catch (e) {
      return null;
    }
  }
}
