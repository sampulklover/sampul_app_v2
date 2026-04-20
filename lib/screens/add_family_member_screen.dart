import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import '../services/executor_invitation_email_service.dart';
import '../models/relationship.dart';
import '../l10n/app_localizations.dart';
import '../widgets/stepper_footer_controls.dart';
import '../utils/form_decoration_helper.dart';
import 'dart:io';
import 'family_info_screen.dart';
import '../utils/sampul_icons.dart';

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

  // Categories supported: executor (co_sampul), future_owner (beneficiary), guardian
  static const List<String> _typeOptions = <String>['co_sampul', 'future_owner', 'guardian'];
  String _selectedType = 'co_sampul';
  bool _notifyExecutorByEmail = true;
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

  // Use the new relationship model with waris/non-waris classification
  String? _selectedRelationship;
  static const int _minimumAdultAge = 18;

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
    if (!_validateAdultByNricForExecutorGuardian()) {
      setState(() => _currentStep = 1);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.youMustBeSignedIn);
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
        final l10n = AppLocalizations.of(context)!;
        final String p = _percentageController.text.trim();
        if (p.isEmpty) {
          payload['percentage'] = 0.0;
        } else {
          final double parsed = double.tryParse(p) ?? -1;
          if (parsed < 0 || parsed > 100) {
            throw Exception(l10n.percentageMustBeBetween0And100);
          }
          payload['percentage'] = parsed;
        }
      }

      if (_selectedType == 'co_sampul') {
        final bool canAddExecutor = await _canAddMoreExecutors(user.id);
        if (!canAddExecutor) {
          throw Exception('You can only register up to 2 executors.');
        }
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

      if (_selectedType == 'co_sampul' && _notifyExecutorByEmail) {
        final String recipientEmail = _emailController.text.trim();
        final String executorCode = 'CO-SAMPUL-$belovedId';
        // Best effort: family member save should still succeed even if email fails.
        await ExecutorInvitationEmailService.instance.sendInvitationForBeloved(
          belovedId: belovedId,
          recipientEmail: recipientEmail,
          executorCode: executorCode,
        );
      }

      if (!mounted) return;
      final AppLocalizations addedL10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addedL10n.familyMemberAdded), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToAdd(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addFamilyMemberTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.aboutFamilyMembers,
            icon: SampulIcons.buildIconButtonIcon(SampulIcons.help, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FamilyInfoScreen(fromHelpIcon: true)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            // Use standardized fixed-footer controls instead.
            return const SizedBox.shrink();
          },
          steps: <Step>[
            Step(
              title: Text(l10n.basicInfo),
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
                                ? SampulIcons.buildIcon(SampulIcons.person, width: 36, height: 36)
                                : null,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final File? file = await ImageUploadService().pickImage();
                                if (file != null) {
                                  if (!ImageUploadService().validateImage(file)) {
                                    if (!context.mounted) return;
                                    final AppLocalizations loc = AppLocalizations.of(context)!;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(loc.invalidImageUseJpgPngWebp)),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedImageFile = file;
                                  });
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                final AppLocalizations loc = AppLocalizations.of(context)!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.imageSelectionFailed(e.toString()))),
                                );
                              }
                            },
                            icon: SampulIcons.buildIcon(SampulIcons.photo, width: 20, height: 20),
                            label: Text(l10n.addPhoto),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.fullName,
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return l10n.nameRequired;
                        if (v.trim().length < 2) return l10n.pleaseEnterValidName;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.email,
                        prefixIcon: Icons.mail_outline,
                      ),
                      validator: (String? v) {
                        final String value = (v ?? '').trim();
                        if (value.isEmpty) return l10n.emailRequired;
                        if (!_isValidEmail(value)) return l10n.pleaseEnterValidEmailAddress;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRelationship,
                      isExpanded: true,
                      icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
                      menuMaxHeight: 300, // Limit dropdown height
                      items: Relationship.allRelationships
                          .map((Relationship r) => DropdownMenuItem<String>(
                                value: r.value,
                                child: _buildRelationshipItem(r),
                              ))
                          .toList(),
                      onChanged: (String? v) => setState(() => _selectedRelationship = v),
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.relationship,
                        prefixIcon: Icons.diversity_3_outlined,
                      ),
                      validator: (String? v) {
                        if ((v ?? '').isEmpty) return l10n.relationshipRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      isExpanded: true,
                      icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
                      items: _typeOptions
                          .map((String t) => DropdownMenuItem<String>(value: t, child: Text(_prettyType(t, l10n))))
                          .toList(),
                      onChanged: (String? v) {
                        setState(() {
                          _selectedType = v ?? 'co_sampul';
                          if (_selectedType != 'future_owner') {
                            _percentageController.clear();
                          }
                        });
                      },
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.category,
                        prefixIcon: Icons.category_outlined,
                      ),
                    ),
                    if (_selectedType != 'future_owner') ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SampulIcons.buildIcon(SampulIcons.info, width: 16, height: 16, color: const Color.fromRGBO(83, 61, 233, 1)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _typeHelpText(_selectedType, l10n),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_selectedType == 'co_sampul') ...<Widget>[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _notifyExecutorByEmail,
                        dense: true,
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Notify executor by email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            _notifyExecutorByEmail = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_selectedType == 'future_owner')
                      TextFormField(
                        controller: _percentageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: l10n.beneficiaryShareFieldLabel,
                          prefixIcon: Icons.percent,
                          helperText: l10n.beneficiaryShareHelperDefault,
                          helperMaxLines: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Step(
              title: Text(l10n.otherInfoOptional),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(
                key: _contactFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nricController,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.icNricNumber,
                        prefixIcon: Icons.badge_outlined,
                        errorMaxLines: 3,
                      ),
                      validator: (String? v) {
                        if (!(_selectedType == 'co_sampul' || _selectedType == 'guardian')) {
                          return null;
                        }
                        final String normalized = _normalizeNric(v ?? '');
                        if (normalized.isEmpty) {
                          return 'IC diperlukan untuk executor atau guardian.';
                        }
                        if (!_isValidNricDate(normalized)) {
                          return 'Sila masukkan IC yang sah.';
                        }
                        final int? age = _extractAgeFromNric(normalized);
                        if (age == null) {
                          return 'Sila masukkan IC yang sah.';
                        }
                        if (age < _minimumAdultAge) {
                          return 'Executor dan guardian mesti berumur sekurang-kurangnya 18 tahun.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address1Controller,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.addressLine1,
                        prefixIcon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address2Controller,
                      textInputAction: TextInputAction.next,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.addressLine2,
                        prefixIcon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            textInputAction: TextInputAction.next,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.city,
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postcodeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.postcode,
                              prefixIcon: Icons.local_post_office_outlined,
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
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.state,
                              prefixIcon: Icons.map_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCountry,
                            isExpanded: true,
                            icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
                            items: _countryOptions
                                .map((String c) => DropdownMenuItem<String>(value: c, child: Text(_prettyCountry(c))))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedCountry = v),
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.country,
                              prefixIcon: Icons.public_outlined,
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
              title: Text(l10n.review),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
              content: _buildReview(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StepperFooterControls(
        currentStep: _currentStep,
        lastStep: 2,
        isBusy: _isSubmitting,
        primaryLabel: _currentStep == 2 ? l10n.save : null,
        onPrimaryPressed: () async {
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
        onBackPressed: _currentStep > 0
            ? () {
                setState(() => _currentStep = _currentStep - 1);
              }
            : null,
      ),
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context)!;
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
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Text(
                            l10n.ifPersonPartOfWillSync,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            row(l10n.name, _nameController.text),
            row(l10n.relationship, _prettyRelationship(_selectedRelationship ?? '')),
            row(l10n.category, _prettyType(_selectedType, l10n)),
            if (_selectedType == 'future_owner')
              row(
                l10n.beneficiaryShareFieldLabel,
                _percentageController.text.isEmpty ? '0%' : '${_percentageController.text}%',
              ),
            row(l10n.icNricNumber, _nricController.text),
            row(l10n.email, _emailController.text),
            row(l10n.phone, _phoneController.text),
            row(l10n.addressLine1, _address1Controller.text),
            row(l10n.addressLine2, _address2Controller.text),
            row(l10n.city, _cityController.text),
            row(l10n.postcode, _postcodeController.text),
            row(l10n.state, _stateController.text),
            row(l10n.country, _selectedCountry == null ? null : _prettyCountry(_selectedCountry!)),
          ],
        ),
      ),
    );
  }

  String _prettyType(String t, AppLocalizations l10n) {
    switch (t) {
      case 'co_sampul':
        return l10n.coSampulExecutor;
      case 'future_owner':
        return l10n.beneficiary;
      case 'guardian':
        return l10n.guardian;
      default:
        return t;
    }
  }

  Widget _buildRelationshipItem(Relationship relationship) {
    final l10n = AppLocalizations.of(context)!;
    final bool isLegacy = Relationship.isLegacyRelationship(relationship.value);
    
    return Row(
      children: [
        Expanded(
          child: Text(relationship.displayName),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: relationship.isWaris 
                ? Colors.green.withValues(alpha: 0.1) 
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: relationship.isWaris 
                  ? Colors.green.withValues(alpha: 0.3) 
                  : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            relationship.isWaris ? l10n.waris : l10n.nonWaris,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: relationship.isWaris ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ),
        if (isLegacy) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              l10n.legacy,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _prettyRelationship(String r) {
    final Relationship? relationship = Relationship.getByValue(r);
    return relationship?.displayName ?? r;
  }

  bool _isValidEmail(String value) {
    // Simple, broadly compatible email regex
    final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
    return re.hasMatch(value);
  }

  String _typeHelpText(String t, AppLocalizations l10n) {
    final String label = _prettyType(t, l10n);
    switch (t) {
      case 'co_sampul':
        return l10n.coSampulExecutorHelp;
      case 'future_owner':
        return l10n.beneficiaryHelp;
      case 'guardian':
        return l10n.guardianHelp;
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

  bool _validateAdultByNricForExecutorGuardian() {
    if (!(_selectedType == 'co_sampul' || _selectedType == 'guardian')) {
      return true;
    }
    final String normalized = _normalizeNric(_nricController.text);
    final int? age = _extractAgeFromNric(normalized);
    final bool isValid = normalized.isNotEmpty && _isValidNricDate(normalized) && age != null && age >= _minimumAdultAge;
    if (isValid) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Executor dan guardian mesti berumur sekurang-kurangnya 18 tahun berdasarkan IC.'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  String _normalizeNric(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  bool _isValidNricDate(String normalizedNric) {
    if (normalizedNric.length < 6) return false;
    final int? yy = int.tryParse(normalizedNric.substring(0, 2));
    final int? mm = int.tryParse(normalizedNric.substring(2, 4));
    final int? dd = int.tryParse(normalizedNric.substring(4, 6));
    if (yy == null || mm == null || dd == null) return false;
    if (mm < 1 || mm > 12) return false;
    if (dd < 1 || dd > 31) return false;

    final int currentTwoDigitYear = DateTime.now().year % 100;
    final int year = yy > currentTwoDigitYear ? 1900 + yy : 2000 + yy;
    try {
      final DateTime date = DateTime(year, mm, dd);
      return date.year == year && date.month == mm && date.day == dd && !date.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  int? _extractAgeFromNric(String normalizedNric) {
    if (!_isValidNricDate(normalizedNric)) return null;
    final int yy = int.parse(normalizedNric.substring(0, 2));
    final int mm = int.parse(normalizedNric.substring(2, 4));
    final int dd = int.parse(normalizedNric.substring(4, 6));
    final int currentTwoDigitYear = DateTime.now().year % 100;
    final int year = yy > currentTwoDigitYear ? 1900 + yy : 2000 + yy;
    final DateTime dob = DateTime(year, mm, dd);
    final DateTime now = DateTime.now();
    int age = now.year - dob.year;
    final bool hasBirthdayPassed =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hasBirthdayPassed) age--;
    return age;
  }

  Future<bool> _canAddMoreExecutors(String userId) async {
    final List<dynamic> existingExecutors = await SupabaseService.instance.client
        .from('beloved')
        .select('id')
        .eq('uuid', userId)
        .eq('type', 'co_sampul');
    return existingExecutors.length < 2;
  }
}


