import 'package:flutter/material.dart';
import '../models/will.dart';
import '../models/user_profile.dart';
import '../services/will_service.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';

class WillGenerationScreen extends StatefulWidget {
  final Will? existingWill;

  const WillGenerationScreen({super.key, this.existingWill});

  @override
  State<WillGenerationScreen> createState() => _WillGenerationScreenState();
}

class _WillGenerationScreenState extends State<WillGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDraft = true;
  int _currentStep = 0;
  
  UserProfile? _userProfile;
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _assets = [];
  
  int? _selectedCoSampul1;
  int? _selectedCoSampul2;
  int? _selectedGuardian1;
  int? _selectedGuardian2;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;

      // Load user profile
      final profile = await AuthController.instance.getUserProfile();
      
      // Load family members and deduplicate by id to avoid duplicate Dropdown values
      final familyMembersRaw = await WillService.instance.getFamilyMembers(user.id);
      final Map<int, Map<String, dynamic>> idToMember = {
        for (final Map<String, dynamic> m in familyMembersRaw)
          if (m['id'] != null) (m['id'] as int): m,
      };
      final List<Map<String, dynamic>> familyMembers = idToMember.values.toList();
      final Set<int> validMemberIds = familyMembers
          .map((m) => m['id'])
          .whereType<int>()
          .toSet();
      
      // Load assets
      final assets = await WillService.instance.getUserAssets(user.id);

      // Validate any preselected IDs against available family members
      int? selCo1 = widget.existingWill?.coSampul1;
      int? selCo2 = widget.existingWill?.coSampul2;
      int? selG1 = widget.existingWill?.guardian1;
      int? selG2 = widget.existingWill?.guardian2;

      if (selCo1 != null && !validMemberIds.contains(selCo1)) selCo1 = null;
      if (selCo2 != null && !validMemberIds.contains(selCo2)) selCo2 = null;
      if (selG1 != null && !validMemberIds.contains(selG1)) selG1 = null;
      if (selG2 != null && !validMemberIds.contains(selG2)) selG2 = null;

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _familyMembers = familyMembers;
          _assets = assets;
          
          if (widget.existingWill != null) {
            _nameController.text = widget.existingWill!.nricName ?? profile?.displayName ?? '';
            _selectedCoSampul1 = selCo1;
            _selectedCoSampul2 = selCo2;
            _selectedGuardian1 = selG1;
            _selectedGuardian2 = selG2;
            _isDraft = widget.existingWill!.isDraft ?? true;
          } else {
            _nameController.text = profile?.displayName ?? '';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load initial data: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveWill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (widget.existingWill != null) {
        await WillService.instance.updateWill(
          willId: widget.existingWill!.id!,
          nricName: _nameController.text.trim(),
          coSampul1: _selectedCoSampul1,
          coSampul2: _selectedCoSampul2,
          guardian1: _selectedGuardian1,
          guardian2: _selectedGuardian2,
          isDraft: _isDraft,
        );
        _showSuccessSnackBar('Will updated successfully!');
      } else {
        await WillService.instance.createWill(
          uuid: user.id,
          nricName: _nameController.text.trim(),
          coSampul1: _selectedCoSampul1,
          coSampul2: _selectedCoSampul2,
          guardian1: _selectedGuardian1,
          guardian2: _selectedGuardian2,
          isDraft: _isDraft,
        );
        _showSuccessSnackBar('Will created successfully!');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save will: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingWill != null ? 'Edit Will' : 'Create Will'),
        actions: [
          if (widget.existingWill != null && !_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveWill,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                      currentStep: _currentStep,
                      onStepTapped: (step) {
                        if (step < _getSteps().length) {
                          setState(() => _currentStep = step);
                        }
                      },
                      onStepContinue: _nextStep,
                      onStepCancel: _previousStep,
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              if (details.stepIndex > 0)
                                OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              const SizedBox(width: 8),
                              if (details.stepIndex < _getSteps().length - 1)
                                ElevatedButton(
                                  onPressed: details.onStepContinue,
                                  child: const Text('Next'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _saveWill,
                                  child: _isSaving
                                      ? const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Saving...'),
                                          ],
                                        )
                                      : Text(widget.existingWill != null ? 'Update Will' : 'Create Will'),
                                ),
                            ],
                          ),
                        );
                      },
                      steps: _getSteps(),
                    ),
            ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Personal Information'),
        content: _buildPersonalInfoStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Executors'),
        content: _buildExecutorsStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Guardians'),
        content: _buildGuardiansStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review & Save'),
        content: _buildReviewStep(),
        isActive: _currentStep >= 3,
        state: StepState.indexed,
      ),
    ];
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
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                    final refreshed = await AuthController.instance.getUserProfile();
                    if (mounted) {
                      setState(() {
                        _userProfile = refreshed;
                      });
                    }
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

  Widget _buildExecutorsStep() {
    return Column(
      children: [
        _buildFamilyMemberSelector(
          title: 'Primary Executor (Co-Sampul 1)',
          subtitle: 'Select the primary person to execute your will',
          selectedId: _selectedCoSampul1,
          onChanged: (value) => setState(() => _selectedCoSampul1 = value),
        ),
        const SizedBox(height: 16),
        _buildFamilyMemberSelector(
          title: 'Secondary Executor (Co-Sampul 2)',
          subtitle: 'Optional: Select a secondary executor',
          selectedId: _selectedCoSampul2,
          onChanged: (value) => setState(() => _selectedCoSampul2 = value),
        ),
      ],
    );
  }

  Widget _buildGuardiansStep() {
    return Column(
      children: [
        _buildFamilyMemberSelector(
          title: 'Primary Guardian',
          subtitle: 'Select guardian for minor children (if applicable)',
          selectedId: _selectedGuardian1,
          onChanged: (value) => setState(() => _selectedGuardian1 = value),
        ),
        const SizedBox(height: 16),
        _buildFamilyMemberSelector(
          title: 'Secondary Guardian',
          subtitle: 'Optional: Select a secondary guardian',
          selectedId: _selectedGuardian2,
          onChanged: (value) => setState(() => _selectedGuardian2 = value),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreviewInfoRow('Name', (_userProfile?.displayName ?? '').isNotEmpty ? _userProfile!.displayName : 'Not provided'),
                _buildPreviewInfoRow('NRIC', _userProfile?.nricNo ?? 'Not provided'),
                _buildPreviewInfoRow('Phone', _userProfile?.phoneNo ?? 'Not provided'),
                _buildPreviewInfoRow('Email', _userProfile?.email ?? 'Not provided'),
                _buildPreviewInfoRow('Address', _formatAddress(_userProfile)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Executors Preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Executors',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreviewInfoRow('Primary Executor', _getSelectedMemberName(_selectedCoSampul1)),
                _buildPreviewInfoRow('Secondary Executor', _getSelectedMemberName(_selectedCoSampul2)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Guardians Preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Guardians',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreviewInfoRow('Primary Guardian', _getSelectedMemberName(_selectedGuardian1)),
                _buildPreviewInfoRow('Secondary Guardian', _getSelectedMemberName(_selectedGuardian2)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Auto-Sync Notice (standardized)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.sync_alt, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your will updates automatically with your profile, assets, and family changes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
      ),
    );
  }

  String _getSelectedMemberName(int? memberId) {
    if (memberId == null) return 'None selected';
    
    final member = _familyMembers.firstWhere(
      (m) => m['id'] == memberId,
      orElse: () => <String, dynamic>{},
    );
    
    if (member.isEmpty) return 'Not found';
    
    return '${member['name']} (${member['relationship'] ?? 'Family member'})';
  }

  Widget _buildFamilyMemberSelector({
    required String title,
    required String subtitle,
    required int? selectedId,
    required ValueChanged<int?> onChanged,
  }) {
    final selectedMember = _familyMembers.firstWhere(
      (member) => member['id'] == selectedId,
      orElse: () => <String, dynamic>{},
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: selectedId,
              decoration: const InputDecoration(
                labelText: 'Select family member',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None selected'),
                ),
                ..._familyMembers.map((member) => DropdownMenuItem<int?>(
                  value: member['id'] as int,
                  child: Text('${member['name']} (${member['relationship'] ?? 'Family member'})'),
                )),
              ],
              onChanged: onChanged,
            ),
            if (selectedMember.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Profile Image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: selectedMember['image_path'] != null && selectedMember['image_path'].toString().isNotEmpty
                            ? Image.network(
                                SupabaseService.instance.getFullImageUrl(selectedMember['image_path']) ?? '',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedMember['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedMember['relationship'] ?? 'Family member',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _getSteps().length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
}