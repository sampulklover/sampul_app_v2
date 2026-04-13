import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/executor.dart';
import '../services/executor_service.dart';
import 'executor_info_screen.dart';
import 'executor_create_screen.dart';
import 'executor_detail_screen.dart';

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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.executors),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: '${l10n.all} (${_executors.length})'),
            Tab(text: '${l10n.draft} (${drafts.length})'),
            Tab(text: '${l10n.submitted} (${submitted.length})'),
            Tab(text: '${l10n.approved} (${approved.length})'),
            Tab(text: '${l10n.rejected} (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.aboutPusaka,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _createExecutor,
        child: const Icon(Icons.add),
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
    if (e.id == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExecutorDetailScreen(executorId: e.id!),
      ),
    );
    await _loadExecutors();
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: <Widget>[
        if (_tabController.index == 0) _ExecutorInfoBanner(),
        Expanded(
          child: Center(
            child: Text(
              l10n.noPusakaYet,
              style: theme.textTheme.bodyMedium,
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

  String _statusLabel(BuildContext context, ExecutorStatus s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case ExecutorStatus.submitted:
        return l10n.submitted;
      case ExecutorStatus.approved:
        return l10n.approved;
      case ExecutorStatus.rejected:
        return l10n.rejected;
      case ExecutorStatus.draft:
        return l10n.draft;
    }
  }

  Color _statusColor(BuildContext context, ExecutorStatus s) {
    switch (s) {
      case ExecutorStatus.submitted:
        return Colors.orange.shade700;
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
          title: Text((e.executorCode ?? '').isNotEmpty ? e.executorCode! : (e.name ?? 'Pusaka')),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if ((e.name ?? '').isNotEmpty) Text(e.name!),
              Text('Updated: ${DateFormat.MMMd().format(e.updatedAt)}'),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(context, e.computedStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(context, e.computedStatus),
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
    final l10n = AppLocalizations.of(context)!;
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
            Expanded(child: Text(l10n.newToPusaka)),
            Text('Learn more', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

