/// Supabase Configuration
/// 
/// This file contains all Supabase-related configuration.
/// To update URLs or keys, modify the values below.
/// 
/// For production, consider using environment variables or a secure configuration.
library;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // ========================================
  // SUPABASE PROJECT CONFIGURATION
  // ========================================
  // For production, read from environment variables loaded via flutter_dotenv
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get passwordResetRedirectUrl => dotenv.env['PASSWORD_RESET_REDIRECT_URL'] ?? 'https://sampul.co/change-password';
  
  // ========================================
  // STORAGE CONFIGURATION
  // ========================================
  
  /// Storage URL for public files (automatically derived from supabaseUrl)
  static String get storageUrl => '$supabaseUrl/storage/v1/object/public';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Get full image URL from storage path
  static String? getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return '$storageUrl/images/$imagePath';
  }
  
  /// Get storage bucket URL for a specific bucket
  static String getBucketUrl(String bucketName) {
    return '$storageUrl/$bucketName';
  }
}
