import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../services/image_upload_service.dart';
import '../services/will_service.dart';
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
  static const List<String> _relationshipOptions = <String>['friend','partner','sibling','parent','child','colleague','acquaintance','spouse','relative','others'];
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
      if (_type == 'future_owner') {
        final String p = _percentageController.text.trim();
        if (p.isEmpty) {
          throw Exception('Please provide percentage for beneficiary');
        }
        final double parsed = double.tryParse(p) ?? -1;
        if (parsed < 0 || parsed > 100) {
          throw Exception('Percentage must be between 0 and 100');
        }
        payload['percentage'] = parsed;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Family Member'),
        actions: <Widget>[
          IconButton(
            onPressed: _isSaving ? null : _confirmAndDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
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
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid image. Use JPG/PNG/WebP under 5MB.')),
                                    );
                                    return;
                                  }
                                  setState(() => _newImageFile = file);
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Image selection failed: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_outlined),
                            label: const Text('Change photo'),
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
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                                'Changes here update your will automatically.',
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
                            Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
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
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? v) {
                                final String value = (v ?? '').trim();
                                if (value.isEmpty) return 'Email is required';
                                final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
                                if (!re.hasMatch(value)) return 'Please enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _relationship,
                              isExpanded: true,
                              items: _relationshipOptions
                                  .map((String r) => DropdownMenuItem<String>(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (String? v) => setState(() => _relationship = v),
                              decoration: const InputDecoration(
                                labelText: 'Relationship',
                                prefixIcon: Icon(Icons.diversity_3_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? v) => ((v ?? '').isEmpty) ? 'Relationship is required' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _type,
                              items: _typeOptions
                                  .map((String t) => DropdownMenuItem<String>(value: t, child: Text(t == 'future_owner' ? 'Beneficiary' : (t == 'co_sampul' ? 'Co-sampul (Executor)' : 'Guardian'))))
                                  .toList(),
                              onChanged: (String? v) => setState(() => _type = v ?? 'co_sampul'),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_type == 'future_owner')
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

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Contact & ID', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nricController,
                              decoration: const InputDecoration(
                                labelText: 'IC/NRIC Number',
                                prefixIcon: Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
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
                            Text('Address', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _address1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Address Line 1',
                                prefixIcon: Icon(Icons.home_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _address2Controller,
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
                                    initialValue: _country,
                                    isExpanded: true,
                                    items: _countryOptions
                                        .map((String c) => DropdownMenuItem<String>(value: c, child: Text(c[0].toUpperCase()+c.substring(1))))
                                        .toList(),
                                    onChanged: (String? v) => setState(() => _country = v),
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
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Family Member'),
          content: const Text('Are you sure you want to delete this family member? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member deleted'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}


