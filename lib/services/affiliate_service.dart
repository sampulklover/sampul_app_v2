import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import 'supabase_service.dart';

class AffiliateService {
  AffiliateService._();

  static final AffiliateService instance = AffiliateService._();

  static const String _pendingReferralCodeKey = 'pending_referral_code';
  static const String _claimedReferralCodeKeyPrefix = 'claimed_referral_code:';
  static const String _myAffiliateCodeKeyPrefix = 'my_affiliate_code:';

  String _claimedKeyForUser(String userId) => '$_claimedReferralCodeKeyPrefix$userId';
  String _myCodeKeyForUser(String userId) => '$_myAffiliateCodeKeyPrefix$userId';

  String friendlyReferralClaimError(Object error) {
    // Edge Function errors typically arrive as FunctionException with JSON body:
    // {"error":"code_not_found"} etc.
    if (error is FunctionException) {
      final details = error.details;
      String? code;

      // Newer supabase_flutter may provide details as a Map already.
      if (details is Map) {
        final dynamic raw = details['error'];
        if (raw is String) code = raw;
      }

      // Or details could be a JSON string.
      if (code == null && details is String) {
        try {
          final decoded = jsonDecode(details);
          if (decoded is Map && decoded['error'] is String) {
            code = decoded['error'] as String;
          }
        } catch (_) {
          // ignore
        }
      }

      // Fallback: look inside toString for known codes.
      final text = error.toString();
      if (code == null) {
        if (text.contains('code_not_found')) code = 'code_not_found';
        if (text.contains('cannot_refer_self')) code = 'cannot_refer_self';
        if (text.contains('invalid_code')) code = 'invalid_code';
        if (text.contains('not_authenticated')) code = 'not_authenticated';
        if (text.contains('already_referred')) code = 'already_referred';
      }

      switch (code) {
        case 'code_not_found':
          return 'Referral code not found';
        case 'cannot_refer_self':
          return 'You can’t use your own referral code';
        case 'invalid_code':
          return 'Please enter a valid referral code';
        case 'not_authenticated':
          return 'Please sign in and try again';
        case 'already_referred':
          return 'You already used a referral code';
        default:
          return 'Failed to apply referral code';
      }
    }
    return 'Failed to apply referral code';
  }

  /// Clear locally cached affiliate data for a specific user (use on logout).
  Future<void> clearUserCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claimedKeyForUser(userId));
    await prefs.remove(_myCodeKeyForUser(userId));
  }

  String? normalizeReferralCode(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    // Keep it simple and predictable: uppercase and remove spaces.
    return v.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingReferralCodeKey);
  }

  Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReferralCodeKey);
  }

  Future<void> setPendingReferralCode(String rawCode) async {
    final code = normalizeReferralCode(rawCode);
    if (code == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingReferralCodeKey, code);
  }

  /// Attempts to claim a referral code for the currently authenticated user.
  ///
  /// Notes:
  /// - Safe to call multiple times; server-side should enforce "one referral per user".
  /// - Stores a "claimed" marker locally to avoid repeated attempts.
  Future<bool> claimReferralCodeNow(String rawCode) async {
    final code = normalizeReferralCode(rawCode);
    if (code == null) return false;

    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      // Not logged in yet; keep it pending.
      await setPendingReferralCode(code);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getString(_claimedKeyForUser(user.id));
    if (alreadyClaimed != null && normalizeReferralCode(alreadyClaimed) == code) {
      return true;
    }

    try {
      // Uses Supabase Edge Function `claim-referral`.
      final resp = await SupabaseService.instance.client.functions.invoke(
        'claim-referral',
        body: <String, dynamic>{'code': code},
      );

      // Edge Function may return 200 with {claimed:false, reason:"already_referred"}
      if (resp.data is Map) {
        final m = resp.data as Map;
        if (m['claimed'] == false && m['reason'] == 'already_referred') {
          // Treat as success UX-wise (idempotent), but don't overwrite claimed code cache.
          await prefs.remove(_pendingReferralCodeKey);
          return true;
        }
      }

      await prefs.setString(_claimedKeyForUser(user.id), code);
      await prefs.remove(_pendingReferralCodeKey);
      return true;
    } on FunctionException {
      // Invalid code, already referred, etc. Keep pending so user can retry/edit.
      rethrow;
    }
  }

  /// Convenience: claim whatever is pending after user signs in.
  Future<void> claimPendingIfAny() async {
    final pending = await getPendingReferralCode();
    if (pending == null) return;
    await claimReferralCodeNow(pending);
  }

  /// Fetch (or create) the current user's own affiliate code via Edge Function.
  /// Cached locally to avoid unnecessary calls.
  Future<String> getOrCreateMyAffiliateCode({bool forceRefresh = false}) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = prefs.getString(_myCodeKeyForUser(user.id));
      if (cached != null && cached.trim().isNotEmpty) return cached;
    }

    final resp = await SupabaseService.instance.client.functions.invoke('my-affiliate-code');
    final data = resp.data;
    if (data is! Map) {
      throw Exception('Unexpected response');
    }
    final code = (data['code'] as String?)?.trim();
    if (code == null || code.isEmpty) {
      throw Exception('Missing code');
    }

    await prefs.setString(_myCodeKeyForUser(user.id), code);
    return code;
  }
}

