import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/body.dart';
import '../models/trust_charity.dart';
import '../utils/form_decoration_helper.dart';
import 'trust_charity_browse_screen.dart';

class TrustCharityFormScreen extends StatefulWidget {
  final TrustCharity? charity;
  final int? index;

  const TrustCharityFormScreen({
    super.key,
    this.charity,
    this.index,
  });

  @override
  State<TrustCharityFormScreen> createState() => _TrustCharityFormScreenState();
}

class _TrustCharityFormScreenState extends State<TrustCharityFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static const String _sedekahMarker = 'sedekah_jumaat';
  
  late TextEditingController _organizationNameCtrl;
  late TextEditingController _donationAmountCtrl;
  
  double? _amount;
  String _frequency = 'monthly';
  bool _isSedekahJumaat = false;
  int _years = 1;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  bool _detectSedekahJumaat(TrustCharity? charity) {
    final String marker = (charity?.addressLine2 ?? '').trim().toLowerCase();
    if (marker == _sedekahMarker) return true;
    final String n = (charity?.organizationName ?? '').trim().toLowerCase();
    return n.startsWith('sedekah jumaat');
  }

  String _stripSedekahPrefix(String name) {
    final trimmed = name.trim();
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('sedekah jumaat')) return trimmed;
    // Accept both "Sedekah Jumaat — X" and "Sedekah Jumaat - X"
    final parts = trimmed.split(RegExp(r'[—-]'));
    if (parts.length <= 1) return 'Sedekah Jumaat';
    return parts.sublist(1).join('—').trim();
  }

  int _parseYearsFromAddressLine1(String? addressLine1) {
    final String raw = (addressLine1 ?? '').trim();
    if (raw.isEmpty) return 1;
    final RegExpMatch? match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) return 1;
    final int? parsed = int.tryParse(match.group(1) ?? '');
    if (parsed == null) return 1;
    return parsed.clamp(1, 20);
  }

  void _initializeControllers() {
    final charity = widget.charity;
    _isSedekahJumaat = _detectSedekahJumaat(charity);
    _years = _isSedekahJumaat ? _parseYearsFromAddressLine1(charity?.addressLine1) : 1;
    final String initialName = _isSedekahJumaat
        ? _stripSedekahPrefix(charity?.organizationName ?? '')
        : (charity?.organizationName ?? '');
    _organizationNameCtrl = TextEditingController(text: initialName);
    _amount = charity?.donationAmount;
    _donationAmountCtrl = TextEditingController(
      text: charity?.donationAmount != null ? charity!.donationAmount!.toStringAsFixed(0) : '',
    );
    _frequency = (charity?.donationDuration?.trim().isNotEmpty == true)
        ? charity!.donationDuration!
        : 'monthly';
    if (_isSedekahJumaat) {
      _frequency = 'weekly';
    }
  }

  @override
  void dispose() {
    _organizationNameCtrl.dispose();
    _donationAmountCtrl.dispose();
    super.dispose();
  }

  void _saveCharity() {
    if (_formKey.currentState?.validate() ?? false) {
      final double? amount = _amount ?? double.tryParse(_donationAmountCtrl.text.trim());
      final String orgName = _organizationNameCtrl.text.trim();
      final String resolvedOrgName = orgName;
      final newCharity = TrustCharity(
        id: widget.charity?.id,
        organizationName: resolvedOrgName,
        donationAmount: amount,
        donationDuration: _isSedekahJumaat ? 'weekly' : _frequency,
        // Preserve any extra fields (e.g. Sedekah Jumaat "For X years") by carrying forward the old values.
        addressLine1: _isSedekahJumaat
            ? (_years == 1 ? 'For 1 year' : 'For $_years years')
            : widget.charity?.addressLine1,
        // If this is Sedekah Jumaat, keep / set marker for reliable differentiation.
        addressLine2: _isSedekahJumaat ? _sedekahMarker : widget.charity?.addressLine2,
        city: widget.charity?.city,
        postcode: widget.charity?.postcode,
        state: widget.charity?.state,
        country: widget.charity?.country,
        category: widget.charity?.category,
        bank: widget.charity?.bank,
        accountNumber: widget.charity?.accountNumber,
        email: widget.charity?.email,
        phoneNo: widget.charity?.phoneNo,
      );

      Navigator.pop(context, newCharity);
    }
  }

  Future<void> _pickOrganisation() async {
    if (_isSedekahJumaat) return;
    final BodyItem? picked = await Navigator.of(context).push<BodyItem>(
      MaterialPageRoute<BodyItem>(
        builder: (_) => const TrustCharityBrowseScreen(pickOrganisationOnly: true),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _organizationNameCtrl.text = (picked.name ?? '').trim();
    });
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
        title: Text(widget.charity == null ? 'Add Charity' : 'Edit charity'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _organizationNameCtrl,
                    readOnly: !_isSedekahJumaat,
                    onTap: _isSedekahJumaat ? null : _pickOrganisation,
                    textCapitalization:
                        _isSedekahJumaat ? TextCapitalization.words : TextCapitalization.none,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: _isSedekahJumaat ? 'Masjid / Surau name' : 'Organisation name',
                      prefixIcon: _isSedekahJumaat ? Icons.mosque_outlined : Icons.account_balance_outlined,
                    ).copyWith(
                      suffixIcon: _isSedekahJumaat
                          ? null
                          : IconButton(
                              tooltip: 'Change',
                              onPressed: _pickOrganisation,
                              icon: const Icon(Icons.search),
                            ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _donationAmountCtrl,
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
                    onChanged: (v) => setState(() => _amount = double.tryParse(v.trim())),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final amount = double.tryParse(v.trim());
                      if (amount == null || amount <= 0) return 'Enter a valid amount';
                      return null;
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
                            _donationAmountCtrl.text = '$amt';
                          });
                        },
                        selectedColor: colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_isSedekahJumaat) ...[
                    DropdownButtonFormField<int>(
                      value: _years,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'How many years?',
                        prefixIcon: Icons.schedule_outlined,
                      ),
                      items: List<int>.generate(20, (i) => i + 1)
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: (v) => setState(() => _years = v ?? 1),
                    ),
                  ] else ...[
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
                    onPressed: _saveCharity,
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
                      widget.charity == null ? 'Add' : 'Save',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
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
}

