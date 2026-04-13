import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Subscription state for Wasiat: driven by `accounts` CHIP billing window,
/// with a fallback to `is_subscribed` for legacy Stripe-linked rows (no end date).
class BillingStatus {
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool? backendIsSubscribedFlag;

  const BillingStatus({
    this.periodStart,
    this.periodEnd,
    this.backendIsSubscribedFlag,
  });

  /// True when the current access window is active, or legacy Stripe subscription.
  bool get isSubscribed {
    final DateTime? end = periodEnd;
    if (end != null) {
      return DateTime.now().isBefore(end);
    }
    return backendIsSubscribedFlag == true;
  }

  /// User has CHIP-managed dates (show start / end in UI).
  bool get hasChipBillingWindow => periodEnd != null;

  factory BillingStatus.fromAccountRow(Map<String, dynamic>? row) {
    if (row == null) return const BillingStatus();
    return BillingStatus(
      periodStart: row['wasiat_subscription_period_start'] != null
          ? DateTime.tryParse(row['wasiat_subscription_period_start'].toString())
          : null,
      periodEnd: row['wasiat_subscription_period_end'] != null
          ? DateTime.tryParse(row['wasiat_subscription_period_end'].toString())
          : null,
      backendIsSubscribedFlag: row['is_subscribed'] as bool?,
    );
  }
}

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<BillingStatus> fetchStatus() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return const BillingStatus();

    final Map<String, dynamic>? row = await _client
        .from('accounts')
        .select(
          'is_subscribed, wasiat_subscription_period_start, wasiat_subscription_period_end',
        )
        .eq('uuid', userId)
        .maybeSingle();

    return BillingStatus.fromAccountRow(row);
  }
}
