import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trust.dart';
import '../config/trust_constants.dart';
import '../services/trust_payment_service.dart';
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

    if (amountInCents > TrustConstants.maxTransactionAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum transaction amount is ${_formatCurrencyWithCommas(TrustConstants.maxTransactionAmount)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🟢 [TRUST PAYMENT] Starting payment flow...');
      print('🟢 [TRUST PAYMENT] Amount: ${_formatCurrencyWithCommas(amountInCents)}');
      print('🟢 [TRUST PAYMENT] Trust ID: ${widget.trust.id}');
      print('🟢 [TRUST PAYMENT] Trust Code: ${widget.trust.trustCode}');

      // Step 1: Get or create CHIP client ID
      print('🟢 [TRUST PAYMENT] Step 1: Getting CHIP client ID...');
      final clientId = await TrustPaymentService.instance.getChipClient();
      print('🟢 [TRUST PAYMENT] Got CHIP client ID: $clientId');

      // Step 2: Create payment session
      print('🟢 [TRUST PAYMENT] Step 2: Creating payment session...');
      final paymentResponse = await TrustPaymentService.instance.createPayment(
        trustId: widget.trust.id!,
        trustCode: widget.trust.trustCode ?? '',
        amount: amountInCents,
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
    final totalPaid = widget.trust.totalPaidInCents;
    final remaining = widget.trust.remainingInCents;
    final progress = widget.trust.progressPercentage;

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
              // Progress section
              Card(
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trust Progress',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${progress.toStringAsFixed(1)}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress / 100,
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
                                _formatCurrencyWithCommas(totalPaid),
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
                                _formatCurrencyWithCommas(remaining),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum required: ${_formatCurrencyWithCommas(TrustConstants.minTrustAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                    return 'Maximum transaction amount is ${_formatCurrencyWithCommas(TrustConstants.maxTransactionAmount)}';
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
                          label: 'Execution',
                          amount: 'RM 25',
                          frequency: 'Per post-demise instruction',
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
