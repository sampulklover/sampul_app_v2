import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/chip_config.dart';
import '../controllers/auth_controller.dart';
import '../models/hibah_payment.dart';
import 'supabase_service.dart';
import 'trust_payment_service.dart';

class HibahPaymentBreakdown {
  final int assetCount;
  final int registrationFeeInCents;
  final int amendmentFeeInCents;
  final int executionFeeInCents;
  final int stampDutyInCents;
  final int totalAmountInCents;
  final String description;

  const HibahPaymentBreakdown({
    required this.assetCount,
    required this.registrationFeeInCents,
    required this.amendmentFeeInCents,
    required this.executionFeeInCents,
    required this.stampDutyInCents,
    required this.totalAmountInCents,
    required this.description,
  });
}

class HibahPaymentService {
  HibahPaymentService._();
  static final HibahPaymentService instance = HibahPaymentService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  int calculateRegistrationFeeInCents(int assetCount) {
    if (assetCount <= 1) {
      return 250000;
    }
    if (assetCount <= 10) {
      return 850000;
    }
    return 850000 + ((assetCount - 10) * 50000);
  }

  String getRegistrationFeeDescription(int assetCount) {
    if (assetCount <= 1) {
      return '1 asset';
    }
    if (assetCount <= 10) {
      return 'Up to 10 assets';
    }
    return '$assetCount assets (RM 8,500 + RM 500 x ${assetCount - 10})';
  }

  int calculateAmendmentFeeInCents(int amendmentCount) {
    return amendmentCount * 50000;
  }

  int calculateExecutionFeeInCents(
    double propertyValue, {
    int stampDutyInCents = 0,
  }) {
    final int executionFee = (propertyValue * 0.005 * 100).round();
    return executionFee + stampDutyInCents;
  }

  HibahPaymentBreakdown calculatePayment({
    required int assetCount,
    int amendmentCount = 0,
    double propertyValue = 0,
    int stampDutyInCents = 0,
  }) {
    final int registrationFee = calculateRegistrationFeeInCents(assetCount);
    final int amendmentFee = calculateAmendmentFeeInCents(amendmentCount);
    final int executionFee = propertyValue > 0
        ? calculateExecutionFeeInCents(
            propertyValue,
            stampDutyInCents: stampDutyInCents,
          )
        : 0;

    return HibahPaymentBreakdown(
      assetCount: assetCount,
      registrationFeeInCents: registrationFee,
      amendmentFeeInCents: amendmentFee,
      executionFeeInCents: executionFee,
      stampDutyInCents: stampDutyInCents,
      totalAmountInCents: registrationFee + amendmentFee + executionFee,
      description: getRegistrationFeeDescription(assetCount),
    );
  }

  Future<String> getChipClient() {
    return TrustPaymentService.instance.getChipClient();
  }

  Future<ChipPaymentResponse> createPayment({
    required String hibahId,
    required String certificateId,
    required int amount,
    required String clientId,
    String? userCouponId,
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    developer.log('createPayment called', name: 'HIBAH PAYMENT SERVICE');
    developer.log(
      'hibahId: $hibahId, certificateId: $certificateId, amount: $amount, clientId: $clientId',
      name: 'HIBAH PAYMENT SERVICE',
    );

    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        ChipConfig.createPaymentFunction,
        body: <String, dynamic>{
          'paymentType': 'hibah',
          'hibahId': hibahId,
          'certificateId': certificateId,
          'userId': user.id,
          'clientId': clientId,
          'amount': amount,
          'description': 'Payment for Hibah $certificateId',
          if (userCouponId != null && userCouponId.isNotEmpty)
            'userCouponId': userCouponId,
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Function invoke failed: $e',
        name: 'HIBAH PAYMENT SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    developer.log(
      'Edge function response status: ${response.status}',
      name: 'HIBAH PAYMENT SERVICE',
    );
    developer.log(
      'Edge function response data: ${response.data}',
      name: 'HIBAH PAYMENT SERVICE',
    );

    if (response.status != 200) {
      throw Exception(
        'Edge function error: ${response.status} - ${response.data}',
      );
    }

    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return ChipPaymentResponse.fromJson(data);
    }
    if (data is Map) {
      return ChipPaymentResponse.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Failed to create payment: Invalid response format');
  }

  Future<List<HibahPayment>> getPaymentHistory(String hibahId) async {
    final List<dynamic> rows = await _client
        .from('hibah_payments')
        .select()
        .eq('hibah_id', hibahId)
        .order('created_at', ascending: false);

    return rows
        .map((dynamic e) => HibahPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All rows for the signed-in user (RLS), newest first.
  Future<List<HibahPayment>> fetchAllPaymentsForCurrentUser() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <HibahPayment>[];

    final List<dynamic> rows = await _client
        .from('hibah_payments')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((dynamic e) => HibahPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HibahPayment?> getLatestPayment(String hibahId) async {
    final List<HibahPayment> history = await getPaymentHistory(hibahId);
    if (history.isEmpty) {
      return null;
    }
    return history.first;
  }
}
