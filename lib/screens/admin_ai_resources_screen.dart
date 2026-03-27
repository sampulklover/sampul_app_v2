import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/ai_chat_settings.dart';
import '../services/ai_chat_settings_service.dart';
import '../utils/admin_utils.dart';

class AdminAiResourcesScreen extends StatefulWidget {
  const AdminAiResourcesScreen({super.key});

  @override
  State<AdminAiResourcesScreen> createState() => _AdminAiResourcesScreenState();
}

class _AdminAiResourcesScreenState extends State<AdminAiResourcesScreen> {
  bool _hasContentAccess = false;
  bool _isLoading = true;
  bool _isSaving = false;
  AiChatSettings? _activeSettings;
  List<AiResource> _resources = [];

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final bool allowed = await AdminUtils.canManageAppContent();
    if (!mounted) return;

    setState(() {
      _hasContentAccess = allowed;
    });

    if (!allowed) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workspaceAccessNotAvailable)),
      );
      Navigator.of(context).pop();
      return;
    }

    await _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await AiChatSettingsService.instance.getActiveSettings();
      if (!mounted) return;
      setState(() {
        _activeSettings = settings;
        _resources = List<AiResource>.from(settings.resources);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load resources: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveResources() async {
    if (_activeSettings == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final resourcesJson =
          _resources.map((resource) => resource.toJson()).toList();

      await AiChatSettingsService.instance.updateSettings(
        id: _activeSettings!.id,
        resources: resourcesJson,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resources saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save resources: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContentAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base Resources'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveResources,
              tooltip: 'Save Resources',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadResources,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Manage links, documents, and other resources that Sampul AI should prioritize when answering questions.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResourcesSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildResourcesSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resources',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addResource,
                  tooltip: 'Add Resource',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add links, documents, or any resources the AI should prioritize.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_resources.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No resources added',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_resources.length, (index) {
                return _buildResourceItem(theme, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(ThemeData theme, int index) {
    final resource = _resources[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: ListTile(
        leading: Icon(
          _getResourceIcon(resource.type),
          color: theme.colorScheme.primary,
        ),
        title: Text(
          resource.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.url,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
            if (resource.type != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    resource.type!.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (resource.description != null && resource.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  resource.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            setState(() {
              _resources.removeAt(index);
            });
          },
        ),
        onTap: () => _editResource(index),
      ),
    );
  }

  IconData _getResourceIcon(String? type) {
    if (type == null) return Icons.link;
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'article':
      case 'webpage':
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _addResource() {
    _showResourceDialog();
  }

  void _editResource(int index) {
    _showResourceDialog(resource: _resources[index], index: index);
  }

  void _showResourceDialog({AiResource? resource, int? index}) {
    final urlController = TextEditingController(text: resource?.url ?? '');
    final titleController = TextEditingController(text: resource?.title ?? '');
    final descController =
        TextEditingController(text: resource?.description ?? '');
    final typeController = TextEditingController(text: resource?.type ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add Resource' : 'Edit Resource'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Estate Planning Guide',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL *',
                    hintText: 'https://example.com/article',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'URL is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Type (Optional)',
                    hintText: 'e.g., link, pdf, doc, article, webpage',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of the resource',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newResource = AiResource(
                  url: urlController.text.trim(),
                  title: titleController.text.trim(),
                  type:
                      typeController.text.trim().isEmpty ? null : typeController.text.trim(),
                  description:
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _resources[index] = newResource;
                  } else {
                    _resources.add(newResource);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

