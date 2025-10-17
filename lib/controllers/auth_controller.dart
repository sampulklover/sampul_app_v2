import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../config/supabase_config.dart';

class AuthController {
  AuthController._();

  static final AuthController instance = AuthController._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Get current user
  User? get currentUser => _supabaseService.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabaseService.signInWithEmail(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google authentication failed');
      }

      return await _supabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabaseService.signOut();
      
      // Sign out from Google if previously signed in
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.passwordResetRedirectUrl,
    );
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // First, verify the current password by attempting to sign in
    try {
      await _supabaseService.client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } catch (e) {
      throw Exception('Current password is incorrect');
    }

    // Update the password
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Update user profile in profiles table
  Future<void> updateProfile({
    String? username,
    String? nricName,
    String? phoneNo,
    String? imagePath,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    bool? isAftercareOnboard,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Update profile in profiles table
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (nricName != null) data['nric_name'] = nricName;
    if (phoneNo != null) data['phone_no'] = phoneNo;
    if (imagePath != null) data['image_path'] = imagePath;
    if (address1 != null) data['address_1'] = address1;
    if (address2 != null) data['address_2'] = address2;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (postcode != null) data['postcode'] = postcode;
    if (isAftercareOnboard != null) data['is_aftercare_onboard'] = isAftercareOnboard;

    if (data.isNotEmpty) {
      await _supabaseService.client
          .from('profiles')
          .update(data)
          .eq('uuid', user.id);
    }
  }

  // Get user profile from profiles table
  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('uuid', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // If profile doesn't exist, return null
      return null;
    }
  }

  // Create or update user profile in profiles table
  Future<void> upsertUserProfile(UserProfile profile) async {
    await _supabaseService.client
        .from('profiles')
        .upsert(profile.toJson());
  }
}


