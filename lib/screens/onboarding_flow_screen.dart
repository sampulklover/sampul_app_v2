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
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

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

  List<_OnboardingStep> _getSteps(AppLocalizations l10n) {
    return <_OnboardingStep>[
      _OnboardingStep(
        title: l10n.completeYourProfile,
        description: l10n.setUpYourBasicInformation,
        icon: Icons.person_outline,
      ),
      _OnboardingStep(
        title: l10n.addYourFirstFamilyMember,
        description: l10n.addSomeoneImportantToYourWill,
        icon: Icons.family_restroom,
      ),
      _OnboardingStep(
        title: l10n.addYourFirstAsset,
        description: l10n.startTrackingYourDigitalAssets,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _OnboardingStep(
        title: l10n.createYourWill,
        description: l10n.createYourWillWithSampul,
        icon: Icons.description_outlined,
      ),
    ];
  }

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
            final mediaQuery = MediaQuery.of(context);
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: mediaQuery.size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.card_giftcard_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Title
                              Text(
                                AppLocalizations.of(context)!.haveReferralCode,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.enterReferralCodeBelow,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Text Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: controller,
                                  textInputAction: TextInputAction.done,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.referralCodeLabel,
                                    prefixIcon: Icon(
                                      Icons.card_giftcard_outlined,
                                      color: const Color.fromRGBO(83, 61, 233, 1),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
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
                                    if (v.length < 4) return AppLocalizations.of(context)!.codeLooksTooShort;
                                    return null;
                                  },
                                ),
                              ),
                              
                              // Error message
                              if (inlineError != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: theme.colorScheme.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          inlineError!,
                                          style: TextStyle(
                                            color: theme.colorScheme.onErrorContainer,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Success message
                              if (inlineSuccess != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: theme.colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          inlineSuccess!,
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimaryContainer,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Buttons
                    Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
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
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: theme.colorScheme.outline),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.clear,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                            inlineSuccess = AppLocalizations.of(context)!.referralCodeApplied;
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isReferralSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.apply,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeOnboarding() async {
    final l10n = AppLocalizations.of(context)!;
    // Only the first three steps are required to finish onboarding.
    // Creating a will and setting up a family trust are now optional.
    if (!_profileCompleted || !_familyMemberAdded || !_assetAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseCompleteAllStepsBeforeFinishing), backgroundColor: Colors.orange),
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
        SnackBar(content: Text(l10n.failedToCompleteOnboarding(e.toString())), backgroundColor: Colors.red),
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
    // When all required steps (3) are done, allow completing onboarding.
    if (completed == 3) {
      await _completeOnboarding();
      return;
    }

    // Identify first incomplete *required* step (profile, family, asset).
    final List<bool> stepStatuses = <bool>[_profileCompleted, _familyMemberAdded, _assetAdded];
    final int firstIncomplete = stepStatuses.indexWhere((bool s) => !s);

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    // Scroll to approximate position of the first incomplete step
    if (_listController.hasClients && firstIncomplete >= 0) {
      final double target = (_listController.position.maxScrollExtent) * (firstIncomplete / (stepStatuses.length - 1));
      _listController.animateTo(
        target.clamp(0, _listController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    // Show snackbar hint
    final l10n = AppLocalizations.of(context)!;
    final List<_OnboardingStep> onboardingSteps = _getSteps(l10n);
    // Only required steps are used for guidance here.
    final List<String> titles = onboardingSteps.take(3).map((e) => e.title).toList();
    final String nextTitle = firstIncomplete >= 0 ? titles[firstIncomplete] : l10n.theRemainingSteps;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseComplete(nextTitle))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    // Only the first three steps are required for onboarding completion.
    final int completed = <bool>[_profileCompleted, _familyMemberAdded, _assetAdded].where((bool e) => e).length;
    final List<_OnboardingStep> steps = _getSteps(l10n);

    return PopScope(
      // Allow leaving this screen once required steps are done.
      canPop: completed == 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.getStartedTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.logOut,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logOut),
                    content: Text(l10n.areYouSureYouWantToLogOut),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.logOut),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final navigator = Navigator.of(context);
                await AuthController.instance.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
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
                            widthFactor: completed / 3,
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
                  Text('$completed/3', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Intro helper text (kept short and simple)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Before we get started, complete these quick steps to set up your Sampul account.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                controller: _listController,
                // +1 for referral card, +1 for optional trust step
                itemCount: steps.length + 2,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
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
                                      l10n.referralCode,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.addReferralCodeOptional,
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
                  if (index == steps.length + 1) {
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
                                      l10n.setUpYourFamilyTrustAccount,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.createFamilyAccountForLongTermSupport,
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
                  final _OnboardingStep step2 = steps[stepIndex];
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
                  onPressed: _isLoading || completed < 3 ? null : () => _handleCompleteTap(completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completed == 3
                        ? Colors.green
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: completed == 3
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
                              l10n.completeSetup,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                      color: completed == 3
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                                color: completed == 3
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


