import 'package:flutter/material.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';
import 'hibah_edit_screen.dart';
import 'hibah_create_screen.dart';
import 'hibah_info_screen.dart';

class HibahManagementScreen extends StatefulWidget {
  const HibahManagementScreen({super.key});

  @override
  State<HibahManagementScreen> createState() => _HibahManagementScreenState();
}

class _HibahManagementScreenState extends State<HibahManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Hibah> _hibahs = <Hibah>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // trigger rebuild to toggle banner per active tab
    });
    _loadHibahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHibahs() async {
    try {
      final hibahs = await HibahService.instance.listUserHibahs();
      if (!mounted) return;
      setState(() {
        _hibahs = hibahs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createHibah() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const HibahCreateScreen()),
    );
    if (created == true) await _loadHibahs();
  }

  @override
  Widget build(BuildContext context) {
    final List<Hibah> drafts = _hibahs.where((t) => t.computedStatus == HibahStatus.draft).toList();
    final List<Hibah> submitted = _hibahs.where((t) => t.computedStatus == HibahStatus.submitted).toList();
    final List<Hibah> approved = _hibahs.where((t) => t.computedStatus == HibahStatus.approved).toList();
    final List<Hibah> rejected = _hibahs.where((t) => t.computedStatus == HibahStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hibah'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: 'All (${_hibahs.length})'),
            Tab(text: 'Draft (${drafts.length})'),
            Tab(text: 'Submitted (${submitted.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Hibah',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HibahInfoScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hibahs.isEmpty
              ? Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _HibahInfoBanner(),
                    const Expanded(child: Center(child: Text('No hibahs yet'))),
                  ],
                )
              : Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _HibahInfoBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: <Widget>[
                          _HibahList(hibahs: _hibahs, onDelete: _handleDelete, onTap: _openForEdit),
                          _HibahList(hibahs: drafts, onDelete: _handleDelete, onTap: _openForEdit),
                          _HibahList(hibahs: submitted, onDelete: _handleDelete, onTap: _openForEdit),
                          _HibahList(hibahs: approved, onDelete: _handleDelete, onTap: _openForEdit),
                          _HibahList(hibahs: rejected, onDelete: _handleDelete, onTap: _openForEdit),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createHibah,
        icon: const Icon(Icons.add),
        label: const Text('New hibah'),
      ),
    );
  }

  Future<void> _handleDelete(Hibah t) async {
    if (t.id != null) {
      await HibahService.instance.deleteHibah(t.id!);
      await _loadHibahs();
    }
  }

  // No manual status changes; status is computed from payments

  Future<void> _openForEdit(Hibah t) async {
    // Only allow editing drafts
    final bool isDraft = t.computedStatus == HibahStatus.draft;
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => HibahEditScreen(initial: t)),
    );
    if (updated == true && isDraft) {
      await _loadHibahs();
    }
  }
}

class _CreateHibahDialog extends StatefulWidget {
  const _CreateHibahDialog();

  @override
  State<_CreateHibahDialog> createState() => _CreateHibahDialogState();
}

class _CreateHibahDialogState extends State<_CreateHibahDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  HibahStatus _status = HibahStatus.draft;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create hibah'),
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
              decoration: const InputDecoration(labelText: 'Hibah code (unique)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Text('Status:'),
                const SizedBox(width: 12),
                DropdownButton<HibahStatus>(
                  value: _status,
                  items: const <DropdownMenuItem<HibahStatus>>[
                    DropdownMenuItem(value: HibahStatus.draft, child: Text('Draft')),
                    DropdownMenuItem(value: HibahStatus.submitted, child: Text('Submitted')),
                    DropdownMenuItem(value: HibahStatus.approved, child: Text('Approved')),
                    DropdownMenuItem(value: HibahStatus.rejected, child: Text('Rejected')),
                  ],
                  onChanged: (HibahStatus? v) {
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
                Hibah(name: _nameCtrl.text.trim(), hibahCode: _codeCtrl.text.trim(), computedStatus: _status),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}


class _HibahList extends StatelessWidget {
  final List<Hibah> hibahs;
  final Future<void> Function(Hibah) onDelete;
  final Future<void> Function(Hibah) onTap;

  const _HibahList({required this.hibahs, required this.onDelete, required this.onTap});

  String _statusLabel(HibahStatus s) {
    switch (s) {
      case HibahStatus.submitted:
        return 'Submitted';
      case HibahStatus.approved:
        return 'Approved';
      case HibahStatus.rejected:
        return 'Rejected';
      case HibahStatus.draft:
        return 'Draft';
    }
  }

  Color _statusColor(BuildContext context, HibahStatus s) {
    switch (s) {
      case HibahStatus.submitted:
        return Colors.blue.shade600;
      case HibahStatus.approved:
        return Colors.green.shade700;
      case HibahStatus.rejected:
        return Colors.red.shade700;
      case HibahStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: hibahs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Hibah t = hibahs[index];
        return ListTile(
          onTap: () => onTap(t),
          title: Text(t.name ?? 'Unnamed hibah'),
          subtitle: Row(
            children: <Widget>[
              if ((t.hibahCode ?? '').isNotEmpty) Text(t.hibahCode!),
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
                    title: const Text('Delete Hibah'),
                    content: const Text('Are you sure you want to delete this hibah? This action cannot be undone.'),
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
                    const SnackBar(content: Text('Hibah deleted'), backgroundColor: Colors.green),
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

class _HibahInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HibahInfoScreen()));
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
            const Expanded(child: Text('New to hibah?')),
            Text('Learn more', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


