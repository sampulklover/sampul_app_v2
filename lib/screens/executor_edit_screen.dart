import 'package:flutter/material.dart';
import '../services/executor_service.dart';
import '../models/executor.dart';

class ExecutorEditScreen extends StatefulWidget {
  final Executor initial;

  const ExecutorEditScreen({super.key, required this.initial});

  @override
  State<ExecutorEditScreen> createState() => _ExecutorEditScreenState();
}

class _ExecutorEditScreenState extends State<ExecutorEditScreen> {
  final GlobalKey<FormState> _deceasedFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _claimantFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _documentsFormKey = GlobalKey<FormState>();

  // Deceased information controllers
  final TextEditingController _deceasedNameCtrl = TextEditingController();
  final TextEditingController _deceasedNricCtrl = TextEditingController();
  final TextEditingController _deceasedDobCtrl = TextEditingController();
  final TextEditingController _deceasedDodCtrl = TextEditingController();
  final TextEditingController _relationshipCtrl = TextEditingController();

  // Claimant information controllers
  final TextEditingController _claimantNameCtrl = TextEditingController();
  final TextEditingController _claimantNricCtrl = TextEditingController();
  final TextEditingController _claimantDobCtrl = TextEditingController();
  final TextEditingController _claimantPhoneCtrl = TextEditingController();
  final TextEditingController _claimantEmailCtrl = TextEditingController();
  final TextEditingController _claimantAddress1Ctrl = TextEditingController();
  final TextEditingController _claimantAddress2Ctrl = TextEditingController();
  final TextEditingController _claimantCityCtrl = TextEditingController();
  final TextEditingController _claimantPostcodeCtrl = TextEditingController();
  final TextEditingController _claimantStateCtrl = TextEditingController();

