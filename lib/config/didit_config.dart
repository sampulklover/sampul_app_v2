/// Didit Verification Configuration
/// 
/// This file contains all Didit-related configuration.
/// Matches the website configuration format for consistency.
/// 
/// For production, use environment variables loaded via flutter_dotenv.
library;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DiditConfig {
  // ========================================
  // DIDIT API CONFIGURATION
  // ========================================
  
  /// Didit API Base URL (matches NEXT_PUBLIC_DIDIT_URL from website)
  static String get apiBaseUrl => dotenv.env['DIDIT_URL'] ?? 
                                  dotenv.env['NEXT_PUBLIC_DIDIT_URL'] ?? 
                                  'https://apx.didit.me';
  
  /// Didit Verification URL (matches NEXT_PUBLIC_DIDIT_VERIFICATION_URL from website)
  static String get verificationUrl => dotenv.env['DIDIT_VERIFICATION_URL'] ?? 
                                       dotenv.env['NEXT_PUBLIC_DIDIT_VERIFICATION_URL'] ?? 
                                       'https://verification.didit.me';
  
  /// Didit Client ID (matches NEXT_PUBLIC_DIDIT_CLIENT_ID from website)
  /// IMPORTANT: This should be your API KEY from Didit dashboard (App Settings > API & Webhooks)
  /// NOT the App ID - use the "API Key" field, not "App ID" field
  static String get clientId => dotenv.env['DIDIT_CLIENT_ID'] ?? 
                                 dotenv.env['NEXT_PUBLIC_DIDIT_CLIENT_ID'] ?? 
                                 dotenv.env['DIDIT_API_KEY'] ?? '';
  
  /// Didit API Key (same as Client ID - both refer to the API Key from dashboard)
  /// Get this from: Didit Console > App Settings > API & Webhooks tab > API Key field
  static String get apiKey => dotenv.env['DIDIT_API_KEY'] ?? 
                              dotenv.env['DIDIT_CLIENT_ID'] ?? 
                              dotenv.env['NEXT_PUBLIC_DIDIT_CLIENT_ID'] ?? '';
  
  /// Didit Client Secret (matches DIDIT_CLIENT_SECRET from website)
  /// NOTE: Currently NOT used - we use x-api-key authentication, not client ID/secret
  /// This is kept for compatibility with website config format
  static String get clientSecret => dotenv.env['DIDIT_CLIENT_SECRET'] ?? '';
  
  /// Didit Workflow ID (required for creating verification sessions)
  /// Get this from your Didit Console under Workflows
  static String get workflowId => dotenv.env['DIDIT_WORKFLOW_ID'] ?? 
                                  dotenv.env['NEXT_PUBLIC_DIDIT_WORKFLOW_ID'] ?? '';
  
  /// Redirect URL after verification completion
  /// Uses deep link to return to app (similar to Stripe)
  static String get redirectUrl => dotenv.env['DIDIT_REDIRECT_URL'] ?? 
                                  'sampul://verification/complete';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Check if Didit is properly configured
  /// Requires both API key and workflow ID
  static bool get isConfigured => apiKey.isNotEmpty && workflowId.isNotEmpty;
  
  /// Get headers for Didit API requests using x-api-key authentication
  /// This is the standard authentication method per Didit documentation
  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };
}











