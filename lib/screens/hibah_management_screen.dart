import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';
import 'hibah_detail_screen.dart';
import 'hibah_info_screen.dart';
import 'hibah_create_screen.dart';

class HibahManagementScreen extends StatefulWidget {
  const HibahManagementScreen({super.key});

  @override
  State<HibahManagementScreen> createState() => _HibahManagementScreenState();
}

class _HibahManagementScreenState extends State<HibahManagementScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Hibah> _hibahs = <Hibah>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // trigger rebuild to toggle banner per active tab
      }
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
    // Check if user has seen the about page before
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenAbout = prefs.getBool('hibah_about_seen') ?? false;
    
    // If user hasn't seen about page, show it first
    // Otherwise, go directly to create hibah page
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => hasSeenAbout 
            ? const HibahCreateScreen() 
            : const HibahInfoScreen(),
      ),
    );
    if (created == true) {
      await _loadHibahs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Hibah> drafts = _hibahs
        .where((t) => t.status == HibahStatus.draft)
        .toList();
    final List<Hibah> pending = _hibahs
        .where((t) => t.status == HibahStatus.pendingReview)
        .toList();
    final List<Hibah> underReview = _hibahs
        .where((t) => t.status == HibahStatus.underReview)
        .toList();
    final List<Hibah> approved = _hibahs
        .where((t) => t.status == HibahStatus.approved)
        .toList();
    final List<Hibah> rejected = _hibahs
        .where((t) => t.status == HibahStatus.rejected)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hibah'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: 'All (${_hibahs.length})'),
            Tab(text: 'Draft (${drafts.length})'),
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Under review (${underReview.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Hibah',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HibahInfoScreen(fromHelpIcon: true),
                ),
              );
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
                      _HibahList(
                        hibahs: _hibahs,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
                      _HibahList(
                        hibahs: drafts,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
                      _HibahList(
                        hibahs: pending,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
                      _HibahList(
                        hibahs: underReview,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
                      _HibahList(
                        hibahs: approved,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
                      _HibahList(
                        hibahs: rejected,
                        onDelete: _handleDelete,
                        onTap: _showSubmissionDetails,
                      ),
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

  Future<void> _handleDelete(Hibah hibah) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete submission'),
          content: const Text(
            'Certificates and their assets will be deleted permanently. Continue?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await HibahService.instance.deleteHibah(hibah.id);
    await _loadHibahs();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Submission removed')));
  }

  void _showSubmissionDetails(Hibah hibah) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HibahDetailScreen(hibah: hibah),
      ),
    );
  }
}

String _statusLabel(HibahStatus status) {
  switch (status) {
    case HibahStatus.draft:
      return 'Draft';
    case HibahStatus.pendingReview:
      return 'Pending review';
    case HibahStatus.underReview:
      return 'Under review';
    case HibahStatus.approved:
      return 'Approved';
    case HibahStatus.rejected:
      return 'Rejected';
  }
}

Color _statusColor(BuildContext context, HibahStatus status) {
  switch (status) {
    case HibahStatus.draft:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case HibahStatus.pendingReview:
      return Colors.orange.shade700;
    case HibahStatus.underReview:
      return Colors.blue.shade600;
    case HibahStatus.approved:
      return Colors.green.shade700;
    case HibahStatus.rejected:
      return Colors.red.shade700;
  }
}

class _HibahList extends StatelessWidget {
  final List<Hibah> hibahs;
  final Future<void> Function(Hibah) onDelete;
  final void Function(Hibah) onTap;

  const _HibahList({
    required this.hibahs,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: hibahs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Hibah submission = hibahs[index];
        return ListTile(
          onTap: () => onTap(submission),
          title: Text(
            submission.certificateId.isEmpty
                ? 'Certificate pending'
                : submission.certificateId,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Assets submitted: ${submission.totalSubmissions}'),
              Text(
                'Updated: ${DateFormat.MMMd().format(submission.updatedAt)}',
              ),
            ],
          ),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      context,
                      submission.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(submission.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(context, submission.status),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(submission),
                ),
              ],
            ),
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HibahInfoScreen(fromHelpIcon: true)),
        );
      },
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
            const Expanded(child: Text('New to hibah?')),
            Text(
              'Learn more',
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
