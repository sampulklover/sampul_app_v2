import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import 'inform_death_screen.dart';
import 'inform_death_detail_screen.dart';

class InformDeathManagementScreen extends StatefulWidget {
  const InformDeathManagementScreen({super.key});

  @override
  State<InformDeathManagementScreen> createState() => _InformDeathManagementScreenState();
}

class _InformDeathManagementScreenState extends State<InformDeathManagementScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _records = <Map<String, dynamic>>[];
          });
        }
        return;
      }

      final List<dynamic> rows = await SupabaseService.instance.client
          .from('inform_death')
          .select('id, nric_name, nric_no, certification_id, status, created_at, image_path')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _records = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _records = <Map<String, dynamic>>[];
      });
    }
  }

  Future<void> _createNew() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const InformDeathScreen(),
      ),
    );
    if (created == true) {
      await _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Group by status, defaulting null to 'submitted'
    List<Map<String, dynamic>> byStatus(String status) => _records
        .where((r) => ((r['status'] as String?) ?? 'submitted').toLowerCase() == status)
        .toList();

    final List<Map<String, dynamic>> drafts = byStatus('draft');
    final List<Map<String, dynamic>> submitted = byStatus('submitted');
    final List<Map<String, dynamic>> underReview = byStatus('under_review');
    final List<Map<String, dynamic>> approved = byStatus('approved');
    final List<Map<String, dynamic>> rejected = byStatus('rejected');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.informDeathTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: '${l10n.all} (${_records.length})'),
            Tab(text: '${l10n.draft} (${drafts.length})'),
            Tab(text: '${l10n.submitted} (${submitted.length})'),
            Tab(text: '${l10n.informDeathStatusUnderReview} (${underReview.length})'),
            Tab(text: '${l10n.approved} / ${l10n.rejected} (${approved.length + rejected.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  _InformDeathInfoBanner(onTap: _createNew),
                  const SizedBox(height: 4),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _InformDeathList(
                          records: _records,
                          onRecordUpdated: _loadRecords,
                        ),
                        _InformDeathList(
                          records: drafts,
                          onRecordUpdated: _loadRecords,
                        ),
                        _InformDeathList(
                          records: submitted,
                          onRecordUpdated: _loadRecords,
                        ),
                        _InformDeathList(
                          records: underReview,
                          onRecordUpdated: _loadRecords,
                        ),
                        _InformDeathList(records: <Map<String, dynamic>>[
                          ...approved,
                          ...rejected,
                        ], onRecordUpdated: _loadRecords),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _createNew,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InformDeathList extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final Future<void> Function() onRecordUpdated;

  const _InformDeathList({
    required this.records,
    required this.onRecordUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      // Parent handles refresh; we just complete immediately
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: records.length,
        itemBuilder: (BuildContext context, int index) {
          final record = records[index];
          final String name = (record['nric_name'] as String?) ?? l10n.unknown;
          final String nric = (record['nric_no'] as String?) ?? '-';
          final String certId = (record['certification_id'] as String?) ?? '-';
          final String status = ((record['status'] as String?) ?? 'submitted').toLowerCase();
          final DateTime? createdAt = record['created_at'] != null
              ? DateTime.tryParse(record['created_at'] as String)
              : null;
          final String createdLabel = createdAt != null
              ? DateFormat.yMMMd().add_jm().format(createdAt.toLocal())
              : '-';

          Color _statusColor() {
            switch (status) {
              case 'draft':
                return colorScheme.onSurfaceVariant;
              case 'submitted':
                return Colors.orange.shade700;
              case 'under_review':
                return Colors.blue.shade700;
              case 'approved':
                return Colors.green.shade700;
              case 'rejected':
                return Colors.red.shade700;
              default:
                return colorScheme.onSurfaceVariant;
            }
          }

          String _statusLabel() {
            switch (status) {
              case 'draft':
                return l10n.informDeathStatusDraft;
              case 'submitted':
                return l10n.informDeathStatusSubmitted;
              case 'under_review':
                return l10n.informDeathStatusUnderReview;
              case 'approved':
                return l10n.informDeathStatusApproved;
              case 'rejected':
                return l10n.informDeathStatusRejected;
              default:
                return l10n.informDeathStatusUnknown;
            }
          }

          final Color pillColor = _statusColor();

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final String? result = await Navigator.of(context).push<String>(
                MaterialPageRoute<String>(
                  builder: (_) => InformDeathDetailScreen(record: record),
                ),
              );
              if (result == 'updated' || result == 'deleted') {
                await onRecordUpdated();
                if (!context.mounted) return;
                if (result == 'deleted') {
                  final l10nSnack = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10nSnack.informDeathDeleteSuccess)),
                  );
                }
              }
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pillColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: pillColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Icon(Icons.badge_outlined,
                                      size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.informDeathListNric(nric),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: <Widget>[
                                  Icon(Icons.description_outlined,
                                      size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.informDeathListCertificateId(certId),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: <Widget>[
                                  Icon(Icons.schedule_outlined,
                                      size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.informDeathListSubmittedOn(createdLabel),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InformDeathInfoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _InformDeathInfoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline, color: const Color.fromRGBO(83, 61, 233, 1), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(AppLocalizations.of(context)!.informDeathInfoBannerBody),
            ),
            Text(
              AppLocalizations.of(context)!.informDeathInfoBannerCta,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


