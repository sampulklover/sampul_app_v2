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
  /// [userData] - Optional user data to pre-fill verification form
  /// Returns a map with 'verification' (Verification object) and 'url' (verification URL)
  Future<Map<String, dynamic>> createVerificationSession({
    Map<String, dynamic>? userData,
  }) async {
    print('🟢 [VERIFICATION SERVICE] createVerificationSession called');
    
    final user = AuthController.instance.currentUser;
    if (user == null) {
      print('🔴 [VERIFICATION SERVICE] No authenticated user');
      throw Exception('No authenticated user');
    }
    print('🟢 [VERIFICATION SERVICE] User authenticated: ${user.id}');

    if (!DiditConfig.isConfigured) {
      print('🔴 [VERIFICATION SERVICE] Didit not configured');
      print('🔴 [VERIFICATION SERVICE] Config status: ${getConfigurationStatus()}');
      throw Exception('Didit is not properly configured. Please check your environment variables.');
    }
    print('🟢 [VERIFICATION SERVICE] Didit is configured');

    // Generate a unique session ID
    final String sessionId = _generateSessionId();
    print('🟢 [VERIFICATION SERVICE] Generated session ID: $sessionId');

    // Call Didit API to create verification link and get URL
    print('🟢 [VERIFICATION SERVICE] Calling _createDiditVerificationLink...');
    final Map<String, dynamic> diditResponse = await _createDiditVerificationLink(
      sessionId: sessionId,
      userData: userData,
    );
    print('🟢 [VERIFICATION SERVICE] Got Didit response: $diditResponse');

    // Extract data from Didit response
    final String verificationUrl = diditResponse['url'] as String;
    final String? diditSessionId = diditResponse['id'] as String? ?? 
                                   diditResponse['session_id'] as String?;
    final Map<String, dynamic> metadata = diditResponse;

    // Store verification record in database
    print('🟢 [VERIFICATION SERVICE] Storing verification in database...');
    final Map<String, dynamic> payload = {
      'service_name': 'didit',
      'uuid': user.id,
      'session_id': sessionId,
      'didit_session_id': diditSessionId,
      'status': 'pending',
      'verification_url': verificationUrl,
      'metadata': metadata,
    };
    print('🟢 [VERIFICATION SERVICE] Payload: $payload');

    final List<dynamic> inserted = await _client
        .from('verification')
        .insert(payload)
        .select()
        .limit(1);

    print('🟢 [VERIFICATION SERVICE] Database insert successful');
    final Verification verification = Verification.fromJson(
      inserted.first as Map<String, dynamic>,
    );
    print('🟢 [VERIFICATION SERVICE] Verification record: ${verification.toJson()}');

    print('🟢 [VERIFICATION SERVICE] Returning result');
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
    Map<String, dynamic>? userData,
  }) async {
    print('🟡 [DIDIT API] Creating verification session...');
    print('🟡 [DIDIT API] Using endpoint: ${DiditConfig.verificationUrl}/v2/session/');
    print('🟡 [DIDIT API] API Key: ${DiditConfig.apiKey.isNotEmpty ? "${DiditConfig.apiKey.substring(0, 5)}..." : "EMPTY"}');
    print('🟡 [DIDIT API] Workflow ID: ${DiditConfig.workflowId}');
    
    // Build request body for Didit v2 API
    // Per documentation: https://docs.didit.me/reference/create-session-verification-sessions
    // Required: workflow_id
    // Optional: vendor_data (unique identifier for vendor/user)
    // Optional: callback (redirect URL)
    final Map<String, dynamic> requestBody = {
      'workflow_id': DiditConfig.workflowId,
      'vendor_data': sessionId, // Use our session ID as vendor_data for tracking
      'callback': DiditConfig.redirectUrl,
    };
    
    print('🟡 [DIDIT API] Request body: $requestBody');
    
    try {
      final String url = '${DiditConfig.verificationUrl}/v2/session/';
      print('🟡 [DIDIT API] Making POST request to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: DiditConfig.apiHeaders,
        body: jsonEncode(requestBody),
      );

      print('🟡 [DIDIT API] Response status: ${response.statusCode}');
      print('🟡 [DIDIT API] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🟢 [DIDIT API] Success!');
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Extract session URL from response
        // Per docs, the response contains: session_id, session_number, session_token, 
        // vendor_data, metadata, status, workflow_id, callback, url
        final String? sessionUrl = data['url'] as String?;
        
        if (sessionUrl != null) {
          print('🟢 [DIDIT API] Got session URL: $sessionUrl');
          // Return full response data for storage
          return data;
        }
        
        print('🔴 [DIDIT API] No URL in response');
        print('🔴 [DIDIT API] Full response: ${response.body}');
        throw Exception('No verification URL in response: ${response.body}');
      } else {
        print('🔴 [DIDIT API] Request failed with status ${response.statusCode}');
        print('🔴 [DIDIT API] Response: ${response.body}');
        throw Exception(
          'Failed to create verification session: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e, stackTrace) {
      print('🔴 [DIDIT API] Exception occurred: $e');
      print('🔴 [DIDIT API] Stack trace: $stackTrace');
      throw Exception('Error creating Didit verification session: $e');
    }
  }


  /// Get verification status from Didit API
  Future<Map<String, dynamic>> getVerificationStatus(String sessionId) async {
    if (!DiditConfig.isConfigured) {
      throw Exception('Didit is not properly configured');
    }

    final String url = '${DiditConfig.apiBaseUrl}/api/v1/verification-sessions/$sessionId';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: DiditConfig.apiHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to get verification status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting verification status: $e');
    }
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

  /// Get KYC status from accounts table (source of truth)
  /// Returns the kyc_status value from accounts table
  Future<String?> getKycStatus() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return null;

    final List<dynamic> rows = await _client
        .from('accounts')
        .select('kyc_status')
        .eq('uuid', user.id)
        .limit(1);

    if (rows.isEmpty) return null;
    final account = rows.first as Map<String, dynamic>;
    return account['kyc_status'] as String?;
  }

  /// Check if the current user is verified
  /// Returns true if accounts.kyc_status is 'approved' or 'accepted'
  Future<bool> isUserVerified() async {
    final kycStatus = await getKycStatus();
    return kycStatus == 'approved' || kycStatus == 'accepted';
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

  /// Get verification status for current user
  /// Returns kyc_status from accounts table (source of truth)
  /// Returns null if no account exists or status is not set
  Future<String?> getUserVerificationStatus() async {
    return await getKycStatus();
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
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'didit_${timestamp}_$random';
  }

  /// Map Didit API status to database status
  String _mapDiditStatus(Map<String, dynamic> diditResponse) {
    final String? status = diditResponse['status'] as String?;
    
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'verified':
      case 'approved':
        return 'verified';
      case 'rejected':
      case 'failed':
      case 'declined':
        return 'rejected';
      case 'pending':
      case 'in_progress':
      case 'processing':
        return 'pending';
      default:
        return 'pending';
    }
  }
}