  // Additional information controllers
  final TextEditingController _supportingDocsCtrl = TextEditingController();
  final TextEditingController _additionalNotesCtrl = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    _deceasedNameCtrl.text = widget.initial.deceasedName ?? '';
    _deceasedNricCtrl.text = widget.initial.deceasedNricNumber ?? '';
    _deceasedDobCtrl.text = widget.initial.deceasedDateOfBirth?.toIso8601String().split('T').first ?? '';
    _deceasedDodCtrl.text = widget.initial.deceasedDateOfDeath?.toIso8601String().split('T').first ?? '';
    _relationshipCtrl.text = widget.initial.relationshipToDeceased ?? '';
    _claimantNameCtrl.text = widget.initial.claimantName ?? '';
    _claimantNricCtrl.text = widget.initial.claimantNricNumber ?? '';
    _claimantDobCtrl.text = widget.initial.claimantDateOfBirth?.toIso8601String().split('T').first ?? '';
    _claimantPhoneCtrl.text = widget.initial.claimantPhoneNo ?? '';
    _claimantEmailCtrl.text = widget.initial.claimantEmail ?? '';
    _claimantAddress1Ctrl.text = widget.initial.claimantAddressLine1 ?? '';
    _claimantAddress2Ctrl.text = widget.initial.claimantAddressLine2 ?? '';
    _claimantCityCtrl.text = widget.initial.claimantCity ?? '';
    _claimantPostcodeCtrl.text = widget.initial.claimantPostcode ?? '';
    _claimantStateCtrl.text = widget.initial.claimantState ?? '';
    _supportingDocsCtrl.text = widget.initial.supportingDocuments ?? '';
    _additionalNotesCtrl.text = widget.initial.additionalNotes ?? '';
  }

  @override
  void dispose() {
    _deceasedNameCtrl.dispose();
    _deceasedNricCtrl.dispose();
    _deceasedDobCtrl.dispose();
    _deceasedDodCtrl.dispose();
    _relationshipCtrl.dispose();
    _claimantNameCtrl.dispose();
    _claimantNricCtrl.dispose();
    _claimantDobCtrl.dispose();
    _claimantPhoneCtrl.dispose();
    _claimantEmailCtrl.dispose();
    _claimantAddress1Ctrl.dispose();
    _claimantAddress2Ctrl.dispose();
    _claimantCityCtrl.dispose();
    _claimantPostcodeCtrl.dispose();
    _claimantStateCtrl.dispose();
    _supportingDocsCtrl.dispose();
    _additionalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_deceasedFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      return;
    }
    if (!(_claimantFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!(_documentsFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 2);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> updateData = {
        'deceased_name': _deceasedNameCtrl.text.trim(),
        'deceased_nric_number': _deceasedNricCtrl.text.trim().isEmpty ? null : _deceasedNricCtrl.text.trim(),
        'deceased_date_of_birth': _deceasedDobCtrl.text.isNotEmpty ? _deceasedDobCtrl.text : null,
        'deceased_date_of_death': _deceasedDodCtrl.text.isNotEmpty ? _deceasedDodCtrl.text : null,
        'relationship_to_deceased': _relationshipCtrl.text.trim().isEmpty ? null : _relationshipCtrl.text.trim(),
        'claimant_name': _claimantNameCtrl.text.trim(),
        'claimant_nric_number': _claimantNricCtrl.text.trim().isEmpty ? null : _claimantNricCtrl.text.trim(),
        'claimant_date_of_birth': _claimantDobCtrl.text.isNotEmpty ? _claimantDobCtrl.text : null,
        'claimant_phone_no': _claimantPhoneCtrl.text.trim().isEmpty ? null : _claimantPhoneCtrl.text.trim(),
        'claimant_email': _claimantEmailCtrl.text.trim().isEmpty ? null : _claimantEmailCtrl.text.trim(),
        'claimant_address_line_1': _claimantAddress1Ctrl.text.trim().isEmpty ? null : _claimantAddress1Ctrl.text.trim(),
        'claimant_address_line_2': _claimantAddress2Ctrl.text.trim().isEmpty ? null : _claimantAddress2Ctrl.text.trim(),
        'claimant_city': _claimantCityCtrl.text.trim().isEmpty ? null : _claimantCityCtrl.text.trim(),
        'claimant_postcode': _claimantPostcodeCtrl.text.trim().isEmpty ? null : _claimantPostcodeCtrl.text.trim(),
        'claimant_state': _claimantStateCtrl.text.trim().isEmpty ? null : _claimantStateCtrl.text.trim(),
        'supporting_documents': _supportingDocsCtrl.text.trim().isEmpty ? null : _supportingDocsCtrl.text.trim(),
        'additional_notes': _additionalNotesCtrl.text.trim().isEmpty ? null : _additionalNotesCtrl.text.trim(),
      };

      await ExecutorService.instance.updateExecutor(widget.initial.id!, updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Executor updated successfully'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update executor: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Executor')),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final bool isLast = _currentStep == 3;
            return Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_currentStep == 0) {
                            if (!(_deceasedFormKey.currentState?.validate() ?? false)) return;
                            setState(() => _currentStep = 1);
                          } else if (_currentStep == 1) {
                            if (!(_claimantFormKey.currentState?.validate() ?? false)) return;
                            setState(() => _currentStep = 2);
                          } else if (_currentStep == 2) {
                            if (!(_documentsFormKey.currentState?.validate() ?? true)) return;
                            setState(() => _currentStep = 3);
                          } else {
                            await _submit();
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isLast ? 'Update Executor' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : () => setState(() => _currentStep = _currentStep - 1),
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: <Step>[
            Step(
              title: const Text('Deceased Information'),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: Form(
                key: _deceasedFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _deceasedNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Deceased Name *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedNricCtrl,
                      decoration: InputDecoration(
                        labelText: 'Deceased IC/NRIC Number',                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedDobCtrl,
                      decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)',                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _deceasedDobCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedDodCtrl,
                      decoration: InputDecoration(labelText: 'Date of Death (YYYY-MM-DD) *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final DateTime? date = DateTime.tryParse(v);
                        if (date == null) return 'Please enter a valid date';
                        return null;
                      },
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _deceasedDodCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _relationshipCtrl,
                      decoration: InputDecoration(
                        labelText: 'Your Relationship to Deceased *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Your Information'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(
                key: _claimantFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _claimantNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Your Full Name *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantNricCtrl,
                      decoration: InputDecoration(
                        labelText: 'Your IC/NRIC Number',                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantDobCtrl,
                      decoration: InputDecoration(labelText: 'Your Date of Birth (YYYY-MM-DD)',                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _claimantDobCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',                      ),
                      validator: (String? v) {
                        final String value = (v ?? '').trim();
                        if (value.isEmpty) return null; // optional
                        final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
                        if (!re.hasMatch(value)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantAddress1Ctrl,
                      decoration: InputDecoration(
                        labelText: 'Address Line 1 *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantAddress2Ctrl,
                      decoration: InputDecoration(
                        labelText: 'Address Line 2',                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _claimantCityCtrl,
                            decoration: InputDecoration(
                              labelText: 'City *',                            ),
                            validator: (String? v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _claimantPostcodeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Postcode *',                            ),
                            validator: (String? v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantStateCtrl,
                      decoration: InputDecoration(
                        labelText: 'State *',                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Supporting Documents'),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
              content: Form(
                key: _documentsFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _supportingDocsCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Supporting Documents (List the documents you have)',                        hintText: 'e.g., Death certificate, Will, Identity documents, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _additionalNotesCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',                        hintText: 'Any additional information that might help with your claim...',                      ),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Review & Update'),
              state: StepState.indexed,
              isActive: _currentStep >= 3,
              content: _buildReview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final TextStyle? label = Theme.of(context).textTheme.bodySmall;
    final TextStyle? value = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    Widget row(String k, String? v) {
      if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 140, child: Text(k, style: label)),
            const SizedBox(width: 8),
            Expanded(child: Text(v, style: value)),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Deceased Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            row('Name', _deceasedNameCtrl.text),
            row('IC/NRIC', _deceasedNricCtrl.text),
            row('Date of Birth', _deceasedDobCtrl.text),
            row('Date of Death', _deceasedDodCtrl.text),
            row('Relationship', _relationshipCtrl.text),
            const SizedBox(height: 16),
            Text('Your Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            row('Name', _claimantNameCtrl.text),
            row('IC/NRIC', _claimantNricCtrl.text),
            row('Date of Birth', _claimantDobCtrl.text),
            row('Phone', _claimantPhoneCtrl.text),
            row('Email', _claimantEmailCtrl.text),
            row('Address 1', _claimantAddress1Ctrl.text),
            row('Address 2', _claimantAddress2Ctrl.text),
            row('City', _claimantCityCtrl.text),
            row('Postcode', _claimantPostcodeCtrl.text),
            row('State', _claimantStateCtrl.text),
            const SizedBox(height: 16),
            Text('Supporting Documents', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            row('Documents', _supportingDocsCtrl.text),
            row('Notes', _additionalNotesCtrl.text),
          ],
        ),
      ),
    );
  }
}

