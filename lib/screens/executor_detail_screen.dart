import 'package:flutter/material.dart';

import '../models/executor_document.dart';
import '../services/executor_documents_service.dart';
import '../services/supabase_service.dart';
import 'executor_edit_screen.dart';
import '../models/executor.dart';

class ExecutorDetailScreen extends StatefulWidget {
  const ExecutorDetailScreen({super.key, required this.executorId});

  final int executorId;

  @override
  State<ExecutorDetailScreen> createState() => _ExecutorDetailScreenState();
}

class _ExecutorDetailScreenState extends State<ExecutorDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _executorRow;
  Map<String, dynamic>? _deceasedRow;
  Map<String, dynamic>? _assetsRow;
  Map<String, dynamic>? _guardianRow;
  List<ExecutorDocument> _documents = <ExecutorDocument>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = SupabaseService.instance.client;
      final exec = await client
          .from('executor')
          .select()
          .eq('id', widget.executorId)
          .maybeSingle();
      final deceased = await client
          .from('executor_deceased')
          .select()
          .eq('executor_id', widget.executorId)
          .maybeSingle();
      final assets = await client
          .from('executor_deceased_assets')
          .select()
          .eq('executor_id', widget.executorId)
          .maybeSingle();
      final guardian = await client
          .from('executor_guardian')
          .select()
          .eq('executor_id', widget.executorId)
          .maybeSingle();
      final docs = await ExecutorDocumentsService.instance
          .listForExecutor(widget.executorId);

      if (!mounted) return;
      setState(() {
        _executorRow = exec;
        _deceasedRow = deceased;
        _assetsRow = assets;
        _guardianRow = guardian;
        _documents = docs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteDocument(ExecutorDocument doc) async {
    await ExecutorDocumentsService.instance.delete(doc);
    await _load();
  }

  Future<void> _openEdit() async {
    final exec = _executorRow;
    if (exec == null) return;
    final initial = await SupabaseService.instance.client
        .from('executor')
        .select()
        .eq('id', widget.executorId)
        .maybeSingle();
    if (initial == null) return;
    // Reuse existing edit screen, which reloads its own data from DB.
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ExecutorEditScreen(initial: Executor.fromJson(initial)),
      ),
    );
    if (updated == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pusaka details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exec = _executorRow;
    final deceased = _deceasedRow;
    final String title =
        (deceased?['full_name'] as String?)?.trim().isNotEmpty == true
            ? (deceased!['full_name'] as String)
            : (exec?['executor_code'] as String?) ?? 'Pusaka details';
    final String rawStatus = (exec?['status'] as String? ?? '').toLowerCase();

    String statusLabel(String s) {
      switch (s) {
        case 'approved':
          return 'Approved';
        case 'rejected':
          return 'Rejected';
        case 'under_review':
          return 'Under review';
        case 'submitted':
          return 'Submitted';
        case 'draft':
        default:
          return 'Draft';
      }
    }

    Color statusColor(String s) {
      switch (s) {
        case 'approved':
          return Colors.green.shade700;
        case 'rejected':
          return Colors.red.shade700;
        case 'under_review':
          return Colors.blue.shade700;
        case 'submitted':
          return Colors.orange.shade700;
        case 'draft':
        default:
          return scheme.onSurfaceVariant;
      }
    }

    Widget sectionTitle(String text) {
      return Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    Widget kv(String label, Object? value) {
      final String v = (value ?? '').toString().trim();
      if (v.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                v,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int countList(dynamic x) => (x is List) ? x.length : 0;

    final int immovableCount = countList(_assetsRow?['immovable_assets']);
    final int movableCount = countList(_assetsRow?['movable_assets']);
    final int liabilitiesCount = countList(_assetsRow?['liabilities']);
    final int beneficiariesCount = countList(_assetsRow?['beneficiaries']);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: _openEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          if (exec != null)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (((exec['executor_code'] as String?) ?? '')
                              .trim()
                              .isNotEmpty)
                            Text(
                              (exec['executor_code'] as String).trim(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Status',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(rawStatus).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor(rawStatus).withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        statusLabel(rawStatus),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor(rawStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('Applicant'),
                  const Divider(height: 24),
                  kv('Name', exec?['name']),
                  kv('NRIC', exec?['nric_number']),
                  kv('Phone', exec?['phone_no']),
                  kv('Email', exec?['email']),
                  kv('Address', [
                    exec?['address_line_1'],
                    exec?['address_line_2'],
                    exec?['city'],
                    exec?['state'],
                    exec?['postcode'],
                  ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(', ')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('Deceased'),
                  const Divider(height: 24),
                  kv('Full name', deceased?['full_name']),
                  kv('NRIC', deceased?['nric_new']),
                  kv('Date of death', deceased?['date_of_death']),
                  kv('Cause', deceased?['cause_of_death']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('Assets summary'),
                  const Divider(height: 24),
                  kv('Immovable', '$immovableCount item(s)'),
                  kv('Movable', '$movableCount item(s)'),
                  kv('Liabilities', '$liabilitiesCount item(s)'),
                  kv('Beneficiaries', '$beneficiariesCount item(s)'),
                ],
              ),
            ),
          ),
          if (_guardianRow != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    sectionTitle('Guardian'),
                    const Divider(height: 24),
                    kv('Full name', _guardianRow?['full_name']),
                    kv('Phone', _guardianRow?['phone_no']),
                    kv('Email', _guardianRow?['email']),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('Supporting documents'),
                  const Divider(height: 24),
                  if (_documents.isEmpty)
                    Text(
                      'No documents uploaded yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._documents.map((d) {
                      final String docTitle =
                          (d.title ?? '').trim().isNotEmpty ? d.title!.trim() : d.fileName;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(docTitle),
                          subtitle: Text(d.fileName),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteDocument(d),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

