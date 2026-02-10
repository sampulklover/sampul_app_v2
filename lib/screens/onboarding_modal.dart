import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'family_info_screen.dart';
import 'asset_info_screen.dart';
import '../services/supabase_service.dart';

class OnboardingModal extends StatefulWidget {
  const OnboardingModal({super.key});

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal> {
  bool _isLoading = false;
  bool _profileCompleted = false;
  bool _familyMemberAdded = false;
  bool _assetAdded = false;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Complete Your Profile',
      description: 'Let\'s start by setting up your basic information',
      icon: Icons.person_outline,
    ),
    _OnboardingStep(
      title: 'Add Your First Family Member',
      description: 'Add someone important to your will',
      icon: Icons.family_restroom,
    ),
    _OnboardingStep(
      title: 'Add Your First Asset',
      description: 'Start tracking your digital assets',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  Future<void> _checkCompletionStatus() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (profile != null) {
        // Check if profile has essential info
        _profileCompleted = profile.username != null && 
                          profile.username!.isNotEmpty ||
                          profile.nricName != null && 
                          profile.nricName!.isNotEmpty;
        
        // Check if user has family members
        final user = AuthController.instance.currentUser;
        if (user != null) {
          final familyResponse = await SupabaseService.instance.client
              .from('beloved')
              .select('id')
              .eq('uuid', user.id)
              .limit(1);
          _familyMemberAdded = familyResponse.isNotEmpty;
          
          // Check if user has assets
          final assetsResponse = await SupabaseService.instance.client
              .from('digital_assets')
              .select('id')
              .eq('uuid', user.id)
              .limit(1);
          _assetAdded = assetsResponse.isNotEmpty;
        }
        
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // Error checking, continue with onboarding
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_profileCompleted || !_familyMemberAdded || !_assetAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps before finishing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update isOnboard to true
      await SupabaseService.instance.client
          .from('profiles')
          .update({'isOnboard': true})
          .eq('uuid', user.id);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToStep(int stepIndex) async {
    bool? result;
    
    switch (stepIndex) {
      case 0:
        // Profile setup
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => const EditProfileScreen(),
          ),
        );
        if (result == true) {
          await _checkCompletionStatus();
        }
        break;
      case 1:
        // Add family member
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => const FamilyInfoScreen(),
          ),
        );
        if (result == true) {
          await _checkCompletionStatus();
        }
        break;
      case 2:
        // Add asset
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => const AssetInfoScreen(),
          ),
        );
        if (result == true) {
          await _checkCompletionStatus();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: _profileCompleted && _familyMemberAdded && _assetAdded,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Sampul!',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let\'s get you set up',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_profileCompleted && _familyMemberAdded && _assetAdded)
                        IconButton(
                          onPressed: () => _completeOnboarding(),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: ([_profileCompleted, _familyMemberAdded, _assetAdded]
                                  .where((e) => e).length / 3),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${[_profileCompleted, _familyMemberAdded, _assetAdded].where((e) => e).length}/3',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Steps list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      final isCompleted = index == 0 ? _profileCompleted :
                                         index == 1 ? _familyMemberAdded :
                                         _assetAdded;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _navigateToStep(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isCompleted ? Icons.check_circle : step.icon,
                                    color: isCompleted
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step.description,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCompleted)
                                  Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Footer with complete button
                if (_profileCompleted && _familyMemberAdded && _assetAdded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Complete Setup',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
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

class _OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

