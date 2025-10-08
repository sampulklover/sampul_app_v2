import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import 'dart:io';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final GlobalKey<FormState> _basicFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _contactFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;
  int _currentStep = 0;
  File? _selectedImageFile;

  // Categories supported: co-sampul (co_sampul), future_owner (beneficiary), guardian
  static const List<String> _typeOptions = <String>['co_sampul', 'future_owner', 'guardian'];
  String _selectedType = 'co_sampul';
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _nricController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  // Country enum keys
  static const List<String> _countryOptions = <String>['malaysia', 'singapore', 'brunei', 'indonesia'];
  String? _selectedCountry;

  // Relationship options: friend, partner, sibling, parent, child, colleague, acquaintance, spouse, relative, others
  static const List<String> _relationshipOptions = <String>[
    'friend',
    'partner',
    'sibling',
    'parent',
    'child',
    'colleague',
    'acquaintance',
    'spouse',
    'relative',
    'others',
  ];
  String? _selectedRelationship;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _percentageController.dispose();
    _nricController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate basic info always before submit
    if (!(_basicFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      return;
    }
    // Validate email format if provided on contact step
    if (!(_contactFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 1);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('You must be signed in');
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'uuid': user.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_no': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'relationship': _selectedRelationship,
        'type': _selectedType,
        'nric_no': _nricController.text.trim().isEmpty ? null : _nricController.text.trim(),
        'address_1': _address1Controller.text.trim().isEmpty ? null : _address1Controller.text.trim(),
        'address_2': _address2Controller.text.trim().isEmpty ? null : _address2Controller.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'postcode': _postcodeController.text.trim().isEmpty ? null : _postcodeController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'country': _selectedCountry,
      };

      if (_selectedType == 'future_owner') {
        final String p = _percentageController.text.trim();
        if (p.isEmpty) {
          throw Exception('Please provide percentage for beneficiary');
        }
        final double parsed = double.tryParse(p) ?? -1;
        if (parsed < 0 || parsed > 100) {
          throw Exception('Percentage must be between 0 and 100');
        }
        payload['percentage'] = parsed;
      }

      // Insert record first to get beloved id
      final List<dynamic> insertResp = await SupabaseService.instance.client
          .from('beloved')
          .insert(payload)
          .select('id')
          .limit(1);
      final int belovedId = (insertResp.first['id'] as num).toInt();

      // Upload image after we know belovedId
      if (_selectedImageFile != null) {
        final String path = await ImageUploadService()
            .uploadBelovedImage(imageFile: _selectedImageFile!, userId: user.id, belovedId: belovedId);
        await SupabaseService.instance.client
            .from('beloved')
            .update(<String, dynamic>{'image_path': path})
            .eq('id', belovedId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member added'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
      ),
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
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _currentStep = _currentStep - 1),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Avatar selector
                    Center(
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : null,
                            child: _selectedImageFile == null
                                ? const Icon(Icons.person, size: 36)
                                : null,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final File? file = await ImageUploadService().pickImage();
                                if (file != null) {
                                  if (!ImageUploadService().validateImage(file)) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid image. Use JPG/PNG/WebP under 5MB.')),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedImageFile = file;
                                  });
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Image selection failed: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_outlined),
                            label: const Text('Add photo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        final String value = (v ?? '').trim();
                        if (value.isEmpty) return 'Email is required';
                        if (!_isValidEmail(value)) return 'Please enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRelationship,
                      isExpanded: true,
                      items: _relationshipOptions
                          .map((String r) => DropdownMenuItem<String>(value: r, child: Text(_prettyRelationship(r))))
                          .toList(),
                      onChanged: (String? v) => setState(() => _selectedRelationship = v),
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: Icon(Icons.diversity_3_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) {
                        if ((v ?? '').isEmpty) return 'Relationship is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _typeOptions
                          .map((String t) => DropdownMenuItem<String>(value: t, child: Text(_prettyType(t))))
                          .toList(),
                      onChanged: (String? v) => setState(() => _selectedType = v ?? 'co_sampul'),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _typeHelpText(_selectedType),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedType == 'future_owner')
                      TextFormField(
                        controller: _percentageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Percentage (0 - 100)',
                          prefixIcon: Icon(Icons.percent),
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Other Info (optional)'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(
                key: _contactFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nricController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'IC/NRIC Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address1Controller,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address2Controller,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postcodeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Postcode',
                              prefixIcon: Icon(Icons.local_post_office_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              prefixIcon: Icon(Icons.map_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            isExpanded: true,
                            items: _countryOptions
                                .map((String c) => DropdownMenuItem<String>(value: c, child: Text(_prettyCountry(c))))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedCountry = v),
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              prefixIcon: Icon(Icons.public_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
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
            // Will Sync Notice in Review (conditional by category)
            if (_selectedType == 'co_sampul' || _selectedType == 'future_owner' || _selectedType == 'guardian')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.sync_alt,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If this person is part of your will, any updates you make here will automatically sync to your will.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            row('Name', _nameController.text),
            row('Relationship', _prettyRelationship(_selectedRelationship ?? '')),
            row('Category', _prettyType(_selectedType)),
            if (_selectedType == 'future_owner') row('Percentage', _percentageController.text.isEmpty ? null : '${_percentageController.text}%'),
            row('IC/NRIC', _nricController.text),
            row('Email', _emailController.text),
            row('Phone', _phoneController.text),
            row('Address 1', _address1Controller.text),
            row('Address 2', _address2Controller.text),
            row('City', _cityController.text),
            row('Postcode', _postcodeController.text),
            row('State', _stateController.text),
            row('Country', _selectedCountry == null ? null : _prettyCountry(_selectedCountry!)),
          ],
        ),
      ),
    );
  }

  String _prettyType(String t) {
    switch (t) {
      case 'co_sampul':
        return 'Co-sampul (Executor)';
      case 'future_owner':
        return 'Beneficiary';
      case 'guardian':
        return 'Guardian';
      default:
        return t;
    }
  }

  String _prettyRelationship(String r) {
    switch (r) {
      case 'friend':
        return 'Friend';
      case 'partner':
        return 'Partner';
      case 'sibling':
        return 'Sibling';
      case 'parent':
        return 'Parent';
      case 'child':
        return 'Child';
      case 'colleague':
        return 'Colleague';
      case 'acquaintance':
        return 'Acquaintance';
      case 'spouse':
        return 'Spouse';
      case 'relative':
        return 'Relative';
      case 'others':
        return 'Others';
      default:
        return r;
    }
  }

  bool _isValidEmail(String value) {
    // Simple, broadly compatible email regex
    final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
    return re.hasMatch(value);
  }

  String _typeHelpText(String t) {
    final String label = _prettyType(t);
    switch (t) {
      case 'co_sampul':
        return '$label: A trusted person who executes your will together with you.';
      case 'future_owner':
        return 'Beneficiary: A person who will inherit your selected assets.';
      case 'guardian':
        return '$label: A person responsible for the care of your dependents or minors.';
      default:
        return label;
    }
  }

  String _prettyCountry(String c) {
    switch (c) {
      case 'malaysia':
        return 'Malaysia';
      case 'singapore':
        return 'Singapore';
      case 'brunei':
        return 'Brunei';
      case 'indonesia':
        return 'Indonesia';
      default:
        return c;
    }
  }
}


