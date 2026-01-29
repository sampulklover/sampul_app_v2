import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_chat_settings.dart';
import '../services/ai_chat_settings_service.dart';
import '../utils/admin_utils.dart';

class AdminAiSettingsScreen extends StatefulWidget {
  const AdminAiSettingsScreen({super.key});

  @override
  State<AdminAiSettingsScreen> createState() => _AdminAiSettingsScreenState();
}

class _AdminAiSettingsScreenState extends State<AdminAiSettingsScreen> {
  AiChatSettings? _activeSettings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAdmin = false;

  // Form controllers
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _welcomeMessageController = TextEditingController();
  final TextEditingController _contextResourcesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Dropdown values
  int? _selectedMaxTokens;
  double? _selectedTemperature;

  // Resource management
  List<AiResource> _resources = [];

  // Preset options
  static const List<Map<String, dynamic>> _maxTokensOptions = [
    {'value': 100, 'label': 'Short (100 tokens)', 'description': 'Very brief responses'},
    {'value': 200, 'label': 'Medium-Short (200 tokens)', 'description': 'Concise answers'},
    {'value': 300, 'label': 'Medium (300 tokens)', 'description': 'Balanced length'},
    {'value': 500, 'label': 'Medium-Long (500 tokens)', 'description': 'Detailed responses'},
    {'value': 800, 'label': 'Long (800 tokens)', 'description': 'Comprehensive answers'},
    {'value': 1200, 'label': 'Very Long (1200 tokens)', 'description': 'Extensive explanations'},
  ];

  static const List<Map<String, dynamic>> _temperatureOptions = [
    {'value': 0.0, 'label': 'Very Consistent (0.0)', 'description': 'Same response every time'},
    {'value': 0.3, 'label': 'Consistent (0.3)', 'description': 'Mostly the same'},
    {'value': 0.5, 'label': 'Balanced (0.5)', 'description': 'Good balance'},
    {'value': 0.7, 'label': 'Creative (0.7)', 'description': 'More varied responses'},
    {'value': 1.0, 'label': 'Very Creative (1.0)', 'description': 'Highly varied'},
    {'value': 1.5, 'label': 'Extremely Creative (1.5)', 'description': 'Maximum variation'},
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _modelController.dispose();
    _welcomeMessageController.dispose();
    _contextResourcesController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoad() async {
    final isAdmin = await AdminUtils.isAdmin();
    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });

