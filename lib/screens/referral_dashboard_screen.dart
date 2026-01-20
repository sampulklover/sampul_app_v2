import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../services/affiliate_service.dart';
import '../services/supabase_service.dart';

class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> {
  bool _isLoading = true;
  String? _code;
  int _referralsCount = 0;
  List<Map<String, dynamic>> _recentReferrals = const [];

  String _formatCreatedAt(String raw) {
    if (raw.trim().isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);

    final time = DateFormat.jm().format(local);
    if (date == today) {
      return 'Today • $time';
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • $time';
    }
    return '${DateFormat.yMMMd().format(local)} • $time';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final code = await AffiliateService.instance.getOrCreateMyAffiliateCode();

      final rows = await SupabaseService.instance.client
          .from('affiliate_referrals')
          .select('id, created_at, referred_id')
          .eq('referrer_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      final list = (rows as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _code = code;
        _referralsCount = list.length;
        _recentReferrals = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyCode() async {
    final code = _code;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your referral code',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const LinearProgressIndicator(minHeight: 2)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _code ?? '-',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Copy',
                            onPressed: _isLoading ? null : _copyCode,
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Share this code with friends.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 74,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Referrals', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text(
                              _isLoading ? '—' : '$_referralsCount',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 74,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rewards', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text(
                              'Coming soon',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Recent', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : (_recentReferrals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No referrals yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_recentReferrals.length, (i) {
                            final r = _recentReferrals[i];
                            final createdAt = (r['created_at'] as String?) ?? '';
                            final tile = ListTile(
                              leading: const Icon(Icons.person_add_alt_1_outlined),
                              title: const Text('New signup'),
                              subtitle: Text(_formatCreatedAt(createdAt)),
                              dense: true,
                              minVerticalPadding: 0,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            );
                            if (i == _recentReferrals.length - 1) return tile;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                tile,
                                const Divider(height: 1),
                              ],
                            );
                          }),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

