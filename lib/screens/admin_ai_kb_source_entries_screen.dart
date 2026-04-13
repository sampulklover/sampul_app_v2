import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/admin_utils.dart';

class AdminAiKbSourceEntriesScreen extends StatefulWidget {
  final String sourceId;
  final String sourceName;

  const AdminAiKbSourceEntriesScreen({
    super.key,
    required this.sourceId,
    required this.sourceName,
  });

  @override
  State<AdminAiKbSourceEntriesScreen> createState() => _AdminAiKbSourceEntriesScreenState();
}

class _AdminAiKbSourceEntriesScreenState extends State<AdminAiKbSourceEntriesScreen> {
  bool _hasContentAccess = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String _query = '';

  List<Map<String, dynamic>> _entries = const [];

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
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var q = SupabaseService.instance.client
          .from('ai_kb_entries')
          .select('id, question, answer, category, product, language, priority, is_active, updated_at')
          .eq('source_id', widget.sourceId)
          .order('priority', ascending: false)
          .order('updated_at', ascending: false)
          .limit(500);

      final rows = await q;
      if (!mounted) return;
      setState(() {
        _entries = (rows as List).whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load entries: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredEntries {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries.where((e) {
      final question = (e['question'] ?? '').toString().toLowerCase();
      final answer = (e['answer'] ?? '').toString().toLowerCase();
      final category = (e['category'] ?? '').toString().toLowerCase();
      return question.contains(q) || answer.contains(q) || category.contains(q);
    }).toList();
  }

  Future<void> _toggleEntryActive(String entryId, bool isActive) async {
    try {
      await SupabaseService.instance.client
          .from('ai_kb_entries')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', entryId);
      await _loadEntries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteEntry(String entryId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry'),
        content: Text('Delete this entry?\n\n$title'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
      await SupabaseService.instance.client.from('ai_kb_entries').delete().eq('id', entryId);
      await _loadEntries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    final questionController = TextEditingController(text: (entry['question'] ?? '').toString());
    final answerController = TextEditingController(text: (entry['answer'] ?? '').toString());
    final categoryController = TextEditingController(text: (entry['category'] ?? '').toString());
    final productController = TextEditingController(text: (entry['product'] ?? '').toString());
    final languageController = TextEditingController(text: (entry['language'] ?? '').toString());
    final priorityController = TextEditingController(text: (entry['priority'] ?? 0).toString());
    bool isActive = (entry['is_active'] as bool?) ?? true;

    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool localIsActive = isActive;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Edit entry'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: questionController,
                        decoration: const InputDecoration(labelText: 'Question'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: answerController,
                        decoration: const InputDecoration(labelText: 'Answer *'),
                        maxLines: 6,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Answer is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: categoryController,
                              decoration: const InputDecoration(labelText: 'Category'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: productController,
                              decoration: const InputDecoration(labelText: 'Product'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: languageController,
                              decoration: const InputDecoration(labelText: 'Language'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: priorityController,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localIsActive,
                        onChanged: (v) => setLocalState(() => localIsActive = v),
                        title: const Text('Active'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    isActive = localIsActive;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final priority = int.tryParse(priorityController.text.trim()) ?? 0;
      await SupabaseService.instance.client.from('ai_kb_entries').update({
        'question': questionController.text.trim().isEmpty ? null : questionController.text.trim(),
        'answer': answerController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'product': productController.text.trim().isEmpty ? null : productController.text.trim(),
        'language': languageController.text.trim().isEmpty ? null : languageController.text.trim(),
        'priority': priority,
        'is_active': isActive,
        'search_text': '${questionController.text.trim()}\n${answerController.text.trim()}'.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', entry['id']);

      await _loadEntries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContentAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final items = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search questions, answers, categories…',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEntries,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final e = items[index];
                        final id = (e['id'] ?? '').toString();
                        final q = (e['question'] ?? '').toString().trim();
                        final a = (e['answer'] ?? '').toString().trim();
                        final cat = (e['category'] ?? '').toString();
                        final prio = (e['priority'] ?? 0).toString();
                        final active = (e['is_active'] as bool?) ?? true;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            onTap: () => _editEntry(e),
                            title: Text(q.isEmpty ? '(No question)' : q, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('A: $a', maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (cat.trim().isNotEmpty)
                                      Chip(
                                        label: Text(cat, style: const TextStyle(fontSize: 10)),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    Chip(
                                      label: Text('P$prio', style: const TextStyle(fontSize: 10)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: active,
                                  onChanged: (v) => _toggleEntryActive(id, v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteEntry(id, q.isEmpty ? a : q),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