    if (!isAdmin) {
      // Show error and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allSettings = await AiChatSettingsService.instance.getAllSettings();
      AiChatSettings activeSettings;
      
      try {
        activeSettings = allSettings.firstWhere((s) => s.isActive);
      } catch (_) {
        // No active settings found, use first one or get default
        if (allSettings.isNotEmpty) {
          activeSettings = allSettings.first;
        } else {
          activeSettings = await AiChatSettingsService.instance.getActiveSettings();
        }
      }

      if (mounted) {
        setState(() {
          _activeSettings = activeSettings;
        });
        await _populateForm(activeSettings);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _populateForm(AiChatSettings settings) async {
    _systemPromptController.text = settings.systemPrompt;
    
    // Find closest matching max tokens option
    final maxTokensValue = settings.maxTokens;
    final maxTokensMatch = _maxTokensOptions.firstWhere(
      (option) => option['value'] == maxTokensValue,
      orElse: () => _maxTokensOptions.firstWhere(
        (option) => (option['value'] as int) >= maxTokensValue,
        orElse: () => _maxTokensOptions.last,
      ),
    );
    _selectedMaxTokens = maxTokensMatch['value'] as int;
    
    // Find closest matching temperature option
    final tempValue = settings.temperature;
    final tempMatch = _temperatureOptions.firstWhere(
      (option) => (option['value'] as double) == tempValue,
      orElse: () {
        // Find closest value
        double minDiff = double.infinity;
        Map<String, dynamic>? closest;
        for (final option in _temperatureOptions) {
          final diff = ((option['value'] as double) - tempValue).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closest = option;
          }
        }
        return closest ?? _temperatureOptions[2]; // Default to balanced
      },
    );
    _selectedTemperature = tempMatch['value'] as double;
    
    _modelController.text = settings.model ?? '';
    _welcomeMessageController.text = settings.welcomeMessage;
    _contextResourcesController.text = settings.contextResources ?? '';
    _resources = List.from(settings.resources);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMaxTokens == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Response Length'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Response Style'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final maxTokens = _selectedMaxTokens!;
      final temperature = _selectedTemperature!;

      // Convert resources to JSON format
      final resourcesJson = _resources.map((resource) => resource.toJson()).toList();

      // If there's an active settings, update it; otherwise create new
      if (_activeSettings != null) {
        await AiChatSettingsService.instance.updateSettings(
          id: _activeSettings!.id,
          systemPrompt: _systemPromptController.text.trim(),
          maxTokens: maxTokens,
          temperature: temperature,
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          welcomeMessage: _welcomeMessageController.text.trim(),
          resources: resourcesJson,
          contextResources: _contextResourcesController.text.trim().isEmpty 
              ? null 
              : _contextResourcesController.text.trim(),
        );
      } else {
        await AiChatSettingsService.instance.createSettings(
          systemPrompt: _systemPromptController.text.trim(),
          maxTokens: maxTokens,
          temperature: temperature,
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          welcomeMessage: _welcomeMessageController.text.trim(),
          resources: resourcesJson,
          contextResources: _contextResourcesController.text.trim().isEmpty 
              ? null 
              : _contextResourcesController.text.trim(),
          isActive: true,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload settings
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Settings'),
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
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Changes to these settings will affect how Sampul AI responds to all users. Test carefully before activating.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // System Prompt
                      Text(
                        'System Prompt',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This defines the AI\'s personality and behavior',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _systemPromptController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Enter system prompt...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'System prompt is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Welcome Message
                      Text(
                        'Welcome Message',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The initial message shown when users start a chat',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _welcomeMessageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter welcome message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Welcome message is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Model Settings Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Response Length',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How long should AI responses be?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: _selectedMaxTokens,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _maxTokensOptions.map((option) {
                                    return DropdownMenuItem<int>(
                                      value: option['value'] as int,
                                      child: Text(
                                        option['label'] as String,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return _maxTokensOptions.map((option) {
                                      return Text(
                                        option['label'] as String,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMaxTokens = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select response length';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Response Style',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'How consistent should responses be?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<double>(
                                  value: _selectedTemperature,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _temperatureOptions.map((option) {
                                    return DropdownMenuItem<double>(
                                      value: option['value'] as double,
                                      child: Text(
                                        option['label'] as String,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return _temperatureOptions.map((option) {
                                      return Text(
                                        option['label'] as String,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTemperature = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select response style';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Model (Optional)
                      Text(
                        'Model (Optional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Leave empty to use default model from environment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          hintText: 'e.g., openai/gpt-4, anthropic/claude-3-haiku',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Resource Management Section
                      Divider(height: 32),
                      Text(
                        'Knowledge Base Resources',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add links, documents, or resources that the AI should prioritize when answering questions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resources Section
                      _buildResourcesSection(theme),
                      const SizedBox(height: 24),

                      // Context Resources
                      Text(
                        'Additional Context Resources',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Additional context text that helps the AI understand domain-specific information',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contextResourcesController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Enter additional context, guidelines, or important information...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Settings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Settings Info
                      if (_activeSettings != null)
                        Card(
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
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Active Settings',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Last updated: ${_formatDateTime(_activeSettings!.updatedAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
              'Add links, documents, or any resources the AI should prioritize',
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
    final descController = TextEditingController(text: resource?.description ?? '');
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
                  type: typeController.text.trim().isEmpty
                      ? null
                      : typeController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
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
