import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class FileUploadResult {
  final String storagePath;
  final String publicUrl;
  final String fileName;
  final int sizeBytes;
  final String mimeType;

  const FileUploadResult({
    required this.storagePath,
    required this.publicUrl,
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
  });
}

class FileUploadService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Pick multiple files from device. If [allowImagesOnly] is true, limits to common image types.
  static Future<List<PlatformFile>> pickMultipleFiles({
    bool allowImagesOnly = false,
    int? maxFiles,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withReadStream: false,
      type: allowImagesOnly ? FileType.image : FileType.any,
      allowedExtensions: allowImagesOnly ? null : null,
    );
    if (result == null) return [];
    final files = result.files;
    if (maxFiles != null && files.length > maxFiles) {
      return files.take(maxFiles).toList();
    }
    return files;
  }

  /// Upload a single file to Supabase storage under the 'attachments' bucket.
  /// Path convention: userId/conversationId/timestamp-originalName
  static Future<FileUploadResult> uploadAttachment({
    required File file,
    required String userId,
    required String conversationId,
    String bucket = 'attachments',
  }) async {
    final String fileName = p.basename(file.path);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String key = '$userId/$conversationId/$timestamp-$fileName';
    final List<int> bytes = await file.readAsBytes();
    final String mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final responsePath = await _client.storage
        .from(bucket)
        .uploadBinary(
          key,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
            cacheControl: '3600',
          ),
        );
    // Some SDK versions return 'bucket/key', others return 'key'. Normalize to 'key'.
    final String normalizedPath = responsePath.startsWith('$bucket/')
        ? responsePath.substring(bucket.length + 1)
        : responsePath;
    final String publicUrl = _client.storage.from(bucket).getPublicUrl(normalizedPath);
    return FileUploadResult(
      storagePath: normalizedPath,
      publicUrl: publicUrl,
      fileName: fileName,
      sizeBytes: bytes.length,
      mimeType: mimeType,
    );
  }
}


