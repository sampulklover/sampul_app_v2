import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/verification.dart';
import '../config/didit_config.dart';
import 'supabase_service.dart';

class VerificationService {
  VerificationService._();
  static final VerificationService instance = VerificationService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Create a new verification session with Didit
  /// 
  /// Returns a map with 'verification' (Verification object) and 'url' (verification URL)
  Future<Map<String, dynamic>> createVerificationSession({
    String? workflowIdOverride,
    String sessionPrefix = 'didit',
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    if (!DiditConfig.isConfigured) {
      throw Exception('Didit is not properly configured. Please check your environment variables.');
    }

    // Generate a unique session ID
    final String sessionId = _generateSessionId(prefix: sessionPrefix);
    final String workflowId = (workflowIdOverride?.trim().isNotEmpty ?? false)
        ? workflowIdOverride!.trim()
        : DiditConfig.workflowId;
    if (workflowId.isEmpty) {
      throw Exception('Didit workflow is not configured.');
    }

    // Call Didit API to create verification link and get URL
    final Map<String, dynamic> diditResponse = await _createDiditVerificationLink(
      sessionId: sessionId,
      workflowId: workflowId,
    );

    // Extract data from Didit response
    final String verificationUrl = diditResponse['url'] as String;
    final String? diditSessionId = diditResponse['id'] as String? ?? 
                                   diditResponse['session_id'] as String?;
    final Map<String, dynamic> metadata = diditResponse;

    // Store verification record in database
    final Map<String, dynamic> payload = {
      'service_name': 'didit',
      'uuid': user.id,
      'session_id': sessionId,
      'didit_session_id': diditSessionId,
      'status': 'pending',
      'verification_url': verificationUrl,
      'metadata': metadata,
    };

    final List<dynamic> inserted = await _client
        .from('verification')
        .insert(payload)
        .select()
        .limit(1);

    final Verification verification = Verification.fromJson(
      inserted.first as Map<String, dynamic>,
    );
    return {
      'verification': verification,
      'url': verificationUrl,
    };
  }

  /// Create a verification link via Didit API
  /// Based on Didit API v2 documentation: https://docs.didit.me/reference/create-session-verification-sessions
  /// Returns a map containing the verification URL and full response data
  Future<Map<String, dynamic>> _createDiditVerificationLink({
    required String sessionId,
    required String workflowId,
  }) async {
    // Build request body for Didit v2 API
    // Per documentation: https://docs.didit.me/reference/create-session-verification-sessions
    // Required: workflow_id
    // Optional: vendor_data (unique identifier for vendor/user)
    // Optional: callback (redirect URL)
    final Map<String, dynamic> requestBody = {
      'workflow_id': workflowId,
      'vendor_data': sessionId, // Use our session ID as vendor_data for tracking
      'callback': DiditConfig.redirectUrl,
    };
    
    try {
      final String url = '${DiditConfig.verificationUrl}/v2/session/';
      final response = await http.post(
        Uri.parse(url),
        headers: DiditConfig.apiHeaders,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Extract session URL from response
        // Per docs, the response contains: session_id, session_number, session_token, 
        // vendor_data, metadata, status, workflow_id, callback, url
        final String? sessionUrl = data['url'] as String?;
        
        if (sessionUrl != null) {
          // Return full response data for storage
          return data;
        }

        throw Exception('No verification URL in response');
      } else {
        String detail = response.body;
        try {
          final dynamic parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            final dynamic message = parsed['message'] ?? parsed['error'] ?? parsed['detail'];
            if (message != null) {
              detail = message.toString();
            }
          }
        } catch (_) {
          // Keep raw body when it is not JSON.
        }
        throw Exception(
          'Failed to create verification session (${response.statusCode})'
          ' for workflow "$workflowId": $detail'
        );
      }
    } catch (e) {
      throw Exception('Error creating Didit verification session: $e');
    }
  }


  /// Get verification status from Didit API
  Future<Map<String, dynamic>> getVerificationStatus(String sessionId) async {
    if (!DiditConfig.isConfigured) {
      throw Exception('Didit is not properly configured');
    }

    final List<String> candidateUrls = <String>[
      '${DiditConfig.verificationUrl}/v2/session/$sessionId',
      '${DiditConfig.apiBaseUrl}/api/v1/verification-sessions/$sessionId',
    ];

    Object? lastError;
    for (final String url in candidateUrls) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: DiditConfig.apiHeaders,
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception('Status endpoint returned ${response.statusCode}');
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Error getting verification status: $lastError');
  }

