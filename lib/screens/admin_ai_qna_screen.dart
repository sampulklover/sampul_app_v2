import 'package:flutter/material.dart';
import '../models/ai_chat_qna.dart';
import '../services/ai_chat_qna_service.dart';
import '../utils/admin_utils.dart';

class AdminAiQnaScreen extends StatefulWidget {
  const AdminAiQnaScreen({super.key});

  @override
  State<AdminAiQnaScreen> createState() => _AdminAiQnaScreenState();
}

class _AdminAiQnaScreenState extends State<AdminAiQnaScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isSaving = false;
  List<AiChatQna> _items = const [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    final isAdmin = await AdminUtils.isAdmin();
    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    await _loadQna();
  }

  Future<void> _loadQna() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await AiChatQnaService.instance.getAllQna();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load Q&A: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEditDialog({AiChatQna? item}) async {
    final theme = Theme.of(context);
    final questionController = TextEditingController(text: item?.question ?? '');
    final answerController = TextEditingController(text: item?.answer ?? '');
    final tagsController = TextEditingController(
      text: item?.tags.join(', ') ?? '',
    );
    bool isActive = item?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add Q&A' : 'Edit Q&A'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question *',
                      hintText: 'e.g., What is Hibah?',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Question is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      labelText: 'Answer *',
                      hintText: 'Short, clear answer the AI can use directly.',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Answer is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (optional)',
                      hintText: 'Comma-separated, e.g. hibah, basics',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) {
                      setState(() {
                        isActive = v;
                      });
                    },
                    title: const Text('Active'),
                    subtitle: const Text('Only active Q&A will be sent to the AI'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: Keep answers concise and factual (2–4 short sentences) to save tokens.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop();
                await _saveQna(
                  existing: item,
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                  tags: tagsController.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList(),
                  isActive: isActive,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveQna({
    AiChatQna? existing,
    required String question,
    required String answer,
    required List<String> tags,
    required bool isActive,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (existing == null) {
        await AiChatQnaService.instance.createQna(
          question: question,
          answer: answer,
          tags: tags,
          isActive: isActive,
        );
      } else {
        await AiChatQnaService.instance.updateQna(
          id: existing.id,
          question: question,
          answer: answer,
          tags: tags,
          isActive: isActive,
        );
      }

      if (!mounted) return;
      await _loadQna();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Q&A saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save Q&A: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteQna(AiChatQna item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Q&A'),
        content: const Text('Are you sure you want to delete this Q&A pair?'),
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
      await AiChatQnaService.instance.deleteQna(item.id);
      if (!mounted) return;
      await _loadQna();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Q&A deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete Q&A: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Q&A Knowledge Base'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isSaving ? null : () => _openEditDialog(),
            tooltip: 'Add Q&A',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQna,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // No intro info card; just start with the first Q&A item
                    if (_items.isEmpty) {
                      return const SizedBox.shrink();
                    }
                  }

                  final item = _items[index == 0 ? 0 : index - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _openEditDialog(item: item),
                      title: Text(
                        item.question,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.answer,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: item.tags
                                  .map(
                                    (t) => Chip(
                                      label: Text(
                                        t,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: item.isActive,
                            onChanged: (value) {
                              _saveQna(
                                existing: item,
                                question: item.question,
                                answer: item.answer,
                                tags: item.tags,
                                isActive: value,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteQna(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

