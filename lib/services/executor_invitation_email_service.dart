import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ExecutorInvitationEmailService {
  ExecutorInvitationEmailService._();

  static final ExecutorInvitationEmailService instance =
      ExecutorInvitationEmailService._();

  static const String _functionName = 'executor-registration-email';

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<void> sendInvitationForBeloved({
    required int belovedId,
    required String recipientEmail,
    required String executorCode,
  }) async {
    try {
      final FunctionResponse response = await _client.functions.invoke(
        _functionName,
        body: <String, dynamic>{
          'belovedId': belovedId,
          // Backward-compatible fields for older deployed function contracts.
          'recipientEmail': recipientEmail,
          'executorCode': executorCode,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        developer.log(
          'Failed to send executor invitation email',
          name: 'EXECUTOR INVITATION EMAIL',
          error: 'status=${response.status}, data=${response.data}',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'sendInvitationForBeloved failed',
        name: 'EXECUTOR INVITATION EMAIL',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
