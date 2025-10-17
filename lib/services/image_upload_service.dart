import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _client = Supabase.instance.client;

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Show image source selection dialog
  Future<File?> showImageSourceDialog() async {
    // This will be handled in the UI layer
    return null;
  }

  /// Upload image to Supabase storage
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '$timestamp-${userId.hashCode}.$extension';
      
      // Create storage path
      final storagePath = '$userId/avatar/profile/$fileName';
      
      // Upload to Supabase storage
      final response = await _client.storage
          .from('images')
          .uploadBinary(
            storagePath,
            await imageFile.readAsBytes(),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      if (response.isNotEmpty) {
        // Return the storage path (without bucket name)
        return storagePath;
      } else {
        throw Exception('Upload failed: Empty response');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload beloved/family member image to Supabase storage
  Future<String> uploadBelovedImage({
    required File imageFile,
    required String userId,
    required int belovedId,
    String? existingPath,
    Function(double)? onProgress,
  }) async {
    try {
      // Always generate a new filename to avoid CDN/browser caching issues
      // If existingPath provided, keep the same directory and change only the filename
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String extension = imageFile.path.split('.').last;
      final String fileName = '$timestamp-${userId.hashCode}.$extension';
      final String baseDir = (existingPath != null && existingPath.isNotEmpty)
          ? existingPath.substring(0, existingPath.lastIndexOf('/'))
          : '$userId/beloved/$belovedId/avatar';
      final String storagePath = '$baseDir/$fileName';

      final response = await _client.storage
          .from('images')
          .uploadBinary(
            storagePath,
            await imageFile.readAsBytes(),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      if (response.isNotEmpty) {
        // Delete old file if we replaced an existing one (best-effort)
        if (existingPath != null && existingPath.isNotEmpty && existingPath != storagePath) {
          try {
            await _client.storage.from('images').remove([existingPath]);
          } catch (_) {
            // ignore cleanup failures
          }
        }
        return storagePath;
      } else {
        throw Exception('Upload failed: Empty response');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Supabase storage
  Future<void> deleteImage(String imagePath) async {
    try {
      await _client.storage
          .from('images')
          .remove([imagePath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get public URL for an image
  String getPublicUrl(String imagePath) {
    return SupabaseConfig.getFullImageUrl(imagePath) ?? '';
  }

  /// Validate image file
  bool validateImage(File imageFile) {
    // Check file size (max 5MB)
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    if (imageFile.lengthSync() > maxSizeInBytes) {
      return false;
    }

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      return false;
    }

    return true;
  }

  /// Get image file size in MB
  double getImageSizeInMB(File imageFile) {
    return imageFile.lengthSync() / (1024 * 1024);
  }
}
