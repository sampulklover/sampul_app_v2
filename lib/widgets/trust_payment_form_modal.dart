import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trust.dart';
import '../config/trust_constants.dart';
import '../services/trust_payment_service.dart';
import '../services/analytics_service.dart';
import '../utils/form_decoration_helper.dart';

class TrustPaymentFormModal extends StatefulWidget {
  final Trust trust;

  const TrustPaymentFormModal({
    super.key,
    required this.trust,
  });

  @override
  State<TrustPaymentFormModal> createState() => _TrustPaymentFormModalState();
}

class _TrustPaymentFormModalState extends State<TrustPaymentFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _showFeeInfo = false;
  bool _showAllPaymentSteps = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrencyWithCommas(int cents) {
    final amount = cents / 100;
    return 'RM ${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  int? _parseAmount(String value) {
    // Remove RM, spaces, and commas
    final cleaned = value.replaceAll(RegExp(r'[RM\s,]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null) return null;
    // Convert to cents
    return (amount * 100).round();
  }

  List<int> _buildPlanStepsToClearRemaining(int stepAmountInCents) {
    final int remainingTarget = widget.trust.remainingInCents;
    if (stepAmountInCents <= 0 || remainingTarget <= 0) {
      return <int>[];
    }

    final int normalizedStepAmount =
        stepAmountInCents > TrustConstants.maxTransactionAmount
            ? TrustConstants.maxTransactionAmount
            : stepAmountInCents;

    final List<int> steps = <int>[];
    int remaining = remainingTarget;
    while (remaining > 0) {
      final int nextStep = remaining > normalizedStepAmount
          ? normalizedStepAmount
          : remaining;
      steps.add(nextStep);
      remaining -= nextStep;
    }
    return steps;
  }

  List<int> _buildMaxCapStepsForRemaining() {
    final int remainingTarget = widget.trust.remainingInCents;
    if (remainingTarget <= 0) {
      return <int>[];
    }
    final List<int> steps = <int>[];
    int remaining = remainingTarget;
    while (remaining > 0) {
      final int nextStep = remaining > TrustConstants.maxTransactionAmount
          ? TrustConstants.maxTransactionAmount
          : remaining;
      steps.add(nextStep);
      remaining -= nextStep;
    }
    return steps;
  }

  Widget _buildPaymentStepsCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final int totalPaid = widget.trust.totalPaidInCents;
    final int remaining = widget.trust.remainingInCents;
    final int required = widget.trust.requiredFundingInCents;

    final List<int> historySteps = <int>[];
    int paidLeft = totalPaid;
    while (paidLeft > 0) {
      final int doneStep = paidLeft > TrustConstants.maxTransactionAmount
          ? TrustConstants.maxTransactionAmount
          : paidLeft;
      historySteps.add(doneStep);
      paidLeft -= doneStep;
    }

    final List<int> remainingSteps = _buildMaxCapStepsForRemaining();
    const int previewStepCount = 3;
    final int doneVisibleCount = _showAllPaymentSteps
        ? historySteps.length
        : (historySteps.length > previewStepCount ? previewStepCount : historySteps.length);
    final int nextVisibleCount = _showAllPaymentSteps
        ? remainingSteps.length
        : (remainingSteps.length > previewStepCount ? previewStepCount : remainingSteps.length);
    final List<int> doneVisible = historySteps.take(doneVisibleCount).toList();
    final List<int> nextVisible = remainingSteps.take(nextVisibleCount).toList();
    final int hiddenDoneCount = historySteps.length - doneVisibleCount;
    final int hiddenNextCount = remainingSteps.length - nextVisibleCount;
    final bool canExpand = historySteps.length > previewStepCount ||
        remainingSteps.length > previewStepCount;
    int runningRemaining = required;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Payment Steps',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Paid: ${_formatCurrencyWithCommas(totalPaid)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Remaining: ${_formatCurrencyWithCommas(remaining)}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (historySteps.isEmpty && remainingSteps.isEmpty)
            Text(
              'No payment steps yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ...List<Widget>.generate(doneVisible.length, (index) {
            final int amount = doneVisible[index];
            runningRemaining = (runningRemaining - amount).clamp(0, required);
            return _buildTimelineRow(
              theme: theme,
              colorScheme: colorScheme,
              indexLabel: '${index + 1}',
              amountLabel: _formatCurrencyWithCommas(amount),
              statusLabel: 'done',
              state: _TimelineState.done,
            );
          }),
          ...List<Widget>.generate(nextVisible.length, (index) {
            final int amount = nextVisible[index];
            runningRemaining = (runningRemaining - amount).clamp(0, required);
            final bool isCurrent = index == 0;
            final bool isFinal = runningRemaining == 0;
            return _buildTimelineRow(
              theme: theme,
              colorScheme: colorScheme,
              indexLabel: '${doneVisible.length + index + 1}',
              amountLabel: _formatCurrencyWithCommas(amount),
              statusLabel: isCurrent
                  ? "you're here"
                  : (isFinal ? 'final step' : 'next step'),
              state: isCurrent ? _TimelineState.current : _TimelineState.upcoming,
            );
          }),
          if ((hiddenDoneCount > 0 || hiddenNextCount > 0) && !_showAllPaymentSteps)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                '+${hiddenDoneCount + hiddenNextCount} more steps',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (canExpand) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                setState(() {
                  _showAllPaymentSteps = !_showAllPaymentSteps;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllPaymentSteps ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllPaymentSteps ? 'Show less' : 'Show all steps',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String indexLabel,
    required String amountLabel,
    required String statusLabel,
    required _TimelineState state,
  }) {
    final Color dotColor;
    final Color amountColor;
    switch (state) {
      case _TimelineState.done:
        dotColor = Colors.teal;
        amountColor = Colors.teal;
        break;
      case _TimelineState.current:
        dotColor = colorScheme.primary;
        amountColor = colorScheme.onSurface;
        break;
      case _TimelineState.upcoming:
        dotColor = colorScheme.outline.withOpacity(0.45);
        amountColor = colorScheme.onSurfaceVariant;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: state == _TimelineState.done
                ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
                : Text(
                    indexLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: state == _TimelineState.current
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$amountLabel - $statusLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: amountColor,
                    fontWeight: state == _TimelineState.current
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountInCents = _parseAmount(_amountController.text);
    if (amountInCents == null || amountInCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentSteps = _buildPlanStepsToClearRemaining(amountInCents);
    if (paymentSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No remaining balance to fund'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final amountForThisPayment = paymentSteps.first;

    setState(() => _isLoading = true);

    try {
      await AnalyticsService.capture(
        'trust funding started',
        properties: <String, Object>{
          if (widget.trust.id != null) 'trust_id': widget.trust.id!,
          if (widget.trust.trustCode != null && widget.trust.trustCode!.isNotEmpty)
            'trust_code': widget.trust.trustCode!,
          'amount_cents': amountForThisPayment,
          'requested_total_amount_cents': amountInCents,
          'payment_steps_count': paymentSteps.length,
        },
      );
      print('🟢 [TRUST PAYMENT] Starting payment flow...');
      print(
        '🟢 [TRUST PAYMENT] Amount (current step): ${_formatCurrencyWithCommas(amountForThisPayment)}',
      );
      print(
        '🟢 [TRUST PAYMENT] Requested total: ${_formatCurrencyWithCommas(amountInCents)}',
      );
      print('🟢 [TRUST PAYMENT] Total steps: ${paymentSteps.length}');
      print('🟢 [TRUST PAYMENT] Trust ID: ${widget.trust.id}');
      print('🟢 [TRUST PAYMENT] Trust Code: ${widget.trust.trustCode}');

      // Step 1: Get or create CHIP client ID
      print('🟢 [TRUST PAYMENT] Step 1: Getting CHIP client ID...');
      final clientId =
          await TrustPaymentService.instance.getChipClient(forTrustMerchant: true);
      print('🟢 [TRUST PAYMENT] Got CHIP client ID: $clientId');

      // Step 2: Create payment session
      print('🟢 [TRUST PAYMENT] Step 2: Creating payment session...');
      final paymentResponse = await TrustPaymentService.instance.createPayment(
        trustId: widget.trust.id!,
        trustCode: widget.trust.trustCode ?? '',
        amount: amountForThisPayment,
        clientId: clientId,
      );
      print('🟢 [TRUST PAYMENT] Payment response: ${paymentResponse.id}');
      print('🟢 [TRUST PAYMENT] Checkout URL: ${paymentResponse.checkoutUrl}');

      if (paymentResponse.checkoutUrl.isEmpty) {
        print('🔴 [TRUST PAYMENT] No checkout URL received');
        throw Exception('No checkout URL received from payment provider');
      }

      // Step 3: Open checkout URL
      print('🟢 [TRUST PAYMENT] Step 3: Opening checkout URL...');
      final uri = Uri.parse(paymentResponse.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await AnalyticsService.capture(
          'trust funding checkout opened',
          properties: <String, Object>{
            if (widget.trust.id != null) 'trust_id': widget.trust.id!,
            'amount_cents': amountForThisPayment,
            'requested_total_amount_cents': amountInCents,
            'payment_steps_count': paymentSteps.length,
          },
        );
        if (paymentSteps.length > 1 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'At this payment amount, you will need ${paymentSteps.length} steps '
                'to clear the remaining balance. '
                'This checkout is step 1 (${_formatCurrencyWithCommas(amountForThisPayment)}).',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🟢 [TRUST PAYMENT] Checkout URL opened successfully');
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate payment initiated
        }
      } else {
        print('🔴 [TRUST PAYMENT] Unable to launch URL: ${paymentResponse.checkoutUrl}');
        throw Exception('Unable to open payment page');
      }
    } catch (e, stackTrace) {
      await AnalyticsService.capture(
        'trust funding failed',
        properties: <String, Object>{
          if (widget.trust.id != null) 'trust_id': widget.trust.id!,
        },
      );
      print('🔴 [TRUST PAYMENT] Error occurred: $e');
      print('🔴 [TRUST PAYMENT] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add fund: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Add Fund',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment for Trust ${widget.trust.trustCode ?? ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildPaymentStepsCard(theme: theme, colorScheme: colorScheme),
              const SizedBox(height: 24),
              // Amount input
              Text(
                'Payment Amount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                onChanged: (_) => setState(() {
                  _showAllPaymentSteps = false;
                }),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: FormDecorationHelper.roundedInputDecoration(
                  context: context,
                  labelText: 'Amount (RM)',
                  hintText: '0.00',
                ).copyWith(
                  prefixText: 'RM ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amountInCents = _parseAmount(value);
                  if (amountInCents == null || amountInCents <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amountInCents > TrustConstants.maxTransactionAmount) {
                    return 'Maximum per payment is ${_formatCurrencyWithCommas(TrustConstants.maxTransactionAmount)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum per transaction: ${_formatCurrencyWithCommas(TrustConstants.maxTransactionAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // Fee structure info (collapsible)
              InkWell(
                onTap: () => setState(() => _showFeeInfo = !_showFeeInfo),
                child: Row(
                  children: [
                    Icon(
                      _showFeeInfo ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fee Structure',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showFeeInfo) ...[
                const SizedBox(height: 8),
                Card(
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Immediate Asset Transfer',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFeeRow(
                          context: context,
                          theme: theme,
                          colorScheme: colorScheme,
                          label: 'Management Fee',
                          amount: '1.5% of assets',
                          frequency: 'Annual/Upfront',
                        ),
                        const SizedBox(height: 12),
                        _buildFeeRow(
                          context: context,
                          theme: theme,
                          colorScheme: colorScheme,
                          label: 'Documentation',
                          amount: 'RM 200',
                        ),
                        const SizedBox(height: 12),
                        _buildFeeRow(
                          context: context,
                          theme: theme,
                          colorScheme: colorScheme,
                          label: 'Amendment/Cancellation',
                          amount: 'RM 500',
                          frequency: 'Per request',
                        ),
                        const SizedBox(height: 12),
                        _buildFeeRow(
                          context: context,
                          theme: theme,
                          colorScheme: colorScheme,
                          label: 'Withdrawal',
                          amount: 'RM 25',
                          frequency: 'Per trustor withdrawal',
                        ),
                        const SizedBox(height: 12),
                        _buildFeeRow(
                          context: context,
                          theme: theme,
                          colorScheme: colorScheme,
                          label: 'Execution (Post-Demised)',
                          amount: 'RM 25',
                          frequency: 'Per instruction/transaction',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                          child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continue to Add Fund'),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String label,
    required String amount,
    String? frequency,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
              if (frequency != null) ...[
                const SizedBox(height: 2),
                Text(
                  frequency,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _TimelineState { done, current, upcoming }
