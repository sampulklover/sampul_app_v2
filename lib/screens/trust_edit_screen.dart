import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../models/trust_charity.dart';
import '../models/user_profile.dart';
import '../services/trust_service.dart';
import '../config/trust_constants.dart';
import 'edit_profile_screen.dart';
import 'trust_beneficiary_form_screen.dart';
import 'trust_charity_form_screen.dart';

class TrustEditScreen extends StatefulWidget {
  final Trust initial;
  const TrustEditScreen({super.key, required this.initial});

  @override
  State<TrustEditScreen> createState() => _TrustEditScreenState();
}

class _TrustEditScreenState extends State<TrustEditScreen> {
  final GlobalKey<FormState> _financialFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _businessFormKey = GlobalKey<FormState>();

  // Beneficiaries and Charities
  List<TrustBeneficiary> _beneficiaries = [];
  List<TrustCharity> _charities = [];
  
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
  bool _isLoadingData = true;
  bool _isLoadingProfile = true;
  String? _profileError;
  String? _dataError;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeData();
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

  Future<void> _initializeData() async {
    // Load profile
    _loadProfile();
    
    // Load trust data
    _loadTrustData();
  }

  Future<void> _loadProfile() async {
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

  Future<void> _loadTrustData() async {
    setState(() => _dataError = null);
    try {
      // Load beneficiaries and charities
      final beneficiaries = await TrustService.instance.getBeneficiariesByTrustId(widget.initial.id!);
      final charities = await TrustService.instance.getCharitiesByTrustId(widget.initial.id!);
      
      if (!mounted) return;
      
      // Initialize form controllers with existing trust data
      final trust = widget.initial;
      _selectedEstimatedNetWorth = _normalizeDropdownValue(TrustConstants.estimatedNetWorths, trust.estimatedNetWorth);
      _selectedSourceOfFund = _normalizeDropdownValue(TrustConstants.sourceOfWealth, trust.sourceOfFund);
      _purposeOfTransactionCtrl.text = trust.purposeOfTransaction ?? '';
      _employerNameCtrl.text = trust.employerName ?? '';
      _businessNatureCtrl.text = trust.businessNature ?? '';
      _businessAddress1Ctrl.text = trust.businessAddressLine1 ?? '';
      _businessAddress2Ctrl.text = trust.businessAddressLine2 ?? '';
      _businessCityCtrl.text = trust.businessCity ?? '';
      _businessPostcodeCtrl.text = trust.businessPostcode ?? '';
      _businessStateCtrl.text = trust.businessState ?? '';
      _selectedBusinessCountry = _normalizeDropdownValue(TrustConstants.countries, trust.businessCountry);

      setState(() {
        _beneficiaries = beneficiaries;
        _charities = charities;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _dataError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  String? _normalizeDropdownValue(List<Map<String, String>> items, String? value) {
    if (value == null || value.isEmpty) return null;
    final bool exists = items.any((item) => item['value'] == value);
    return exists ? value : null;
  }

  String _formatAddress(UserProfile? profile) {
    if (profile == null) return 'Not provided';
    
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    if (profile.country != null) {
      final countryName = TrustConstants.countries
          .firstWhere((c) => c['value'] == profile.country, orElse: () => {'name': profile.country!})['name'];
      if (countryName != null) parts.add(countryName);
    }
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Future<void> _addBeneficiary() async {
    final result = await Navigator.push<TrustBeneficiary>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrustBeneficiaryFormScreen(),
      ),
    );
    
    if (result != null) {
      // Save to database immediately
      try {
        final created = await TrustService.instance.createBeneficiary(
          TrustBeneficiary(
            trustId: widget.initial.id!,
            name: result.name,
            nricPassportNumber: result.nricPassportNumber,
            dateOfBirth: result.dateOfBirth,
            gender: result.gender,
            relationship: result.relationship,
            residentStatus: result.residentStatus,
            nationality: result.nationality,
            phoneNo: result.phoneNo,
            email: result.email,
            addressLine1: result.addressLine1,
            addressLine2: result.addressLine2,
            city: result.city,
            postcode: result.postcode,
            stateProvince: result.stateProvince,
            country: result.country,
            monthlyDistributionLiving: result.monthlyDistributionLiving,
            monthlyDistributionEducation: result.monthlyDistributionEducation,
            medicalExpenses: result.medicalExpenses,
            educationExpenses: result.educationExpenses,
            settleOutstanding: result.settleOutstanding,
            investMarket: result.investMarket,
            investUnit: result.investUnit,
            mentallyIncapacitated: result.mentallyIncapacitated,
          ),
        );
        if (mounted) {
          setState(() {
            _beneficiaries.add(created);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Beneficiary added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add beneficiary: $e')),
          );
        }
      }
    }
  }

  Future<void> _editBeneficiary(int index) async {
    final beneficiary = _beneficiaries[index];
    final result = await Navigator.push<TrustBeneficiary>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustBeneficiaryFormScreen(
          beneficiary: beneficiary,
          index: index,
        ),
      ),
    );
    
    if (result != null && beneficiary.id != null) {
      // Update in database
      try {
        final updated = await TrustService.instance.updateBeneficiary(
          beneficiary.id!,
          result.toJson(),
        );
        if (mounted) {
          setState(() {
            _beneficiaries[index] = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Beneficiary updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update beneficiary: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteBeneficiary(int index) async {
    final beneficiary = _beneficiaries[index];
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Beneficiary'),
        content: Text('Are you sure you want to delete "${beneficiary.name ?? 'this beneficiary'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && beneficiary.id != null) {
      try {
        await TrustService.instance.deleteBeneficiary(beneficiary.id!);
        if (mounted) {
          setState(() {
            _beneficiaries.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Beneficiary deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete beneficiary: $e')),
          );
        }
      }
    }
  }

  Future<void> _addCharity() async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => const TrustCharityFormScreen(),
      ),
    );
    
    if (result != null) {
      // Save to database immediately
      try {
        final created = await TrustService.instance.createCharity(
          TrustCharity(
            trustId: widget.initial.id!,
            organizationName: result.organizationName,
            category: result.category,
            bank: result.bank,
            accountNumber: result.accountNumber,
            donationAmount: result.donationAmount,
            donationDuration: result.donationDuration,
            email: result.email,
            phoneNo: result.phoneNo,
            addressLine1: result.addressLine1,
            addressLine2: result.addressLine2,
            city: result.city,
            postcode: result.postcode,
            state: result.state,
            country: result.country,
          ),
        );
        if (mounted) {
          setState(() {
            _charities.add(created);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Charity added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add charity: $e')),
          );
        }
      }
    }
  }

  Future<void> _editCharity(int index) async {
    final charity = _charities[index];
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustCharityFormScreen(
          charity: charity,
          index: index,
        ),
      ),
    );
    
    if (result != null && charity.id != null) {
      // Update in database
      try {
        final updated = await TrustService.instance.updateCharity(
          charity.id!,
          result.toJson(),
        );
        if (mounted) {
          setState(() {
            _charities[index] = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Charity updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update charity: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCharity(int index) async {
    final charity = _charities[index];
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Charity'),
        content: Text('Are you sure you want to delete "${charity.organizationName ?? 'this charity'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && charity.id != null) {
      try {
        await TrustService.instance.deleteCharity(charity.id!);
        if (mounted) {
          setState(() {
            _charities.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Charity deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete charity: $e')),
          );
        }
      }
    }
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
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                    if (result == true) {
                      _loadProfile();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_isLoadingProfile)
              const Center(child: CircularProgressIndicator())
            else if (_userProfile != null) ...[
              _buildInfoRow('Full Name', _userProfile!.nricName ?? _userProfile!.username ?? 'Not provided'),
              _buildInfoRow('NRIC', _userProfile!.nricNo ?? 'Not provided'),
              _buildInfoRow('Phone', _userProfile!.phoneNo ?? 'Not provided'),
              _buildInfoRow('Email', _userProfile!.email),
              _buildInfoRow('Address', _formatAddress(_userProfile)),
            ] else
              Text(
                'Unable to load profile information',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
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
                    'Add people who will benefit from this trust',
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
                  _buildReviewRow('Employer Name', _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim()),
                  _buildReviewRow('Business Nature', _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim()),
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

  Future<void> _submit() async {
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

    setState(() => _isSubmitting = true);
    try {
      // Update trust main information
      await TrustService.instance.updateTrust(widget.initial.id!, {
        'estimated_net_worth': _selectedEstimatedNetWorth,
        'source_of_fund': _selectedSourceOfFund,
        'purpose_of_transaction': _purposeOfTransactionCtrl.text.trim().isEmpty ? null : _purposeOfTransactionCtrl.text.trim(),
        'employer_name': _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim(),
        'business_nature': _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim(),
        'business_address_line_1': _businessAddress1Ctrl.text.trim().isEmpty ? null : _businessAddress1Ctrl.text.trim(),
        'business_address_line_2': _businessAddress2Ctrl.text.trim().isEmpty ? null : _businessAddress2Ctrl.text.trim(),
        'business_city': _businessCityCtrl.text.trim().isEmpty ? null : _businessCityCtrl.text.trim(),
        'business_postcode': _businessPostcodeCtrl.text.trim().isEmpty ? null : _businessPostcodeCtrl.text.trim(),
        'business_state': _businessStateCtrl.text.trim().isEmpty ? null : _businessStateCtrl.text.trim(),
        'business_country': _selectedBusinessCountry,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trust'),
      ),
      body: (_isLoadingProfile || _isLoadingData)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_dataError != null)
                  MaterialBanner(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    content: Text('Error loading trust data: $_dataError'),
                    leading: const Icon(Icons.error_outline),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => setState(() => _dataError = null),
                        child: const Text('DISMISS'),
                      )
                    ],
                  ),
                if (_profileError != null)
                  MaterialBanner(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    content: Text('Error loading profile: $_profileError'),
                    leading: const Icon(Icons.error_outline),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => setState(() => _profileError = null),
                        child: const Text('DISMISS'),
                      )
                    ],
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
                                      setState(() => _currentStep = 1);
                                    } else if (_currentStep == 1) {
                                      if (!(_financialFormKey.currentState?.validate() ?? true)) return;
                                      setState(() => _currentStep = 2);
                                    } else if (_currentStep == 2) {
                                      if (!(_businessFormKey.currentState?.validate() ?? true)) return;
                                      setState(() => _currentStep = 3);
                                    } else if (_currentStep == 3) {
                                      if (_beneficiaries.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please add at least one beneficiary'), backgroundColor: Colors.orange),
                                        );
                                        return;
                                      }
                                      setState(() => _currentStep = 4);
                                    } else if (_currentStep == 4) {
                                      setState(() => _currentStep = 5);
                                    } else {
                                      await _submit();
                                    }
                                  },
                            child: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(isLast ? 'Save Changes' : 'Next'),
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
    );
  }
}
