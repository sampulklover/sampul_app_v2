import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/hibah.dart';
import '../services/supabase_service.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/sampul_icons.dart';

class HibahAssetEditScreen extends StatefulWidget {
  final HibahGroupRequest initial;

  const HibahAssetEditScreen({super.key, required this.initial});

  @override
  State<HibahAssetEditScreen> createState() => _HibahAssetEditScreenState();
}

class _HibahAssetEditScreenState extends State<HibahAssetEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _propertyNameCtrl = TextEditingController();
  final TextEditingController _registeredTitleCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _estimatedValueCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _loanAmountCtrl = TextEditingController();

  String? _loanStatus;
  List<String> _landCategories = <String>[];
  List<HibahBeneficiaryRequest> _beneficiaries = <HibahBeneficiaryRequest>[];
  List<_BelovedOption> _belovedOptions = <_BelovedOption>[];
  bool _isLoadingBeloved = false;

  static const List<String> _loanStatuses = <String>[
    'fully_paid',
    'ongoing_financing',
    'no_financing',
  ];

  static const List<String> _landCategoryOptions = <String>[
    'Residential',
    'Commercial',
    'Industrial',
    'Agriculture',
    'Mixed development',
  ];

  String? _normalizeLoanStatus(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;

    // Legacy / inconsistent values we’ve seen from older data.
    if (v == 'false' || v == 'no' || v == 'none' || v == 'no_loan') {
      return 'no_financing';
    }
    if (v == 'true' || v == 'yes' || v == 'under_loan') {
      return 'ongoing_financing';
    }
    if (v == 'paid' || v == 'fullypaid' || v == 'fully_paid') {
      return 'fully_paid';
    }

    // If it’s already one of our allowed values, keep it.
    if (_loanStatuses.contains(v)) return v;

    // Unknown value: don’t set initialValue to avoid Dropdown assertion.
    return null;
  }

  @override
  void initState() {
    super.initState();
    final HibahGroupRequest initial = widget.initial;
    _propertyNameCtrl.text = initial.propertyName ?? '';
    _registeredTitleCtrl.text = initial.registeredTitleNumber ?? '';
    _locationCtrl.text = initial.propertyLocation ?? '';
    _estimatedValueCtrl.text = initial.estimatedValue ?? '';
    _bankNameCtrl.text = initial.bankName ?? '';
    _loanAmountCtrl.text = initial.outstandingLoanAmount ?? '';
    _loanStatus = _normalizeLoanStatus(initial.loanStatus);
    _landCategories = List<String>.from(initial.landCategories);
    _beneficiaries = List<HibahBeneficiaryRequest>.from(initial.beneficiaries);
    _loadBelovedOptions();
  }

  Future<void> _loadBelovedOptions() async {
    if (_isLoadingBeloved) return;
    setState(() => _isLoadingBeloved = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;

      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name,relationship')
          .eq('uuid', user.id)
          .order('name');

      if (!mounted) return;
      setState(() {
        _belovedOptions = rows
            .map(
              (dynamic row) =>
                  _BelovedOption.fromMap(row as Map<String, dynamic>),
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isLoadingBeloved = false);
    }
  }

  @override
  void dispose() {
    _propertyNameCtrl.dispose();
    _registeredTitleCtrl.dispose();
    _locationCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _bankNameCtrl.dispose();
    _loanAmountCtrl.dispose();
    super.dispose();
  }

  double _currentShareTotal([HibahBeneficiaryRequest? exclude]) {
    return _beneficiaries
        .where((HibahBeneficiaryRequest b) => b != exclude)
        .fold(
          0.0,
          (double sum, HibahBeneficiaryRequest b) =>
              sum + (b.sharePercentage ?? 0),
        );
  }

  Future<void> _addOrEditBeneficiary({HibahBeneficiaryRequest? initial}) async {
    final _BeneficiaryFormResult? result =
        await showModalBottomSheet<_BeneficiaryFormResult>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _BeneficiaryForm(
            belovedOptions: _belovedOptions,
            initial: initial,
          ),
        );

    if (result == null) return;

    final double totalIfAdded =
        _currentShareTotal(initial) + (result.sharePercentage ?? 0);
    if (totalIfAdded > 100.0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shares exceed 100% (current total ${totalIfAdded.toStringAsFixed(2)}%)',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (initial == null) {
        _beneficiaries.add(result.toRequest());
      } else {
        final int index = _beneficiaries.indexOf(initial);
        if (index != -1) _beneficiaries[index] = result.toRequest();
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_beneficiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one beneficiary')),
      );
      return;
    }

    Navigator.of(context).pop(
      HibahGroupRequest(
        tempId: widget.initial.tempId,
        propertyName: _propertyNameCtrl.text.trim(),
        assetType: widget.initial.assetType,
        registeredTitleNumber: _propertyName(_registeredTitleCtrl.text),
        propertyLocation: _propertyName(_locationCtrl.text),
        estimatedValue: _propertyName(_estimatedValueCtrl.text),
        loanStatus: _loanStatus,
        bankName: _propertyName(_bankNameCtrl.text),
        outstandingLoanAmount: _propertyName(_loanAmountCtrl.text),
        landCategories: _landCategories,
        beneficiaries: _beneficiaries,
      ),
    );
  }

  String? _propertyName(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  InputDecoration _fieldDecoration(String label) {
    IconData? prefix;
    switch (label) {
      case 'Property / asset name *':
        prefix = Icons.domain_outlined;
        break;
      case 'Registered title number':
        prefix = Icons.badge_outlined;
        break;
      case 'Property location':
        prefix = Icons.place_outlined;
        break;
      case 'Estimated value (MYR)':
        prefix = Icons.payments_outlined;
        break;
      case 'Loan status':
        prefix = Icons.account_balance_outlined;
        break;
      case 'Bank / financier':
        prefix = Icons.account_balance_outlined;
        break;
      case 'Outstanding loan amount':
        prefix = Icons.payments_outlined;
        break;
      default:
        prefix = null;
    }

    return FormDecorationHelper.roundedInputDecoration(
      context: context,
      labelText: label,
      prefixIcon: prefix,
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiariesCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.group, color: const Color.fromRGBO(83, 61, 233, 1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beneficiaries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditBeneficiary(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_isLoadingBeloved) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            if (_beneficiaries.isEmpty)
              Text(
                'No beneficiaries yet. Add at least one recipient.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ..._beneficiaries.asMap().entries.map((entry) {
                final int index = entry.key;
                final HibahBeneficiaryRequest b = entry.value;
                final String shareLabel =
                    '${(b.sharePercentage ?? 0).toStringAsFixed(2)}% share';
                return Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.name),
                      subtitle: Text(
                        b.relationship == null
                            ? shareLabel
                            : '${b.relationship} • $shareLabel',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _addOrEditBeneficiary(initial: b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _beneficiaries.remove(b)),
                          ),
                        ],
                      ),
                    ),
                    if (index != _beneficiaries.length - 1)
                      const Divider(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit asset'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEAEAEA),
                      ),
                      alignment: Alignment.center,
                      child: SampulIcons.buildIcon(
                        SampulIcons.home,
                        width: 36,
                        height: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_propertyNameCtrl.text.trim().isEmpty)
                          ? 'Asset'
                          : _propertyNameCtrl.text.trim(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.domain_outlined,
                color: scheme.primary,
                title: 'Asset details',
                children: <Widget>[
                  TextFormField(
                    controller: _propertyNameCtrl,
                    decoration: _fieldDecoration('Property / asset name *'),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registeredTitleCtrl,
                    decoration: _fieldDecoration('Registered title number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: _fieldDecoration('Property location'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _estimatedValueCtrl,
                    decoration: _fieldDecoration('Estimated value (MYR)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.account_balance_outlined,
                color: scheme.secondary,
                title: 'Loan & financing',
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _loanStatus,
                    isExpanded: true,
                    icon: SampulIcons.buildIcon(
                      SampulIcons.chevronDown,
                      width: 24,
                      height: 24,
                    ),
                    decoration: _fieldDecoration('Loan status'),
                    items: _loanStatuses
                        .map(
                          (String status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => _loanStatus = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankNameCtrl,
                    decoration: _fieldDecoration('Bank / financier'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _loanAmountCtrl,
                    decoration: _fieldDecoration('Outstanding loan amount'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.terrain_outlined,
                color: scheme.tertiary,
                title: 'Land categories',
                children: <Widget>[
                  Text(
                    'Select one or more categories if the asset is land-based.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _landCategoryOptions.map((String option) {
                      final bool selected = _landCategories.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              _landCategories.add(option);
                            } else {
                              _landCategories.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBeneficiariesCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                'Save changes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BelovedOption {
  final int id;
  final String name;
  final String? relationship;

  const _BelovedOption({
    required this.id,
    required this.name,
    this.relationship,
  });

  factory _BelovedOption.fromMap(Map<String, dynamic> map) {
    return _BelovedOption(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String? ?? 'Unnamed',
      relationship: map['relationship'] as String?,
    );
  }
}

class _BeneficiaryFormResult {
  final int? belovedId;
  final String name;
  final String? relationship;
  final double? sharePercentage;
  final String? notes;

  const _BeneficiaryFormResult({
    this.belovedId,
    required this.name,
    this.relationship,
    this.sharePercentage,
    this.notes,
  });

  HibahBeneficiaryRequest toRequest() {
    return HibahBeneficiaryRequest(
      belovedId: belovedId,
      name: name,
      relationship: relationship,
      sharePercentage: sharePercentage,
      notes: notes,
    );
  }
}

class _BeneficiaryForm extends StatefulWidget {
  final List<_BelovedOption> belovedOptions;
  final HibahBeneficiaryRequest? initial;

  const _BeneficiaryForm({required this.belovedOptions, this.initial});

  @override
  State<_BeneficiaryForm> createState() => _BeneficiaryFormState();
}

class _BeneficiaryFormState extends State<_BeneficiaryForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _relationshipCtrl = TextEditingController();
  final TextEditingController _shareCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  int? _selectedBelovedId;

  @override
  void initState() {
    super.initState();
    final HibahBeneficiaryRequest? initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.name;
      _relationshipCtrl.text = initial.relationship ?? '';
      _shareCtrl.text = initial.sharePercentage?.toString() ?? '';
      _notesCtrl.text = initial.notes ?? '';
      _selectedBelovedId = initial.belovedId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    _shareCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleBelovedChange(int? id) {
    setState(() => _selectedBelovedId = id);
    if (id == null) return;
    final _BelovedOption option = widget.belovedOptions.firstWhere(
      (opt) => opt.id == id,
    );
    _nameCtrl.text = option.name;
    if ((option.relationship ?? '').isNotEmpty) {
      _relationshipCtrl.text = option.relationship!;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final double? share = _shareCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_shareCtrl.text.trim());

    Navigator.of(context).pop(
      _BeneficiaryFormResult(
        belovedId: _selectedBelovedId,
        name: _nameCtrl.text.trim(),
        relationship: _relationshipCtrl.text.trim().isEmpty
            ? null
            : _relationshipCtrl.text.trim(),
        sharePercentage: share,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.initial == null
                            ? 'Add beneficiary'
                            : 'Edit beneficiary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose who should receive this hibah and how much they should receive.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (widget.belovedOptions.isNotEmpty)
                          DropdownButtonFormField<int>(
                            initialValue: _selectedBelovedId,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: 'Select from family',
                              prefixIcon: Icons.group_outlined,
                            ),
                            isExpanded: true,
                            icon: SampulIcons.buildIcon(
                              SampulIcons.chevronDown,
                              width: 24,
                              height: 24,
                            ),
                            items: widget.belovedOptions
                                .map(
                                  (_BelovedOption option) => DropdownMenuItem<int>(
                                    value: option.id,
                                    child: Text(option.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _handleBelovedChange,
                          ),
                        if (widget.belovedOptions.isNotEmpty)
                          const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Full name',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _relationshipCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Relationship',
                            prefixIcon: Icons.family_restroom_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shareCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Share (%)',
                            hintText: 'For example, 50',
                            prefixIcon: Icons.percent_outlined,
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Notes',
                            hintText: 'Add any helpful note',
                            prefixIcon: Icons.notes_outlined,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        'Save beneficiary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
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
