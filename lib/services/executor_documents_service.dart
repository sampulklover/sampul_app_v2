import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/executor_document.dart';
import 'file_upload_service.dart';
import 'supabase_service.dart';

class ExecutorDocumentsService {
  ExecutorDocumentsService._();
  static final ExecutorDocumentsService instance = ExecutorDocumentsService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<ExecutorDocument>> listForExecutor(int executorId) async {
    final List<dynamic> rows = await _client
        .from('executor_documents')
        .select()
        .eq('executor_id', executorId)
        .order('uploaded_at', ascending: true);
    return rows
        .map((dynamic e) => ExecutorDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExecutorDocument> uploadAndCreateRow({
    required int executorId,
    String? title,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String documentType = 'supporting',
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to upload documents.');
    }

    final FileUploadResult uploaded = await FileUploadService.uploadBytes(
      bytes: bytes,
      fileName: fileName,
      userId: user.id,
      namespace: 'executor-documents/$executorId',
      mimeType: mimeType,
      bucket: 'images',
    );

    final Map<String, dynamic> inserted = await _client
        .from('executor_documents')
        .insert(<String, dynamic>{
          'executor_id': executorId,
          'title': (title ?? '').trim().isEmpty ? null : title!.trim(),
          'file_name': fileName,
          'file_path': uploaded.storagePath,
          'file_size': uploaded.sizeBytes,
          'file_type': uploaded.mimeType,
          'document_type': documentType,
          'uuid': user.id,
        })
        .select()
        .single();

    return ExecutorDocument.fromJson(inserted);
  }

  Future<void> delete(ExecutorDocument document) async {
    // Best-effort: remove storage object first.
    try {
      await _client.storage.from('images').remove(<String>[document.filePath]);
    } catch (_) {
      // Keep going so the row can still be removed.
    }
    await _client.from('executor_documents').delete().eq('id', document.id);
  }
}

