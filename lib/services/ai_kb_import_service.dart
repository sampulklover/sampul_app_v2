import 'dart:typed_data';
import 'file_upload_service.dart';
import 'supabase_service.dart';

class AiKbImportResult {
  final String sourceId;
  final int insertedEntries;
  final int insertedChunks;

  const AiKbImportResult({
    required this.sourceId,
    required this.insertedEntries,
    required this.insertedChunks,
  });

  factory AiKbImportResult.fromJson(Map<String, dynamic> json) {
    return AiKbImportResult(
      sourceId: (json['sourceId'] as String?) ?? '',
      insertedEntries: (json['insertedEntries'] as num?)?.toInt() ?? 0,
      insertedChunks: (json['insertedChunks'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiKbImportPreviewRow {
  final String sheet;
  final int row;
  final String? category;
  final String? product;
  final String? language;
  final String? question;
  final String answer;

  const AiKbImportPreviewRow({
    required this.sheet,
    required this.row,
    required this.answer,
    this.category,
    this.product,
    this.language,
    this.question,
  });

  factory AiKbImportPreviewRow.fromJson(Map<String, dynamic> json) {
    return AiKbImportPreviewRow(
      sheet: (json['sheet'] as String?) ?? '',
      row: (json['row'] as num?)?.toInt() ?? 0,
      category: json['category'] as String?,
      product: json['product'] as String?,
      language: json['language'] as String?,
      question: json['question'] as String?,
      answer: (json['answer'] as String?) ?? '',
    );
  }
}

class AiKbImportPreviewResult {
  final int parsedEntries;
  final int parsedChunks;
  final List<AiKbImportPreviewRow> preview;

  const AiKbImportPreviewResult({
    required this.parsedEntries,
    required this.parsedChunks,
    required this.preview,
  });

  factory AiKbImportPreviewResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['preview'] as List?) ?? const [];
    return AiKbImportPreviewResult(
      parsedEntries: (json['parsedEntries'] as num?)?.toInt() ?? 0,
      parsedChunks: (json['parsedChunks'] as num?)?.toInt() ?? 0,
      preview: raw
          .whereType<Map<String, dynamic>>()
          .map(AiKbImportPreviewRow.fromJson)
          .toList(),
    );
  }
}

class AiKbImportService {
  static final AiKbImportService instance = AiKbImportService._();
  AiKbImportService._();

  Future<AiKbImportResult> importFromFile({
    required List<int> bytes,
    required String fileName,
    required String sourceName,
    String product = 'general',
    String language = 'en',
    String version = 'v1',
    bool replace = false,
  }) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }

    final upload = await FileUploadService.uploadBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      userId: user.id,
      namespace: 'kb-import',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bucket: 'attachments',
    );

    final res = await SupabaseService.instance.client.functions.invoke(
      'kb-import',
      body: {
        'storageBucket': 'attachments',
        'storagePath': upload.storagePath,
        'name': sourceName,
        'product': product,
        'language': language,
        'version': version,
        'replace': replace,
      },
    );

    if (res.status != 200) {
      throw Exception('Import failed: ${res.data}');
    }

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return AiKbImportResult.fromJson(data);
    }
    return const AiKbImportResult(sourceId: '', insertedEntries: 0, insertedChunks: 0);
  }

  Future<AiKbImportPreviewResult> previewFromFile({
    required List<int> bytes,
    required String fileName,
    required String sourceName,
    String product = 'general',
    String language = 'en',
    String version = 'v1',
    int previewLimit = 10,
  }) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }

    final upload = await FileUploadService.uploadBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      userId: user.id,
      namespace: 'kb-import',
      mimeType: 'application/octet-stream',
      bucket: 'attachments',
    );

    final res = await SupabaseService.instance.client.functions.invoke(
      'kb-import',
      body: {
        'storageBucket': 'attachments',
        'storagePath': upload.storagePath,
        'name': sourceName,
        'product': product,
        'language': language,
        'version': version,
        'dryRun': true,
        'previewLimit': previewLimit,
      },
    );

    if (res.status != 200) {
      throw Exception('Preview failed: ${res.data}');
    }

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return AiKbImportPreviewResult.fromJson(data);
    }
    return const AiKbImportPreviewResult(parsedEntries: 0, parsedChunks: 0, preview: []);
  }

  Future<void> deleteImportSource({required String sourceId}) async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }

    final res = await SupabaseService.instance.client.functions.invoke(
      'kb-delete',
      body: {
        'sourceId': sourceId,
      },
    );

    if (res.status != 200) {
      throw Exception('Delete failed: ${res.data}');
    }
  }
}