  /// Update verification status in database
  Future<Verification> updateVerificationStatus(
    String sessionId,
    String status, {
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    final Map<String, dynamic> updateData = {'status': status};
    
    // Set completed_at if status is verified or rejected
    if (status == 'verified' || status == 'rejected') {
      updateData['completed_at'] = (completedAt ?? DateTime.now()).toIso8601String();
    }
    
    // Add error message if provided
    if (errorMessage != null) {
      updateData['error_message'] = errorMessage;
    }
    
    // Merge metadata if provided
    if (metadata != null) {
      updateData['metadata'] = metadata;
    }

    final List<dynamic> rows = await _client
        .from('verification')
        .update(updateData)
        .eq('session_id', sessionId)
        .select()
        .limit(1);

    if (rows.isEmpty) {
      throw Exception('Verification session not found');
    }

    return Verification.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Get all verification records for current user
  Future<List<Verification>> getUserVerifications() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <Verification>[];

    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((e) => Verification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get verification by session ID
  Future<Verification?> getVerificationBySessionId(String sessionId) async {
    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('session_id', sessionId)
        .limit(1);

    if (rows.isEmpty) return null;
    return Verification.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Get verification by ID
  Future<Verification?> getVerificationById(int id) async {
    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('id', id)
        .limit(1);

    if (rows.isEmpty) return null;
    return Verification.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Sync verification status with Didit API
  /// This should be called periodically or via webhook
  Future<Verification> syncVerificationStatus(String sessionId) async {
    final verification = await getVerificationBySessionId(sessionId);
    if (verification == null) {
      throw Exception('Verification session not found');
    }

    // Use Didit session ID if available, otherwise use our session ID
    final String diditSessionId = verification.diditSessionId ?? sessionId;
    final Map<String, dynamic> diditStatus = await getVerificationStatus(diditSessionId);
    
    // Map Didit status to your database status
    final String status = _mapDiditStatus(diditStatus);
    
    // Check if verification is completed
    DateTime? completedAt;
    if (status == 'verified' || status == 'rejected') {
      completedAt = DateTime.now();
    }
    
    return await updateVerificationStatus(
      sessionId,
      status,
      completedAt: completedAt,
      metadata: diditStatus,
    );
  }

  /// Delete verification record
  Future<void> deleteVerification(int id) async {
    await _client.from('verification').delete().eq('id', id);
  }

  /// Check if the current user is verified
  /// Returns true when any verification row is approved/accepted/verified.
  Future<bool> isUserVerified() async {
    final Verification? approved = await getLatestVerificationFiltered(
      statuses: const <String>['verified', 'approved', 'accepted'],
    );
    return approved != null;
  }

  /// Get the latest verification record for current user
  /// Returns the most recent verification, or null if none exists
  Future<Verification?> getLatestVerification() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;

    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Verification.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Returns the latest pending verification for current user.
  /// Optionally filters by session_id prefix (e.g. didit_kyc_ / didit_cert_).
  Future<Verification?> getLatestPendingVerification({String? sessionPrefix}) async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;

    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('uuid', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    if (rows.isEmpty) return null;

    final List<Verification> verifications = rows
        .whereType<Map<String, dynamic>>()
        .map(Verification.fromJson)
        .toList();
    if (verifications.isEmpty) return null;

    if (sessionPrefix == null || sessionPrefix.isEmpty) {
      return verifications.first;
    }

    for (final Verification v in verifications) {
      if (v.sessionId.startsWith(sessionPrefix)) return v;
    }
    return null;
  }

  /// Returns latest verification matching optional status list and session prefix.
  Future<Verification?> getLatestVerificationFiltered({
    List<String>? statuses,
    String? sessionPrefix,
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;

    final List<dynamic> rows = await _client
        .from('verification')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    final List<String>? normalizedStatuses = statuses
        ?.map((s) => s.toLowerCase())
        .toList();

    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final Verification v = Verification.fromJson(row);
      final String status = (v.status ?? '').toLowerCase();
      if (normalizedStatuses != null && !normalizedStatuses.contains(status)) {
        continue;
      }
      if (sessionPrefix != null &&
          sessionPrefix.isNotEmpty &&
          !v.sessionId.startsWith(sessionPrefix)) {
        continue;
      }
      return v;
    }
    return null;
  }

  /// Get verification status for current user
  /// Returns the latest status from verification table.
  Future<String?> getUserVerificationStatus() async {
    final Verification? latest = await getLatestVerification();
    return latest?.status?.toLowerCase();
  }

  /// Test Didit configuration and API connectivity
  /// Returns true if configuration is valid and API is reachable
  Future<bool> testConfiguration() async {
    if (!DiditConfig.isConfigured) {
      return false;
    }

    try {
      // Try to make a simple API call to verify connectivity
      // This is a lightweight test - adjust based on Didit's actual API
      final response = await http.get(
        Uri.parse('${DiditConfig.apiBaseUrl}/api/v1/health'),
        headers: DiditConfig.apiHeaders,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      // If health endpoint doesn't exist, that's okay
      // We'll know if there's a real issue when creating a session
      return true; // Assume configured if we can't test
    }
  }

  /// Get configuration status for debugging
  Map<String, dynamic> getConfigurationStatus() {
    return {
      'is_configured': DiditConfig.isConfigured,
      'api_base_url': DiditConfig.apiBaseUrl,
      'verification_url': DiditConfig.verificationUrl,
      'has_api_key': DiditConfig.apiKey.isNotEmpty,
      'has_workflow_id': DiditConfig.workflowId.isNotEmpty,
      'workflow_id': DiditConfig.workflowId,
      'redirect_url': DiditConfig.redirectUrl,
    };
  }

  /// Generate a unique session ID
  String _generateSessionId({String prefix = 'didit'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return '${prefix}_${timestamp}_$random';
  }

  /// Map Didit API status to database status
  String _mapDiditStatus(Map<String, dynamic> diditResponse) {
    final List<String> statusCandidates = <String>[
      diditResponse['status']?.toString() ?? '',
      diditResponse['verification_status']?.toString() ?? '',
      diditResponse['kyc_status']?.toString() ?? '',
      diditResponse['decision']?.toString() ?? '',
      diditResponse['result']?.toString() ?? '',
    ];

    for (final String raw in statusCandidates) {
      final String status = raw.toLowerCase().trim();
      if (status.isEmpty) continue;

      if (status == 'completed' ||
          status == 'verified' ||
          status == 'approved' ||
          status == 'accepted' ||
          status == 'success' ||
          status == 'passed' ||
          status == 'pass') {
        return 'verified';
      }

      if (status == 'rejected' ||
          status == 'failed' ||
          status == 'declined' ||
          status == 'denied' ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'error') {
        return 'rejected';
      }

      if (status == 'pending' ||
          status == 'in_progress' ||
          status == 'processing' ||
          status == 'in_review' ||
          status == 'review') {
        return 'pending';
      }
    }

    return 'pending';
  }
}

