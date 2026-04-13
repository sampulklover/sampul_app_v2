import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/chip_config.dart';
import '../config/wasiat_chip_amount.dart';
import '../controllers/auth_controller.dart';
import '../models/wasiat_subscription_payment.dart';
import 'supabase_service.dart';
import 'trust_payment_service.dart';

/// CHIP checkout for Wasiat annual access (same CHIP merchant as Hibah).
class WasiatSubscriptionPaymentService {
  WasiatSubscriptionPaymentService._();
  static final WasiatSubscriptionPaymentService instance =
      WasiatSubscriptionPaymentService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<ChipPaymentResponse> createAnnualPayment({
    required String clientId,
    int? amountCents,
    String? userCouponId,
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final int amount = amountCents ?? kWasiatYearlyAmountCents;

    final FunctionResponse response = await _client.functions.invoke(
      ChipConfig.createPaymentFunction,
      body: <String, dynamic>{
        'paymentType': 'wasiat',
        'userId': user.id,
        'clientId': clientId,
        'amount': amount,
        'description': 'Wasiat — annual access',
        if (userCouponId != null && userCouponId.isNotEmpty)
          'userCouponId': userCouponId,
      },
    );

    if (response.status != 200) {
      throw Exception('Edge function error: ${response.status} - ${response.data}');
    }

    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return ChipPaymentResponse.fromJson(data);
    }
    if (data is Map) {
      return ChipPaymentResponse.fromJson(Map<String, dynamic>.from(data));
    }
    if (data is String) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return ChipPaymentResponse.fromJson(decoded);
    }

    throw Exception('Failed to create payment: Invalid response format');
  }

  /// Own rows only (RLS). Newest first.
  Future<List<WasiatSubscriptionPayment>> fetchPaymentHistory() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <WasiatSubscriptionPayment>[];

    final List<dynamic> rows = await _client
        .from('wasiat_subscription_payments')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(WasiatSubscriptionPayment.fromJson)
        .toList();
  }
}
