/// Supabase Configuration
/// 
/// This file contains all Supabase-related configuration.
/// To update URLs or keys, modify the values below.
/// 
/// For production, consider using environment variables or a secure configuration.
class SupabaseConfig {
  // ========================================
  // SUPABASE PROJECT CONFIGURATION
  // ========================================
  // TODO: Replace these with your actual Supabase project values
  // You can find these in your Supabase project settings at:
  // https://app.supabase.com/project/[your-project]/settings/api
  
  /// Your Supabase project URL
  static const String supabaseUrl = 'https://rfzblaianldrfwdqdijl.supabase.co';
  
  /// Your Supabase anonymous key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmemJsYWlhbmxkcmZ3ZHFkaWpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQwMDM5OTMsImV4cCI6MjAxOTU3OTk5M30.QOxPgVvOV0Efon8aleoAnlNKgkI2XwEPgIgz76_oIBU';
  
  // ========================================
  // STORAGE CONFIGURATION
  // ========================================
  
  /// Storage URL for public files (automatically derived from supabaseUrl)
  static const String storageUrl = '$supabaseUrl/storage/v1/object/public';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Get full image URL from storage path
  /// 
  /// Example:
  /// - Input: "46847b5e-ab58-42c7-bfcc-1efe5f97729c/avatar/profile/1753477993914-653184335.png"
  /// - Output: "https://rfzblaianldrfwdqdijl.supabase.co/storage/v1/object/public/images/46847b5e-ab58-42c7-bfcc-1efe5f97729c/avatar/profile/1753477993914-653184335.png"
  static String? getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return '$storageUrl/images/$imagePath';
  }
  
  /// Get storage bucket URL for a specific bucket
  static String getBucketUrl(String bucketName) {
    return '$storageUrl/$bucketName';
  }
}
