import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/onboarding_goal.dart';
import '../models/chat_conversation.dart';
import 'edit_profile_screen.dart';
import 'family_info_screen.dart';
import 'asset_info_screen.dart';
import '../services/supabase_service.dart';
import '../services/will_service.dart';
import '../services/chat_service.dart';
import '../services/ai_chat_settings_service.dart';
import 'will_info_screen.dart';
import '../services/trust_service.dart';
import 'trust_info_screen.dart';
import 'hibah_info_screen.dart';
import 'executor_info_screen.dart';
import 'package:flutter/services.dart';
import '../services/affiliate_service.dart';
import '../l10n/app_localizations.dart';
import '../controllers/locale_controller.dart';
import 'enhanced_chat_conversation_screen.dart';
import 'aftercare_screen.dart';
import '../services/analytics_service.dart';
import '../config/analytics_screens.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final OnboardingGoal? goal;

  const OnboardingFlowScreen({super.key, this.goal});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  bool _isLoading = false;
  bool _profileCompleted = false;
  bool _familyMemberAdded = false;
  bool _assetAdded = false;
  bool _willGenerated = false;
  bool _trustCreated = false;
  bool _hibahCreated = false;
  bool _executionSetUp = false;
  bool _sampulAIExplored = false;
  bool _aftercareExplored = false;
  final ScrollController _listController = ScrollController();
  bool _isReferralSubmitting = false;
  String? _referralCodePreview;

  OnboardingGoal get _goal => widget.goal ?? OnboardingGoal.notSure;

  List<OnboardingStepType> get _steps => _goal.requiredSteps;

  int get _minimumRequiredSteps => _goal.minimumRequiredSteps;

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
    _loadPendingReferralCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logScreen(AnalyticsScreens.onboardingFlow);
    });
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

          final will = await WillService.instance.getUserWill(user.id);
          _willGenerated = will != null;

          try {
            final trusts = await TrustService.instance.listUserTrusts();
            _trustCreated = trusts.isNotEmpty;
          } catch (_) {
            _trustCreated = false;
          }

          try {
            final List<dynamic> hibahResponse = await SupabaseService.instance.client
                .from('hibah')
                .select('id')
                .eq('uuid', user.id)
                .limit(1);
            _hibahCreated = hibahResponse.isNotEmpty;
          } catch (_) {
            _hibahCreated = false;
          }

          // Check execution setup
          try {
            final List<dynamic> executorResponse = await SupabaseService.instance.client
                .from('executors')
                .select('id')
                .eq('uuid', user.id)
                .limit(1);
            _executionSetUp = executorResponse.isNotEmpty;
          } catch (_) {
            _executionSetUp = false;
          }

          // Check Sampul AI usage
          try {
            final List<dynamic> chatResponse = await SupabaseService.instance.client
                .from('chat_messages')
                .select('id')
                .eq('sender_type', 'user')
                .limit(1);
            _sampulAIExplored = chatResponse.isNotEmpty;
          } catch (_) {
            _sampulAIExplored = false;
          }

          // Aftercare is optional exploratory - mark as explored if user has visited
          // We'll set this to true when they navigate and return
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

  bool _isStepCompleted(OnboardingStepType step) {
    switch (step) {
      case OnboardingStepType.profile:
        return _profileCompleted;
      case OnboardingStepType.familyMember:
        return _familyMemberAdded;
      case OnboardingStepType.asset:
        return _assetAdded;
      case OnboardingStepType.will:
        return _willGenerated;
      case OnboardingStepType.trust:
        return _trustCreated;
      case OnboardingStepType.hibah:
        return _hibahCreated;
      case OnboardingStepType.execution:
        return _executionSetUp;
      case OnboardingStepType.sampulAI:
        return _sampulAIExplored;
      case OnboardingStepType.aftercare:
        return _aftercareExplored;
    }
  }

  int get _completedCount {
    int count = 0;
    for (int i = 0; i < _steps.length && i < _minimumRequiredSteps; i++) {
      if (_isStepCompleted(_steps[i])) count++;
    }
    return count;
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
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
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
                                    if (v.isEmpty) return null;
                                    if (v.length < 4) return AppLocalizations.of(context)!.codeLooksTooShort;
                                    return null;
                                  },
                                ),
                              ),
                              
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
                                          await AffiliateService.instance.claimReferralCodeNow(normalized);

                                          if (!mounted) return;
                                          setState(() => _referralCodePreview = normalized);
                                          setModalState(() {
                                            inlineSuccess = AppLocalizations.of(context)!.referralCodeApplied;
                                          });
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
    
    if (_completedCount < _minimumRequiredSteps) {
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

  Future<void> _navigateToStep(OnboardingStepType step) async {
    bool? result;
    switch (step) {
      case OnboardingStepType.profile:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            settings: const RouteSettings(name: AnalyticsScreens.editProfile),
            builder: (_) => const EditProfileScreen(),
          ),
        );
        break;
      case OnboardingStepType.familyMember:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            settings: const RouteSettings(name: 'Add family member'),
            builder: (_) => const FamilyInfoScreen(),
          ),
        );
        break;
      case OnboardingStepType.asset:
        result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            settings: const RouteSettings(name: 'Add asset'),
            builder: (_) => const AssetInfoScreen(),
          ),
        );
        break;
      case OnboardingStepType.will:
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const WillInfoScreen()),
        );
        break;
      case OnboardingStepType.trust:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen()),
        );
        break;
      case OnboardingStepType.hibah:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HibahInfoScreen()),
        );
        break;
      case OnboardingStepType.execution:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const ExecutorInfoScreen()),
        );
        break;
      case OnboardingStepType.sampulAI:
        await _navigateToSampulAI();
        break;
      case OnboardingStepType.aftercare:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const AftercareScreen()),
        );
        _aftercareExplored = true;
        break;
    }
    if (result == true || step == OnboardingStepType.trust || step == OnboardingStepType.hibah || step == OnboardingStepType.execution || step == OnboardingStepType.sampulAI || step == OnboardingStepType.aftercare) {
      await _checkCompletionStatus();
    }
  }

  Future<void> _navigateToSampulAI() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final conversations = await ChatService.getUserConversations(currentUser.id);
      ChatConversation aiConversation;
      
      try {
        aiConversation = conversations.firstWhere(
          (conv) => conv.conversationType == ConversationType.ai,
        );
      } catch (_) {
        final response = await Supabase.instance.client
            .from('chat_conversations')
            .insert({
              'name': 'Sampul AI',
              'last_message': (await AiChatSettingsService.instance.getActiveSettings()).welcomeMessage,
              'last_message_time': DateTime.now().toIso8601String(),
              'avatar_url': '',
              'unread_count': 0,
              'is_online': true,
              'conversation_type': 'ai',
              'created_by': currentUser.id,
            })
            .select()
            .single();

        aiConversation = ChatConversation.fromJson(response);
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedChatConversationScreen(
            conversation: aiConversation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final tempConversation = ChatConversation(
        id: 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Sampul AI',
        lastMessage: 'Hello! I\'m your estate planning assistant. How can I help you today?',
        lastMessageTime: DateTime.now(),
        avatarUrl: '',
        unreadCount: 0,
        isOnline: true,
        conversationType: ConversationType.ai,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedChatConversationScreen(
            conversation: tempConversation,
          ),
        ),
      );
    }
  }

  Future<void> _handleCompleteTap() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if minimum required steps are completed
    if (_completedCount < _minimumRequiredSteps) {
      // Find first incomplete required step
      int firstIncomplete = -1;
      for (int i = 0; i < _steps.length && i < _minimumRequiredSteps; i++) {
        if (!_isStepCompleted(_steps[i])) {
          firstIncomplete = i;
          break;
        }
      }

      await HapticFeedback.mediumImpact();

      if (_listController.hasClients && firstIncomplete >= 0) {
        final double target = (_listController.position.maxScrollExtent) * (firstIncomplete / (_minimumRequiredSteps - 1));
        _listController.animateTo(
          target.clamp(0, _listController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }

      final String nextTitle = firstIncomplete >= 0 ? _steps[firstIncomplete].getTitle(context) : l10n.theRemainingSteps;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseComplete(nextTitle))),
        );
      }
      return;
    }

    // Check for incomplete optional steps
    List<String> skippedSteps = [];
    for (int i = _minimumRequiredSteps; i < _steps.length; i++) {
      if (!_isStepCompleted(_steps[i])) {
        skippedSteps.add(_steps[i].getTitle(context));
      }
    }

    // If there are skipped optional steps, ask for confirmation
    if (skippedSteps.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Skip remaining steps?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You haven\'t completed:'),
              const SizedBox(height: 12),
              ...skippedSteps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'You can always complete these later from the app.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Skip & continue'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await _completeOnboarding();
  }

  Future<void> _showLanguageSelector(AppLocalizations l10n) async {
    final currentLocale = LocaleController.instance.locale;
    
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        
        return Container(
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
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Icon
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.translate,
                    size: 32,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  l10n.selectLanguage,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Language options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildLanguageOption(
                        context: context,
                        theme: theme,
                        title: l10n.english,
                        subtitle: 'English',
                        value: 'en',
                        currentValue: currentLocale.languageCode,
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                        context: context,
                        theme: theme,
                        title: l10n.malay,
                        subtitle: 'Bahasa Melayu',
                        value: 'ms',
                        currentValue: currentLocale.languageCode,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    if (selectedLanguage != null && selectedLanguage != currentLocale.languageCode) {
      await LocaleController.instance.setLocale(Locale(selectedLanguage));
    }
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
  }) {
    final isSelected = value == currentValue;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalSpecificMessage(AppLocalizations l10n) {
    switch (_goal) {
      case OnboardingGoal.familyAccount:
        return l10n.completeStepsFamilyAccount;
      case OnboardingGoal.protectProperty:
        return l10n.completeStepsProtectProperty;
      case OnboardingGoal.managePusaka:
        return l10n.completeStepsManagePusaka;
      case OnboardingGoal.writeWasiat:
        return l10n.completeStepsWriteWasiat;
      case OnboardingGoal.getGuidance:
        return l10n.completeStepsGetGuidance;
      case OnboardingGoal.notSure:
        return l10n.completeStepsNotSure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final int completed = _completedCount;
    final bool isComplete = completed >= _minimumRequiredSteps;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_goal.getTitle(context)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.translate),
              tooltip: l10n.language,
              onPressed: () => _showLanguageSelector(l10n),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // Progress Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: completed / _minimumRequiredSteps,
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
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isComplete 
                                ? Colors.green.withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$completed/$_minimumRequiredSteps',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isComplete ? Colors.green : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getGoalSpecificMessage(l10n),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Steps List
              Expanded(
                child: SingleChildScrollView(
                  controller: _listController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Step Cards
                      ...List.generate(_steps.length, (index) {
                        final step = _steps[index];
                        final isCompleted = _isStepCompleted(step);
                        return _buildStepCard(theme, step, isCompleted, isDark, l10n, index + 1);
                      }),
                      
                      // Subtle referral link
                      if (_referralCodePreview == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: TextButton.icon(
                            onPressed: _showReferralCodeDialog,
                            icon: Icon(
                              Icons.card_giftcard_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            label: Text(
                              l10n.haveReferralCode,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.referralCode}: $_referralCodePreview',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleCompleteTap(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isComplete
                          ? Colors.green
                          : const Color.fromRGBO(83, 61, 233, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.completeSetup,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
    );
  }

  Widget _buildStepCard(
    ThemeData theme,
    OnboardingStepType step,
    bool isCompleted,
    bool isDark,
    AppLocalizations l10n,
    int stepNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToStep(step),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // Step number badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : const Color.fromRGBO(83, 61, 233, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            '$stepNumber',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.getTitle(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted 
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.getDescription(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: isCompleted 
                      ? Colors.green 
                      : const Color.fromRGBO(83, 61, 233, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
