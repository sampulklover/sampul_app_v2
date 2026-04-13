class ExecutorDocument {
  final String id;
  final int executorId;
  final String? title;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final String documentType;
  final DateTime uploadedAt;
  final String uuid;

  const ExecutorDocument({
    required this.id,
    required this.executorId,
    this.title,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.documentType,
    required this.uploadedAt,
    required this.uuid,
  });

  factory ExecutorDocument.fromJson(Map<String, dynamic> json) {
    return ExecutorDocument(
      id: json['id'] as String,
      executorId: (json['executor_id'] as num).toInt(),
      title: json['title'] as String?,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      fileType: json['file_type'] as String,
      documentType: json['document_type'] as String? ?? 'supporting',
      uploadedAt:
          DateTime.tryParse(json['uploaded_at'] as String? ?? '') ??
              DateTime.now(),
      uuid: json['uuid'] as String? ?? '',
    );
  }
}

