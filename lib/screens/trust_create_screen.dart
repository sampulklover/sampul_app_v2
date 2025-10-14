import 'package:flutter/material.dart';
import '../services/trust_service.dart';
import '../models/trust.dart';

class TrustCreateScreen extends StatefulWidget {
  const TrustCreateScreen({super.key});

  @override
  State<TrustCreateScreen> createState() => _TrustCreateScreenState();
}

class _TrustCreateScreenState extends State<TrustCreateScreen> {
  final GlobalKey<FormState> _basicFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _contactFormKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _nricCtrl = TextEditingController();
  final TextEditingController _address1Ctrl = TextEditingController();
  final TextEditingController _address2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _postcodeCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nricCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_basicFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      return;
    }
    if (!(_contactFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 1);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await TrustService.instance.createTrust(Trust(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phoneNo: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        nricNumber: _nricCtrl.text.trim().isEmpty ? null : _nricCtrl.text.trim(),
        addressLine1: _address1Ctrl.text.trim().isEmpty ? null : _address1Ctrl.text.trim(),
        addressLine2: _address2Ctrl.text.trim().isEmpty ? null : _address2Ctrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        postcode: _postcodeCtrl.text.trim().isEmpty ? null : _postcodeCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust created'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trust')),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final bool isLast = _currentStep == 2;
            return Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_currentStep == 0) {
                            if (!(_basicFormKey.currentState?.validate() ?? false)) return;
                            setState(() => _currentStep = 1);
                          } else if (_currentStep == 1) {
                            if (!(_contactFormKey.currentState?.validate() ?? true)) return;
                            setState(() => _currentStep = 2);
                          } else {
                            await _submit();
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isLast ? 'Save' : 'Next'),
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
              title: const Text('Basic Info'),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: Form(
                key: _basicFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Trust Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Contact & Address'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(
                key: _contactFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
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
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nricCtrl,
                      decoration: const InputDecoration(labelText: 'IC/NRIC Number', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address1Ctrl,
                      decoration: const InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address2Ctrl,
                      decoration: const InputDecoration(labelText: 'Address Line 2', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postcodeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Postcode', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Review'),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
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
            SizedBox(width: 120, child: Text(k, style: label)),
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
            row('Trust Name', _nameCtrl.text),
            row('Email', _emailCtrl.text),
            row('Phone', _phoneCtrl.text),
            row('IC/NRIC', _nricCtrl.text),
            row('Address 1', _address1Ctrl.text),
            row('Address 2', _address2Ctrl.text),
            row('City', _cityCtrl.text),
            row('Postcode', _postcodeCtrl.text),
            row('State', _stateCtrl.text),
          ],
        ),
      ),
    );
  }
}


