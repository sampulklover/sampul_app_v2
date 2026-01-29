import 'package:flutter/material.dart';

import '../config/trust_constants.dart';
import '../models/trust.dart';
import '../models/trust_charity.dart';
import '../services/trust_service.dart';
import 'trust_charity_form_screen.dart';

class TrustDonationsRecordScreen extends StatefulWidget {
  final Trust trust;

  const TrustDonationsRecordScreen({super.key, required this.trust});

  @override
  State<TrustDonationsRecordScreen> createState() => _TrustDonationsRecordScreenState();
}

class _TrustDonationsRecordScreenState extends State<TrustDonationsRecordScreen> {
  bool _loading = true;
  List<TrustCharity> _items = <TrustCharity>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trustId = widget.trust.id;
    if (trustId == null) {
      setState(() {
        _items = <TrustCharity>[];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await TrustService.instance.getCharitiesByTrustId(trustId);
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatAmount(double? amount) {
    final v = amount ?? 0.0;
    return 'RM ${v.toStringAsFixed(2)}';
  }

  String? _categoryLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    return TrustConstants.donationCategories
        .firstWhere((c) => c['value'] == value, orElse: () => {'name': value})['name'];
  }

  String? _durationLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    return TrustConstants.donationDurations
        .firstWhere((d) => d['value'] == value, orElse: () => {'name': value})['name'];
  }

  Future<void> _add() async {
    final trustId = widget.trust.id;
    if (trustId == null) return;

    final created = await Navigator.of(context).push<TrustCharity>(
      MaterialPageRoute<TrustCharity>(
        builder: (_) => const TrustCharityFormScreen(),
      ),
    );
    if (created == null) return;

    try {
      await TrustService.instance.createCharity(created.copyWith(trustId: trustId));
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add donation: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _edit(TrustCharity charity) async {
    if (charity.id == null) return;

    final updated = await Navigator.of(context).push<TrustCharity>(
      MaterialPageRoute<TrustCharity>(
        builder: (_) => TrustCharityFormScreen(charity: charity),
      ),
    );
    if (updated == null) return;

    try {
      await TrustService.instance.updateCharity(charity.id!, updated.toJson());
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update donation: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(TrustCharity charity) async {
    if (charity.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete donation?'),
        content: Text('Remove ${charity.organizationName ?? 'this organization'} from this trust?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await TrustService.instance.deleteCharity(charity.id!);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete donation: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trustTitle = widget.trust.name?.trim().isNotEmpty == true ? widget.trust.name!.trim() : 'Trust Fund';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust Donations Record'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    trustTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Charities / Donations (${_items.length})',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.volunteer_activism_outlined, size: 48, color: const Color.fromRGBO(49, 24, 211, 1).withOpacity(0.6)),
                            const SizedBox(height: 12),
                            Text('No donations recorded yet', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              'Tap Add to record a charity/donation for this trust.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._items.map((c) {
                      final cat = _categoryLabel(c.category);
                      final dur = _durationLabel(c.donationDuration);

                      final subtitleParts = <String>[];
                      if (cat != null) subtitleParts.add(cat);
                      subtitleParts.add('${_formatAmount(c.donationAmount)}${dur != null ? ' • $dur' : ''}');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(c.organizationName ?? 'Unnamed Organization'),
                          subtitle: Text(subtitleParts.join('\n')),
                          isThreeLine: subtitleParts.length > 1,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _edit(c),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _delete(c),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

