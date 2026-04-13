import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import '../utils/form_decoration_helper.dart';

class ExecutorDocumentDraft {
  ExecutorDocumentDraft({
    required this.id,
    required this.title,
    required this.file,
    required this.mimeType,
  });

  final String id;
  final String title;
  final PlatformFile file;
  final String mimeType;
}

class ExecutorDocumentFormScreen extends StatefulWidget {
  const ExecutorDocumentFormScreen({super.key});

  @override
  State<ExecutorDocumentFormScreen> createState() =>
      _ExecutorDocumentFormScreenState();
}

class _ExecutorDocumentFormScreenState extends State<ExecutorDocumentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  PlatformFile? _selectedFile;
  String? _mimeType;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to read this file. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final String mime =
          lookupMimeType(file.name, headerBytes: bytes) ??
              'application/octet-stream';
      setState(() {
        _selectedFile = file;
        _mimeType = mime;
      });
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }
    Navigator.of(context).pop(
      ExecutorDocumentDraft(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        file: _selectedFile!,
        mimeType: _mimeType ?? 'application/octet-stream',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add document')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEAEAEA),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 36,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Document',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a supporting document for your submission.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.description_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Document details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'Document title *',
                          hintText: 'For example: Death certificate',
                          prefixIcon: Icons.title_outlined,
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isPickingFile ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_selectedFile?.name ?? 'Select file'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_selectedFile != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • ${_selectedFile!.extension?.toUpperCase() ?? 'FILE'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _save,
              icon: const Icon(Icons.attach_file_outlined),
              label: Text(
                'Attach document',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

