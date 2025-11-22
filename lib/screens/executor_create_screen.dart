import 'package:flutter/material.dart';
import '../config/executor_constants.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import 'edit_profile_screen.dart';
import 'executor_deceased_form_screen.dart';
import 'executor_guardian_form_screen.dart';
import 'executor_assets_form_screen.dart';

class ExecutorCreateScreen extends StatefulWidget {
  const ExecutorCreateScreen({super.key});

  @override
  State<ExecutorCreateScreen> createState() => _ExecutorCreateScreenState();
}

class _ExecutorCreateScreenState extends State<ExecutorCreateScreen> {
  // Form keys
  final GlobalKey<FormState> _applicantFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _documentsFormKey = GlobalKey<FormState>();

  // Step 2: Applicant Info (executor table) - using profile data
  bool _isLoadingProfile = true;
  String? _profileError;
  UserProfile? _userProfile;
  String? _selectedRelationship;
  final TextEditingController _otherRelationshipCtrl = TextEditingController();
  final TextEditingController _applicantHomePhoneCtrl = TextEditingController();
  final TextEditingController _applicantOfficePhoneCtrl = TextEditingController();
  final TextEditingController _correspondenceAddress1Ctrl = TextEditingController();
  final TextEditingController _correspondenceAddress2Ctrl = TextEditingController();
  final TextEditingController _correspondenceCityCtrl = TextEditingController();
  final TextEditingController _correspondencePostcodeCtrl = TextEditingController();
  final TextEditingController _correspondenceStateCtrl = TextEditingController();
  String? _selectedCorrespondenceCountry;
  bool _isSameAddress = true;

  // Deceased Info (stored from separate screen)
  Map<String, dynamic>? _deceasedData;

  // Step 4: Assets Info (executor_deceased_assets table) - stored from separate screen
  Map<String, dynamic>? _assetsData;

  // Guardian Info (stored from separate screen)
  Map<String, dynamic>? _guardianData;

  // Step 6: Documents
  final TextEditingController _supportingDocumentsCtrl = TextEditingController();
  final TextEditingController _additionalNotesCtrl = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _otherRelationshipCtrl.dispose();
    _applicantHomePhoneCtrl.dispose();
    _applicantOfficePhoneCtrl.dispose();
    _correspondenceAddress1Ctrl.dispose();
    _correspondenceAddress2Ctrl.dispose();
    _correspondenceCityCtrl.dispose();
    _correspondencePostcodeCtrl.dispose();
    _correspondenceStateCtrl.dispose();
    _supportingDocumentsCtrl.dispose();
    _additionalNotesCtrl.dispose();
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

