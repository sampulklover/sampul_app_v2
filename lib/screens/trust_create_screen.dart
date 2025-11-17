import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../models/trust_charity.dart';
import '../models/user_profile.dart';
import '../services/trust_service.dart';
import '../services/supabase_service.dart';
import '../config/trust_constants.dart';
import 'edit_profile_screen.dart';
import 'trust_beneficiary_form_screen.dart';
import 'trust_charity_form_screen.dart';

class TrustCreateScreen extends StatefulWidget {
  const TrustCreateScreen({super.key});

  @override
  State<TrustCreateScreen> createState() => _TrustCreateScreenState();
}

class _TrustCreateScreenState extends State<TrustCreateScreen> {
  final GlobalKey<FormState> _financialFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _businessFormKey = GlobalKey<FormState>();

  // Beneficiaries
  final List<TrustBeneficiary> _beneficiaries = [];
  
  // Charities/Donations
  final List<TrustCharity> _charities = [];

  // Personal and Contact information now comes from UserProfile

  // Financial Information
  String? _selectedEstimatedNetWorth;
  String? _selectedSourceOfFund;
  final TextEditingController _purposeOfTransactionCtrl = TextEditingController();

  // Business Information
  final TextEditingController _employerNameCtrl = TextEditingController();
  final TextEditingController _businessNatureCtrl = TextEditingController();
  final TextEditingController _businessAddress1Ctrl = TextEditingController();
  final TextEditingController _businessAddress2Ctrl = TextEditingController();
  final TextEditingController _businessCityCtrl = TextEditingController();
  final TextEditingController _businessPostcodeCtrl = TextEditingController();
  final TextEditingController _businessStateCtrl = TextEditingController();
  String? _selectedBusinessCountry;

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  String? _profileError;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _purposeOfTransactionCtrl.dispose();
    _employerNameCtrl.dispose();
    _businessNatureCtrl.dispose();
    _businessAddress1Ctrl.dispose();
    _businessAddress2Ctrl.dispose();
    _businessCityCtrl.dispose();
    _businessPostcodeCtrl.dispose();
    _businessStateCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillFromProfile() async {
    setState(() => _profileError = null);
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _profileError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  String _formatAddress(UserProfile? profile) {
    if (profile == null) return 'Not provided';
    
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBeneficiariesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_beneficiaries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No beneficiaries added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add beneficiaries who will receive benefits from this trust',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._beneficiaries.asMap().entries.map((entry) {
            final index = entry.key;
            final beneficiary = entry.value;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(beneficiary.name ?? 'Unnamed'),
                subtitle: Text(beneficiary.relationship ?? 'No relationship'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editBeneficiary(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteBeneficiary(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addBeneficiary,
            icon: const Icon(Icons.add),
            label: const Text('Add Beneficiary'),
          ),
        ),
      ],
    );
  }

  Widget _buildCharitiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_charities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No charities/donations added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add charitable organizations you would like to donate to (optional)',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._charities.asMap().entries.map((entry) {
            final index = entry.key;
            final charity = entry.value;
            
