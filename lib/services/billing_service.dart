import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/stripe_config.dart';
import 'supabase_service.dart';

class BillingPlan {
  final String priceId;
  final String name;
  final int? amount; // smallest unit
  final String? currency;
  final String? interval;
  final String? description;

  const BillingPlan({
    required this.priceId,
    required this.name,
    this.amount,
    this.currency,
    this.interval,
    this.description,
  });

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      priceId: json['price_id'] as String,
      name: json['name'] as String? ?? 'Plan',
      amount: json['price'] as int?,
      currency: json['currency'] as String?,
      interval: json['interval'] as String?,
      description: json['description'] as String?,
    );
  }
}

class BillingStatus {
  final String? planId;
  final String? planName;
  final String? status;
  final DateTime? currentPeriodEnd;

  BillingStatus({
    this.planId,
    this.planName,
    this.status,
    this.currentPeriodEnd,
  });

  bool get isSubscribed =>
      status != null &&
      status!.isNotEmpty &&
      status != 'incomplete' &&
      status != 'canceled' &&
      status != 'incomplete_expired';

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    return BillingStatus(
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      status: json['status'] as String?,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'].toString())
          : null,
    );
  }
}

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<BillingPlan>> fetchPlans() async {
    final response = await _client.functions.invoke(
      StripeConfig.listPlansFunction,
      method: HttpMethod.get,
    );
    // Debug: log raw response for troubleshooting
    // ignore: avoid_print
    print('list-plans response: ${response.data}');
    final data = response.data;
    if (data is Map<String, dynamic> && data['plans'] is List) {
      return (data['plans'] as List)
          .whereType<Map<String, dynamic>>()
          .map(BillingPlan.fromJson)
          .toList();
    }
    // try decode string response
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic> && decoded['plans'] is List) {
        return (decoded['plans'] as List)
            .whereType<Map<String, dynamic>>()
            .map(BillingPlan.fromJson)
            .toList();
      }
    }
    return <BillingPlan>[];
  }

  Future<BillingStatus> fetchStatus() async {
    final response = await _client.functions.invoke(
      StripeConfig.subscriptionStatusFunction,
      method: HttpMethod.get,
    );
    // Debug: log raw response for troubleshooting
    // ignore: avoid_print
    print('get-subscription response: ${response.data}');

    final data = response.data;
    if (data == null) return BillingStatus();

    if (data is Map<String, dynamic>) {
      return BillingStatus.fromJson(data);
    }

    // Try to decode if it is JSON string
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      return BillingStatus.fromJson(decoded);
    } catch (_) {
      return BillingStatus();
    }
  }

  Future<String> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _client.functions.invoke(
      StripeConfig.createCheckoutFunction,
      body: <String, dynamic>{
        'priceId': priceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      },
    );

    final data = response.data;
    if (data is Map && data['sessionUrl'] is String) {
      return data['sessionUrl'] as String;
    }
    throw Exception('Failed to create checkout session');
  }

  Future<String> createBillingPortal({required String returnUrl}) async {
    final response = await _client.functions.invoke(
      StripeConfig.billingPortalFunction,
      body: <String, dynamic>{
        'returnUrl': returnUrl,
      },
    );

    final data = response.data;
    if (data is Map && data['portalUrl'] is String) {
      return data['portalUrl'] as String;
    }
    throw Exception('Failed to create billing portal session');
  }
}

