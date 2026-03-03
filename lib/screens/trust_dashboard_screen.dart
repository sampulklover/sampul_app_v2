import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'trust_edit_screen.dart';
import 'fund_support_config_screen.dart';
import '../utils/card_decoration_helper.dart';
import '../widgets/trust_payment_form_modal.dart';
import '../widgets/trust_payment_history_modal.dart';
import '../widgets/payment_status_modal.dart';

class TrustDashboardScreen extends StatefulWidget {
  final Trust trust;
  /// When true, shows a one-time "trust created" welcome dialog
  /// the first time the user lands on this screen (e.g. right
  /// after finishing the creation flow).
  final bool showWelcome;

  const TrustDashboardScreen({
    super.key,
    required this.trust,
    this.showWelcome = false,
  });

  @override
  State<TrustDashboardScreen> createState() => _TrustDashboardScreenState();
}

class _TrustDashboardScreenState extends State<TrustDashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isCopyCooldown = false;
  Timer? _cooldownTimer;
  /// Local copy of trust so we can refresh after editing fund support config.
  Trust? _currentTrust;
  // Family members (beneficiaries) so we can show profile avatars in cards.
  List<Map<String, dynamic>> _familyMembers = <Map<String, dynamic>>[];
  // Track if we're waiting for a payment to complete
  String? _pendingPaymentId;
  // Track previous payment count to detect new payments
  int _previousPaymentCount = 0;

  Trust get _trust => _currentTrust ?? widget.trust;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTrust = widget.trust;
    _previousPaymentCount = _trust.trustPayments?.length ?? 0;
    _loadData();
    if (widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Small delay so the user can first see the dashboard content
        // before the welcome dialog appears.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _showWelcomeDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, check if payment was completed
    if (state == AppLifecycleState.resumed) {
      _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_trust.id == null) return;
    
    try {
      // Reload trust data to get latest payment status
      final updatedTrust = await TrustService.instance.getTrustWithPayments(_trust.id!);
      if (!mounted || updatedTrust == null) return;

      final currentPaymentCount = updatedTrust.trustPayments?.length ?? 0;
      
      // If we have a new payment or payment count changed, show status
      if (currentPaymentCount > _previousPaymentCount) {
        // New payment detected
        final latestPayment = updatedTrust.trustPayments?.last;
        if (latestPayment != null) {
          setState(() {
            _currentTrust = updatedTrust;
            _previousPaymentCount = currentPaymentCount;
          });
          
          // Show payment status modal
          if (mounted) {
            final isSuccess = latestPayment.isSuccessful;
            showDialog(
              context: context,
              builder: (context) => PaymentStatusModal(
                isSuccess: isSuccess,
                message: isSuccess
                    ? 'Your payment of ${latestPayment.formattedAmount} has been processed successfully.'
                    : 'Your payment could not be processed. Please try again.',
              ),
            );
          }
        }
      } else if (_pendingPaymentId != null) {
        // Check if pending payment status changed
        final pendingPayment = updatedTrust.trustPayments?.firstWhere(
          (p) => p.id == _pendingPaymentId,
          orElse: () => throw StateError('Payment not found'),
        );
        
        if (pendingPayment != null) {
          final isSuccess = pendingPayment.isSuccessful;
          if (isSuccess || pendingPayment.status == 'failed') {
            setState(() {
              _currentTrust = updatedTrust;
              _pendingPaymentId = null;
            });
            
            // Show payment status modal
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => PaymentStatusModal(
                  isSuccess: isSuccess,
                  message: isSuccess
                      ? 'Your payment of ${pendingPayment.formattedAmount} has been processed successfully.'
                      : 'Your payment could not be processed. Please try again.',
                ),
              );
            }
          }
        }
      } else {
        // Just refresh the data
        setState(() {
          _currentTrust = updatedTrust;
          _previousPaymentCount = currentPaymentCount;
        });
      }
    } catch (e) {
      print('🔴 [TRUST DASHBOARD] Error checking payment status: $e');
      // Fail silently - user can manually refresh
    }
  }

  Future<void> _loadData() async {
    // If the widget is no longer in the tree, bail out early to avoid
    // looking up inherited widgets or calling setState on a deactivated context.
    if (!mounted) return;

    if (widget.trust.id == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    // Load family members so we can resolve beneficiary profiles per category.
    await _fetchFamilyMembers();

    // Reload trust with payment data
    if (widget.trust.id != null) {
      try {
        final updatedTrust = await TrustService.instance.getTrustWithPayments(widget.trust.id!);
        if (mounted && updatedTrust != null) {
          setState(() => _currentTrust = updatedTrust);
        }
      } catch (_) {
        // Fail silently if payment data can't be loaded
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        return;
      }

      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id, name, image_path, relationship, type')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _familyMembers = rows.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // Fail silently; beneficiary avatars are a UX enhancement only.
      if (!mounted) return;
      setState(() {
        _familyMembers = <Map<String, dynamic>>[];
      });
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'RM 0.00';
    return 'RM ${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  Future<void> _showPaymentForm() async {
    if (_trust.id == null) return;
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrustPaymentFormModal(trust: _trust),
    );

    // If payment was initiated, refresh data
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showPaymentHistory() async {
    if (_trust.id == null) return;
    
    // Reload trust with latest payment data
    try {
      final updatedTrust = await TrustService.instance.getTrustWithPayments(_trust.id!);
      if (mounted && updatedTrust != null) {
        setState(() => _currentTrust = updatedTrust);
      }
    } catch (_) {
      // Fail silently
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TrustPaymentHistoryModal(trust: _currentTrust ?? _trust),
      );
    }
  }

  String _formatEstimatedNetWorth(String? estimatedNetWorth) {
    if (estimatedNetWorth == null || estimatedNetWorth.isEmpty) {
      return 'RM0.00';
    }
    // Try to parse as number, if it's a range string, just return it formatted
    try {
      final num = double.tryParse(estimatedNetWorth);
      if (num != null) {
        return 'RM${num.toStringAsFixed(2)}';
      }
    } catch (_) {}
    // If it's a string like "below_rm_50k", format it nicely
    return estimatedNetWorth.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'\brm\b', caseSensitive: false),
      (match) => 'RM',
    );
  }

  String _getStatusLabel(TrustStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case TrustStatus.submitted:
        return l10n.submitted;
      case TrustStatus.approved:
        return l10n.yourPlanIsActive;
      case TrustStatus.rejected:
        return l10n.rejected;
      case TrustStatus.draft:
        return l10n.draft;
    }
  }

  Color _getStatusColor(TrustStatus status, BuildContext context) {
    switch (status) {
      case TrustStatus.submitted:
        return Colors.blue.shade600;
      case TrustStatus.approved:
        return Colors.green;
      case TrustStatus.rejected:
        return Colors.red.shade700;
      case TrustStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  // Get category configuration from fund support configs
  Map<String, dynamic>? _getCategoryConfig(String categoryId) {
    return _trust.fundSupportConfigs?[categoryId] as Map<String, dynamic>?;
  }

  // Calculate amount for a category based on its configuration
  double _calculateCategoryAmount(String categoryId) {
    final config = _getCategoryConfig(categoryId);
    if (config == null) return 0.0;

    // For regular payments, use paymentAmount
    final isRegularPayments = config['isRegularPayments'] as bool?;
    if (isRegularPayments == true) {
      final paymentAmount = (config['paymentAmount'] as num?)?.toDouble() ?? 0.0;
      return paymentAmount;
    }

    // For charitable category, sum up charity amounts
    if (categoryId == 'charitable') {
      final charitiesData = config['charities'] as List?;
      if (charitiesData != null) {
        double total = 0.0;
        for (var charityData in charitiesData) {
          final charityMap = charityData as Map<String, dynamic>;
          // TrustCharity.toJson() uses snake_case donation_amount
          final amount = (charityMap['donation_amount'] as num?)?.toDouble() ??
              (charityMap['donationAmount'] as num?)?.toDouble() ?? 0.0;
          total += amount;
        }
        return total;
      }
    }

    return 0.0;
  }

  double _calculateHealthcare() {
    return _calculateCategoryAmount('healthcare');
  }

  double _calculateEducation() {
    return _calculateCategoryAmount('education');
  }

  double _calculateExpenses() {
    return _calculateCategoryAmount('living');
  }

  double _calculateCharitable() {
    return _calculateCategoryAmount('charitable');
  }

  double _calculateDebt() {
    return _calculateCategoryAmount('debt');
  }

  Future<void> _copyTrustId() async {
    // Prevent abuse: silently ignore clicks during cooldown period
    if (_isCopyCooldown) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final trustCode = _trust.trustCode;
    if (trustCode == null || trustCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.trustIdNotAvailable),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Set cooldown flag immediately to prevent multiple rapid clicks
    setState(() {
      _isCopyCooldown = true;
    });

    await Clipboard.setData(ClipboardData(text: trustCode));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trustIdCopiedToClipboard),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Reset cooldown after 2 seconds
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopyCooldown = false;
        });
      }
    });
  }

  Future<void> _showWelcomeDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.familyAccountCreated,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.yourFamilyNowHasClearGuidance,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.whatHappensNow,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.familyAccountSavedAndFollowed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.nextSteps,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            l10n.youMayReceiveConfirmationEmail,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            l10n.youCanAlwaysReturnHere,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      l10n.viewInstructions,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trustFundDetails),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                final bool? updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => TrustEditScreen(initial: _trust),
                  ),
                );
                if (updated == true && mounted) {
                  await _loadData();
                }
                return;
              }

              if (value == 'delete') {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    final l10n = AppLocalizations.of(context)!;
                    return AlertDialog(
                      title: Text(l10n.deleteTrustFund),
                      content: Text(l10n.areYouSureDeleteTrustFund),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true && widget.trust.id != null) {
                  try {
                    await TrustService.instance.deleteTrust(widget.trust.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.trustFundDeleted),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.failedToDeleteTrustFund(e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trust info header - matching homepage design
                    CardDecorationHelper.styledCard(
                      context: context,
                      elevation: 1,
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: _copyTrustId,
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          child: Stack(
                            children: [
                              // Background gradient (same as homepage trust card)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      Colors.white,
                                      colorScheme.primaryContainer.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                              // Decorative element (same pattern as homepage trust card)
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  transform: Matrix4.rotationZ(0.2),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.familyAccount,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color.fromRGBO(83, 61, 233, 1),
                                                ),
                                              ),
                                              if (_trust.trustCode != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  _trust.trustCode!,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox.shrink(),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatEstimatedNetWorth(_trust.estimatedNetWorth),
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_trust.computedStatus, context),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getStatusLabel(_trust.computedStatus, context),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _getStatusColor(_trust.computedStatus, context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment section
                    if (_trust.id != null) ...[
                      CardDecorationHelper.styledCard(
                        context: context,
                        elevation: 1,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fund',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_trust.trustPayments != null && _trust.trustPayments!.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () => _showPaymentHistory(),
                                    icon: const Icon(Icons.history, size: 18),
                                    label: const Text('History'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '${_trust.progressPercentage.toStringAsFixed(1)}%',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _trust.progressPercentage / 100,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Paid',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          _formatAmount(_trust.totalPaidInCents / 100),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Remaining',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          _formatAmount(_trust.remainingInCents / 100),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _trust.remainingInCents > 0 ? Colors.orange : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showPaymentForm(),
                                    icon: const Icon(Icons.account_balance_wallet),
                                    label: const Text('Add Fund'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions / categories section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.instructions,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.allocateWhatTrustFundWillCover,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category cards grid - only show selected categories
                    Builder(
                      builder: (context) {
                        final fundSupportCategories = [
                          {
                            'id': 'education',
                            'title': l10n.education,
                            'icon': Icons.school_outlined,
                            'calculateAmount': () => _calculateEducation(),
                          },
                          {
                            'id': 'living',
                            'title': l10n.livingExpenses,
                            'icon': Icons.home_outlined,
                            'calculateAmount': () => _calculateExpenses(),
                          },
                          {
                            'id': 'healthcare',
                            'title': l10n.healthcare,
                            'icon': Icons.medical_services_outlined,
                            'calculateAmount': () => _calculateHealthcare(),
                          },
                          {
                            'id': 'charitable',
                            'title': l10n.charitable,
                            'icon': Icons.volunteer_activism_outlined,
                            'calculateAmount': () => _calculateCharitable(),
                          },
                          {
                            'id': 'debt',
                            'title': l10n.debt,
                            'icon': Icons.receipt_long_outlined,
                            'calculateAmount': () => _calculateDebt(),
                          },
                        ];

                        // Show all categories; unselected use muted style but stay tappable
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: fundSupportCategories.map((category) {
                            final categoryId = category['id'] as String? ?? '';
                            final title = category['title'] as String? ?? 'Unknown';
                            final icon = category['icon'] as IconData? ?? Icons.category_outlined;
                            final calculateAmount = category['calculateAmount'] as double Function()? ?? () => 0.0;
                            
                            final isSelected = _trust.fundSupportCategories?.contains(categoryId) ?? false;

                            // Resolve beneficiary for this category (if any) so we can show profile avatar.
                            final Map<String, dynamic>? categoryConfig = _getCategoryConfig(categoryId);
                            int? beneficiaryId;
                            if (categoryConfig != null) {
                              final Object? rawId = categoryConfig['beneficiaryId'];
                              if (rawId is num) {
                                beneficiaryId = rawId.toInt();
                              } else if (rawId is String) {
                                beneficiaryId = int.tryParse(rawId);
                              }
                            }

                            Map<String, dynamic>? beneficiaryData;
                            if (beneficiaryId != null && _familyMembers.isNotEmpty) {
                              beneficiaryData = _familyMembers.firstWhere(
                                (member) => (member['id'] as num?)?.toInt() == beneficiaryId,
                                orElse: () => <String, dynamic>{},
                              );
                              if (beneficiaryData.isEmpty) {
                                beneficiaryData = null;
                              }
                            }

                            Widget? beneficiaryAvatar;
                            if (beneficiaryData != null) {
                              final theme = Theme.of(context);
                              final colorScheme = theme.colorScheme;
                              final String name = (beneficiaryData['name'] as String?) ?? 'Unknown';
                              final String? imagePath = beneficiaryData['image_path'] as String?;

                              ImageProvider? imageProvider;
                              if (imagePath != null && imagePath.isNotEmpty) {
                                final String? url = SupabaseService.instance.getFullImageUrl(imagePath);
                                if (url != null && url.isNotEmpty) {
                                  imageProvider = NetworkImage(url);
                                }
                              }

                              beneficiaryAvatar = CircleAvatar(
                                radius: 14,
                                backgroundImage: imageProvider,
                                backgroundColor: colorScheme.primaryContainer,
                                child: imageProvider == null
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              );
                            }

                            return _CategoryCard(
                              title: title,
                              subtitle: isSelected ? _formatAmount(calculateAmount()) : l10n.tapToSetUp,
                              icon: icon,
                              iconColor: isSelected 
                                  ? const Color.fromRGBO(49, 24, 211, 1)
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                              isUnselected: !isSelected,
                              beneficiaryAvatar: beneficiaryAvatar,
                              onTap: () async {
                                // Navigate to view/edit configuration (any category can be opened)
                                final config = _getCategoryConfig(categoryId) ?? {};
                                final categoryInfo = {
                                  'id': categoryId,
                                  'title': title,
                                  'icon': icon,
                                };
                                
                                final updatedConfig = await Navigator.of(context).push<Map<String, dynamic>>(
                                  MaterialPageRoute<Map<String, dynamic>>(
                                    builder: (_) => FundSupportConfigScreen(
                                      categoryId: categoryId,
                                      category: categoryInfo,
                                      initialConfig: config,
                                      // In dashboard we manage live instructions,
                                      // so keep pause / request fund actions visible.
                                      showRequestActions: true,
                                    ),
                                  ),
                                );
                                
                                // Persist updated config and refresh UI
                                if (updatedConfig != null && widget.trust.id != null) {
                                  try {
                                    final merged = Map<String, dynamic>.from(_trust.fundSupportConfigs ?? {});
                                    merged[categoryId] = updatedConfig;
                                    final mergedCategories = List<String>.from(_trust.fundSupportCategories ?? []);
                                    if (!mergedCategories.contains(categoryId)) {
                                      mergedCategories.add(categoryId);
                                    }
                                    await TrustService.instance.updateTrust(
                                      widget.trust.id!,
                                      {
                                        'fund_support_configs': merged,
                                        'fund_support_categories': mergedCategories,
                                      },
                                    );
                                    final updatedTrust = await TrustService.instance.getTrustById(widget.trust.id!);
                                    if (mounted && updatedTrust != null) {
                                      setState(() => _currentTrust = updatedTrust);
                                      await _loadData();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.settingsSaved),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.failedToSave(e.toString())),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    
                    // Partnership section
                    _PartnershipSection(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  /// Muted style for unselected; card stays tappable.
  final bool isUnselected;
  /// Optional beneficiary avatar shown in the card (without name for quick visual context).
  final Widget? beneficiaryAvatar;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.isUnselected = false,
    this.beneficiaryAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CardDecorationHelper.styledCard(
      context: context,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isUnselected
                ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                : colorScheme.primaryContainer.withOpacity(0.4),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon in soft container to match other cards
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor ?? const Color.fromRGBO(49, 24, 211, 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom-aligned text block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isUnselected
                              ? colorScheme.onSurface
                              : colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isUnselected
                              ? colorScheme.onSurfaceVariant.withOpacity(0.9)
                              : colorScheme.onPrimaryContainer.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ],
              ),
              if (beneficiaryAvatar != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: beneficiaryAvatar!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnershipSection extends StatelessWidget {
  const _PartnershipSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Logos row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rakyat Trustee logo
              _PartnerLogo(
                imagePath: 'assets/rakyat-trustee.png',
                iconColor: const Color.fromRGBO(49, 24, 211, 1),
              ),
              const SizedBox(width: 32),
              // Halogen Capital logo
              _PartnerLogo(
                imagePath: 'assets/halogen-capital.png',
                iconColor: const Color.fromRGBO(49, 24, 211, 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Text content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: l10n.sampulPartnerWithRakyat,
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to learn more page or open URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.learnMoreAboutPartners),
                          ),
                        );
                      },
                      child: Text(
                        l10n.learnMore,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
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
    );
  }
}

class _PartnerLogo extends StatelessWidget {
  final String? imagePath;
  final Color iconColor;

  const _PartnerLogo({
    this.imagePath,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return imagePath != null
        ? Image.asset(
            imagePath!,
            width: 120,
            height: 60,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to generic business icon if image fails to load
              debugPrint('Error loading image: $imagePath - $error');
              return Icon(
                Icons.business,
                color: iconColor,
                size: 28,
              );
            },
          )
        : Icon(
            Icons.business,
            color: iconColor,
            size: 28,
          );
  }
}
