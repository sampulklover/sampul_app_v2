import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';
import 'trust_info_screen.dart';
import 'trust_dashboard_screen.dart';
import 'trust_create_screen.dart';

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
    // Check if user has seen the about page before
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenAbout = prefs.getBool('trust_about_seen') ?? false;
    
    // If user hasn't seen about page, show it first
    // Otherwise, go directly to create trust page.
    //
    // The creation flow returns the created Trust instance on success,
    // but we only need to know that the user returned to this screen,
    // so we ignore the value and simply reload the list afterward.
    await Navigator.of(context).push<Trust>(
      MaterialPageRoute<Trust>(
        builder: (_) => hasSeenAbout
            ? const TrustCreateScreen()
            : const TrustInfoScreen(),
      ),
    );
    // When the user returns here (after closing the dashboard),
    // refresh the list to include any newly created/updated trusts.
    await _loadTrusts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Trust> drafts = _trusts.where((t) => t.computedStatus == TrustStatus.draft).toList();
    final List<Trust> submitted = _trusts.where((t) => t.computedStatus == TrustStatus.submitted).toList();
    final List<Trust> approved = _trusts.where((t) => t.computedStatus == TrustStatus.approved).toList();
    final List<Trust> rejected = _trusts.where((t) => t.computedStatus == TrustStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyTrustFund),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: '${l10n.all} (${_trusts.length})'),
            Tab(text: '${l10n.draft} (${drafts.length})'),
            Tab(text: '${l10n.submitted} (${submitted.length})'),
            Tab(text: '${l10n.approved} (${approved.length})'),
            Tab(text: '${l10n.rejected} (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.aboutTrustFund,
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen(fromHelpIcon: true)));
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
                    Expanded(child: Center(child: Text(l10n.noTrustFundsYet))),
                  ],
                )
              : Column(
                  children: <Widget>[
                    if (_tabController.index == 0) _TrustInfoBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: <Widget>[
                          _TrustList(trusts: _trusts, onTap: _openForEdit),
                          _TrustList(trusts: drafts, onTap: _openForEdit),
                          _TrustList(trusts: submitted, onTap: _openForEdit),
                          _TrustList(trusts: approved, onTap: _openForEdit),
                          _TrustList(trusts: rejected, onTap: _openForEdit),
                        ],
                      ),
                    ),
                  ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _createTrust,
        child: const Icon(Icons.add),
      ),
    );
  }

  // No manual status changes; status is computed from payments

  Future<void> _openForEdit(Trust t) async {
    // Navigate to dashboard instead of directly to edit
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TrustDashboardScreen(trust: t)),
    );
    // Refresh trusts list when returning from dashboard
    await _loadTrusts();
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.createTrust),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            TextFormField(
              controller: _codeCtrl,
              decoration: InputDecoration(labelText: l10n.trustCodeUnique),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Text('${l10n.draft}:'),
                const SizedBox(width: 12),
                DropdownButton<TrustStatus>(
                  value: _status,
                  items: <DropdownMenuItem<TrustStatus>>[
                    DropdownMenuItem(value: TrustStatus.draft, child: Text(l10n.draft)),
                    DropdownMenuItem(value: TrustStatus.submitted, child: Text(l10n.submitted)),
                    DropdownMenuItem(value: TrustStatus.approved, child: Text(l10n.approved)),
                    DropdownMenuItem(value: TrustStatus.rejected, child: Text(l10n.rejected)),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                Trust(name: _nameCtrl.text.trim(), trustCode: _codeCtrl.text.trim(), computedStatus: _status),
              );
            }
          },
          child: Text(l10n.createTrust),
        ),
      ],
    );
  }
}


class _TrustList extends StatelessWidget {
  final List<Trust> trusts;
  final Future<void> Function(Trust) onTap;

  const _TrustList({required this.trusts, required this.onTap});

  String _statusLabel(TrustStatus s, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case TrustStatus.submitted:
        return l10n.submitted;
      case TrustStatus.approved:
        return l10n.approved;
      case TrustStatus.rejected:
        return l10n.rejected;
      case TrustStatus.draft:
        return l10n.draft;
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

  String _formatAmount(String? estimatedNetWorth) {
    if (estimatedNetWorth == null || estimatedNetWorth.isEmpty) {
      return 'RM0.00';
    }
    // Match the formatting used on the Homepage
    // (see _formatAmount in home_screen.dart)
    try {
      final double? numValue = double.tryParse(estimatedNetWorth);
      if (numValue != null) {
        return 'RM${numValue.toStringAsFixed(2)}';
      }
    } catch (_) {}
    // If it's a string like "below_rm_50k" or "rm_50k_to_100k", format it nicely
    return estimatedNetWorth.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'\brm\b', caseSensitive: false),
      (Match match) => 'RM',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: trusts.length,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Trust t = trusts[index];
        return _TrustSummaryCard(
          trust: t,
          amountText: _formatAmount(t.estimatedNetWorth),
          statusText: _statusLabel(t.computedStatus, context),
          statusColor: _statusColor(context, t.computedStatus),
          onTap: () => onTap(t),
        );
      },
    );
  }
}

class _TrustSummaryCard extends StatelessWidget {
  final Trust trust;
  final String amountText;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _TrustSummaryCard({
    required this.trust,
    required this.amountText,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String title = l10n.familyAccount;
    final String trustCode = (trust.trustCode ?? '').trim();
    final bool isActive = trust.computedStatus == TrustStatus.approved;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: Stack(
              children: <Widget>[
                // Background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 0,
                    ),
                  ),
                ),
                // Decorative image - behind content
                Positioned(
                  right: -20,
                  bottom: -0,
                  child: Transform.rotate(
                    angle: 0,
                    child: Opacity(
                      opacity: 0.9,
                      child: Image.asset(
                        'assets/trust-three-coin.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color.fromRGBO(83, 61, 233, 1),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (trustCode.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    trustCode,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        amountText,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? l10n.yourPlanIsActive : statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isActive ? Colors.green.shade700 : statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen(fromHelpIcon: true)));
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
            Icon(Icons.info_outline, color: const Color.fromRGBO(83, 61, 233, 1), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.newToTrusts)),
            Text(l10n.learnMore, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


