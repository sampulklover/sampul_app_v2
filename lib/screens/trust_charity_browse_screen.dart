import 'package:flutter/material.dart';
import '../models/body.dart';
import '../models/trust_charity.dart';
import '../services/bodies_service.dart';

/// Browse charitable bodies (from `bodies` table) and configure a simple
/// instruction (amount + frequency) that will be stored as a `TrustCharity`.
class TrustCharityBrowseScreen extends StatefulWidget {
  const TrustCharityBrowseScreen({super.key});

  @override
  State<TrustCharityBrowseScreen> createState() => _TrustCharityBrowseScreenState();
}

class _TrustCharityBrowseScreenState extends State<TrustCharityBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<BodyItem> _allBodies = <BodyItem>[];
  List<BodyItem> _filteredBodies = <BodyItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBodies();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBodies() async {
    try {
      final List<BodyItem> rows = await BodiesService.instance.listActiveBodies();
      // Filter only sadaqah/waqf/zakat bodies as requested
      const String allowCat = 'sadaqah_waqaf_zakat';
      final List<BodyItem> filtered = rows.where((BodyItem b) {
        return (b.category ?? '').toLowerCase() == allowCat;
      }).toList();
      setState(() {
        _allBodies
          ..clear()
          ..addAll(filtered);
        _filteredBodies = List<BodyItem>.from(_allBodies);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final String q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredBodies = List<BodyItem>.from(_allBodies);
      } else {
        _filteredBodies = _allBodies
            .where((BodyItem b) => (b.name ?? '').toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _openInstructionConfig(BodyItem body) async {
    final TrustCharity? result = await Navigator.of(context).push<TrustCharity>(
      MaterialPageRoute<TrustCharity>(
        builder: (BuildContext context) => _TrustCharityInstructionScreen(body: body),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop<TrustCharity>(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charitable instructions'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by organisation name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filteredBodies.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final BodyItem body = _filteredBodies[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              (body.name ?? '?').isNotEmpty
                                  ? body.name![0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(body.name ?? 'Organisation #${body.id}'),
                          subtitle: Text(
                            (body.category ?? '').isNotEmpty
                                ? body.category!
                                : 'Charitable organisation',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openInstructionConfig(body),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Second step: choose contribution type (ongoing vs one-time) and amount.
class _TrustCharityInstructionScreen extends StatefulWidget {
  final BodyItem body;

  const _TrustCharityInstructionScreen({required this.body});

  @override
  State<_TrustCharityInstructionScreen> createState() => _TrustCharityInstructionScreenState();
}

class _TrustCharityInstructionScreenState extends State<_TrustCharityInstructionScreen> {
  bool _isOngoing = true;
  double _percentage = 5;
  String _frequency = 'yearly';

  void _confirm() {
    // Map slider % into a simple RM amount placeholder of 0; actual RM will be
    // decided at execution time, but we still store a nominal percentage.
    final TrustCharity charity = TrustCharity(
      organizationName: widget.body.name,
      // Leave category null here to avoid enum mismatches; it can be refined later
      // using the dedicated donationCategories options if needed.
      category: null,
      donationAmount: _percentage, // interpret as percentage for now
      donationDuration: _isOngoing ? _frequency : 'one_time',
    );
    Navigator.of(context).pop<TrustCharity>(charity);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOngoing ? 'Ongoing contribution' : 'One-time contribution'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How should this contribution be carried out?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ToggleButtons(
                borderRadius: BorderRadius.circular(24),
                isSelected: <bool>[_isOngoing, !_isOngoing],
                onPressed: (int index) {
                  setState(() {
                    _isOngoing = index == 0;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Ongoing'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('One-time'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Percentage of fund',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${_percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Slider(
                value: _percentage,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${_percentage.toStringAsFixed(0)}%',
                onChanged: (double v) {
                  setState(() => _percentage = v);
                },
              ),
              const SizedBox(height: 16),
              if (_isOngoing) ...[
                Text(
                  'How often should this contribution be carried out?',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFreqChip('monthly', 'Monthly'),
                    _buildFreqChip('quarterly', 'Quarterly'),
                    _buildFreqChip('yearly', 'Yearly'),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: Text(_isOngoing ? 'Confirm ongoing instruction' : 'Confirm one-time instruction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreqChip(String value, String label) {
    final ThemeData theme = Theme.of(context);
    final bool selected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _frequency = value),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}

