import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/body.dart';
import '../models/trust_charity.dart';
import '../services/bodies_service.dart';
import '../utils/form_decoration_helper.dart';

/// Browse charitable bodies (from `bodies` table) and configure a simple
/// instruction (amount + frequency) that will be stored as a `TrustCharity`.
class TrustCharityBrowseScreen extends StatefulWidget {
  /// When true, selecting a body pops a [BodyItem] (organisation only).
  /// When false (default), selecting a body opens the contribution setup flow
  /// and pops a configured [TrustCharity].
  final bool pickOrganisationOnly;

  const TrustCharityBrowseScreen({
    super.key,
    this.pickOrganisationOnly = false,
  });

  @override
  State<TrustCharityBrowseScreen> createState() => _TrustCharityBrowseScreenState();
}

class _TrustCharityBrowseScreenState extends State<TrustCharityBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<BodyItem> _allBodies = <BodyItem>[];
  List<BodyItem> _filteredBodies = <BodyItem>[];
  bool _isLoading = true;
  
  String? _categoryLabel(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    switch (v) {
      case 'sadaqah_waqaf_zakat':
        return 'Sadaqah • Waqf • Zakat';
      default:
        // Fallback: prettify snake_case to Title Case
        final words = v.split('_').where((w) => w.isNotEmpty).toList();
        if (words.isEmpty) return null;
        return words
            .map((w) => w.length <= 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

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
    if (widget.pickOrganisationOnly) {
      if (!mounted) return;
      Navigator.of(context).pop<BodyItem>(body);
      return;
    }
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
        title: const Text('Select organisation'),
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
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Search',
                        hintText: 'Search by organisation name',
                        prefixIcon: Icons.search,
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
                          title: Text(body.name ?? 'Organisation #${body.id}'),
                          subtitle: Text(
                            _categoryLabel(body.category) ?? 'Charity organisation',
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

/// Second step: set amount + frequency (no one-time option).
class _TrustCharityInstructionScreen extends StatefulWidget {
  final BodyItem body;

  const _TrustCharityInstructionScreen({required this.body});

  @override
  State<_TrustCharityInstructionScreen> createState() => _TrustCharityInstructionScreenState();
}

class _TrustCharityInstructionScreenState extends State<_TrustCharityInstructionScreen> {
  double? _amount = 50;
  String _frequency = 'monthly';
  late final TextEditingController _amountCtrl = TextEditingController(text: '50');

  void _confirm() {
    final amount = _amount;
    if (amount == null || amount <= 0) return;

    final TrustCharity charity = TrustCharity(
      organizationName: widget.body.name,
      // Leave category null here to avoid enum mismatches; it can be refined later
      // using the dedicated donationCategories options if needed.
      category: null,
      donationAmount: amount,
      donationDuration: _frequency,
    );
    Navigator.of(context).pop<TrustCharity>(charity);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<int> presetAmounts = <int>[10, 50, 100];
    final List<Map<String, String>> frequencies = const <Map<String, String>>[
      {'value': 'weekly', 'label': 'Weekly'},
      {'value': 'monthly', 'label': 'Monthly'},
      {'value': 'quarterly', 'label': 'Quarterly'},
      {'value': 'yearly', 'label': 'Yearly'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution setup'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.body.name ?? 'Charity organisation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set the amount and frequency.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Amount (RM)',
                      hintText: 'e.g. 50',
                      prefixIcon: Icons.payments_outlined,
                    ).copyWith(prefixText: 'RM '),
                    onChanged: (String v) {
                      setState(() => _amount = double.tryParse(v.trim()));
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetAmounts.map((int amt) {
                      final bool selected = _amount != null && (_amount! - amt).abs() < 0.01;
                      return ChoiceChip(
                        label: Text('RM $amt'),
                        selected: selected,
                        onSelected: (bool on) {
                          if (!on) return;
                          setState(() {
                            _amount = amt.toDouble();
                            _amountCtrl.text = '$amt';
                          });
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Frequency',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    items: frequencies
                        .map(
                          (f) => DropdownMenuItem<String>(
                            value: f['value'],
                            child: Text(f['label'] ?? f['value'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _frequency = v);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SafeArea(
                top: false,
                bottom: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_amount ?? 0) > 0 ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Save',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: (_amount ?? 0) > 0
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Frequency is now a dropdown (matches other form steps).
}

