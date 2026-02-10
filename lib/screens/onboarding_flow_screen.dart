import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'family_info_screen.dart';
import 'asset_info_screen.dart';
import '../services/supabase_service.dart';
import '../services/will_service.dart';
import 'will_info_screen.dart';
import '../services/trust_service.dart';
import 'trust_info_screen.dart';
import 'package:flutter/services.dart';
import '../services/affiliate_service.dart';

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
  bool _trustCreated = false; // Optional step
  final ScrollController _listController = ScrollController();
  bool _isReferralSubmitting = false;
  String? _referralCodePreview;

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
    _loadPendingReferralCode();
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

          // Optional: Check if user has at least one trust / family account
          try {
            final trusts = await TrustService.instance.listUserTrusts();
            _trustCreated = trusts.isNotEmpty;
          } catch (_) {
            // If this fails, we simply treat the optional step as not completed
            _trustCreated = false;
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadPendingReferralCode() async {
    final pending = await AffiliateService.instance.getPendingReferralCode();
    if (!mounted) return;
    setState(() => _referralCodePreview = pending);
  }

  Future<void> _showReferralCodeDialog() async {
    final controller = TextEditingController(text: _referralCodePreview ?? '');
    final formKey = GlobalKey<FormState>();
    String? inlineError;
    String? inlineSuccess;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Have a referral code?',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your code below.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Referral code',
                          hintText: 'Example: ABC123',                          prefixIcon: Icon(Icons.card_giftcard_outlined),                        ),
                        onChanged: (_) {
                          if (inlineError != null || inlineSuccess != null) {
                            setModalState(() {
                              inlineError = null;
                              inlineSuccess = null;
                            });
                          }
                        },
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return null; // optional
                          if (v.length < 4) return 'Code looks too short';
                          return null;
                        },
                      ),
                      if (inlineError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inlineError!,
                                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (inlineSuccess != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: const Color.fromRGBO(83, 61, 233, 1), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inlineSuccess!,
                                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isReferralSubmitting
                                  ? null
                                  : () async {
                                      await AffiliateService.instance.clearPendingReferralCode();
                                      if (!mounted) return;
                                      setState(() => _referralCodePreview = null);
                                      Navigator.of(context).pop();
                                    },
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isReferralSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      final raw = controller.text;
                                      final normalized = AffiliateService.instance.normalizeReferralCode(raw);
                                      if (normalized == null) {
                                        // empty input: treat as "skip"
                                        Navigator.of(context).pop();
                                        return;
                                      }

                                      setModalState(() => _isReferralSubmitting = true);
                                      try {
                                        setModalState(() {
                                          inlineError = null;
                                          inlineSuccess = null;
                                        });
                                        await AffiliateService.instance.setPendingReferralCode(normalized);
                                        // Try to claim immediately (user is logged in during onboarding flow).
                                        await AffiliateService.instance.claimReferralCodeNow(normalized);

                                        if (!mounted) return;
                                        setState(() => _referralCodePreview = normalized);
                                        setModalState(() {
                                          inlineSuccess = 'Referral code applied';
                                        });
                                        // Close automatically after a short delay so user sees feedback.
                                        Future.delayed(const Duration(milliseconds: 900), () {
                                          if (Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
                                        });
                                      } catch (e) {
                                        if (!mounted) return;
                                        final msg = AffiliateService.instance.friendlyReferralClaimError(e);
                                        setModalState(() {
                                          inlineError = msg;
                                        });
                                      } finally {
                                        setModalState(() => _isReferralSubmitting = false);
                                      }
                                    },
                              child: _isReferralSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
          MaterialPageRoute<bool>(builder: (_) => const FamilyInfoScreen()),
        );
        break;
      case 2:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => const AssetInfoScreen()),
        );
        break;
      case 3:
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const WillInfoScreen()),
        );
        break;
    }
    if (result == true) {
      await _checkCompletionStatus();
    }
  }

  Future<void> _navigateToTrustSetup() async {
    // Family trust setup is optional; we don't depend on the result here.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const TrustInfoScreen(),
      ),
    );
    // If the user returns here after creating a trust, refresh optional state.
    await _checkCompletionStatus();
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
                // +1 for referral card, +1 for optional trust step
                itemCount: _steps.length + 2,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    const subtitle = 'Add a referral code (optional)';
                    final bool isReferralApplied = _referralCodePreview != null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _showReferralCodeDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isReferralApplied
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.card_giftcard_outlined,
                                  color: isReferralApplied
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
                                      'Referral code',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isReferralApplied
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                  : Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Last item: optional Family Trust setup step
                  if (index == _steps.length + 1) {
                    final theme = Theme.of(context);
                    final isCompleted = _trustCreated;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _navigateToTrustSetup,
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
                                  Icons.family_restroom,
                                  size: 24,
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
                                      'Set up your Family Trust account',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create a family account to manage long-term support (optional).',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isCompleted
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                  : Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final stepIndex = index - 1;
                  // Adjust completion mapping for shifted index (because referral card is index 0 now).
                  final _OnboardingStep step2 = _steps[stepIndex];
                  final bool isCompleted2 = stepIndex == 0
                      ? _profileCompleted
                      : stepIndex == 1
                          ? _familyMemberAdded
                          : stepIndex == 2
                              ? _assetAdded
                              : _willGenerated;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _navigateToStep(stepIndex),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isCompleted2
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                step2.icon,
                                color: isCompleted2
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
                                    step2.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompleted2 ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(step2.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            isCompleted2
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                : Icon(Icons.arrow_forward_ios, size: 16, color: const Color.fromRGBO(83, 61, 233, 1)),
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
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewPadding.bottom + 24,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || completed < 4 ? null : () => _handleCompleteTap(completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completed == 4
                        ? Colors.green
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: completed == 4
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Complete setup',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: completed == 4
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: completed == 4
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
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


