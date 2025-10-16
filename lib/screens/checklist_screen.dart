import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/aftercare_task.dart';
import '../services/aftercare_service.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool _loading = true;
  List<AftercareTask> _tasks = <AftercareTask>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final tasks = await AftercareService.instance.listTasks(user.id);
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({AftercareTask? existing}) async {
    final TextEditingController controller = TextEditingController(text: existing?.task ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Task')),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
          ],
        );
      },
    );
    if (result != true) return;
    final user = AuthController.instance.currentUser;
    if (user == null) return;
    if (existing == null) {
      await AftercareService.instance.createTask(uuid: user.id, task: controller.text.trim());
    } else {
      await AftercareService.instance.updateTask(id: existing.id!, task: controller.text.trim());
    }
    await _load();
  }

  Future<void> _toggleComplete(AftercareTask t) async {
    await AftercareService.instance.updateTask(id: t.id!, isCompleted: !t.isCompleted);
    await _load();
  }

  Future<void> _togglePin(AftercareTask t) async {
    await AftercareService.instance.updateTask(id: t.id!, isPinned: !t.isPinned);
    await _load();
  }

  Future<void> _delete(AftercareTask t) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text('This action cannot be undone.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (ok == true) {
      await AftercareService.instance.deleteTask(t.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        actions: <Widget>[
          if (_tasks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                final user = AuthController.instance.currentUser;
                if (user == null) return;
                if (value == 'delete_all') {
                  final bool? ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete all tasks?'),
                      content: const Text('This will remove all tasks permanently.'),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete all')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await AftercareService.instance.deleteAll(uuid: user.id);
                    await _load();
                  }
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'delete_all', child: Text('Delete all')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _EmptyState(
                  onCreateCustom: () => _addOrEdit(),
                  onCreateDefault: () async {
                    final user = AuthController.instance.currentUser;
                    if (user == null) return;
                    // determine starting index (0 as list empty)
                    await AftercareService.instance.seedDefaultTasks(uuid: user.id, startIndex: 0);
                    await _load();
                  },
                )
              : ReorderableListView.builder(
                  itemCount: _tasks.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    setState(() {
                      final moved = _tasks.removeAt(oldIndex);
                      _tasks.insert(newIndex, moved);
                    });
                    final user = AuthController.instance.currentUser;
                    if (user != null) {
                      await AftercareService.instance.updatePositions(
                        uuid: user.id,
                        orderedIds: _tasks.map((e) => e.id!).toList(),
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final t = _tasks[index];
                    return ListTile(
                      key: ValueKey(t.id),
                      onLongPress: () => _showItemActions(t),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const _DotsHandle(),
                      ),
                      title: Row(
                        children: <Widget>[
                          if (t.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                            ),
                          Expanded(
                            child: Text(
                              t.task,
                              style: TextStyle(
                                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Checkbox(value: t.isCompleted, onChanged: (_) => _toggleComplete(t)),
                    );
                  },
                ),
    );
  }
}

class _DotsHandle extends StatelessWidget {
  const _DotsHandle();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.35);
    Widget dot() => Container(width: 3, height: 3, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[dot(), const SizedBox(width: 2), dot()]),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[dot(), const SizedBox(width: 2), dot()]),
        ],
      ),
    );
  }
}

extension on _ChecklistScreenState {
  Future<void> _showItemActions(AftercareTask t) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: Icon(t.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(t.isPinned ? 'Unpin' : 'Pin'),
                onTap: () => Navigator.of(context).pop('toggle_pin'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (action == null) return;
    if (action == 'edit') return _addOrEdit(existing: t);
    if (action == 'toggle_pin') return _togglePin(t);
    if (action == 'delete') return _delete(t);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateCustom;
  final VoidCallback onCreateDefault;
  const _EmptyState({required this.onCreateCustom, required this.onCreateDefault});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.checklist_outlined, size: 64),
            const SizedBox(height: 12),
            const Text('No tasks yet'),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FilledButton(onPressed: onCreateDefault, child: const Text('Add default steps')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: onCreateCustom, child: const Text('Add custom step')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


