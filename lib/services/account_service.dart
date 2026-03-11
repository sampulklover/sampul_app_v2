import 'package:sampul_app_v2/services/supabase_service.dart';

/// Service for account-level operations such as deleting the current user.
class AccountService {
  const AccountService._();

  static const AccountService instance = AccountService._();

  /// Delete account for the current user by calling the Supabase Edge Function.
  ///
  /// Mirrors the website's `/api/profile/delete` logic:
  /// - Checks `accounts.is_subscribed`
  /// - If subscribed, returns a helpful error
  /// - Otherwise deletes the user with `auth.admin.deleteUser`
  Future<void> deleteAccount() async {
    final client = SupabaseService.instance.client;
    final response = await client.functions.invoke('delete-account');

    // `response.data` should contain the JSON returned by the edge function.
    // On error we return `{ error: { message: "..." } }`.
    final data = response.data;
    if (data is Map && data['error'] != null) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        throw Exception(error['message'] as String);
      } else if (error is String) {
        throw Exception(error);
      }
      throw Exception('Failed to delete account. Please try again.');
    }
  }
}