  Widget _buildGetStartedStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Executor Registration',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We help you manage and distribute your loved one\'s estate, ensuring everything is handled properly and legally.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you get:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildSellingPoint(
                      'Professional Management',
                      'We handle the legal and administrative work—so you don\'t have to navigate it alone.',
                    ),
                    const SizedBox(height: 16),
                    _buildSellingPoint(
                      'Find what\'s left behind',
                      'We help identify key assets—so nothing essential is left behind.',
                    ),
                    const SizedBox(height: 16),
                    _buildSellingPoint(
                      'Support that goes beyond paperwork',
                      'From document prep to grief care, we guide you with empathy through a difficult time.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellingPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicantInfoStep() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    
    return Form(
      key: _applicantFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_profileError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
            // Personal Information Card
            Card(
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
            ),
            const SizedBox(height: 24),
            // Executor-specific fields
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: const InputDecoration(
                labelText: 'Relationship with Deceased *',
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
                  setState(() => _selectedRelationship = v);
                }
              },
              validator: (v) {
                if (v == null) return 'Required';
                final validValues = ['husband', 'wife', 'father', 'mother', 'child', 'others'];
                if (!validValues.contains(v)) {
                  return 'Please select a valid relationship';
                }
                return null;
              },
            ),
            if (_selectedRelationship == 'others') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherRelationshipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Other Relationship *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _applicantHomePhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Home Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _applicantOfficePhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Office Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Correspondence Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Same as personal address'),
              value: _isSameAddress,
              onChanged: (v) {
                setState(() {
                  _isSameAddress = v ?? true;
                  if (_isSameAddress) {
                    _correspondenceAddress1Ctrl.clear();
                    _correspondenceAddress2Ctrl.clear();
                    _correspondenceCityCtrl.clear();
                    _correspondencePostcodeCtrl.clear();
                    _correspondenceStateCtrl.clear();
                    _selectedCorrespondenceCountry = null;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!_isSameAddress) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _correspondenceAddress1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1 *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correspondenceAddress2Ctrl,
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
                      controller: _correspondenceCityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _correspondencePostcodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Postcode *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _correspondenceStateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCorrespondenceCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country *',
                        border: OutlineInputBorder(),
                      ),
                      items: ExecutorConstants.countries
                          .map((c) => DropdownMenuItem<String>(
                                value: c['value'],
                                child: Text(c['name']!),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCorrespondenceCountry = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDeceasedInfo() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutorDeceasedFormScreen(
          initialData: _deceasedData,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _deceasedData = result;
      });
    }
  }

  Future<void> _navigateToGuardianInfo() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutorGuardianFormScreen(
          initialData: _guardianData,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _guardianData = result;
      });
    }
  }

  Future<void> _navigateToAssetsInfo() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutorAssetsFormScreen(
          initialData: _assetsData,
        ),
      ),
    );

    // Update assets data if result is not null, otherwise keep existing data
    if (result != null) {
      setState(() {
        _assetsData = Map<String, dynamic>.from(result);
      });
    }
  }

  Widget _buildDeceasedInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deceased Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.account_circle_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Deceased Information'),
              subtitle: Text(
                _deceasedData != null
                    ? '${_deceasedData!['full_name'] ?? 'Unknown'}'
                    : 'Not provided yet',
                style: TextStyle(
                  color: _deceasedData != null ? Colors.green : Colors.grey,
                  fontStyle: _deceasedData == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToDeceasedInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsInfoStep() {
    final immovableCount = (_assetsData?['immovable_assets'] as List?)?.length ?? 0;
    final movableCount = (_assetsData?['movable_assets'] as List?)?.length ?? 0;
    final liabilitiesCount = (_assetsData?['liabilities'] as List?)?.length ?? 0;
    final beneficiariesCount = (_assetsData?['beneficiaries'] as List?)?.length ?? 0;
    final int totalItems = immovableCount + movableCount + liabilitiesCount + beneficiariesCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assets Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.account_balance_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: const Text('Assets Information'),
              subtitle: Text(
                _assetsData != null
                    ? '$totalItems items added'
                    : 'Not provided yet',
                style: TextStyle(
                  color: _assetsData != null ? Colors.green : Colors.grey,
                  fontStyle: _assetsData == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToAssetsInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guardian Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.family_restroom_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Guardian Information'),
              subtitle: Text(
                _guardianData != null
                    ? '${_guardianData!['full_name'] ?? 'Unknown'}'
                    : 'Optional - Not provided yet',
                style: TextStyle(
                  color: _guardianData != null ? Colors.green : Colors.grey,
                  fontStyle: _guardianData == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToGuardianInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Form(
      key: _documentsFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporting Documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supportingDocumentsCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Supporting Documents',
                hintText: 'List the documents you have (e.g., Death certificate, Will, Identity documents, etc.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _additionalNotesCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any additional information that might help with your executor registration...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Applicant Info
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
                        'Applicant Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow('Name', (_userProfile?.displayName ?? '').isNotEmpty ? _userProfile!.displayName : 'Not provided'),
                  _buildReviewRow('NRIC', _userProfile?.nricNo),
                  _buildReviewRow('Phone', _userProfile?.phoneNo),
                  _buildReviewRow('Email', _userProfile?.email),
                  _buildReviewRow('Relationship', _selectedRelationship != null
                      ? ExecutorConstants.executorRelationships.firstWhere((r) => r['value'] == _selectedRelationship, orElse: () => {'name': ''})['name']
                      : null),
                  _buildReviewRow('Address', _formatAddress(_userProfile)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Deceased Info
          if (_deceasedData != null)
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
                      Icon(Icons.account_circle, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Deceased Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildReviewRow('Full Name', _deceasedData!['full_name']?.toString()),
                    _buildReviewRow('Date of Death', _deceasedData!['date_of_death']?.toString()),
                    _buildReviewRow('Cause of Death', _deceasedData!['cause_of_death'] != null
                        ? ExecutorConstants.deathCauses.firstWhere((c) => c['value'] == _deceasedData!['cause_of_death'], orElse: () => {'name': ''})['name']
                        : null),
                    _buildReviewRow('Marital Status', _deceasedData!['marital_status'] != null
                        ? ExecutorConstants.maritalStatus.firstWhere((m) => m['value'] == _deceasedData!['marital_status'], orElse: () => {'name': ''})['name']
                        : null),
                  ],
                ),
              ),
            ),
          if (_deceasedData != null)
            const SizedBox(height: 16),
          const SizedBox(height: 16),
          // Assets Summary
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Assets Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow('Immovable Assets', '${(_assetsData?['immovable_assets'] as List?)?.length ?? 0} items'),
                  _buildReviewRow('Movable Assets', '${(_assetsData?['movable_assets'] as List?)?.length ?? 0} items'),
                  _buildReviewRow('Liabilities', '${(_assetsData?['liabilities'] as List?)?.length ?? 0} items'),
                  _buildReviewRow('Beneficiaries', '${(_assetsData?['beneficiaries'] as List?)?.length ?? 0} items'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Guardian Info
          if (_guardianData != null)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.family_restroom, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Guardian Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildReviewRow('Full Name', _guardianData!['full_name']?.toString()),
                    _buildReviewRow('Phone', _guardianData!['phone_no']?.toString()),
                    _buildReviewRow('Email', _guardianData!['email']?.toString()),
                  ],
                ),
              ),
            ),
        ],
      ),
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


  Future<void> _submit() async {
    // Validate profile exists
    if (_userProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first'), backgroundColor: Colors.orange),
      );
      setState(() => _currentStep = 1);
      return;
    }
    if (!(_applicantFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 1);
      return;
    }
    // Validate deceased info is provided
    if (_deceasedData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide deceased information'), backgroundColor: Colors.orange),
      );
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final client = SupabaseService.instance.client;

      // Generate executor code
      final int currentYear = DateTime.now().year;
      final int randomDigits = (DateTime.now().microsecondsSinceEpoch % 10000000000).toInt();
      final String padded = randomDigits.toString().padLeft(10, '0');
      String executorCode = 'EXEC-$currentYear-$padded';

      // Validate relationship_with_deceased
      final validRelationships = ['husband', 'wife', 'father', 'mother', 'child', 'others'];
      if (_selectedRelationship == null || !validRelationships.contains(_selectedRelationship)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid relationship with deceased'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 1: Create executor record
      int attempts = 0;
      int? executorId;
      while (executorId == null && attempts < 5) {
        try {
          final executorData = {
        'name': _userProfile!.nricName ?? _userProfile!.username ?? 'Unknown',
        'nric_number': _userProfile!.nricNo ?? '',
        'age': null, // Age can be calculated from DOB if needed
        'phone_no': _userProfile!.phoneNo ?? '',
        'home_phone': _applicantHomePhoneCtrl.text.trim().isNotEmpty ? _applicantHomePhoneCtrl.text.trim() : null,
        'office_phone': _applicantOfficePhoneCtrl.text.trim().isNotEmpty ? _applicantOfficePhoneCtrl.text.trim() : null,
        'email': _userProfile!.email,
        'relationship_with_deceased': _selectedRelationship,
        'other_relationship': _selectedRelationship == 'others' ? _otherRelationshipCtrl.text.trim() : null,
        'address_line_1': _userProfile!.address1 ?? '',
        'address_line_2': _userProfile!.address2,
        'city': _userProfile!.city ?? '',
        'postcode': _userProfile!.postcode ?? '',
        'state': _userProfile!.state ?? '',
        'country': _userProfile!.country,
        'correspondence_address_line_1': _isSameAddress ? (_userProfile!.address1 ?? '') : _correspondenceAddress1Ctrl.text.trim(),
        'correspondence_address_line_2': _isSameAddress ? _userProfile!.address2 : (_correspondenceAddress2Ctrl.text.trim().isNotEmpty ? _correspondenceAddress2Ctrl.text.trim() : null),
        'correspondence_city': _isSameAddress ? (_userProfile!.city ?? '') : _correspondenceCityCtrl.text.trim(),
        'correspondence_postcode': _isSameAddress ? (_userProfile!.postcode ?? '') : _correspondencePostcodeCtrl.text.trim(),
        'correspondence_state': _isSameAddress ? (_userProfile!.state ?? '') : _correspondenceStateCtrl.text.trim(),
        'correspondence_country': _isSameAddress ? _userProfile!.country : _selectedCorrespondenceCountry,
        'is_same_address': _isSameAddress,
        'executor_code': executorCode,
        'uuid': user.id,
          };

          final executorResult = await client.from('executor').insert(executorData).select().limit(1);
          executorId = executorResult.first['id'] as int;
        } catch (e) {
          // Retry on unique violation by generating a new code
          final String msg = e.toString().toLowerCase();
          final bool isUniqueViolation = msg.contains('duplicate key') || msg.contains('unique') || msg.contains('23505');
          if (!isUniqueViolation || attempts >= 4) {
            rethrow;
          }
          attempts += 1;
          // Generate new code
          final int newRandomDigits = (DateTime.now().microsecondsSinceEpoch % 10000000000).toInt();
          final String newPadded = newRandomDigits.toString().padLeft(10, '0');
          executorCode = 'EXEC-$currentYear-$newPadded';
        }
      }

      if (executorId == null) {
        throw Exception('Failed to create executor after multiple attempts');
      }

      // Step 2: Create executor_deceased record
      if (_deceasedData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide deceased information'), backgroundColor: Colors.orange),
        );
        return;
      }

      final deceasedData = {
        'executor_id': executorId,
        ..._deceasedData!,
        'uuid': user.id,
      };

      await client.from('executor_deceased').insert(deceasedData);

      // Step 3: Create executor_deceased_assets record
      final assetsData = {
        'executor_id': executorId,
        'immovable_assets': _assetsData?['immovable_assets'] ?? [],
        'movable_assets': _assetsData?['movable_assets'] ?? [],
        'liabilities': _assetsData?['liabilities'] ?? [],
        'beneficiaries': _assetsData?['beneficiaries'] ?? [],
        'uuid': user.id,
      };

      await client.from('executor_deceased_assets').insert(assetsData);

      // Step 4: Create executor_guardian record (if provided)
      if (_guardianData != null) {
        final guardianData = {
          'executor_id': executorId,
          ..._guardianData!,
          'uuid': user.id,
        };

        await client.from('executor_guardian').insert(guardianData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Executor submitted successfully\nCode: $executorCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit executor: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Executor')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepTapped: (int i) => setState(() => _currentStep = i),
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  final bool isLast = _currentStep == 6;
                  final bool isFirst = _currentStep == 0;
                  String getButtonText() {
                    if (isLast) return 'Submit Executor';
                    if (isFirst) return 'Start my application';
                    return 'Next';
                  }
                  return Row(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_currentStep == 0) {
                                  setState(() => _currentStep = 1);
                                } else if (_currentStep == 1) {
                                  if (!(_applicantFormKey.currentState?.validate() ?? false)) return;
                                  setState(() => _currentStep = 2);
                                } else if (_currentStep == 2) {
                                  // Validate deceased info is provided
                                  if (_deceasedData == null) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please provide deceased information'), backgroundColor: Colors.orange),
                                    );
                                    return;
                                  }
                                  setState(() => _currentStep = 3);
                                } else if (_currentStep == 3) {
                                  setState(() => _currentStep = 4);
                                } else if (_currentStep == 4) {
                                  // Guardian is optional, so just proceed
                                  setState(() => _currentStep = 5);
                                } else if (_currentStep == 5) {
                                  setState(() => _currentStep = 6);
                                } else {
                                  await _submit();
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(getButtonText()),
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
                    title: const Text('Get Started'),
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 0,
                    content: _buildGetStartedStep(),
                  ),
                  Step(
                    title: const Text('Personal Information'),
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 1,
                    content: _buildApplicantInfoStep(),
                  ),
                  Step(
                    title: const Text('Deceased Info'),
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 2,
                    content: _buildDeceasedInfoStep(),
                  ),
                  Step(
                    title: const Text('Assets Info'),
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 3,
                    content: _buildAssetsInfoStep(),
                  ),
                  Step(
                    title: const Text('Guardian Info'),
                    state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 4,
                    content: _buildGuardianInfoStep(),
                  ),
                  Step(
                    title: const Text('Documents'),
                    state: _currentStep > 5 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 5,
                    content: _buildDocumentsStep(),
                  ),
                  Step(
                    title: const Text('Review'),
                    state: StepState.indexed,
                    isActive: _currentStep >= 6,
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
