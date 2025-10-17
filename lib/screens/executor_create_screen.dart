import 'package:flutter/material.dart';
import '../services/executor_service.dart';
import '../models/executor.dart';

class ExecutorCreateScreen extends StatefulWidget {
  const ExecutorCreateScreen({super.key});

  @override
  State<ExecutorCreateScreen> createState() => _ExecutorCreateScreenState();
}

class _ExecutorCreateScreenState extends State<ExecutorCreateScreen> {
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
      await ExecutorService.instance.createExecutor(Executor(
        deceasedName: _deceasedNameCtrl.text.trim(),
        deceasedNricNumber: _deceasedNricCtrl.text.trim().isEmpty ? null : _deceasedNricCtrl.text.trim(),
        deceasedDateOfBirth: _deceasedDobCtrl.text.isNotEmpty ? DateTime.tryParse(_deceasedDobCtrl.text) : null,
        deceasedDateOfDeath: _deceasedDodCtrl.text.isNotEmpty ? DateTime.tryParse(_deceasedDodCtrl.text) : null,
        relationshipToDeceased: _relationshipCtrl.text.trim().isEmpty ? null : _relationshipCtrl.text.trim(),
        claimantName: _claimantNameCtrl.text.trim(),
        claimantNricNumber: _claimantNricCtrl.text.trim().isEmpty ? null : _claimantNricCtrl.text.trim(),
        claimantDateOfBirth: _claimantDobCtrl.text.isNotEmpty ? DateTime.tryParse(_claimantDobCtrl.text) : null,
        claimantPhoneNo: _claimantPhoneCtrl.text.trim().isEmpty ? null : _claimantPhoneCtrl.text.trim(),
        claimantEmail: _claimantEmailCtrl.text.trim().isEmpty ? null : _claimantEmailCtrl.text.trim(),
        claimantAddressLine1: _claimantAddress1Ctrl.text.trim().isEmpty ? null : _claimantAddress1Ctrl.text.trim(),
        claimantAddressLine2: _claimantAddress2Ctrl.text.trim().isEmpty ? null : _claimantAddress2Ctrl.text.trim(),
        claimantCity: _claimantCityCtrl.text.trim().isEmpty ? null : _claimantCityCtrl.text.trim(),
        claimantPostcode: _claimantPostcodeCtrl.text.trim().isEmpty ? null : _claimantPostcodeCtrl.text.trim(),
        claimantState: _claimantStateCtrl.text.trim().isEmpty ? null : _claimantStateCtrl.text.trim(),
        supportingDocuments: _supportingDocsCtrl.text.trim().isEmpty ? null : _supportingDocsCtrl.text.trim(),
        additionalNotes: _additionalNotesCtrl.text.trim().isEmpty ? null : _additionalNotesCtrl.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estate claim submitted successfully'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Estate Claim')),
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
                      : Text(isLast ? 'Submit Claim' : 'Next'),
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
                      decoration: const InputDecoration(
                        labelText: 'Deceased Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedNricCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Deceased IC/NRIC Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedDobCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Date of Death (YYYY-MM-DD) *',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Your Relationship to Deceased *',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Your Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantNricCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your IC/NRIC Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantDobCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your Date of Birth (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1 *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantAddress2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _claimantCityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Postcode *',
                              border: OutlineInputBorder(),
                            ),
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
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Supporting Documents (List the documents you have)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Death certificate, Will, Identity documents, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _additionalNotesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Any additional information that might help with your claim...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Review & Submit'),
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