            // Build subtitle text
            String subtitleText = '';
            if (charity.category != null) {
              final categoryName = TrustConstants.donationCategories
                  .firstWhere((c) => c['value'] == charity.category,
                      orElse: () => {'name': charity.category!})['name']!;
              subtitleText = categoryName;
            }
            if (charity.donationAmount != null) {
              final amountText = 'RM ${charity.donationAmount!.toStringAsFixed(2)}';
              final durationText = charity.donationDuration != null 
                  ? ' (${TrustConstants.donationDurations.firstWhere((d) => d['value'] == charity.donationDuration, orElse: () => {'name': charity.donationDuration!})['name']})'
                  : '';
              if (subtitleText.isNotEmpty) {
                subtitleText += ' • $amountText$durationText';
              } else {
                subtitleText = '$amountText$durationText';
              }
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(charity.organizationName ?? 'Unnamed Organization'),
                subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editCharity(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCharity(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addCharity,
            icon: const Icon(Icons.add),
            label: const Text('Add Charity/Donation'),
          ),
        ),
      ],
    );
  }

  Future<void> _addBeneficiary() async {
    final result = await Navigator.push<TrustBeneficiary>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrustBeneficiaryFormScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _beneficiaries.add(result);
      });
    }
  }

  Future<void> _editBeneficiary(int index) async {
    final result = await Navigator.push<TrustBeneficiary>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustBeneficiaryFormScreen(
          beneficiary: _beneficiaries[index],
          index: index,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _beneficiaries[index] = result;
      });
    }
  }

  void _deleteBeneficiary(int index) {
    setState(() {
      _beneficiaries.removeAt(index);
    });
  }

  Future<void> _addCharity() async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrustCharityFormScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities.add(result);
      });
    }
  }

  Future<void> _editCharity(int index) async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustCharityFormScreen(
          charity: _charities[index],
          index: index,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities[index] = result;
      });
    }
  }

  void _deleteCharity(int index) {
    setState(() {
      _charities.removeAt(index);
    });
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Section
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
                    Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildReviewRow('Full Name', _userProfile?.nricName ?? _userProfile?.username),
                _buildReviewRow('NRIC', _userProfile?.nricNo),
                _buildReviewRow('Phone', _userProfile?.phoneNo),
                _buildReviewRow('Email', _userProfile?.email),
                _buildReviewRow('Address', _formatAddress(_userProfile)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Financial Information Section
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
                    Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Financial Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildReviewRow(
                  'Estimated Net Worth',
                  _selectedEstimatedNetWorth != null
                      ? TrustConstants.estimatedNetWorths
                          .firstWhere((e) => e['value'] == _selectedEstimatedNetWorth,
                              orElse: () => {'name': _selectedEstimatedNetWorth!})['name']
                      : null,
                ),
                _buildReviewRow(
                  'Source of Fund',
                  _selectedSourceOfFund != null
                      ? TrustConstants.sourceOfWealth
                          .firstWhere((e) => e['value'] == _selectedSourceOfFund,
                              orElse: () => {'name': _selectedSourceOfFund!})['name']
                      : null,
                ),
                _buildReviewRow('Purpose of Transaction', _purposeOfTransactionCtrl.text.trim().isEmpty ? null : _purposeOfTransactionCtrl.text.trim()),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Business Information Section
        if (_employerNameCtrl.text.trim().isNotEmpty ||
            _businessNatureCtrl.text.trim().isNotEmpty)
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
                      Icon(Icons.business, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Business Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow('Employer/Company Name', _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim()),
                  _buildReviewRow('Nature of Business', _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim()),
                  _buildReviewRow('Business Address', _formatBusinessAddress()),
                ],
              ),
            ),
          ),
        
        if (_employerNameCtrl.text.trim().isNotEmpty ||
            _businessNatureCtrl.text.trim().isNotEmpty)
          const SizedBox(height: 16),
        
        // Beneficiaries Section
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Beneficiaries (${_beneficiaries.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_beneficiaries.isEmpty)
                  const Text('No beneficiaries added', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ..._beneficiaries.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name ?? 'Unnamed',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (b.relationship != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                TrustConstants.relationships
                                    .firstWhere((r) => r['value'] == b.relationship,
                                        orElse: () => {'name': b.relationship!})['name']!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (b.monthlyDistributionLiving != null || b.monthlyDistributionEducation != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Monthly Distribution: Living RM${b.monthlyDistributionLiving ?? 0} • Education RM${b.monthlyDistributionEducation ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Charities Section
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.volunteer_activism, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Charities/Donations (${_charities.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_charities.isEmpty)
                  const Text('No charities/donations added', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ..._charities.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.organizationName ?? 'Unnamed Organization',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (c.category != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                TrustConstants.donationCategories
                                    .firstWhere((cat) => cat['value'] == c.category,
                                        orElse: () => {'name': c.category!})['name']!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (c.donationAmount != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'RM ${c.donationAmount!.toStringAsFixed(2)} ${c.donationDuration != null ? "• ${TrustConstants.donationDurations.firstWhere((d) => d['value'] == c.donationDuration, orElse: () => {'name': c.donationDuration!})['name']}" : ""}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'Not provided',
              style: TextStyle(
                fontStyle: value?.isEmpty ?? true ? FontStyle.italic : FontStyle.normal,
                color: value?.isEmpty ?? true ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBusinessAddress() {
    final parts = <String>[];
    if (_businessAddress1Ctrl.text.trim().isNotEmpty) parts.add(_businessAddress1Ctrl.text.trim());
    if (_businessAddress2Ctrl.text.trim().isNotEmpty) parts.add(_businessAddress2Ctrl.text.trim());
    if (_businessCityCtrl.text.trim().isNotEmpty) parts.add(_businessCityCtrl.text.trim());
    if (_businessStateCtrl.text.trim().isNotEmpty) parts.add(_businessStateCtrl.text.trim());
    if (_businessPostcodeCtrl.text.trim().isNotEmpty) parts.add(_businessPostcodeCtrl.text.trim());
    if (_selectedBusinessCountry != null) {
      final countryName = TrustConstants.countries
          .firstWhere((c) => c['value'] == _selectedBusinessCountry,
              orElse: () => {'name': _selectedBusinessCountry!})['name'];
      if (countryName != null) parts.add(countryName);
    }
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildPersonalInfoStep() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Personal Information',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    // Refresh profile after returning
                    await _prefillFromProfile();
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profile Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _userProfile?.imagePath != null && _userProfile!.imagePath!.isNotEmpty
                        ? Image.network(
                            SupabaseService.instance.getFullImageUrl(_userProfile!.imagePath!) ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 30,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 30,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Profile Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name', (_userProfile?.displayName ?? '').isNotEmpty ? _userProfile!.displayName : 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('NRIC', _userProfile?.nricNo ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Phone', _userProfile?.phoneNo ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Email', _userProfile?.email ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Address', _formatAddress(_userProfile)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Validate profile exists
    if (_userProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first'), backgroundColor: Colors.orange),
      );
      setState(() => _currentStep = 0);
      return;
    }
    if (!(_financialFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!(_businessFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 2);
      return;
    }
    if (_beneficiaries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one beneficiary'), backgroundColor: Colors.orange),
      );
      setState(() => _currentStep = 3);
      return;
    }
    // Note: Charities are optional, so no validation needed

    setState(() => _isSubmitting = true);
    try {
      await TrustService.instance.createTrust(
        Trust(
          // Personal info from profile
          name: _userProfile!.nricName ?? _userProfile!.username,
          nricNumber: _userProfile!.nricNo,
          dateOfBirth: _userProfile!.dob,
          gender: _userProfile!.gender,
          residentStatus: null, // Not in profile yet
          nationality: _userProfile!.country,
          phoneNo: _userProfile!.phoneNo,
          email: _userProfile!.email,
          addressLine1: _userProfile!.address1,
          addressLine2: _userProfile!.address2,
          city: _userProfile!.city,
          postcode: _userProfile!.postcode,
          state: _userProfile!.state,
          country: _userProfile!.country,
          // Financial info from form
          estimatedNetWorth: _selectedEstimatedNetWorth,
          sourceOfFund: _selectedSourceOfFund,
          purposeOfTransaction: _purposeOfTransactionCtrl.text.trim().isEmpty ? null : _purposeOfTransactionCtrl.text.trim(),
          // Business info from form
          employerName: _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim(),
          businessNature: _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim(),
          businessAddressLine1: _businessAddress1Ctrl.text.trim().isEmpty ? null : _businessAddress1Ctrl.text.trim(),
          businessAddressLine2: _businessAddress2Ctrl.text.trim().isEmpty ? null : _businessAddress2Ctrl.text.trim(),
          businessCity: _businessCityCtrl.text.trim().isEmpty ? null : _businessCityCtrl.text.trim(),
          businessPostcode: _businessPostcodeCtrl.text.trim().isEmpty ? null : _businessPostcodeCtrl.text.trim(),
          businessState: _businessStateCtrl.text.trim().isEmpty ? null : _businessStateCtrl.text.trim(),
          businessCountry: _selectedBusinessCountry,
        ),
        beneficiaries: _beneficiaries,
        charities: _charities.isNotEmpty ? _charities : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust created successfully'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create trust: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Trust')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Trust')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_profileError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: MaterialBanner(
                  elevation: 0,
                  content: Text(
                    'We could not load your profile automatically. Please fill the details manually.\n$_profileError',
                  ),
                  leading: const Icon(Icons.info_outline),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => setState(() => _profileError = null),
                      child: const Text('DISMISS'),
                    )
                  ],
                ),
              ),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepTapped: (int i) => setState(() => _currentStep = i),
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  final bool isLast = _currentStep == 5;
                  return Row(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_currentStep == 0) {
                                  // Just move to next step, profile validation happens at submit
                                  setState(() => _currentStep = 1);
                                } else if (_currentStep == 1) {
                                  if (!(_financialFormKey.currentState?.validate() ?? true)) return;
                                  setState(() => _currentStep = 2);
                                } else if (_currentStep == 2) {
                                  if (!(_businessFormKey.currentState?.validate() ?? true)) return;
                                  setState(() => _currentStep = 3);
                                } else if (_currentStep == 3) {
                                  // Beneficiaries - validate at least one exists
                                  if (_beneficiaries.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please add at least one beneficiary'), backgroundColor: Colors.orange),
                                    );
                                    return;
                                  }
                                  setState(() => _currentStep = 4);
                                } else if (_currentStep == 4) {
                                  // Charities - optional, just proceed to review
                                  setState(() => _currentStep = 5);
                                } else {
                                  await _submit();
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(isLast ? 'Submit' : 'Next'),
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
                    title: const Text('Personal Information'),
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 0,
                    content: _buildPersonalInfoStep(),
                  ),
                  Step(
                    title: const Text('Financial Information'),
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 1,
                    content: Form(
                      key: _financialFormKey,
                      child: Column(
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            value: _selectedEstimatedNetWorth,
                            decoration: const InputDecoration(
                              labelText: 'Estimated Net Worth',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                            ),
                            items: TrustConstants.estimatedNetWorths
                                .map((Map<String, String> item) => DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedEstimatedNetWorth = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedSourceOfFund,
                            decoration: const InputDecoration(
                              labelText: 'Source of Fund',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            items: TrustConstants.sourceOfWealth
                                .map((Map<String, String> item) => DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedSourceOfFund = v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _purposeOfTransactionCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Purpose of Transaction',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Employment/Business Information'),
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 2,
                    content: Form(
                      key: _businessFormKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _employerNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Employer Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessNatureCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Business Nature',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.work_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessAddress1Ctrl,
                            decoration: const InputDecoration(
                              labelText: 'Business Address Line 1',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessAddress2Ctrl,
                            decoration: const InputDecoration(
                              labelText: 'Business Address Line 2',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _businessCityCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _businessPostcodeCtrl,
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
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: _businessStateCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'State',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBusinessCountry,
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: TrustConstants.countries
                                      .map((Map<String, String> item) => DropdownMenuItem<String>(
                                            value: item['value'],
                                            child: Text(item['name']!),
                                          ))
                                      .toList(),
                                  onChanged: (String? v) => setState(() => _selectedBusinessCountry = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Beneficiaries'),
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 3,
                    content: _buildBeneficiariesStep(),
                  ),
                  Step(
                    title: const Text('Donations/Charities'),
                    state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 4,
                    content: _buildCharitiesStep(),
                  ),
                  Step(
                    title: const Text('Review & Submit'),
                    state: StepState.indexed,
                    isActive: _currentStep >= 5,
                    content: _buildReviewStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
