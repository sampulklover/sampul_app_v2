import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/executor.dart';
import '../services/executor_service.dart';
import 'executor_edit_screen.dart';
import 'executor_info_screen.dart';
import 'executor_create_screen.dart';

class ExecutorManagementScreen extends StatefulWidget {
  const ExecutorManagementScreen({super.key});

  @override
  State<ExecutorManagementScreen> createState() => _ExecutorManagementScreenState();
}

class _ExecutorManagementScreenState extends State<ExecutorManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Executor> _executors = <Executor>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // trigger rebuild to toggle banner per active tab
    });
    _loadExecutors();
  }

  Future<void> _loadExecutors() async {
    try {
      final executors = await ExecutorService.instance.listUserExecutors();
      if (!mounted) return;
      setState(() {
        _executors = executors;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createExecutor() async {
    // Check if user has seen the about page before
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenAbout = prefs.getBool('executor_about_seen') ?? false;
    
    // If user hasn't seen about page, show it first
    // Otherwise, go directly to create executor page
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => hasSeenAbout 
            ? const ExecutorCreateScreen() 
            : const ExecutorInfoScreen(),
      ),
    );
    if (created == true) await _loadExecutors();
  }

  @override
  Widget build(BuildContext context) {
    final List<Executor> drafts = _executors.where((e) => e.computedStatus == ExecutorStatus.draft).toList();
    final List<Executor> submitted = _executors.where((e) => e.computedStatus == ExecutorStatus.submitted).toList();
    final List<Executor> approved = _executors.where((e) => e.computedStatus == ExecutorStatus.approved).toList();
    final List<Executor> rejected = _executors.where((e) => e.computedStatus == ExecutorStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executors'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: 'All (${_executors.length})'),
            Tab(text: 'Draft (${drafts.length})'),
            Tab(text: 'Submitted (${submitted.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Executors',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ExecutorInfoScreen(fromHelpIcon: true)));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _executors.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _ExecutorInfoBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: <Widget>[
                          _ExecutorList(executors: _executors, onDelete: _handleDelete, onTap: _openForEdit),
                          _ExecutorList(executors: drafts, onDelete: _handleDelete, onTap: _openForEdit),
                          _ExecutorList(executors: submitted, onDelete: _handleDelete, onTap: _openForEdit),
                          _ExecutorList(executors: approved, onDelete: _handleDelete, onTap: _openForEdit),
                          _ExecutorList(executors: rejected, onDelete: _handleDelete, onTap: _openForEdit),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createExecutor,
        icon: const Icon(Icons.add),
        label: const Text('New Executor'),
      ),
    );
  }

  Future<void> _handleDelete(Executor e) async {
    if (e.id != null) {
      await ExecutorService.instance.deleteExecutor(e.id!);
      await _loadExecutors();
    }
  }

  Future<void> _openForEdit(Executor e) async {
    // Only allow editing drafts
    final bool isDraft = e.computedStatus == ExecutorStatus.draft;
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ExecutorEditScreen(initial: e)),
    );
    if (updated == true && isDraft) {
      await _loadExecutors();
    }
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Let's register as an executor",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Register to manage and distribute a deceased person's estate according to their will or the law.",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Center(
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "What is an executor?",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "An executor is appointed to manage and distribute the assets of a deceased person's estate. This involves handling legal matters, settling debts, and ensuring proper distribution to beneficiaries.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ExecutorFeatureItem(
                            text: "Manage the deceased person's estate and assets.",
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _ExecutorFeatureItem(
                            text: "Settle debts and handle legal matters.",
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _ExecutorFeatureItem(
                            text: "Distribute assets to beneficiaries according to the will or law.",
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final bool? created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const ExecutorInfoScreen(),
                      ),
                    );
                    if (created == true) {
                      await _loadExecutors();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Register as executor",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutorFeatureItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _ExecutorFeatureItem({
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

class _ExecutorList extends StatelessWidget {
  final List<Executor> executors;
  final Future<void> Function(Executor) onDelete;
  final Future<void> Function(Executor) onTap;

  const _ExecutorList({required this.executors, required this.onDelete, required this.onTap});

  String _statusLabel(ExecutorStatus s) {
    switch (s) {
      case ExecutorStatus.submitted:
        return 'Submitted';
      case ExecutorStatus.approved:
        return 'Approved';
      case ExecutorStatus.rejected:
        return 'Rejected';
      case ExecutorStatus.draft:
        return 'Draft';
    }
  }

  Color _statusColor(BuildContext context, ExecutorStatus s) {
    switch (s) {
      case ExecutorStatus.submitted:
        return Colors.blue.shade600;
      case ExecutorStatus.approved:
        return Colors.green.shade700;
      case ExecutorStatus.rejected:
        return Colors.red.shade700;
      case ExecutorStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: executors.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Executor e = executors[index];
        return ListTile(
          onTap: () => onTap(e),
          title: Text(e.name ?? e.deceasedName ?? 'Unnamed Executor'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (e.claimantName != null) Text('Claimant: ${e.claimantName}'),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  if ((e.executorCode ?? '').isNotEmpty) Text(e.executorCode!),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(context, e.computedStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(e.computedStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(context, e.computedStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Executor'),
                    content: const Text('Are you sure you want to delete this executor? This action cannot be undone.'),
                    actions: <Widget>[
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await onDelete(e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Executor deleted'), backgroundColor: Colors.green),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _ExecutorInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ExecutorInfoScreen(fromHelpIcon: true)));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline, color: const Color.fromRGBO(49, 24, 211, 1), size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('New to executors?')),
            Text('Learn more', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

