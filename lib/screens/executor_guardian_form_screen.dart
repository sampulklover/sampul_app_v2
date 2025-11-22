import 'package:flutter/material.dart';
import '../config/executor_constants.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';

class ExecutorGuardianFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ExecutorGuardianFormScreen({
    super.key,
    this.initialData,
  });

  @override
  State<ExecutorGuardianFormScreen> createState() => _ExecutorGuardianFormScreenState();
}

class _ExecutorGuardianFormScreenState extends State<ExecutorGuardianFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _familyMembers = [];
  int? _selectedGuardianFamilyMemberId;
  final TextEditingController _guardianFullNameCtrl = TextEditingController();
  final TextEditingController _guardianNricNewCtrl = TextEditingController();
  final TextEditingController _guardianNricOldCtrl = TextEditingController();
  final TextEditingController _guardianPoliceArmyNricCtrl = TextEditingController();
  final TextEditingController _guardianDateOfBirthCtrl = TextEditingController();
  final TextEditingController _guardianAgeCtrl = TextEditingController();
  final TextEditingController _guardianAddress1Ctrl = TextEditingController();
  final TextEditingController _guardianAddress2Ctrl = TextEditingController();
  final TextEditingController _guardianCityCtrl = TextEditingController();
  final TextEditingController _guardianPostcodeCtrl = TextEditingController();
  final TextEditingController _guardianStateCtrl = TextEditingController();
  String? _selectedGuardianCountry;
  final TextEditingController _guardianPhoneCtrl = TextEditingController();
  final TextEditingController _guardianHomePhoneCtrl = TextEditingController();
  final TextEditingController _guardianOfficePhoneCtrl = TextEditingController();
  final TextEditingController _guardianEmailCtrl = TextEditingController();
  String? _selectedGuardianRelationship;

  @override
  void initState() {
    super.initState();
    _fetchFamilyMembers();
    _initializeControllers();
  }

  void _initializeControllers() {
    final data = widget.initialData;
    if (data != null) {
      _guardianFullNameCtrl.text = data['full_name'] ?? '';
      _guardianNricNewCtrl.text = data['nric_new'] ?? '';
      _guardianNricOldCtrl.text = data['nric_old'] ?? '';
      _guardianPoliceArmyNricCtrl.text = data['police_army_nric'] ?? '';
      _guardianDateOfBirthCtrl.text = data['date_of_birth'] ?? '';
      _guardianAgeCtrl.text = data['age']?.toString() ?? '';
      _guardianAddress1Ctrl.text = data['address_line_1'] ?? '';
      _guardianAddress2Ctrl.text = data['address_line_2'] ?? '';
      _guardianCityCtrl.text = data['city'] ?? '';
      _guardianPostcodeCtrl.text = data['postcode'] ?? '';
      _guardianStateCtrl.text = data['state'] ?? '';
      _selectedGuardianCountry = data['country'];
      _guardianPhoneCtrl.text = data['phone_no'] ?? '';
      _guardianHomePhoneCtrl.text = data['home_phone'] ?? '';
      _guardianOfficePhoneCtrl.text = data['office_phone'] ?? '';
      _guardianEmailCtrl.text = data['email'] ?? '';
      _selectedGuardianRelationship = data['relationship'];
    }
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;
      
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id, name, nric_no, phone_no, email, relationship, address_1, address_2, city, postcode, state, country, image_path')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _familyMembers = rows.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // Silently fail - form can still be used manually
    }
  }

  void _onGuardianFamilyMemberSelected(int? memberId) {
    setState(() {
      _selectedGuardianFamilyMemberId = memberId;
      if (memberId != null && memberId != -1) {
        // Find the selected member
        final member = _familyMembers.firstWhere(
          (m) => (m['id'] as num).toInt() == memberId,
        );
        // Auto-fill form with family member data
        _guardianFullNameCtrl.text = member['name'] ?? '';
        _guardianNricNewCtrl.text = member['nric_no'] ?? '';
        _guardianPhoneCtrl.text = member['phone_no'] ?? '';
        _guardianEmailCtrl.text = member['email'] ?? '';
        _guardianAddress1Ctrl.text = member['address_1'] ?? '';
        _guardianAddress2Ctrl.text = member['address_2'] ?? '';
        _guardianCityCtrl.text = member['city'] ?? '';
        _guardianPostcodeCtrl.text = member['postcode'] ?? '';
        _guardianStateCtrl.text = member['state'] ?? '';
        _selectedGuardianCountry = member['country'];
        // Only set relationship if it's a valid executor relationship value
        final memberRelationship = member['relationship'] as String?;
        final validRelationships = ['husband', 'wife', 'father', 'mother', 'child', 'others'];
        _selectedGuardianRelationship = (memberRelationship != null && validRelationships.contains(memberRelationship))
            ? memberRelationship
            : null;
      } else if (memberId == -1) {
        // Clear form for manual entry
        _guardianFullNameCtrl.clear();
        _guardianNricNewCtrl.clear();
        _guardianPhoneCtrl.clear();
        _guardianEmailCtrl.clear();
        _guardianAddress1Ctrl.clear();
        _guardianAddress2Ctrl.clear();
        _guardianCityCtrl.clear();
        _guardianPostcodeCtrl.clear();
        _guardianStateCtrl.clear();
        _selectedGuardianCountry = null;
        _selectedGuardianRelationship = null;
      }
    });
  }

  @override
  void dispose() {
    _guardianFullNameCtrl.dispose();
    _guardianNricNewCtrl.dispose();
    _guardianNricOldCtrl.dispose();
    _guardianPoliceArmyNricCtrl.dispose();
    _guardianDateOfBirthCtrl.dispose();
    _guardianAgeCtrl.dispose();
    _guardianAddress1Ctrl.dispose();
    _guardianAddress2Ctrl.dispose();
    _guardianCityCtrl.dispose();
    _guardianPostcodeCtrl.dispose();
    _guardianStateCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _guardianHomePhoneCtrl.dispose();
    _guardianOfficePhoneCtrl.dispose();
    _guardianEmailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'full_name': _guardianFullNameCtrl.text.trim(),
        'nric_new': _guardianNricNewCtrl.text.trim().isNotEmpty ? _guardianNricNewCtrl.text.trim() : null,
        'nric_old': _guardianNricOldCtrl.text.trim().isNotEmpty ? _guardianNricOldCtrl.text.trim() : null,
        'police_army_nric': _guardianPoliceArmyNricCtrl.text.trim().isNotEmpty ? _guardianPoliceArmyNricCtrl.text.trim() : null,
        'date_of_birth': _guardianDateOfBirthCtrl.text.trim().isNotEmpty ? _guardianDateOfBirthCtrl.text.trim() : null,
        'age': _guardianAgeCtrl.text.trim().isNotEmpty ? int.tryParse(_guardianAgeCtrl.text.trim()) : null,
        'address_line_1': _guardianAddress1Ctrl.text.trim().isNotEmpty ? _guardianAddress1Ctrl.text.trim() : null,
        'address_line_2': _guardianAddress2Ctrl.text.trim().isNotEmpty ? _guardianAddress2Ctrl.text.trim() : null,
        'city': _guardianCityCtrl.text.trim().isNotEmpty ? _guardianCityCtrl.text.trim() : null,
        'postcode': _guardianPostcodeCtrl.text.trim().isNotEmpty ? _guardianPostcodeCtrl.text.trim() : null,
        'state': _guardianStateCtrl.text.trim().isNotEmpty ? _guardianStateCtrl.text.trim() : null,
        'country': _selectedGuardianCountry,
        'phone_no': _guardianPhoneCtrl.text.trim().isNotEmpty ? _guardianPhoneCtrl.text.trim() : null,
        'home_phone': _guardianHomePhoneCtrl.text.trim().isNotEmpty ? _guardianHomePhoneCtrl.text.trim() : null,
        'office_phone': _guardianOfficePhoneCtrl.text.trim().isNotEmpty ? _guardianOfficePhoneCtrl.text.trim() : null,
        'email': _guardianEmailCtrl.text.trim().isNotEmpty ? _guardianEmailCtrl.text.trim() : null,
        'relationship': _selectedGuardianRelationship,
      };
      Navigator.of(context).pop(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Information'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Family Member Selection
                if (_familyMembers.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Select from Family Members',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a family member to auto-fill their information',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedGuardianFamilyMemberId,
                            decoration: const InputDecoration(
                              labelText: 'Select Family Member',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_search),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: -1,
                                child: Text('-- Enter Manually --'),
                              ),
                              ..._familyMembers.map((member) {
                                final memberId = (member['id'] as num).toInt();
                                final memberName = member['name'] ?? 'Unknown';
                                final imagePath = member['image_path'] as String?;
                                final hasImage = imagePath != null && imagePath.isNotEmpty;
                                
                                return DropdownMenuItem<int>(
                                  value: memberId,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasImage)
                                        Container(
                                          width: 32,
                                          height: 32,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                SupabaseService.instance.getFullImageUrl(imagePath) ?? '',
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 32,
                                          height: 32,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[300],
                                          ),
                                          child: const Icon(Icons.person, size: 20),
                                        ),
                                      Flexible(
                                        child: Text(
                                          memberName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: _onGuardianFamilyMemberSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _guardianFullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianNricNewCtrl,
                        decoration: const InputDecoration(
                          labelText: 'NRIC (New)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianNricOldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'NRIC (Old)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianPoliceArmyNricCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Police/Army NRIC',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianDateOfBirthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _guardianDateOfBirthCtrl.text = date.toIso8601String().split('T').first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianAgeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGuardianRelationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship with Deceased',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: ExecutorConstants.executorRelationships
                      .map((r) => DropdownMenuItem<String>(
                            value: r['value'],
                            child: Text(r['name']!),
                          ))
                      .toList(),
                  onChanged: (v) {
                    // Ensure only valid values are set
                    final validValues = ['husband', 'wife', 'father', 'mother', 'child', 'others'];
                    if (v != null && validValues.contains(v)) {
                      setState(() => _selectedGuardianRelationship = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianAddress1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianAddress2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _guardianCityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianPostcodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Postcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianStateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGuardianCountry,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                        items: ExecutorConstants.countries
                            .map((c) => DropdownMenuItem<String>(
                                  value: c['value'],
                                  child: Text(c['name']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGuardianCountry = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianHomePhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Home Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianOfficePhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Office Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
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

