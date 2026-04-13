import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/ai_kb_import_service.dart';
import '../utils/admin_utils.dart';
import 'admin_ai_kb_source_entries_screen.dart';

class AdminAiKbImportScreen extends StatefulWidget {
  const AdminAiKbImportScreen({super.key});

  @override
  State<AdminAiKbImportScreen> createState() => _AdminAiKbImportScreenState();
}

class _AdminAiKbImportScreenState extends State<AdminAiKbImportScreen> {
  bool _hasContentAccess = false;
  bool _isLoading = true;
  bool _isImporting = false;
  bool _replace = false;

  String _product = 'general';
  String _language = 'en';
  String _version = 'v1';

  List<Map<String, dynamic>> _sources = const [];

  String _formatCreatedAt(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final allowed = await AdminUtils.canManageAppContent();
    if (!mounted) return;
    setState(() {
      _hasContentAccess = allowed;
    });
    if (!allowed) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final rows = await SupabaseService.instance.client
          .from('ai_kb_sources')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _sources = (rows as List).whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load imports: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleSourceActive(String id, bool isActive) async {
    try {
      await SupabaseService.instance.client
          .from('ai_kb_sources')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      await _loadSources();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSource(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete import'),
        content: Text('Delete "$name"? This also removes its KB entries and the uploaded file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AiKbImportService.instance.deleteImportSource(sourceId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import deleted'), backgroundColor: Colors.green),
      );
      await _loadSources();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importFile() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          setState(() {
            _isImporting = false;
          });
        }
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Could not read file bytes');
      }

      final preview = await AiKbImportService.instance.previewFromFile(
        bytes: bytes,
        fileName: file.name,
        sourceName: file.name,
        product: _product,
        language: _language,
        version: _version,
        previewLimit: 10,
      );

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm import'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('We found ${preview.parsedEntries} entries to import.'),
                  const SizedBox(height: 12),
                  const Text('Preview (first 10):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: preview.preview.length,
                      itemBuilder: (context, idx) {
                        final p = preview.preview[idx];
                        final q = (p.question ?? '').trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.sheet} • row ${p.row}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (q.isNotEmpty) Text('Q: $q', maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('A: ${p.answer}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Import'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (mounted) {
          setState(() {
            _isImporting = false;
          });
        }
        return;
      }

      final res = await AiKbImportService.instance.importFromFile(
        bytes: bytes,
        fileName: file.name,
        sourceName: file.name,
        product: _product,
        language: _language,
        version: _version,
        replace: _replace,
      );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${res.insertedEntries} entries'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSources();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final csv = await rootBundle.loadString('assets/kb_template.csv');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kb_template.csv');
      await file.writeAsString(csv, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: 'kb_template.csv')],
        subject: 'Sampul AI KB Template (CSV)',
        text: 'Save this file to Files, fill it in, then import it back in Sampul.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load template: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContentAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KB Imports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSources,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSources,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import a KB file',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload an XLSX/CSV and we’ll update the AI knowledge base. Your live chat will use it immediately.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isImporting ? null : _downloadTemplate,
                              icon: const Icon(Icons.download_outlined, size: 18),
                              label: const Text('Download template'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _product,
                                  decoration: const InputDecoration(labelText: 'Product'),
                                  items: const [
                                    DropdownMenuItem(value: 'general', child: Text('General')),
                                    DropdownMenuItem(value: 'hibah', child: Text('Hibah')),
                                    DropdownMenuItem(value: 'wasiat', child: Text('Wasiat')),
                                    DropdownMenuItem(value: 'executor', child: Text('Executor')),
                                    DropdownMenuItem(value: 'trust', child: Text('Trust')),
                                  ],
                                  onChanged: _isImporting ? null : (v) => setState(() => _product = v ?? 'general'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _language,
                                  decoration: const InputDecoration(labelText: 'Language'),
                                  items: const [
                                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                                    DropdownMenuItem(value: 'bm', child: Text('Bahasa (bm)')),
                                  ],
                                  onChanged: _isImporting ? null : (v) => setState(() => _language = v ?? 'en'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _version,
                            decoration: const InputDecoration(labelText: 'Version (e.g. v1, v2)'),
                            enabled: !_isImporting,
                            onChanged: (v) => _version = v.trim().isEmpty ? 'v1' : v.trim(),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _replace,
                            onChanged: _isImporting ? null : (v) => setState(() => _replace = v),
                            title: const Text('Replace existing'),
                            subtitle: const Text('Use this when re-uploading the same KB to avoid duplicates.'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isImporting ? null : _importFile,
                              icon: _isImporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(_isImporting ? 'Importing…' : 'Choose file and import'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Import history',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_sources.isEmpty)
                    Text(
                      'No imports yet.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  else
                    ..._sources.map((s) {
                      final id = (s['id'] ?? '').toString();
                      final name = (s['name'] ?? '').toString();
                      final product = (s['product'] ?? '').toString();
                      final language = (s['language'] ?? '').toString();
                      final version = (s['version'] ?? '').toString();
                      final isActive = (s['is_active'] as bool?) ?? false;
                      final createdAt = _formatCreatedAt((s['created_at'] ?? '').toString());

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AdminAiKbSourceEntriesScreen(
                                  sourceId: id,
                                  sourceName: name,
                                ),
                              ),
                            );
                          },
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${product.isEmpty ? 'general' : product} • ${language.isEmpty ? '-' : language} • ${version.isEmpty ? '-' : version}\n$createdAt',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: (v) => _toggleSourceActive(id, v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete import',
                                onPressed: () => _deleteSource(id, name),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

