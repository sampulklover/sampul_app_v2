import 'package:flutter/material.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';
import 'trust_edit_screen.dart';
import 'trust_create_screen.dart';
import 'trust_info_screen.dart';

class TrustManagementScreen extends StatefulWidget {
  const TrustManagementScreen({super.key});

  @override
  State<TrustManagementScreen> createState() => _TrustManagementScreenState();
}

class _TrustManagementScreenState extends State<TrustManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Trust> _trusts = <Trust>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // trigger rebuild to toggle banner per active tab
    });
    _loadTrusts();
  }

  Future<void> _loadTrusts() async {
    try {
      final trusts = await TrustService.instance.listUserTrusts();
      if (!mounted) return;
      setState(() {
        _trusts = trusts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTrust() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const TrustCreateScreen()),
    );
    if (created == true) await _loadTrusts();
  }

  @override
  Widget build(BuildContext context) {
    final List<Trust> drafts = _trusts.where((t) => t.computedStatus == TrustStatus.draft).toList();
    final List<Trust> submitted = _trusts.where((t) => t.computedStatus == TrustStatus.submitted).toList();
    final List<Trust> approved = _trusts.where((t) => t.computedStatus == TrustStatus.approved).toList();
    final List<Trust> rejected = _trusts.where((t) => t.computedStatus == TrustStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: 'All (${_trusts.length})'),
            Tab(text: 'Draft (${drafts.length})'),
            Tab(text: 'Submitted (${submitted.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Trusts',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trusts.isEmpty
              ? Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _TrustInfoBanner(),
                    const Expanded(child: Center(child: Text('No trusts yet'))),
                  ],
                )
              : Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _TrustInfoBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: <Widget>[
                          _TrustList(trusts: _trusts, onDelete: _handleDelete, onTap: _openForEdit),
                          _TrustList(trusts: drafts, onDelete: _handleDelete, onTap: _openForEdit),
                          _TrustList(trusts: submitted, onDelete: _handleDelete, onTap: _openForEdit),
                          _TrustList(trusts: approved, onDelete: _handleDelete, onTap: _openForEdit),
                          _TrustList(trusts: rejected, onDelete: _handleDelete, onTap: _openForEdit),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTrust,
        icon: const Icon(Icons.add),
        label: const Text('New trust'),
      ),
    );
  }

  Future<void> _handleDelete(Trust t) async {
    if (t.id != null) {
      await TrustService.instance.deleteTrust(t.id!);
      await _loadTrusts();
    }
  }

  // No manual status changes; status is computed from payments

  Future<void> _openForEdit(Trust t) async {
    // Only allow editing drafts
    final bool isDraft = t.computedStatus == TrustStatus.draft;
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TrustEditScreen(initial: t)),
    );
    if (updated == true && isDraft) {
      await _loadTrusts();
    }
  }
}

class _CreateTrustDialog extends StatefulWidget {
  const _CreateTrustDialog();

  @override
  State<_CreateTrustDialog> createState() => _CreateTrustDialogState();
}

class _CreateTrustDialogState extends State<_CreateTrustDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  TrustStatus _status = TrustStatus.draft;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create trust'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Trust code (unique)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Text('Status:'),
                const SizedBox(width: 12),
                DropdownButton<TrustStatus>(
                  value: _status,
                  items: const <DropdownMenuItem<TrustStatus>>[
                    DropdownMenuItem(value: TrustStatus.draft, child: Text('Draft')),
                    DropdownMenuItem(value: TrustStatus.submitted, child: Text('Submitted')),
                    DropdownMenuItem(value: TrustStatus.approved, child: Text('Approved')),
                    DropdownMenuItem(value: TrustStatus.rejected, child: Text('Rejected')),
                  ],
                  onChanged: (TrustStatus? v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                Trust(name: _nameCtrl.text.trim(), trustCode: _codeCtrl.text.trim(), computedStatus: _status),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}


class _TrustList extends StatelessWidget {
  final List<Trust> trusts;
  final Future<void> Function(Trust) onDelete;
  final Future<void> Function(Trust) onTap;

  const _TrustList({required this.trusts, required this.onDelete, required this.onTap});

  String _statusLabel(TrustStatus s) {
    switch (s) {
      case TrustStatus.submitted:
        return 'Submitted';
      case TrustStatus.approved:
        return 'Approved';
      case TrustStatus.rejected:
        return 'Rejected';
      case TrustStatus.draft:
        return 'Draft';
    }
  }

  Color _statusColor(BuildContext context, TrustStatus s) {
    switch (s) {
      case TrustStatus.submitted:
        return Colors.blue.shade600;
      case TrustStatus.approved:
        return Colors.green.shade700;
      case TrustStatus.rejected:
        return Colors.red.shade700;
      case TrustStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: trusts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Trust t = trusts[index];
        return ListTile(
          onTap: () => onTap(t),
          title: Text(t.name ?? 'Unnamed trust'),
          subtitle: Row(
            children: <Widget>[
              if ((t.trustCode ?? '').isNotEmpty) Text(t.trustCode!),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(context, t.computedStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(t.computedStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(context, t.computedStatus),
                  ),
                ),
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
                    title: const Text('Delete Trust'),
                    content: const Text('Are you sure you want to delete this trust? This action cannot be undone.'),
                    actions: <Widget>[
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await onDelete(t);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trust deleted'), backgroundColor: Colors.green),
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

class _TrustInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen()));
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
            Icon(Icons.info_outline, color: scheme.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('New to trusts?')),
            Text('Learn more', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


