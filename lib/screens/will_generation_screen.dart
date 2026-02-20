import 'package:flutter/material.dart';
import '../models/will.dart';
import '../models/user_profile.dart';
import '../services/will_service.dart';
import 'assets_list_screen.dart';
import 'asset_info_screen.dart';
import 'edit_asset_screen.dart';
import 'add_asset_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extra_wishes.dart';
import '../services/extra_wishes_service.dart';
import 'extra_wishes_screen.dart';
import '../services/supabase_service.dart';
import '../services/brandfetch_service.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import '../widgets/stepper_footer_controls.dart';

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
  ExtraWishes? _extraWishes;
  
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

      // Load extra wishes
      final wishes = await ExtraWishesService.instance.getForCurrentUser();

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
          _extraWishes = wishes;
          
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
                controlsBuilder: (context, details) {
                  // Use standardized fixed-footer controls instead.
                  return const SizedBox.shrink();
                },
                steps: _getSteps(),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : StepperFooterControls(
              currentStep: _currentStep,
              lastStep: _getSteps().length - 1,
              isBusy: _isSaving,
              onPrimaryPressed: () async {
                if (_currentStep < _getSteps().length - 1) {
                  _nextStep();
                } else {
                  await _saveWill();
                }
              },
              onBackPressed: _currentStep > 0
                  ? () {
                      _previousStep();
                    }
                  : null,
              primaryLabel: _currentStep == _getSteps().length - 1
                  ? (widget.existingWill != null ? 'Update Will' : 'Create Will')
                  : null,
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
        title: const Text('Assets'),
        content: _buildAssetsStep(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Extra Wishes'),
        content: _buildExtraWishesStep(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review & Save'),
        content: _buildReviewStep(),
        isActive: _currentStep >= 5,
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

  // Extra Wishes step
  Widget _buildExtraWishesStep() {
    final theme = Theme.of(context);
    final String nazar = (_extraWishes?.nazarWishes ?? '').trim();
    final double? nazarCost = _extraWishes?.nazarEstimatedCostMyr;
    final int? fidyahDays = _extraWishes?.fidyahFastLeftDays;
    final double? fidyahAmount = _extraWishes?.fidyahAmountDueMyr;
    final bool organ = _extraWishes?.organDonorPledge ?? false;
    final int waqfCount = _extraWishes?.waqfBodies.length ?? 0;
    final double waqfTotal = (_extraWishes?.waqfBodies ?? const <Map<String, dynamic>>[])
        .fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
    final int charityCount = _extraWishes?.charityBodies.length ?? 0;
    final double charityTotal = (_extraWishes?.charityBodies ?? const <Map<String, dynamic>>[])
        .fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Extra Wishes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () async {
                final bool? changed = await Navigator.of(context).push(
                  MaterialPageRoute<bool>(builder: (_) => const ExtraWishesScreen()),
                );
                if (changed == true) {
                  await _refreshExtraWishes();
                }
              },
              icon: const Icon(Icons.edit, size: 16),
              label: Text(_extraWishes == null ? 'Add' : 'Edit'),
              style: TextButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_extraWishes == null)
          Text('No wishes yet. Add your nazar, fidyah, organ donor pledge, and charitable allocations.', style: theme.textTheme.bodyMedium)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _previewRow('Nazar wishes', nazar.isEmpty ? '—' : nazar, theme),
                  if (nazarCost != null) _previewRow('Nazar cost', 'RM ${nazarCost.toStringAsFixed(2)}', theme),
                  if (fidyahDays != null) _previewRow('Fidyah days', '$fidyahDays', theme),
                  if (fidyahAmount != null) _previewRow('Fidyah amount', 'RM ${fidyahAmount.toStringAsFixed(2)}', theme),
                  _previewRow('Organ donor pledge', organ ? 'Yes' : 'No', theme),
                  if (waqfCount > 0 || charityCount > 0) const SizedBox(height: 8),
                  if (waqfCount > 0) _chipLine('Waqf: $waqfCount bodies • RM ${waqfTotal.toStringAsFixed(2)}', theme),
                  if (charityCount > 0) _chipLine('Charity: $charityCount bodies • RM ${charityTotal.toStringAsFixed(2)}', theme),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _refreshExtraWishes() async {
    try {
      final wishes = await ExtraWishesService.instance.getForCurrentUser();
      if (!mounted) return;
      setState(() {
        _extraWishes = wishes;
      });
    } catch (_) {}
  }

  Widget _previewRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _chipLine(String text, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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

        // Assets Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total assets: RM ' + _assets
                      .fold<double>(0, (sum, a) => sum + ((a['value'] as num?)?.toDouble() ?? 0.0))
                      .toStringAsFixed(2),
                  style: theme.textTheme.bodyMedium,
                ),
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
              Icon(Icons.sync_alt, size: 16, color: const Color.fromRGBO(49, 24, 211, 1)),
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
              decoration: InputDecoration(
                labelText: 'Select family member',              ),
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

  // Assets step
  Widget _buildAssetsStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Assets', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    // Check if user has seen the about page before
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    final bool hasSeenAbout = prefs.getBool('assets_about_seen') ?? false;
                    
                    // If user hasn't seen about page, show it first
                    // Otherwise, go directly to add asset page
                    final bool? result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => hasSeenAbout 
                            ? const AddAssetScreen() 
                            : const AssetInfoScreen(),
                      ),
                    );
                    if (result == true) {
                      await _refreshAssets();
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AssetsListScreen()),
                    );
                    await _refreshAssets();
                  },
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Manage All'),
                  style: TextButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 8),
        if (_assets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No assets yet. Add at least one to include in your will.', style: theme.textTheme.bodyMedium),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (_assets.length > 3 ? 3 : _assets.length) + (_assets.length > 3 ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bool isShowMoreRow = _assets.length > 3 && index == 3;
              if (isShowMoreRow) {
                final int remaining = _assets.length - 3;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AssetsListScreen()),
                        );
                        await _refreshAssets();
                      },
                      child: Text('Show more ($remaining)'),
                    ),
                  ),
                );
              }
              final Map<String, dynamic> a = _assets[index];
              final int id = (a['id'] as num).toInt();
              final String name = (a['name'] as String?) ?? 'Unknown';
              final String type = (a['type'] as String?) ?? 'asset';
              final double value = (a['value'] as num?)?.toDouble() ?? 0.0;
              final String? logo = a['logo_url'] as String?; // only for digital
              final String? instruction = a['instructions_after_death'] as String?;
              return ListTile(
                onTap: () async {
                  if (type == 'digital') {
                    final bool? changed = await Navigator.of(context).push(
                      MaterialPageRoute<bool>(builder: (_) => EditAssetScreen(assetId: id)),
                    );
                    if (changed == true) {
                      await _refreshAssets();
                    }
                  } else {
                    // For physical assets, navigate to assets list for now
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AssetsListScreen()),
                    );
                    await _refreshAssets();
                  }
                },
                leading: _buildAssetAvatar(logo),
                title: Text(name),
                subtitle: (instruction ?? '').isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildChip(_prettyInstruction(instruction), _badgeBg(instruction), _badgeFg(instruction)),
                        ],
                      )
                    : null,
                trailing: Text('RM ${value.toStringAsFixed(2)}'),
              );
            },
          ),
      ],
    );
  }

  Future<void> _refreshAssets() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;
      final assets = await WillService.instance.getUserAssets(user.id);
      if (!mounted) return;
      setState(() {
        _assets = assets;
      });
    } catch (_) {
      // ignore
    }
  }

  Widget _buildAssetAvatar(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceVariant),
        alignment: Alignment.center,
        child: const Icon(Icons.apps_outlined),
      );
    }
    // Add client ID dynamically if it's a Brandfetch URL
    final String finalUrl = BrandfetchService.instance.addClientIdToUrl(logoUrl) ?? logoUrl;
    return ClipOval(
      child: Image.network(finalUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceVariant),
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined),
        );
      }),
    );
  }

  String _prettyInstruction(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'faraid':
        return 'Faraid';
      case 'terminate':
        return 'Terminate Subscriptions';
      case 'transfer_as_gift':
        return 'Transfer as Gift';
      case 'settle':
        return 'Settle Debts';
      default:
        return 'Unspecified';
    }
  }

  Color _badgeBg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade50;
      case 'terminate':
        return Colors.red.shade50;
      case 'transfer_as_gift':
        return Colors.teal.shade50;
      case 'settle':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _badgeFg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade700;
      case 'terminate':
        return Colors.red.shade700;
      case 'transfer_as_gift':
        return Colors.teal.shade800;
      case 'settle':
        return Colors.orange.shade800;
      default:
        return Colors.black87;
    }
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}