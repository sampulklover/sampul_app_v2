import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../services/image_upload_service.dart';
import '../services/will_service.dart';
import '../models/relationship.dart';
import '../l10n/app_localizations.dart';
import '../utils/form_decoration_helper.dart';
import 'dart:io';

class EditFamilyMemberScreen extends StatefulWidget {
  final int belovedId;
  const EditFamilyMemberScreen({super.key, required this.belovedId});

  @override
  State<EditFamilyMemberScreen> createState() => _EditFamilyMemberScreenState();
}

class _EditFamilyMemberScreenState extends State<EditFamilyMemberScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nricController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();

  static const List<String> _typeOptions = <String>['co_sampul', 'future_owner', 'guardian'];
  // Use the new relationship model with waris/non-waris classification
  static const List<String> _countryOptions = <String>['malaysia','singapore','brunei','indonesia'];

  String? _relationship;
  String _type = 'co_sampul';
  String? _country;
  String? _imagePath;
  File? _newImageFile;
  bool _isInWill = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('name,email,phone_no,relationship,type,nric_no,address_1,address_2,city,postcode,state,country,percentage,image_path')
          .eq('id', widget.belovedId)
          .limit(1);
      if (!mounted) return;
      final Map<String, dynamic> b = rows.first as Map<String, dynamic>;
      _nameController.text = (b['name'] as String?) ?? '';
      _emailController.text = (b['email'] as String?) ?? '';
      _phoneController.text = (b['phone_no'] as String?) ?? '';
      _relationship = b['relationship'] as String?;
      _type = (b['type'] as String?) ?? 'co_sampul';
      _nricController.text = (b['nric_no'] as String?) ?? '';
      _address1Controller.text = (b['address_1'] as String?) ?? '';
      _address2Controller.text = (b['address_2'] as String?) ?? '';
      _cityController.text = (b['city'] as String?) ?? '';
      _postcodeController.text = (b['postcode'] as String?) ?? '';
      _stateController.text = (b['state'] as String?) ?? '';
      _country = b['country'] as String?;
      _percentageController.text = ((b['percentage'] as num?)?.toString() ?? '');
      _imagePath = b['image_path'] as String?;
      
      // Check if this family member is included in the user's will
      await _checkIfInWill();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfInWill() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user != null) {
        final will = await WillService.instance.getUserWill(user.id);
        if (will != null) {
          _isInWill = will.coSampul1 == widget.belovedId || 
                     will.coSampul2 == widget.belovedId ||
                     will.guardian1 == widget.belovedId ||
                     will.guardian2 == widget.belovedId;
        }
      }
    } catch (e) {
      // If there's an error checking the will, assume not in will
      _isInWill = false;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final Map<String, dynamic> payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_no': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'relationship': _relationship,
        'type': _type,
        'nric_no': _nricController.text.trim().isEmpty ? null : _nricController.text.trim(),
        'address_1': _address1Controller.text.trim().isEmpty ? null : _address1Controller.text.trim(),
        'address_2': _address2Controller.text.trim().isEmpty ? null : _address2Controller.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'postcode': _postcodeController.text.trim().isEmpty ? null : _postcodeController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'country': _country,
      };
      final l10n = AppLocalizations.of(context)!;
      if (_type == 'future_owner') {
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
      } else {
        payload['percentage'] = null;
      }

      // Upload new image if chosen
      if (_newImageFile != null) {
        final String path = await ImageUploadService().uploadBelovedImage(
          imageFile: _newImageFile!,
          userId: user.id,
          belovedId: widget.belovedId,
          existingPath: _imagePath,
        );
        _imagePath = path;
        payload['image_path'] = path;
      }

      await SupabaseService.instance.client
          .from('beloved')
          .update(payload)
          .eq('id', widget.belovedId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToSaveFamilyMember(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editFamilyMember),
        actions: <Widget>[
          IconButton(
            onPressed: _isSaving ? null : _confirmAndDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Center(
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: _newImageFile != null
                                ? FileImage(_newImageFile!)
                                : ((_imagePath ?? '').isNotEmpty
                                    ? NetworkImage(SupabaseService.instance.getFullImageUrl(_imagePath!) ?? '')
                                    : null) as ImageProvider<Object>?,
                            child: (_newImageFile == null && ((_imagePath ?? '').isEmpty))
                                ? const Icon(Icons.person, size: 36)
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
                                  setState(() => _newImageFile = file);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                final AppLocalizations loc = AppLocalizations.of(context)!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.imageSelectionFailed(e.toString()))),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_outlined),
                            label: Text(l10n.changePhoto),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Will Sync Notice
                    if (_isInWill)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sync_alt,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.changesHereUpdateWillAutomatically,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.basicInfoSection, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
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
                              decoration: FormDecorationHelper.roundedInputDecoration(
                                context: context,
                                labelText: l10n.email,
                                prefixIcon: Icons.mail_outline,
                              ),
                              validator: (String? v) {
                                final String value = (v ?? '').trim();
                                if (value.isEmpty) return l10n.emailRequired;
                                final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
                                if (!re.hasMatch(value)) return l10n.pleaseEnterValidEmailAddress;
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _relationship,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_outlined),
                              menuMaxHeight: 300, // Limit dropdown height
                              items: Relationship.allRelationships
                                  .map((Relationship r) => DropdownMenuItem<String>(
                                        value: r.value,
                                        child: _buildRelationshipItem(r, l10n),
                                      ))
                                  .toList(),
                              onChanged: (String? v) => setState(() => _relationship = v),
                              decoration: FormDecorationHelper.roundedInputDecoration(
                                context: context,
                                labelText: l10n.relationship,
                                prefixIcon: Icons.diversity_3_outlined,
                              ),
                              validator: (String? v) => ((v ?? '').isEmpty) ? l10n.relationshipRequired : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _type,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_outlined),
                              items: _typeOptions
                                  .map((String t) => DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(t == 'future_owner' ? l10n.beneficiary : (t == 'co_sampul' ? l10n.coSampulExecutor : l10n.guardian)),
                                      ))
                                  .toList(),
                              onChanged: (String? v) {
                                setState(() {
                                  _type = v ?? 'co_sampul';
                                  if (_type != 'future_owner') {
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
                            const SizedBox(height: 12),
                            if (_type == 'future_owner')
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

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.contactIdSection, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nricController,
                              decoration: FormDecorationHelper.roundedInputDecoration(
                                context: context,
                                labelText: l10n.icNricNumber,
                                prefixIcon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: FormDecorationHelper.roundedInputDecoration(
                                context: context,
                                labelText: l10n.phone,
                                prefixIcon: Icons.phone_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l10n.addressSection, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _address1Controller,
                              decoration: FormDecorationHelper.roundedInputDecoration(
                                context: context,
                                labelText: l10n.addressLine1,
                                prefixIcon: Icons.home_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _address2Controller,
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
                                    initialValue: _country,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                                    items: _countryOptions
                                        .map((String c) => DropdownMenuItem<String>(value: c, child: Text(c[0].toUpperCase()+c.substring(1))))
                                        .toList(),
                                    onChanged: (String? v) => setState(() => _country = v),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRelationshipItem(Relationship relationship, AppLocalizations l10n) {
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

  Future<void> _confirmAndDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.deleteFamilyMember),
          content: Text(l10n.areYouSureDeleteFamilyMember),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
          ],
        );
      },
    );
    if (ok != true) return;

    setState(() => _isSaving = true);
    try {
      if ((_imagePath ?? '').isNotEmpty) {
        try {
          await ImageUploadService().deleteImage(_imagePath!);
        } catch (_) {}
      }
      await SupabaseService.instance.client.from('beloved').delete().eq('id', widget.belovedId);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.familyMemberDeleted), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToDeleteFamilyMember(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}


