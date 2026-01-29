import 'package:flutter/material.dart';
import '../models/trust_charity.dart';
import '../config/trust_constants.dart';
import 'trust_charity_form_screen.dart';

class FundSupportConfigScreen extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> category;
  final Map<String, dynamic> initialConfig;

  const FundSupportConfigScreen({
    super.key,
    required this.categoryId,
    required this.category,
    required this.initialConfig,
  });

  @override
  State<FundSupportConfigScreen> createState() => _FundSupportConfigScreenState();
}

class _FundSupportConfigScreenState extends State<FundSupportConfigScreen> {
  late Map<String, dynamic> _config;
  late List<TrustCharity> _charities;

  @override
  void initState() {
    super.initState();
    // Deep copy the initial config to avoid modifying the original
    _config = Map<String, dynamic>.from(widget.initialConfig);
    
    // Initialize charities list from config (for charitable category)
    if (widget.categoryId == 'charitable') {
      final charitiesData = _config['charities'] as List?;
      _charities = charitiesData != null
          ? charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList()
          : [];
    } else {
      _charities = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category['title'] as String? ?? 'Fund Support'),
        actions: [
          TextButton(
            onPressed: () {
              // Save charities to config if charitable category
              if (widget.categoryId == 'charitable') {
                _config['charities'] = _charities.map((c) => c.toJson()).toList();
              }
              Navigator.of(context).pop(_config);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: widget.categoryId == 'charitable'
          ? _buildCharitableContent(theme, colorScheme)
          : _buildRegularContent(theme, colorScheme),
    );
  }

  Widget _buildCharitableContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_charities.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      size: 48,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No charities/donations added yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add charitable organizations you would like to donate to',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._charities.asMap().entries.map((entry) {
              final index = entry.key;
              final charity = entry.value;
              
              // Build subtitle text
              String subtitleText = '';
              if (charity.category != null) {
                final categoryName = TrustConstants.donationCategories
                    .firstWhere((c) => c['value'] == charity.category,
                        orElse: () => {'name': charity.category!})['name']!;
                subtitleText = categoryName;
              }
              if (charity.donationAmount != null) {
                final amountText = 'RM ${charity.donationAmount!.toStringAsFixed(2)}';
                final durationText = charity.donationDuration != null 
                    ? ' (${TrustConstants.donationDurations.firstWhere((d) => d['value'] == charity.donationDuration, orElse: () => {'name': charity.donationDuration!})['name']})'
                    : '';
                if (subtitleText.isNotEmpty) {
                  subtitleText += ' • $amountText$durationText';
                } else {
                  subtitleText = '$amountText$durationText';
                }
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(charity.organizationName ?? 'Unnamed Organization'),
                  subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCharity(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCharity(index),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCharity,
              icon: const Icon(Icons.add),
              label: const Text('Add Charity/Donation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularContent(ThemeData theme, ColorScheme colorScheme) {
    final durationType = _config['durationType'] as String?;
    final endAge = (_config['endAge'] as num?)?.toDouble() ?? 24.0;
    final isRegularPayments = _config['isRegularPayments'] as bool?; // null means nothing selected
    final paymentAmount = (_config['paymentAmount'] as num?)?.toDouble() ?? 1000.0;
    final paymentFrequency = _config['paymentFrequency'] as String?;
    final releaseCondition = _config['releaseCondition'] as String?;

    final presetAmounts = [1000.0, 2000.0, 3000.0, 5000.0];
    final paymentFrequencies = [
      {'value': 'monthly', 'label': 'Monthly'},
      {'value': 'quarterly', 'label': 'Quarterly'},
      {'value': 'yearly', 'label': 'Yearly'},
      {'value': 'when_conditions', 'label': 'When conditions'},
    ];

    // Calculate years from now and end year
    final currentYear = DateTime.now().year;
    final yearsFromNow = (endAge - 18).round();
    final endYear = currentYear + yearsFromNow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Support Duration Section
          Text(
            'How long should this last?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Until a specific age option
          InkWell(
              onTap: () {
                setState(() {
                  _config['durationType'] = 'age';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: durationType == 'age'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: durationType == 'age'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: durationType == 'age' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: durationType == 'age'
                                ? colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: durationType == 'age'
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: durationType == 'age'
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Until a specific age',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (durationType == 'age') ...[
                      const SizedBox(height: 12),
                      Text(
                        'Age',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${endAge.round()}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: endAge,
                        min: 18,
                        max: 40,
                        divisions: 22,
                        label: '${endAge.round()}',
                        onChanged: (value) {
                          setState(() {
                            _config['endAge'] = value;
                          });
                        },
                      ),
                      Text(
                        "That's $yearsFromNow years from now (Year $endYear)",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Their entire lifetime option
          InkWell(
              onTap: () {
                setState(() {
                  _config['durationType'] = 'lifetime';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: durationType == 'lifetime'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: durationType == 'lifetime'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: durationType == 'lifetime' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: durationType == 'lifetime'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: durationType == 'lifetime'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: durationType == 'lifetime'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Their entire lifetime',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Payment Configuration Section
          Text(
              'Payment Configuration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          // Regular payments option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = true;
                  _config['releaseCondition'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == true
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == true
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == true ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRegularPayments == true
                                ? colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isRegularPayments == true
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: isRegularPayments == true
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Regular payments',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isRegularPayments == true) ...[
                      const SizedBox(height: 16),
                      // Amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'RM',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paymentAmount.toStringAsFixed(2).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: paymentAmount,
                                  min: 100,
                                  max: 10000,
                                  divisions: 99,
                                  label: 'RM ${paymentAmount.toStringAsFixed(0)}',
                                  onChanged: (value) {
                                    setState(() {
                                      _config['paymentAmount'] = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: presetAmounts.map((amount) {
                                    final isSelected = (paymentAmount - amount).abs() < 0.01;
                                    return ChoiceChip(
                                      label: Text('RM ${amount.toStringAsFixed(0)}'),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _config['paymentAmount'] = amount;
                                          });
                                        }
                                      },
                                      selectedColor: colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'How often should this contribution be carried out?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: paymentFrequencies.map((freq) {
                                    final isSelected = paymentFrequency == freq['value'];
                                    return ChoiceChip(
                                      label: Text(freq['label']!),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _config['paymentFrequency'] = freq['value'] as String;
                                          });
                                        }
                                      },
                                      selectedColor: colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // As needed option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = false;
                  _config['releaseCondition'] = 'as_needed';
                  _config['paymentAmount'] = null;
                  _config['paymentFrequency'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == false && releaseCondition == 'as_needed'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == false && releaseCondition == 'as_needed'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == false && releaseCondition == 'as_needed' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRegularPayments == false && releaseCondition == 'as_needed'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isRegularPayments == false && releaseCondition == 'as_needed'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isRegularPayments == false && releaseCondition == 'as_needed'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'As needed (trustee decides)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your trustee releases money when needed for approved purposes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Lump sum option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = false;
                  _config['releaseCondition'] = 'lump_sum';
                  _config['paymentAmount'] = null;
                  _config['paymentFrequency'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == false && releaseCondition == 'lump_sum'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == false && releaseCondition == 'lump_sum'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == false && releaseCondition == 'lump_sum' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRegularPayments == false && releaseCondition == 'lump_sum'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isRegularPayments == false && releaseCondition == 'lump_sum'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isRegularPayments == false && releaseCondition == 'lump_sum'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lump sum at the end',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Everything released when the trust period ends',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'This is a guide. Your executor can adjust based on real needs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          ],
        ),
      );
  }

  Future<void> _addCharity() async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrustCharityFormScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities.add(result);
      });
    }
  }

  Future<void> _editCharity(int index) async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustCharityFormScreen(
          charity: _charities[index],
          index: index,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities[index] = result;
      });
    }
  }

  void _deleteCharity(int index) {
    setState(() {
      _charities.removeAt(index);
    });
  }
}
