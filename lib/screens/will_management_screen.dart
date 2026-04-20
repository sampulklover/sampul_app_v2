import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/will.dart';
import '../models/user_profile.dart';
import '../services/will_service.dart';
import '../services/notification_service.dart';
import '../models/extra_wishes.dart';
import '../services/extra_wishes_service.dart';
import '../services/billing_service.dart';
import '../services/wasiat_generated_document_service.dart';
import '../controllers/auth_controller.dart';
import '../config/analytics_screens.dart';
import '../services/analytics_service.dart';
import '../services/verification_service.dart';
import '../models/verification.dart';
import '../config/didit_config.dart';
import '../widgets/verification_status_modal.dart';
import 'main_shell.dart';
import 'plans_overview_screen.dart';
import 'will_generation_screen.dart';
import '../models/wasiat_generated_document.dart';

enum _WasiatDocView { certificate, details }

class WillManagementScreen extends StatefulWidget {
  const WillManagementScreen({super.key});

  @override
  State<WillManagementScreen> createState() => WillManagementScreenState();
}

class WillManagementScreenState extends State<WillManagementScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Will? _will;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isGeneratingSnapshot = false;
  _WasiatDocView _docView = _WasiatDocView.certificate;
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _assets = [];
  ExtraWishes? _extraWishes;
  BillingStatus _planStatus = const BillingStatus();
  List<WasiatGeneratedDocument> _generatedHistory = <WasiatGeneratedDocument>[];
  WasiatGeneratedDocument? _selectedGenerated;
  final ScrollController _scrollController = ScrollController();
  bool _showActionBar = true;
  double _lastScrollOffset = 0.0;
  late final AnimationController _actionBarController;
  late final ConfettiController _confettiController;
  bool _diditVerificationLaunched = false;
  String? _activeVerificationSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWillData();
    _scrollController.addListener(_onScroll);
    _actionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 420),
      value: 1.0,
    );
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 900));
  }

  // Expose a public reload method for external triggers (e.g., when tab becomes active)
  Future<void> reload() async {
    await _loadWillData();
  }

  Future<void> openGenerateCertificatePrompt() async {
    if (!mounted) return;
    if (_isGeneratingSnapshot) return;
    final int? verificationId = await _validateCertificateEligibility();
    if (verificationId == null) return;
    await _publishWill(verificationId: verificationId);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final delta = current - _lastScrollOffset;
    _lastScrollOffset = current;

    // Standard behavior: hide on scroll down, show on scroll up, with small guard
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && current > kToolbarHeight && delta.abs() > 2 && _showActionBar) {
      _showActionBar = false;
      _actionBarController.reverse();
      setState(() {});
    } else if (direction == ScrollDirection.forward && delta.abs() > 2 && !_showActionBar) {
      _showActionBar = true;
      _actionBarController.forward();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _actionBarController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _diditVerificationLaunched) {
      _diditVerificationLaunched = false;
      _refreshAfterDiditReturn();
    }
  }

  Future<void> _refreshAfterDiditReturn() async {
    await _loadWillData();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    String title = l10n.verifyYourIdentity;
    String message = l10n.wasiatPublishVerificationSettingsHint;
    VerificationStatusModalType type = VerificationStatusModalType.pending;
    String ctaLabel = l10n.continueLabel;
    VoidCallback? onCtaPressed;

    try {
      Verification? activeVerification;
      if (_activeVerificationSessionId != null &&
          _activeVerificationSessionId!.isNotEmpty) {
        final String sessionId = _activeVerificationSessionId!;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            activeVerification = await VerificationService.instance.syncVerificationStatus(
              sessionId,
            );
          } catch (_) {
            activeVerification = await VerificationService.instance.getVerificationBySessionId(
              sessionId,
            );
          }

          final String latestStatus = (activeVerification?.status ?? '').toLowerCase();
          final bool isFinalStatus = latestStatus == 'verified' ||
              latestStatus == 'approved' ||
              latestStatus == 'accepted' ||
              latestStatus == 'declined' ||
              latestStatus == 'rejected' ||
              latestStatus == 'failed';
          if (isFinalStatus) {
            break;
          }

          if (attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 1200));
          }
        }
      }

      final String status = (activeVerification?.status ?? '').toLowerCase();
      if (status == 'verified' || status == 'approved' || status == 'accepted') {
        title = l10n.yourIdentityIsVerified;
        message = l10n.yourIdentityIsVerified;
        type = VerificationStatusModalType.success;
        // Avoid duplicating "Generate certificate" (the next dialog’s primary action).
        ctaLabel = l10n.continueLabel;
        onCtaPressed = () {
          Navigator.of(context).pop();
          MainShell.maybeOf(context)?.openWasiatCertificatePrompt();
        };
      } else if (status == 'pending' || status.isEmpty) {
        title = l10n.pending;
        message = l10n.pending;
      } else if (status == 'declined') {
        title = l10n.declined;
        message = l10n.verificationWasDeclined;
        type = VerificationStatusModalType.failed;
      } else if (status == 'rejected' || status == 'failed') {
        title = l10n.rejected;
        message = l10n.verificationWasRejected;
        type = VerificationStatusModalType.failed;
      }
    } catch (_) {
      // If status refresh fails, keep a neutral verification reminder.
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => VerificationStatusModal(
        type: type,
        title: title,
        message: message,
        ctaLabel: ctaLabel,
        onCtaPressed: onCtaPressed,
      ),
    );
    _activeVerificationSessionId = null;
  }

  Future<void> _showConfettiCelebration() async {
    if (!mounted) return;
    // Common mobile pattern: a light impact when celebration starts.
    HapticFeedback.lightImpact();
    _confettiController.play();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'confetti',
      barrierColor: Colors.black.withOpacity(0.12),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, _, __) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Stack(
            children: [
              // Confetti from top
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.22,
                  numberOfParticles: 18,
                  maxBlastForce: 18,
                  minBlastForce: 10,
                  gravity: 0.35,
                  colors: <Color>[
                    cs.primary,
                    cs.secondary,
                    cs.tertiary,
                    cs.primaryContainer,
                    cs.secondaryContainer,
                  ],
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
    // Auto-close after a short burst (if still open).
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  

  Future<void> _loadWillData() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        return;
      }

      final Future<BillingStatus> planFuture = BillingService.instance.fetchStatus();
      final will = await WillService.instance.getUserWill(user.id);
      final profile = await AuthController.instance.getUserProfile();
      final Future<List<WasiatGeneratedDocument>> historyFuture =
          WasiatGeneratedDocumentService.instance.fetchHistory();

      BillingStatus planStatus = const BillingStatus();
      try {
        planStatus = await planFuture;
      } catch (_) {
        planStatus = const BillingStatus();
      }

      if (will != null && profile != null) {
        // Load family members and assets for will document generation
        final familyMembers = await WillService.instance.getFamilyMembers(user.id);
        final assets = await WillService.instance.getUserAssets(user.id);
        
        // Load extra wishes
        final wishes = await ExtraWishesService.instance.getForCurrentUser();
        List<WasiatGeneratedDocument> history = <WasiatGeneratedDocument>[];
        try {
          history = await historyFuture;
        } catch (_) {
          history = <WasiatGeneratedDocument>[];
        }

        if (mounted) {
          setState(() {
            _will = will;
            _userProfile = profile;
            _familyMembers = familyMembers;
            _assets = assets;
            _extraWishes = wishes;
            _planStatus = planStatus;
            _generatedHistory = history;
            _selectedGenerated ??= history.isNotEmpty ? history.first : null;
            _isLoading = false;
          });
        }
      } else {
        List<WasiatGeneratedDocument> history = <WasiatGeneratedDocument>[];
        try {
          history = await historyFuture;
        } catch (_) {
          history = <WasiatGeneratedDocument>[];
        }
        if (mounted) {
          setState(() {
            _will = will;
            _userProfile = profile;
            _planStatus = planStatus;
            _generatedHistory = history;
            _selectedGenerated ??= history.isNotEmpty ? history.first : null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        _showErrorSnackBar(l10n.failedToLoadWillData(e.toString()));
      }
    }
  }

  Future<void> _generateSnapshot({int? verificationId}) async {
    if (_will == null || _userProfile == null) return;
    if (_isGeneratingSnapshot) return;

    final int? resolvedVerificationId =
        verificationId ?? await _validateCertificateEligibility();
    if (resolvedVerificationId == null) {
      return;
    }

    setState(() => _isGeneratingSnapshot = true);
    try {
      final doc = await WasiatGeneratedDocumentService.instance.createSnapshot(
        will: _will!,
        userProfile: _userProfile!,
        familyMembers: _familyMembers,
        assets: _assets,
        extraWishes: _extraWishes,
        verificationId: resolvedVerificationId,
      );
      final List<WasiatGeneratedDocument> updated = <WasiatGeneratedDocument>[doc, ..._generatedHistory];
      if (!mounted) return;
      setState(() {
        _generatedHistory = updated;
        _selectedGenerated = doc;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10n.failedToPublishWill(e.toString()));
    } finally {
      if (mounted) setState(() => _isGeneratingSnapshot = false);
    }
  }

  Future<void> _openGeneratedHistoryPicker() async {
    if (_generatedHistory.isEmpty) {
      await _generateSnapshot();
      return;
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.wasiatGeneratedHistoryTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _generatedHistory.length,
                    separatorBuilder: (_, __) => Divider(color: cs.outline.withOpacity(0.12)),
                    itemBuilder: (context, i) {
                      final d = _generatedHistory[i];
                      final bool selected = _selectedGenerated?.id == d.id;
                      final DateTime when = d.createdAt ?? DateTime.now();
                      final String label = DateFormat.yMMMd().add_jm().format(when);
                      return ListTile(
                        onTap: () {
                          setState(() => _selectedGenerated = d);
                          Navigator.of(context).pop();
                          if (_scrollController.hasClients) _scrollController.jumpTo(0);
                        },
                        leading: Icon(selected ? Icons.check_circle_rounded : Icons.history_rounded),
                        title: Text(label),
                        subtitle: d.willCode != null ? Text('Will ID: ${d.willCode}') : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isGeneratingSnapshot
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            await _generateSnapshot();
                          },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isGeneratingSnapshot) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(l10n.wasiatGenerateNewVersionCta),
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

  Future<void> _createNewWill() async {
    // For the main Will tab, go straight into the editor to avoid
    // duplicating the intro copy that is already shown on this page.
    await AnalyticsService.capture('will journey started', properties: {'mode': 'create'});
    if (!mounted) return;
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: AnalyticsScreens.willGeneration),
        builder: (context) => const WillGenerationScreen(),
      ),
    );

    if (result == true) {
      await _loadWillData();
    }
  }

  Future<void> _editWill() async {
    if (_will == null) return;

    await AnalyticsService.capture('will journey started', properties: {'mode': 'edit'});
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: AnalyticsScreens.willGeneration),
        builder: (context) => WillGenerationScreen(existingWill: _will),
      ),
    );

    if (result == true) {
      await _loadWillData();
    }
  }

  Future<void> _openWasiatPlan() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AnalyticsScreens.plansOverview),
        builder: (_) => const PlansOverviewScreen(),
      ),
    );
    if (!mounted) return;
    try {
      final BillingStatus s = await BillingService.instance.fetchStatus();
      if (mounted) setState(() => _planStatus = s);
    } catch (_) {}
  }

  /// Same title as the real publish flow ([publishWill]), so this feels like the publish modal.
  Future<void> _showPublishBlockedByPlanDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.wasiatCertificateDialogTitle),
        content: SizedBox(
          width: 360,
          child: Text(
            l10n.wasiatPublishBlockedBody,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openWasiatPlan();
            },
            child: Text(l10n.wasiatViewPlanAndPay),
          ),
        ],
      ),
    );
  }

  Future<void> _onPublishPressed() async {
    if (_will == null || _will!.id == null) return;
    if (_will!.isDraft != true) {
      await _unpublishWill();
      return;
    }
    if (!_planStatus.isSubscribed) {
      await _showPublishBlockedByPlanDialog();
      return;
    }
    final int? verificationId = await _validateCertificateEligibility();
    if (verificationId == null) return;
    await _publishWill(verificationId: verificationId);
  }

  Future<void> _startDiditKycVerification({required bool requireFullKyc}) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final String sessionPrefix = requireFullKyc ? 'didit_kyc_' : 'didit_cert_';

    if (!DiditConfig.isConfigured) {
      _showErrorSnackBar(l10n.diditNotConfigured);
      return;
    }
    if (!requireFullKyc && DiditConfig.reauthWorkflowId.isEmpty) {
      _showErrorSnackBar(l10n.diditNotConfigured);
      return;
    }

    try {
      final Verification? pendingVerification =
          await VerificationService.instance.getLatestPendingVerification(
        sessionPrefix: sessionPrefix,
      );
      if (pendingVerification != null) {
        final String? pendingUrl = pendingVerification.verificationUrl;
        if (pendingUrl != null && pendingUrl.isNotEmpty) {
          final Uri uri = Uri.parse(pendingUrl);
          if (await canLaunchUrl(uri)) {
            _activeVerificationSessionId = pendingVerification.sessionId;
            _diditVerificationLaunched = true;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verificationInProgress),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } catch (_) {
      // Continue to create a new session if pending lookup fails.
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(l10n.creatingVerificationSession),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await VerificationService.instance.createVerificationSession(
        workflowIdOverride: requireFullKyc
            ? DiditConfig.workflowId
            : DiditConfig.reauthWorkflowId,
        sessionPrefix: requireFullKyc ? 'didit_kyc' : 'didit_cert',
      );
      final String verificationUrl = result['url'] as String;
      final Verification? createdVerification = result['verification'] as Verification?;
      _activeVerificationSessionId = createdVerification?.sessionId;

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      final uri = Uri.parse(verificationUrl);
      if (await canLaunchUrl(uri)) {
        _diditVerificationLaunched = true;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showErrorSnackBar(l10n.couldNotOpenVerificationLink);
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        _showErrorSnackBar(
          l10n.failedToStartVerification(e.toString().replaceFirst('Exception: ', '')),
        );
      }
    }
  }

  Future<void> _showPublishBlockedByVerificationDialog({
    required bool planActive,
    required String identityStatusText,
    required Color identityStatusColor,
    required String reauthStatusText,
    required Color reauthStatusColor,
    required bool requireFullKyc,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;

        Widget statusRow({
          required IconData icon,
          required String label,
          required String statusText,
          required Color statusColor,
        }) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          title: Text(l10n.wasiatCertificateDialogTitle),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wasiatPublishVerificationChecklistTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                statusRow(
                  icon: Icons.verified_rounded,
                  label: l10n.wasiatEligibilityPlanStatusLabel,
                  statusText: planActive
                      ? l10n.wasiatEligibilityStatusActive
                      : l10n.wasiatEligibilityStatusInactive,
                  statusColor: planActive ? Colors.green.shade700 : Colors.red.shade700,
                ),
                statusRow(
                  icon: Icons.badge_outlined,
                  label: l10n.wasiatEligibilityDiditKycStatusLabel,
                  statusText: identityStatusText,
                  statusColor: identityStatusColor,
                ),
                statusRow(
                  icon: Icons.shield_outlined,
                  label: l10n.wasiatEligibilityDiditStatusLabel,
                  statusText: reauthStatusText,
                  statusColor: reauthStatusColor,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.wasiatPublishVerificationSettingsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _startDiditKycVerification(requireFullKyc: requireFullKyc);
              },
              child: Text(l10n.startVerification),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _validateCertificateEligibility() async {
    Verification? latestApprovedKyc;
    Verification? latestPendingKyc;
    Verification? latestDeclinedKyc;
    Verification? latestRejectedKyc;
    try {
      latestApprovedKyc = await VerificationService.instance.getLatestVerificationFiltered(
        statuses: const <String>['verified', 'approved', 'accepted'],
      );
      latestPendingKyc = await VerificationService.instance.getLatestPendingVerification(
        sessionPrefix: 'didit_kyc_',
      );
      latestDeclinedKyc = await VerificationService.instance.getLatestVerificationFiltered(
        statuses: const <String>['declined'],
        sessionPrefix: 'didit_kyc_',
      );
      latestRejectedKyc = await VerificationService.instance.getLatestVerificationFiltered(
        statuses: const <String>['rejected', 'failed'],
        sessionPrefix: 'didit_kyc_',
      );
    } catch (_) {}

    final bool hasApprovedKyc = latestApprovedKyc != null;

    int? verificationId;
    bool hasPendingReauth = false;
    try {
      if (hasApprovedKyc) {
        // Returning user flow: prefer fresh certificate re-auth sessions.
        verificationId = await WasiatGeneratedDocumentService.instance
            .pickUnusedVerifiedVerificationId(
          sessionPrefix: 'didit_cert_',
          requireAfterLatestGenerated: true,
        );
        if (verificationId == null) {
          final Verification? pending =
              await VerificationService.instance.getLatestPendingVerification(
            sessionPrefix: 'didit_cert_',
          );
          hasPendingReauth = pending != null;
        }
      } else {
        verificationId = await WasiatGeneratedDocumentService.instance
            .pickUnusedVerifiedVerificationId(
          sessionPrefix: 'didit_kyc_',
          requireAfterLatestGenerated: false,
        );
      }
    } catch (_) {
      verificationId = null;
    }

    final bool isDiditKycVerified = verificationId != null;
    if (!isDiditKycVerified) {
      final l10n = AppLocalizations.of(context)!;
      final String identityStatusText = hasApprovedKyc
          ? l10n.wasiatEligibilityStatusComplete
          : (latestPendingKyc != null
              ? l10n.pending
              : latestDeclinedKyc != null
                  ? l10n.declined
                  : latestRejectedKyc != null
                      ? l10n.rejected
              : l10n.wasiatEligibilityStatusNotComplete);
      final Color identityStatusColor = hasApprovedKyc
          ? Colors.green.shade700
          : (latestPendingKyc != null ? Colors.orange.shade700 : Colors.red.shade700);

      final String reauthStatusText = hasApprovedKyc
          ? (hasPendingReauth ? l10n.pending : l10n.wasiatEligibilityStatusNotComplete)
          : l10n.wasiatEligibilityStatusNotComplete;
      final Color reauthStatusColor = hasApprovedKyc
          ? (hasPendingReauth ? Colors.orange.shade700 : Colors.red.shade700)
          : Colors.red.shade700;

      await _showPublishBlockedByVerificationDialog(
        planActive: _planStatus.isSubscribed,
        identityStatusText: identityStatusText,
        identityStatusColor: identityStatusColor,
        reauthStatusText: reauthStatusText,
        reauthStatusColor: reauthStatusColor,
        requireFullKyc: !hasApprovedKyc,
      );
      return null;
    }

    return verificationId;
  }

  Future<void> _openCertificateShareSheet(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareLinkCopiedToClipboard),
          backgroundColor: Colors.green,
        ),
      );
    }

    Future<void> systemShare() async {
      await Share.share(url);
    }

    Widget quickAction({required IconData icon, required String label, required VoidCallback onTap}) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(icon, color: cs.onSurface, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wasiatShareSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.wasiatShareSheetSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          url,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: copy,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: l10n.copy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    quickAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: l10n.wasiatShareSheetMessages,
                      onTap: () {
                        Navigator.of(context).pop();
                        systemShare();
                      },
                    ),
                    const SizedBox(width: 8),
                    quickAction(
                      icon: Icons.email_outlined,
                      label: l10n.wasiatShareSheetEmail,
                      onTap: () {
                        Navigator.of(context).pop();
                        systemShare();
                      },
                    ),
                    const SizedBox(width: 8),
                    quickAction(
                      icon: Icons.send_rounded,
                      label: l10n.wasiatShareSheetTelegram,
                      onTap: () {
                        Navigator.of(context).pop();
                        systemShare();
                      },
                    ),
                    const SizedBox(width: 8),
                    quickAction(
                      icon: Icons.forum_outlined,
                      label: l10n.wasiatShareSheetWhatsApp,
                      onTap: () {
                        Navigator.of(context).pop();
                        systemShare();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          copy();
                        },
                        child: Text(l10n.copy),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          systemShare();
                        },
                        child: Text(l10n.wasiatShareSheetMore),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWasiatValidationSheet({
    required List<String> issues,
    required List<String> warnings,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Widget section({required String title, required List<String> items, required IconData icon, required Color accent}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            height: 1.25,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.wasiatReviewSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                section(
                  title: l10n.wasiatReviewSheetIssues,
                  items: issues,
                  icon: Icons.error_outline_rounded,
                  accent: Colors.red.shade600,
                ),
                if (issues.isNotEmpty && warnings.isNotEmpty) const SizedBox(height: 6),
                section(
                  title: l10n.wasiatReviewSheetWarnings,
                  items: warnings,
                  icon: Icons.info_outline_rounded,
                  accent: Colors.orange.shade700,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _editWill();
                  },
                  child: Text(l10n.wasiatReviewSheetEditCta),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publishWill({required int verificationId}) async {
    if (_will == null || _will!.id == null) return;

    if (!_planStatus.isSubscribed) {
      await _showPublishBlockedByPlanDialog();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final String url = 'https://sampul.co/view-will?id=${_will!.willCode}';
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isTurningOn = _will!.isDraft == true;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wasiatCertificateDialogTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_planStatus.periodEnd != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.wasiatPublishReadyUntil(
                      DateFormat.yMMMd().format(_planStatus.periodEnd!),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.wasiatPublishReadyShort,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(isTurningOn ? l10n.wasiatCertificateConfirmationPre : l10n.wasiatCertificateConfirmation(url)),
              if (!isTurningOn) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          url,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted) {
                            final l10n = AppLocalizations.of(context)!;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shareLinkCopiedToClipboard),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: l10n.copy,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.wasiatCertificateOn),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final updatedWill = await WillService.instance.updateWill(
        willId: _will!.id!,
        isDraft: false,
      );
      
      // Check if the will was actually published
      if (updatedWill.isDraft == true) {
        _showErrorSnackBar('Failed to publish will: Still marked as draft');
        return;
      }
      
      await _loadWillData();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // Freeze a generated snapshot at publish-time so future edits won't change this version.
      try {
        await _generateSnapshot(verificationId: verificationId);
      } catch (_) {}
      _showSuccessSnackBar(l10n.willPublishedSuccessfully);
      await _showConfettiCelebration();
      await _openCertificateShareSheet(url);
      await NotificationService.instance.createNotification(
        title: l10n.myWill,
        body: l10n.willPublishedSuccessfully,
        type: 'will_published',
        data: _will != null && _will!.id != null
            ? <String, dynamic>{'will_id': _will!.id}
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10n.failedToPublishWill(e.toString()));
    }
  }

  Future<void> _unpublishWill() async {
    if (_will == null || _will!.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    final bool confirmTurnOff = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.wasiatCertificateOff),
            content: Text(
              '${l10n.wasiatCertificateOff}?\n\n${l10n.wasiatPublishVerificationSettingsHint}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.wasiatCertificateOff),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmTurnOff) return;

    try {
      final updatedWill = await WillService.instance.updateWill(
        willId: _will!.id!,
        isDraft: true,
      );
      
      // Check if the will was actually unpublished
      if (updatedWill.isDraft == false) {
        _showErrorSnackBar(l10n.failedToUnpublishWill('Still marked as published'));
        return;
      }
      
      await _loadWillData();
      _showSuccessSnackBar(l10n.willUnpublishedSuccessfully);
    } catch (e) {
      _showErrorSnackBar(l10n.failedToUnpublishWill(e.toString()));
    }
  }

  Future<void> _deleteWill() async {
    if (_will == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteWill),
        content: Text(l10n.areYouSureDeleteWill),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await WillService.instance.deleteWill(_will!.id!);
        _showSuccessSnackBar(l10n.willUpdatedSuccessfully);
        await _loadWillData();
      } catch (e) {
        _showErrorSnackBar(l10n.failedToDeleteWill(e.toString()));
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }


  Future<void> _shareWillDocument() async {
    if (_will == null) return;
    final String url = 'https://sampul.co/view-will?id=${_will!.willCode}';
    await _openCertificateShareSheet(url);
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Widget bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _will == null
            ? _buildNoWillState()
            : _buildWillState();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myWill),
        actions: [
          if (_will != null && _will!.isDraft == false && _docView == _WasiatDocView.certificate)
            IconButton(
              onPressed: _shareWillDocument,
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.shareWill,
            ),
          if (_will != null && _docView == _WasiatDocView.details && _planStatus.isSubscribed)
            IconButton(
              onPressed: _openGeneratedHistoryPicker,
              icon: const Icon(Icons.history_rounded),
              tooltip: l10n.wasiatGeneratedHistoryTitle,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWillData,
        child: bodyContent,
      ),
    );
  }

  Widget _buildNoWillState() {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        children: <Widget>[
          // Scrollable intro content (standardized with trust / hibah / assets)
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.letsCreateYourWill,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.willDescription,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Illustration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Center(
                      child: Image.asset(
                        'assets/will-certificate-scroll.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Why section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.whyCreateYourWillInSampul,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.yourWillPullsFromProfile,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildWillBullet(
                            l10n.keepAllKeyInformation,
                            theme,
                            colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _buildWillBullet(
                            l10n.generateStructuredWillDocument,
                            theme,
                            colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _buildWillBullet(
                            l10n.updateWillLater,
                            theme,
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Fixed CTA button at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _createNewWill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      l10n.startMyWill,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWillBullet(
    String text,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: colorScheme.onPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }

  /// Compact one-line plan status + action (full details on [PlansOverviewScreen]).
  Widget _buildWasiatAccessPanel(AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool active = _planStatus.isSubscribed;
    final DateTime? end = _planStatus.periodEnd;

    final Color bg;
    final Color borderColor;
    final Color accent;
    final IconData icon;
    final String line;

    if (active) {
      bg = cs.primaryContainer.withValues(alpha: 0.4);
      borderColor = cs.primary.withValues(alpha: 0.28);
      accent = cs.primary;
      icon = Icons.verified_rounded;
      line = end != null
          ? l10n.wasiatAccessActiveUntil(DateFormat.yMMMd().format(end))
          : l10n.wasiatAccessActiveNoEndDate;
    } else {
      bg = Colors.amber.shade50;
      borderColor = Colors.amber.shade200;
      accent = Colors.amber.shade900;
      icon = Icons.payment_outlined;
      line = l10n.wasiatAccessInlineInactive;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openWasiatPlan,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _openWasiatPlan,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.only(left: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(active ? l10n.wasiatManagePlan : l10n.wasiatViewPlanAndPay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWillState() {
    final l10n = AppLocalizations.of(context)!;
    final validation = WillService.instance.validateWill(_will!);
    final bool detailsLocked = _docView == _WasiatDocView.details && !_planStatus.isSubscribed;

    return Column(
      children: [
        // Clean Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWasiatAccessPanel(l10n),
            ],
          ),
        ),

        // Compact Validation Alert
        if (!validation['isValid'] || (validation['warnings'] as List).isNotEmpty)
          Material(
            color: validation['isValid'] ? Colors.orange.shade50 : Colors.red.shade50,
            child: InkWell(
              onTap: () => _showWasiatValidationSheet(
                issues: List<String>.from(validation['issues'] as List),
                warnings: List<String>.from(validation['warnings'] as List),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      validation['isValid'] ? Icons.info_outline_rounded : Icons.error_outline_rounded,
                      color: validation['isValid'] ? Colors.orange.shade700 : Colors.red.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        validation['isValid']
                            ? l10n.warningsReviewRecommended((validation['warnings'] as List).length)
                            : l10n.issuesActionRequired((validation['issues'] as List).length),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: validation['isValid'] ? Colors.orange.shade800 : Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _editWill,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.edit),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _isDeleting ? null : _deleteWill,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(_isDeleting ? l10n.deleting : l10n.delete),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (_docView == _WasiatDocView.certificate)
                TextButton.icon(
                  onPressed: _onPublishPressed,
                  icon: Icon(
                    _will!.isDraft == true ? Icons.publish_outlined : Icons.unpublished_outlined,
                    size: 16,
                  ),
                  label: Text(_will!.isDraft == true ? l10n.wasiatCertificateOn : l10n.wasiatCertificateOff),
                  style: TextButton.styleFrom(
                    foregroundColor: _will!.isDraft == true && !_planStatus.isSubscribed
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make segments equal-width so the thumb stays centered.
                    final double segmentWidth = (constraints.maxWidth - 8) / 2;
                    Widget segment(String text) => SizedBox(
                          width: segmentWidth,
                          child: Center(
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.labelLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                    Widget detailsSegment(String text) => SizedBox(
                          width: segmentWidth,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  text,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );

                    return CupertinoSlidingSegmentedControl<_WasiatDocView>(
                      groupValue: _docView,
                      padding: const EdgeInsets.all(4),
                      thumbColor: Theme.of(context).colorScheme.surface,
                      backgroundColor: Colors.transparent,
                      children: <_WasiatDocView, Widget>{
                        _WasiatDocView.certificate: segment(l10n.wasiatViewCertificateTab),
                        _WasiatDocView.details: detailsSegment(l10n.wasiatViewDetailsTab),
                      },
                      onValueChanged: (_WasiatDocView? next) {
                        if (next == null || _docView == next) return;
                        setState(() => _docView = next);
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      },
                    );
                  },
                ),
              ),
              if (_docView == _WasiatDocView.details) ...[
                const SizedBox(height: 8),
                if (_planStatus.isSubscribed && _selectedGenerated != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.wasiatViewingGeneratedVersion(
                              DateFormat.yMMMd().add_jm().format(_selectedGenerated!.createdAt ?? DateTime.now()),
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _openGeneratedHistoryPicker,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.change),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        // Data Sync Notice removed (redundant with review page)

        // Action bar removed (actions live above the switch)

        // Will Document Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: detailsLocked
                ? _buildLockedWasiatDetailsPreview()
                : _buildPaperWill(
                    view: _docView,
                    generated: _docView == _WasiatDocView.details ? _selectedGenerated : null,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedWasiatDetailsPreview() {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    const double pageHeight = 720;

    return Stack(
      children: [
        // Keep content visible, but obscured behind a "glass" layer.
        _buildPaperWill(view: _WasiatDocView.details, locked: true),
        // Glass overlay (transparent + subtle blur)
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Slight tint so it's harder to read, but still visible.
                color: cs.surface.withOpacity(0.05),
              ),
            ),
          ),
        ),
        // Centered lock + small CTA under it (repeated per "page")
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int pageCount = (constraints.maxHeight / pageHeight).ceil().clamp(1, 999);

              Widget lockAndCta() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: cs.surfaceContainerHighest.withOpacity(0.70),
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.16),
                      shape: CircleBorder(
                        side: BorderSide(color: cs.outline.withOpacity(0.14)),
                      ),
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: cs.onSurface.withOpacity(0.88),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: _openWasiatPlan,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            visualDensity: VisualDensity.standard,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.wasiatUpgradePlanCta),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: List.generate(pageCount, (i) {
                  return SizedBox(
                    height: i == pageCount - 1
                        ? (constraints.maxHeight - (pageHeight * (pageCount - 1))).clamp(0, pageHeight)
                        : pageHeight,
                    child: Center(child: lockAndCta()),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaperWill({
    required _WasiatDocView view,
    bool locked = false,
    WasiatGeneratedDocument? generated,
  }) {
    final Map<String, dynamic>? snap = generated?.snapshot;
    final Map<String, dynamic>? snapWill = snap?['will'] is Map ? Map<String, dynamic>.from(snap!['will'] as Map) : null;
    final Map<String, dynamic>? snapProfile =
        snap?['user_profile'] is Map ? Map<String, dynamic>.from(snap!['user_profile'] as Map) : null;
    final List<Map<String, dynamic>> snapFamily = (snap?['family_members'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        _familyMembers;
    final List<Map<String, dynamic>> snapAssets = (snap?['assets'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        _assets;
    final Map<String, dynamic>? snapWishes =
        snap?['extra_wishes'] is Map ? Map<String, dynamic>.from(snap!['extra_wishes'] as Map) : null;

    final Will will = snapWill != null ? Will.fromJson(snapWill) : _will!;
    // In practice, `_userProfile` is always available when `_will` is available.
    // For snapshot mode, we prefer the frozen profile from the snapshot.
    final UserProfile profile = snapProfile != null ? UserProfile.fromJson(snapProfile) : _userProfile!;
    final ExtraWishes? wishes = snapWishes != null ? ExtraWishes.fromJson(snapWishes) : _extraWishes;

    String coSampulUtama() => _getCoSampulUtama(will: will, familyMembers: snapFamily);
    String coSampulGanti() => _getCoSampulGanti(will: will, familyMembers: snapFamily);
    String coSampulGantiNric() => _getCoSampulGantiNric(will: will, familyMembers: snapFamily);
    String guardianUtama() => _getGuardianUtama(will: will, familyMembers: snapFamily);
    String guardianUtamaNric() => _getGuardianUtamaNric(will: will, familyMembers: snapFamily);
    String guardianGanti() => _getGuardianGanti(will: will, familyMembers: snapFamily);
    String guardianGantiNric() => _getGuardianGantiNric(will: will, familyMembers: snapFamily);

    final bool isMuslim = profile.isMuslim;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE), // Slightly off-white for paper effect
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Paper texture lines
          Positioned.fill(
            child: CustomPaint(
              painter: PaperTexturePainter(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (view == _WasiatDocView.certificate) ...[
                  _buildPaperHeader(isMuslim: isMuslim),
                ] else ...[
                  Center(
                    child: Text(
                      isMuslim ? 'WASIAT ASET SAYA' : 'MY ASSETS WILL',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isMuslim) ...[
                  _buildPaperSection(
                    '1. Mukaddimah',
                    [
                      'Dengan nama Allah, Yang Maha Pengasih, Lagi Maha Penyayang, saya, ${will.nricName ?? profile.displayName}, memegang NRIC ${profile.nricNo ?? 'Not provided'}, bermastautin di ${_formatAddress(profile)}, mengisytiharkan dokumen ini sebagai wasiat terakhir saya, memberi tumpuan kepada pengurusan aset saya.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '2. Pengisytiharan',
                    [
                      'Mengakui kepercayaan Islam saya, saya berazam untuk mengisytiharkan wasiat terakhir saya untuk aset saya, yang ditulis pada ${_formatDateMalay(DateTime.now())}.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '3. Permintaan',
                    [
                      'Saya menyeru keluarga saya untuk menegakkan ketaqwaan kepada Allah S.W.T dan menunaikan perintah-Nya. Apabila saya meninggal dunia, harta saya hendaklah diuruskan dengan teliti mengikut prinsip Islam. Saya memohon harta pusaka saya sebagai keutamaan digunakan untuk mengendalikan perbelanjaan pengebumian dan menyelesaikan hutang kepada Allah S.W.T dan manusia, termasuk Zakat dan kewajipan agama lain.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '4. Wasiat Pelengkap',
                    [
                      'Wasiat ini adalah wasiat pelengkap yang terhad kepada aset yang disenaraikan dalam Jadual 1 sahaja.',
                      'Semua wasiat terdahulu berkaitan aset lain kekal sah dan berkuat kuasa jika ada.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '5. Pelaksana Utama dan Pentadbir Bersama',
                    [
                      'Sampul Sdn Bhd (202301027717) dilantik sebagai pentadbir bersama ${coSampulUtama()} sebagai pelaksana utama untuk menyimpan dan menyampaikan wasiat aset saya kepada waris saya.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '6. Pelaksana Ganti',
                    [
                      'Jika perlu, ${coSampulGanti()}, ${coSampulGantiNric()} akan bertindak sebagai pelaksana ganti.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '7. Penyelesaian Hutang dan Tanggungjawab Berkaitan Hutang',
                    [
                      'Saya berharap waris tersayang saya akan melunaskan hutang-hutang saya yang tidak mempunyai perlindungan Takaful seperti yang disenaraikan dalam Jadual 1 dan juga melunaskan tanggungjawab berkaitan hutang yang lain seperti Nazar/Kaffarah/Fidyah saya yang berbaki yang tidak sempat saya sempurnakan ketika hidup dan diambil daripada harta pusaka saya seperti berikut:',
                      '',
                      'Nazar/Kaffarah: ' + ((wishes?.nazarWishes ?? '').trim().isEmpty ? '-' : wishes!.nazarWishes!),
                      'Anggaran Kos: RM ' + ((wishes?.nazarEstimatedCostMyr ?? 0).toStringAsFixed(2)),
                      'Fidyah: ' + ((wishes?.fidyahFastLeftDays ?? 0).toString()) + ' hari',
                      'Kos: RM ' + ((wishes?.fidyahAmountDueMyr ?? 0).toStringAsFixed(2)),
                      'Derma Organ: ' + ((wishes?.organDonorPledge ?? false) ? 'Saya dengan ini bersetuju sebagai penderma organ.' : 'Saya dengan ini tidak bersetuju sebagai penderma organ.'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '8. Penjelasan Kos Pentadbiran Harta Pusaka dan Agihan Pendahuluan',
                    [
                      'Saya membenarkan waris saya setelah melantik pentadbir atau pemegang amanah atau Wasi untuk menjelaskan segala perbelanjaan bagi pentadbiran harta pusaka daripada harta pusaka saya. Saya juga membenarkan sekiranya perlu dikeluarkan satu jumlah yang muhasabah sebagai nafkah perbelanjaan bulanan bagi waris di bawah tanggungan saya dan jumlah itu ditolak daripada bahagian harta pusaka yang akan diterima oleh waris saya semasa agihan akhir sekiranya proses tuntutan pusaka mengambil masa yang lama daripada sepatutnya.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '9. Pengagihan Aset',
                    [
                      'Sehingga ⅓: Aset tertentu kepada bukan waris atau disedekahkan atau diwaqafkan kepada pihak tertentu seperti di [Jadual 2].',
                      '',
                      'Penerima Hadiah (Hibah): Aset tertentu ditetapkan untuk penerima tertentu secara terus tertakluk kepada persetujuan waris Faraid yang berhak seperti di [Jadual 1]',
                      '',
                      'Faraid: Aset tertentu ditetapkan untuk penerima tertentu berdasarkan pembahagian Faraid seperti di [Jadual 1].',
                      '',
                      'Baki Harta: Selebihnya aset saya yang tidak dinyatakan secara khusus akan diagihkan sewajarnya sama ada kepada penerima tertentu tertakluk kepada persetujuan waris Faraid atau berdasarkan pembahagian Faraid.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '10. Penjagaan Anak',
                    ['N/A'],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '11. Tanda Tangan',
                    [
                      'Direkod untuk:',
                      '${will.nricName ?? profile.displayName}',
                      'NRIC: ${profile.nricNo ?? 'Not provided'}',
                      'Tarikh: ${_formatDateMalay(DateTime.now())}',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '12. Notis',
                    [
                      'Walaupun platform kami menyediakan perkhidmatan digital untuk membuat wasiat, kami amat menggalakkan anda mencetak wasiat yang telah dilengkapkan dan menandatanganinya secara fizikal untuk simpanan peribadi anda. Sekiranya timbul sebarang pertikaian pada masa hadapan, salinan wasiat yang ditandatangani secara fizikal akan memberikan kepastian undang-undang. Salinan bercetak dan bertandatangan ini boleh bertindak sebagai sandaran kepada rekod digital anda.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '13. Saksi',
                    [
                      'Diperakui oleh',
                      'Muhammad Arham Munir Merican bin Amir Feisal Merican',
                      '931011875001',
                      'Pengasas, SAMPUL',
                      'pada ${_formatDateMalay(DateTime.now())}',
                      '',
                      'Diperakui oleh',
                      'Mohamad Hafiz bin Che Hamid',
                      '950208035341',
                      'Pembangun Perisian, SAMPUL',
                      'pada ${_formatDateMalay(DateTime.now())}',
                      '',
                      'Diperakui oleh (saksi tambahan jika perlu):',
                      'Nama:',
                      'No IC:',
                      'Hubungan:',
                      'Tarikh:',
                      '',
                      'Diperakui oleh (saksi tambahan jika perlu):',
                      'Nama:',
                      'No IC:',
                      'Hubungan:',
                      'Tarikh:',
                    ],
                  ),
                ] else ...[
                  _buildPaperSection(
                    '1. Declaration',
                    [
                      'I, ${will.nricName ?? profile.displayName}, ${profile.nricNo ?? 'Not provided'}, ${_formatAddress(profile)}, declare this document, created on ${_formatDateMalay(DateTime.now())}, as my Last Will and Testament for my assets.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '2. Supplementary Will',
                    [
                      'This Will complements any existing Wills and is limited solely to the assets listed in Table 1 of this document.',
                      'All previous Wills concerning other assets remain valid and in effect.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '3. Joint executors',
                    [
                      'I hereby appoint the following as co-executors of this Will:',
                      '',
                      'a) Sampul Sdn Bhd (202301027717)',
                      '',
                      'b) ${coSampulUtama()} (your executor)',
                      '',
                      'Both shall act jointly to safekeep and deliver this Will and Testament of my assets to my beneficiaries.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '4. Substitute executor',
                    [
                      'If necessary, ${coSampulGanti()}, ${coSampulGantiNric()} will act as substitute executor.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '5. Assets Distribution',
                    [
                      'Specific Bequests: Certain assets are designated for specific beneficiaries as per [Table 1].',
                      '',
                      'Residual Estate: The rest of my assets not specifically mentioned are to be distributed accordingly.',
                      '',
                      'Additional Bequests: For charity, [Charitable Body] is designated as per [Table 2].',
                      '',
                      'Organ Donation: ${(wishes?.organDonorPledge ?? false) ? 'I hereby Agree to donate my organ at the point of demise.' : 'I do not agree to donate my organ at the point of demise.'}',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '6. Guardianship',
                    [
                      'If my spouse/partner predeceases me or is unable, ${guardianUtama()}, ${guardianUtamaNric()} is appointed for my minor children, with ${guardianGanti()}, ${guardianGantiNric()} as an alternate as per [Table 1].',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '7. Predecease Condition',
                    [
                      'If any beneficiary predeceases me, their share shall be redistributed among the remaining beneficiaries or as specified in this Will.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '8. Signature',
                    [
                      'Recorded for:',
                      '${will.nricName ?? profile.displayName}',
                      'IC: ${profile.nricNo ?? 'Not provided'}',
                      'Date: ${_formatDateMalay(DateTime.now())}',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '9. Notice',
                    [
                      'While our platform provides a digital service for creating wills, we strongly recommend that you print out your completed will and sign it physically for your personal safekeeping. In the event of any potential disputes, a physically signed copy of your will shall provide legal certainty. This printed and signed version can serve as a tangible backup to your digital records.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPaperSection(
                    '10. Witnesses',
                    [
                      'Witnessed by',
                      'Muhammad Arham Munir Merican bin Amir Feisal Merican',
                      '931011875001',
                      'Founder, SAMPUL',
                      'on ${_formatDateMalay(DateTime.now())}',
                      '',
                      'Witnessed by',
                      'Mohamad Hafiz bin Che Hamid',
                      '950208035341',
                      'Software Developer, SAMPUL',
                      'on ${_formatDateMalay(DateTime.now())}',
                      '',
                      'Witnessed by (additional witness if needed):',
                      'Name:',
                      'IC Number:',
                      'Relationship:',
                      'Date:',
                      '',
                      'Witnessed by (additional witness if needed):',
                      'Name:',
                      'IC Number:',
                      'Relationship:',
                      'Date:',
                    ],
                  ),
                ],

                // Page Break
                Container(
                  width: double.infinity,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: CustomPaint(
                    painter: DottedLinePainter(),
                  ),
                ),
                
                // Assets List
                _buildAssetsListFrom(assets: snapAssets),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperHeader({required bool isMuslim}) {
    return Container(
      height: 600, // Fixed height for first page
      child: Column(
        children: [
          // Top spacing
          const SizedBox(height: 60),
          
          // Sampul Logo
          Center(
            child: SvgPicture.network(
              'https://sampul.co/images/Logo.svg',
              height: 35,
              placeholderBuilder: (BuildContext context) => Container(
                height: 35,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            isMuslim ? 'WASIAT' : 'Will and Testament for Digital Asset',
            style: TextStyle(
              fontSize: isMuslim ? 24 : 18,
              fontWeight: FontWeight.bold,
              letterSpacing: isMuslim ? 3 : 1.2,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Author section
          Column(
            children: [
              Text(
                isMuslim ? 'ditulis oleh' : 'of',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _will!.nricName ?? _userProfile?.displayName ?? 'Not provided',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Will ID: ${_will!.willCode}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Website
          Text(
            'Securing Digital Legacies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'https://sampul.co',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          // Information notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isMuslim
                  ? 'Salinan sijil dan perincian penuh wasiat boleh didapati dalam peti simpanan digital Sampul. Sebarang maklumat dan pertanyaan, sila emel kepada hello@sampul.co'
                  : 'A copy of this certificate and details of the will is stored in Sampul digital vault. For queries and info please email hello@sampul.co',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),

          // Footer - End of first page
          Text(
            'Powered by Sampul',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaperSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Section Content
        ...content.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        )),
      ],
    );
  }


  String _formatAddress(UserProfile profile) {
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _formatDateMalay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogs', 'Sep', 'Okt', 'Nov', 'Dis'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  String _getCoSampulUtama({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.coSampul1 == null) return '[PRIMARY EXECUTOR NAME/NICKNAME]';
    
    final executor = members.firstWhere(
      (member) => member['id'] == w!.coSampul1,
      orElse: () => {'name': '[PRIMARY EXECUTOR NAME/NICKNAME]'},
    );
    
    return executor['name'] ?? '[PRIMARY EXECUTOR NAME/NICKNAME]';
  }

  String _getCoSampulGanti({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.coSampul2 == null) return '[SECONDARY EXECUTOR NAME/NICKNAME]';
    
    final executor = members.firstWhere(
      (member) => member['id'] == w!.coSampul2,
      orElse: () => {'name': '[SECONDARY EXECUTOR NAME/NICKNAME]'},
    );
    
    return executor['name'] ?? '[SECONDARY EXECUTOR NAME/NICKNAME]';
  }

  String _getCoSampulGantiNric({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.coSampul2 == null) return '[SECONDARY EXECUTOR NRIC NO]';
    
    final executor = members.firstWhere(
      (member) => member['id'] == w!.coSampul2,
      orElse: () => {'nric_no': '[SECONDARY EXECUTOR NRIC NO]'},
    );
    
    return executor['nric_no'] ?? '[SECONDARY EXECUTOR NRIC NO]';
  }

  String _getGuardianUtama({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.guardian1 == null) return '[Guardian Name]';
    final guardian = members.firstWhere(
      (member) => member['id'] == w!.guardian1,
      orElse: () => {'name': '[Guardian Name]'},
    );
    return guardian['name'] ?? '[Guardian Name]';
  }

  String _getGuardianUtamaNric({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.guardian1 == null) return '[IC]';
    final guardian = members.firstWhere(
      (member) => member['id'] == w!.guardian1,
      orElse: () => {'nric_no': '[IC]'},
    );
    return guardian['nric_no'] ?? '[IC]';
  }

  String _getGuardianGanti({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.guardian2 == null) return '[Guardian Name 2]';
    final guardian = members.firstWhere(
      (member) => member['id'] == w!.guardian2,
      orElse: () => {'name': '[Guardian Name 2]'},
    );
    return guardian['name'] ?? '[Guardian Name 2]';
  }

  String _getGuardianGantiNric({Will? will, List<Map<String, dynamic>>? familyMembers}) {
    final Will? w = will ?? _will;
    final List<Map<String, dynamic>> members = familyMembers ?? _familyMembers;
    if (w?.guardian2 == null) return '[IC]';
    final guardian = members.firstWhere(
      (member) => member['id'] == w!.guardian2,
      orElse: () => {'nric_no': '[IC]'},
    );
    return guardian['nric_no'] ?? '[IC]';
  }

  Widget _buildAssetsListFrom({required List<Map<String, dynamic>> assets}) {
    if (assets.isEmpty) {
      return _buildPaperSection(
        'SENARAI ASET',
        [
          'Tiada aset didaftarkan pada masa ini.',
          '',
          'Untuk menambah aset, sila gunakan fungsi "Tambah Aset" dalam aplikasi.',
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'JADUAL 1: SENARAI ASET',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        // Flat list of all assets (physical + digital), simple like web
        ...assets.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final asset = entry.value;
            final value = _safeParseDouble(asset['value']);
            final instructionsRaw = asset['instructions_after_death'];
            final instructions = _formatInstructions(instructionsRaw);
            final remarks = asset['remarks'] ?? '';

            return _buildAssetCard(
              index: index + 1,
              name: asset['name'] ?? '-',
              typeLabel: '',
              value: value,
              percentage: '',
              details: const [],
              instructions: instructions,
              instructionsRaw: instructionsRaw,
              remarks: remarks,
            );
          },
        ),

      ],
    );
  }


  Widget _buildAssetCard({
    required int index,
    required String name,
    required String typeLabel,
    required double value,
    required String percentage,
    required List<String> details,
    required String instructions,
    required dynamic instructionsRaw,
    required String remarks,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. $name',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (typeLabel.isNotEmpty) const SizedBox(height: 2),
                    if (typeLabel.isNotEmpty)
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  if (percentage.isNotEmpty) const SizedBox(height: 2),
                  if (percentage.isNotEmpty)
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Instruction chip
          if (instructions.isNotEmpty)
            Row(
              children: [
                _buildInstructionChip(instructionsRaw),
              ],
            ),

          if (instructions.isNotEmpty) const SizedBox(height: 8),

          // Details
          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
            ),
          ),

          if (remarks.isNotEmpty) const SizedBox(height: 6),
          if (remarks.isNotEmpty)
            Text(
              'Catatan: $remarks',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionChip(dynamic instructionRaw) {
    final String normalized = (instructionRaw ?? '').toString().toLowerCase();
    final String label = _formatInstructions(instructionRaw);
    final Color bgColor;
    final Color textColor;

    switch (normalized) {
      case 'faraid':
        bgColor = const Color(0xFFE7F5EC);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'terminate':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        break;
      case 'transfer_as_gift':
        bgColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF5E35B1);
        break;
      case 'settle':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _formatInstructions(String? instruction) {
    switch ((instruction ?? '').toLowerCase()) {
      case 'faraid':
        return 'Faraid';
      case 'terminate':
        return 'Terminate Subscriptions';
      case 'transfer_as_gift':
        return 'Transfer as Gift';
      case 'settle':
        return 'Settle Debts';
      default:
        return instruction ?? '';
    }
  }

  /// Helper function to safely parse any dynamic value to double
  /// Handles String, num, and null types
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw subtle horizontal lines to simulate paper texture
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    const double dashWidth = 5;
    const double dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

