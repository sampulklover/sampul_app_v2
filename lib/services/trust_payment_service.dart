import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/chip_config.dart';
import '../models/trust_payment.dart';
import '../controllers/auth_controller.dart';
import 'supabase_service.dart';

class ChipPaymentResponse {
  final String id;
  final String checkoutUrl;
  final String status;
  final String clientId;

  ChipPaymentResponse({
    required this.id,
    required this.checkoutUrl,
    required this.status,
    required this.clientId,
  });

  factory ChipPaymentResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure from edge function
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    return ChipPaymentResponse(
      id: data['id'] as String? ?? '',
      checkoutUrl: data['checkout_url'] as String? ?? '',
      status: data['status'] as String? ?? 'pending_charge',
      clientId: data['client_id'] as String? ?? '',
    );
  }
}

class TrustPaymentService {
  TrustPaymentService._();
  static final TrustPaymentService instance = TrustPaymentService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get or create CHIP customer ID for the signed-in user.
  ///
  /// [forTrustMerchant]: when true, uses the trust-only CHIP merchant and
  /// `accounts.chip_trust_customer_id`. When false, uses Hibah/Wasiat merchant
  /// and `accounts.chip_customer_id`.
  Future<String> getChipClient({bool forTrustMerchant = false}) async {
    print(
      '🟡 [TRUST PAYMENT SERVICE] getChipClient called (forTrustMerchant: $forTrustMerchant)',
    );
    final user = AuthController.instance.currentUser;
    if (user == null) {
      print('🔴 [TRUST PAYMENT SERVICE] No authenticated user');
      throw Exception('No authenticated user');
    }

    print('🟡 [TRUST PAYMENT SERVICE] User ID: ${user.id}, Email: ${user.email}');

    final String column =
        forTrustMerchant ? 'chip_trust_customer_id' : 'chip_customer_id';

    try {
      final accountResponse = await _client
          .from('accounts')
          .select(column)
          .eq('uuid', user.id)
          .maybeSingle();

      print('🟡 [TRUST PAYMENT SERVICE] Account response: $accountResponse');

      if (accountResponse != null && accountResponse[column] != null) {
        final existingId = accountResponse[column] as String;
        print('🟢 [TRUST PAYMENT SERVICE] Found existing CHIP client ID: $existingId');
        return existingId;
      }
    } catch (e) {
      print('🟡 [TRUST PAYMENT SERVICE] Error checking account: $e');
    }

    print('🟡 [TRUST PAYMENT SERVICE] Calling edge function: ${ChipConfig.createClientFunction}');
    try {
      final response = await _client.functions.invoke(
        ChipConfig.createClientFunction,
        body: <String, dynamic>{
          'email': user.email ?? '',
          if (forTrustMerchant) 'chipAccount': 'trust',
        },
      );

      print('🟡 [TRUST PAYMENT SERVICE] Edge function response status: ${response.status}');
      print('🟡 [TRUST PAYMENT SERVICE] Edge function response data: ${response.data}');

      if (response.status != 200) {
        print('🔴 [TRUST PAYMENT SERVICE] Edge function returned error status: ${response.status}');
        throw Exception('Edge function error: ${response.status} - ${response.data}');
      }

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final chipData = data['data'] as Map<String, dynamic>;
        final clientId = chipData['id'] as String? ?? '';
        
        print('🟡 [TRUST PAYMENT SERVICE] Extracted client ID: $clientId');
        
        if (clientId.isNotEmpty) {
          try {
            await _client.from('accounts').upsert({
              'uuid': user.id,
              column: clientId,
            });
            print('🟢 [TRUST PAYMENT SERVICE] Stored CHIP client ID in accounts ($column)');
          } catch (e) {
            print('🟡 [TRUST PAYMENT SERVICE] Warning: Failed to store client ID: $e');
            // Continue even if storage fails
          }
          return clientId;
        }
      }

      print('🔴 [TRUST PAYMENT SERVICE] No client ID in response');
      throw Exception('Failed to get CHIP client ID: No ID in response');
    } catch (e, stackTrace) {
      print('🔴 [TRUST PAYMENT SERVICE] Error in getChipClient: $e');
      print('🔴 [TRUST PAYMENT SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a payment session with CHIP
  Future<ChipPaymentResponse> createPayment({
    required int trustId,
    required String trustCode,
    required int amount, // Amount in cents
    required String clientId,
  }) async {
    print('🟡 [TRUST PAYMENT SERVICE] createPayment called');
    print('🟡 [TRUST PAYMENT SERVICE] trustId: $trustId, trustCode: $trustCode, amount: $amount, clientId: $clientId');
    
    final user = AuthController.instance.currentUser;
    if (user == null) {
      print('🔴 [TRUST PAYMENT SERVICE] No authenticated user');
      throw Exception('No authenticated user');
    }

    // Don't send URLs - let edge function construct proper web URLs
    // CHIP API requires HTTP/HTTPS URLs, not deep links
    print('🟡 [TRUST PAYMENT SERVICE] Calling edge function: ${ChipConfig.createPaymentFunction}');

    try {
      final response = await _client.functions.invoke(
        ChipConfig.createPaymentFunction,
        body: <String, dynamic>{
          'paymentType': 'trust',
          'trustId': trustId.toString(),
          'trustCode': trustCode,
          'userId': user.id,
          'clientId': clientId,
          'amount': amount,
          'description': 'Payment for Trust $trustCode',
        },
      );

      print('🟡 [TRUST PAYMENT SERVICE] Edge function response status: ${response.status}');
      print('🟡 [TRUST PAYMENT SERVICE] Edge function response data: ${response.data}');

      if (response.status != 200) {
        print('🔴 [TRUST PAYMENT SERVICE] Edge function returned error status: ${response.status}');
        throw Exception('Edge function error: ${response.status} - ${response.data}');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final paymentResponse = ChipPaymentResponse.fromJson(data);
        print('🟢 [TRUST PAYMENT SERVICE] Payment created: ${paymentResponse.id}');
        return paymentResponse;
      } else if (data is Map) {
        final paymentResponse = ChipPaymentResponse.fromJson(Map<String, dynamic>.from(data));
        print('🟢 [TRUST PAYMENT SERVICE] Payment created: ${paymentResponse.id}');
        return paymentResponse;
      }

      // Try to decode if it's a JSON string
      if (data is String) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          final paymentResponse = ChipPaymentResponse.fromJson(decoded);
          print('🟢 [TRUST PAYMENT SERVICE] Payment created: ${paymentResponse.id}');
          return paymentResponse;
        } catch (e) {
          print('🔴 [TRUST PAYMENT SERVICE] Failed to parse JSON string: $e');
          throw Exception('Failed to parse payment response: $e');
        }
      }

      print('🔴 [TRUST PAYMENT SERVICE] Invalid response format: ${data.runtimeType}');
      throw Exception('Failed to create payment: Invalid response format - ${data.runtimeType}');
    } catch (e, stackTrace) {
      print('🔴 [TRUST PAYMENT SERVICE] Error in createPayment: $e');
      print('🔴 [TRUST PAYMENT SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get payment history for a trust
  Future<List<TrustPayment>> getPaymentHistory(int trustId) async {
    final List<dynamic> rows = await _client
        .from('trust_payments')
        .select()
        .eq('trust_id', trustId)
        .order('created_at', ascending: false);

    return rows
        .map((e) => TrustPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All CHIP payments for the signed-in user (RLS), newest first.
  Future<List<TrustPayment>> fetchAllPaymentsForCurrentUser() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <TrustPayment>[];

    final List<dynamic> rows = await _client
        .from('trust_payments')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((e) => TrustPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific payment by ID
  Future<TrustPayment?> getPaymentById(int paymentId) async {
    final List<dynamic> rows = await _client
        .from('trust_payments')
        .select()
        .eq('id', paymentId)
        .limit(1);

    if (rows.isEmpty) return null;
    return TrustPayment.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Get payment by CHIP payment ID
  Future<TrustPayment?> getPaymentByChipId(String chipPaymentId) async {
    final List<dynamic> rows = await _client
        .from('trust_payments')
        .select()
        .eq('chip_payment_id', chipPaymentId)
        .limit(1);

    if (rows.isEmpty) return null;
    return TrustPayment.fromJson(rows.first as Map<String, dynamic>);
  }
}
