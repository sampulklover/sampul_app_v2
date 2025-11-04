import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'add_family_member_screen.dart';
import 'add_asset_screen.dart';
import '../services/supabase_service.dart';
import '../services/will_service.dart';
import 'will_generation_screen.dart';
import 'package:flutter/services.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  bool _isLoading = false;
  bool _profileCompleted = false;
  bool _familyMemberAdded = false;
  bool _assetAdded = false;
  bool _willGenerated = false;
  final ScrollController _listController = ScrollController();

  final List<_OnboardingStep> _steps = const <_OnboardingStep>[
    _OnboardingStep(
      title: 'Complete Your Profile',
      description: 'Set up your basic information',
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
    _OnboardingStep(
      title: 'Create Your Will',
      description: 'Create your will with Sampul',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _checkCompletionStatus() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (profile != null) {
        _profileCompleted = (profile.username != null && profile.username!.isNotEmpty) ||
            (profile.nricName != null && profile.nricName!.isNotEmpty);

        final user = AuthController.instance.currentUser;
        if (user != null) {
          final List<dynamic> familyResponse = await SupabaseService.instance.client
              .from('beloved')
              .select('id')
              .eq('uuid', user.id)
              .limit(1);
          _familyMemberAdded = familyResponse.isNotEmpty;

          final List<dynamic> assetsResponse = await SupabaseService.instance.client
              .from('digital_assets')
              .select('id')
              .eq('uuid', user.id)
              .limit(1);
          _assetAdded = assetsResponse.isNotEmpty;

          // Check will
          final will = await WillService.instance.getUserWill(user.id);
          _willGenerated = will != null;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_profileCompleted || !_familyMemberAdded || !_assetAdded || !_willGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps before finishing'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthController.instance.markUserAsOnboarded();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete onboarding: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _navigateToStep(int stepIndex) async {
    bool? result;
    switch (stepIndex) {
      case 0:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => const EditProfileScreen()),
        );
        break;
      case 1:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => const AddFamilyMemberScreen()),
        );
        break;
      case 2:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => const AddAssetScreen()),
        );
        break;
      case 3:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WillGenerationScreen()),
        );
        await _checkCompletionStatus();
        return;
    }
    if (result == true) {
      await _checkCompletionStatus();
    }
  }

  Future<void> _handleCompleteTap(int completed) async {
    if (completed == 4) {
      await _completeOnboarding();
      return;
    }

    // Identify first incomplete step
    final List<bool> steps = <bool>[_profileCompleted, _familyMemberAdded, _assetAdded, _willGenerated];
    final int firstIncomplete = steps.indexWhere((bool s) => !s);

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    // Scroll to approximate position of the first incomplete step
    if (_listController.hasClients && firstIncomplete >= 0) {
      final double target = (_listController.position.maxScrollExtent) * (firstIncomplete / (steps.length - 1));
      _listController.animateTo(
        target.clamp(0, _listController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    // Show snackbar hint
    final List<String> titles = _steps.map((e) => e.title).toList();
    final String nextTitle = firstIncomplete >= 0 ? titles[firstIncomplete] : 'the remaining steps';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete: $nextTitle')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int completed = <bool>[_profileCompleted, _familyMemberAdded, _assetAdded, _willGenerated].where((bool e) => e).length;

    return PopScope(
      canPop: completed == 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Get Started'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: completed / 4,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$completed/4', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                controller: _listController,
                itemCount: _steps.length,
                itemBuilder: (BuildContext context, int index) {
                  final _OnboardingStep step = _steps[index];
                  final bool isCompleted = index == 0
                      ? _profileCompleted
                      : index == 1
                          ? _familyMemberAdded
                          : index == 2
                              ? _assetAdded
                              : _willGenerated;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _navigateToStep(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
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
                                step.icon,
                                color: isCompleted
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    step.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(step.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            isCompleted
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                : Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewPadding.bottom + 20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleCompleteTap(completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completed == 4 ? Colors.green : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: completed == 4 ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  const _OnboardingStep({required this.title, required this.description, required this.icon});
}


