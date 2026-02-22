import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trust_beneficiary.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../config/trust_constants.dart';

class TrustBeneficiaryFormScreen extends StatefulWidget {
  final TrustBeneficiary? beneficiary;
  final int? index;

  const TrustBeneficiaryFormScreen({
    super.key,
    this.beneficiary,
    this.index,
  });

  @override
  State<TrustBeneficiaryFormScreen> createState() => _TrustBeneficiaryFormScreenState();
}

class _TrustBeneficiaryFormScreenState extends State<TrustBeneficiaryFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _nricCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _address1Ctrl;
  late TextEditingController _address2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postcodeCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _monthlyLivingCtrl;
  late TextEditingController _monthlyEducationCtrl;
  
  String? _selectedGender;
  String? _selectedResidentStatus;
  String? _selectedNationality;
  String? _selectedCountry;
  String? _selectedRelationship;
  DateTime? _dateOfBirth;
  
  bool _medicalExpenses = false;
  bool _educationExpenses = false;
  bool _settleOutstanding = false;
  bool _investMarket = false;
  bool _investUnit = false;
  bool _mentallyIncapacitated = false;
  
  List<Map<String, dynamic>> _familyMembers = [];
  int? _selectedFamilyMemberId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchFamilyMembers();
  }

  void _initializeControllers() {
    final beneficiary = widget.beneficiary;
    _nameCtrl = TextEditingController(text: beneficiary?.name);
    _nricCtrl = TextEditingController(text: beneficiary?.nricPassportNumber);
    _phoneCtrl = TextEditingController(text: beneficiary?.phoneNo);
    _emailCtrl = TextEditingController(text: beneficiary?.email);
    _address1Ctrl = TextEditingController(text: beneficiary?.addressLine1);
    _address2Ctrl = TextEditingController(text: beneficiary?.addressLine2);
    _cityCtrl = TextEditingController(text: beneficiary?.city);
    _postcodeCtrl = TextEditingController(text: beneficiary?.postcode);
    _stateCtrl = TextEditingController(text: beneficiary?.stateProvince);
    _monthlyLivingCtrl = TextEditingController(
      text: beneficiary?.monthlyDistributionLiving?.toString() ?? '',
    );
    _monthlyEducationCtrl = TextEditingController(
      text: beneficiary?.monthlyDistributionEducation?.toString() ?? '',
    );
    
    _selectedGender = beneficiary?.gender;
    _selectedResidentStatus = beneficiary?.residentStatus;
    _selectedNationality = beneficiary?.nationality;
    _selectedCountry = beneficiary?.country;
    _selectedRelationship = beneficiary?.relationship;
    _dateOfBirth = beneficiary?.dateOfBirth;
    
    _medicalExpenses = beneficiary?.medicalExpenses ?? false;
    _educationExpenses = beneficiary?.educationExpenses ?? false;
    _settleOutstanding = beneficiary?.settleOutstanding ?? false;
    _investMarket = beneficiary?.investMarket ?? false;
    _investUnit = beneficiary?.investUnit ?? false;
    _mentallyIncapacitated = beneficiary?.mentallyIncapacitated ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nricCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _stateCtrl.dispose();
    _monthlyLivingCtrl.dispose();
    _monthlyEducationCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        return;
      }
      
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

  void _onFamilyMemberSelected(int? memberId) {
    setState(() {
      _selectedFamilyMemberId = memberId;
      if (memberId != null && memberId != -1) {
        // Find the selected member
        final member = _familyMembers.firstWhere(
          (m) => (m['id'] as num).toInt() == memberId,
        );
        // Auto-fill form with family member data
        _nameCtrl.text = member['name'] ?? '';
        _nricCtrl.text = member['nric_no'] ?? '';
        _phoneCtrl.text = member['phone_no'] ?? '';
        _emailCtrl.text = member['email'] ?? '';
        _address1Ctrl.text = member['address_1'] ?? '';
        _address2Ctrl.text = member['address_2'] ?? '';
        _cityCtrl.text = member['city'] ?? '';
        _postcodeCtrl.text = member['postcode'] ?? '';
        _stateCtrl.text = member['state'] ?? '';
        _selectedCountry = member['country'];
        _selectedRelationship = member['relationship'];
      } else if (memberId == -1) {
        // Clear form for manual entry
        _nameCtrl.clear();
        _nricCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
        _address1Ctrl.clear();
        _address2Ctrl.clear();
        _cityCtrl.clear();
        _postcodeCtrl.clear();
        _stateCtrl.clear();
        _selectedCountry = null;
        _selectedRelationship = null;
      }
    });
  }

  void _saveBeneficiary() {
    if (_formKey.currentState?.validate() ?? false) {
      final newBeneficiary = TrustBeneficiary(
        id: widget.beneficiary?.id,
        name: _nameCtrl.text.trim(),
        nricPassportNumber: _nricCtrl.text.trim().isEmpty ? null : _nricCtrl.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _selectedGender,
        residentStatus: _selectedResidentStatus,
        nationality: _selectedNationality,
        phoneNo: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        addressLine1: _address1Ctrl.text.trim().isEmpty ? null : _address1Ctrl.text.trim(),
        addressLine2: _address2Ctrl.text.trim().isEmpty ? null : _address2Ctrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        postcode: _postcodeCtrl.text.trim().isEmpty ? null : _postcodeCtrl.text.trim(),
        stateProvince: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        country: _selectedCountry,
        relationship: _selectedRelationship,
        monthlyDistributionLiving: _monthlyLivingCtrl.text.trim().isEmpty 
            ? null 
            : int.tryParse(_monthlyLivingCtrl.text.trim()),
        monthlyDistributionEducation: _monthlyEducationCtrl.text.trim().isEmpty 
            ? null 
            : int.tryParse(_monthlyEducationCtrl.text.trim()),
        medicalExpenses: _medicalExpenses,
        educationExpenses: _educationExpenses,
        settleOutstanding: _settleOutstanding,
        investMarket: _investMarket,
        investUnit: _investUnit,
        mentallyIncapacitated: _mentallyIncapacitated,
      );

      Navigator.pop(context, newBeneficiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.beneficiary == null ? 'Add Beneficiary' : 'Edit Beneficiary'),
        actions: [
          TextButton(
            onPressed: _saveBeneficiary,
            child: Text(
              widget.beneficiary == null ? 'ADD' : 'UPDATE',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Family Member Selection
            if (_familyMembers.isNotEmpty && widget.beneficiary == null) ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.family_restroom,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Add from Family',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a family member to auto-fill their information',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedFamilyMemberId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: InputDecoration(
                          labelText: 'Select Family Member',                        ),
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
                        onChanged: _onFamilyMemberSelected,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Personal Information Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nricCtrl,
                      decoration: InputDecoration(
                        labelText: 'NRIC/Passport Number',                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRelationship,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      decoration: InputDecoration(
                        labelText: 'Relationship *',                      ),
                      items: TrustConstants.relationships
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['name']!),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRelationship = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Financial Distribution Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Financial Distribution',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyLivingCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Living (RM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyEducationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Education (RM)',
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
            
            const SizedBox(height: 16),
            
            // Trust Provisions - Expandable
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                leading: const Icon(Icons.checklist),
                title: Text(
                  'Trust Provisions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Select applicable provisions for this beneficiary'),
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mentally Incapacitated Provision
                          CheckboxListTile(
              value: _mentallyIncapacitated,
              onChanged: (v) => setState(() => _mentallyIncapacitated = v ?? false),
              title: const Text(
                'Mental Incapacity Support',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'In the event beneficiary becomes mentally incapacitated to make decisions or is unable to provide any written instructions or is unable to be contacted for 30 days, the Trustee shall utilize the Trust Fund for maintenance, medical/hospitalization, caretaker\'s allowances, household expenses and other personal needs upon submission of relevant supporting documents.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                          const Divider(),
                          
                          // Settle Outstanding Debts
                          CheckboxListTile(
              value: _settleOutstanding,
              onChanged: (v) => setState(() => _settleOutstanding = v ?? false),
              title: const Text(
                'Settle Outstanding Debts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'The Trustee shall settle all outstanding debts/liabilities, legal fees, executor fees and other administration expenses incurred for the Estate before and after extraction of Grant of Probate.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                          const Divider(),
                          
                          // Medical Expenses
                          CheckboxListTile(
              value: _medicalExpenses,
              onChanged: (v) => setState(() => _medicalExpenses = v ?? false),
              title: const Text(
                'Medical Expenses Coverage',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'The Trustee may use the trust fund for medical expenses if there is no insurance coverage or the coverage limit has been exhausted. The fund may also be used to pay for a medical policy.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                          const Divider(),
                          
                          // Education Expenses
                          CheckboxListTile(
              value: _educationExpenses,
              onChanged: (v) => setState(() => _educationExpenses = v ?? false),
              title: const Text(
                'Education Expenses',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'The Trustee may use the trust fund for education expenses upon submission of supporting documents. A monthly allowance may also be provided for living expenses during local or overseas studies.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                          const Divider(),
                          
                          // Money Market Investment
                          CheckboxListTile(
              value: _investMarket,
              onChanged: (v) => setState(() => _investMarket = v ?? false),
              title: const Text(
                'Money Market Investment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Trust Fund to be invested in money market instruments with any licensed financial institution in Malaysia.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                          const Divider(),
                          
                          // Unit Trust Investment
                          CheckboxListTile(
              value: _investUnit,
              onChanged: (v) => setState(() => _investUnit = v ?? false),
              title: const Text(
                'Unit Trust/Mutual Fund Investment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Trust Fund to be invested in Unit Trust/Mutual Fund investment with any licensed fund management company in Malaysia based on recommendation from the Management Committee.',
                style: TextStyle(fontSize: 12),
              ),
                            contentPadding: EdgeInsets.zero,
                            isThreeLine: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Optional Contact & Address (Expandable)
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline),
                title: Text(
                  'Additional Information (Optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Details',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dateOfBirth ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _dateOfBirth = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',                              ),
                              child: Text(
                                _dateOfBirth != null
                                    ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(
                              labelText: 'Gender',                            ),
                            items: TrustConstants.genders
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedGender = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedResidentStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(
                              labelText: 'Resident Status',                            ),
                            items: TrustConstants.residentStatus
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedResidentStatus = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedNationality,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(
                              labelText: 'Nationality',                            ),
                            items: TrustConstants.countries
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedNationality = v),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Email',                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Address',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address1Ctrl,
                            decoration: InputDecoration(
                              labelText: 'Address Line 1',                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address2Ctrl,
                            decoration: InputDecoration(
                              labelText: 'Address Line 2',                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'City',                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _postcodeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Postcode',                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stateCtrl,
                            decoration: InputDecoration(
                              labelText: 'State',                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(
                              labelText: 'Country',                            ),
                            items: TrustConstants.countries
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCountry = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

