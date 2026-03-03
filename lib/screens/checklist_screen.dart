import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/aftercare_task.dart';
import '../services/aftercare_service.dart';
import '../l10n/app_localizations.dart';

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
    try {
      final tasks = await AftercareService.instance.listTasks(user.id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _showErrorMessage();
    }
  }

  Future<void> _addOrEdit({AftercareTask? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(text: existing?.task ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? l10n.addTask : l10n.editTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: controller, decoration: InputDecoration(labelText: l10n.task)),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.save)),
          ],
        );
      },
    );
    if (result != true) return;
    final user = AuthController.instance.currentUser;
    if (user == null) return;
    try {
      if (existing == null) {
        await AftercareService.instance.createTask(uuid: user.id, task: controller.text.trim());
      } else {
        await AftercareService.instance.updateTask(id: existing.id!, task: controller.text.trim());
      }
      await _load();
    } catch (e) {
      _showErrorMessage();
    }
  }

  Future<void> _toggleComplete(AftercareTask t) async {
    try {
      await AftercareService.instance.updateTask(id: t.id!, isCompleted: !t.isCompleted);
      await _load();
    } catch (e) {
      _showErrorMessage();
    }
  }

  Future<void> _togglePin(AftercareTask t) async {
    try {
      await AftercareService.instance.updateTask(id: t.id!, isPinned: !t.isPinned);
      await _load();
    } catch (e) {
      _showErrorMessage();
    }
  }

  Future<void> _delete(AftercareTask t) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteTask),
          content: Text(l10n.thisActionCannotBeUndone),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
          ],
        );
      },
    );
    if (ok == true) {
      try {
        await AftercareService.instance.deleteTask(t.id!);
        await _load();
      } catch (e) {
        _showErrorMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checklist),
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
                      title: Text(l10n.deleteAllTasks),
                      content: Text(l10n.thisWillRemoveAllTasksPermanently),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                        FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteAll)),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await AftercareService.instance.deleteAll(uuid: user.id);
                      await _load();
                    } catch (e) {
                      _showErrorMessage();
                    }
                  }
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'delete_all', child: Text(l10n.deleteAll)),
              ],
            ),
        ],
      ),
      floatingActionButton: _tasks.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _addOrEdit(),
              child: const Icon(Icons.add),
            )
          : null,
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
                      try {
                        await AftercareService.instance.updatePositions(
                          uuid: user.id,
                          orderedIds: _tasks.map((e) => e.id!).toList(),
                        );
                      } catch (e) {
                        _showErrorMessage();
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    final t = _tasks[index];
                    return ListTile(
                      key: ValueKey(t.id),
                      onLongPress: () => _showItemActions(t),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {}, // Empty onTap to enable InkWell ripple
                            child: const _DotsHandle(),
                          ),
                        ),
                      ),
                      title: Row(
                        children: <Widget>[
                          if (t.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.push_pin, size: 16, color: const Color.fromRGBO(49, 24, 211, 1).withOpacity(0.7)),
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
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);
    final Color backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    
    Widget dot() => Container(
      width: 4, 
      height: 4, 
      decoration: BoxDecoration(
        color: color, 
        shape: BoxShape.circle,
      ),
    );
    
    return Container(
      // Increase the touchable area
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min, 
              children: <Widget>[
                dot(), 
                const SizedBox(width: 3), 
                dot()
              ]
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min, 
              children: <Widget>[
                dot(), 
                const SizedBox(width: 3), 
                dot()
              ]
            ),
          ],
        ),
      ),
    );
  }
}

extension on _ChecklistScreenState {
  void _showErrorMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to connect. Please check your internet connection.'),
      ),
    );
  }

  Future<void> _showItemActions(AftercareTask t) async {
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.edit),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: Icon(t.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(t.isPinned ? l10n.unpin : l10n.pin),
                onTap: () => Navigator.of(context).pop('toggle_pin'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'assets/checklist-tick.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.createYourChecklist,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.organiseYourAftercareTasks,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.whyUseAChecklist,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.structuredChecklistHelps,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ChecklistBenefitItem(
                          text: l10n.startQuicklyWithRecommended,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _ChecklistBenefitItem(
                          text: l10n.addYourOwnCustomTasks,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _ChecklistBenefitItem(
                          text: l10n.trackProgressSoNothingForgotten,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.aboutChecklists),
                              ],
                            ),
                            content: Text(l10n.defaultChecklistIncludes),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.gotIt),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        l10n.learnMoreAboutChecklists,
                        style: TextStyle(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onCreateDefault,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.useDefaultChecklist),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onCreateCustom,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createCustomTask),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistBenefitItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _ChecklistBenefitItem({
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: colorScheme.onPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}


