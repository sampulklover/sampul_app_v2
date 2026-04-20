import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hibah.dart';
import '../models/hibah_payment.dart';
import '../models/user_coupon.dart';
import '../screens/hibah_asset_edit_screen.dart';
import '../services/analytics_service.dart';
import '../services/hibah_payment_service.dart';
import '../services/hibah_service.dart';
import '../services/user_coupon_service.dart';
import '../services/supabase_service.dart';
import '../utils/card_decoration_helper.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/sampul_icons.dart';
import '../utils/url_launch_helper.dart';
import '../widgets/payment_status_modal.dart';

class HibahDetailScreen extends StatefulWidget {
  final Hibah hibah;
  final bool autoStartPayment;

  const HibahDetailScreen({
    super.key,
    required this.hibah,
    this.autoStartPayment = false,
  });

  @override
  State<HibahDetailScreen> createState() => _HibahDetailScreenState();
}

class _HibahDetailScreenState extends State<HibahDetailScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<HibahGroup> _groups = <HibahGroup>[];
  List<HibahDocument> _documents = <HibahDocument>[];
  HibahPayment? _latestPayment;
  int _previousPaymentCount = 0;
  bool _awaitingPaymentResult = false;
  bool _isStartingPayment = false;
  List<UserCoupon> _activeHibahCoupons = <UserCoupon>[];
  UserCoupon? _selectedHibahCoupon;

  static final DateFormat _couponExpiryFormat = DateFormat('d MMM y');

  static const List<_HibahDocumentOption> _documentOptions =
      <_HibahDocumentOption>[
        _HibahDocumentOption(
          key: 'title_deed',
          label: 'Title Deed / Strata Title',
          requiresAsset: true,
        ),
        _HibahDocumentOption(
          key: 'assessment_tax',
          label: 'Assessment Tax / Land Tax',
          requiresAsset: true,
        ),
        _HibahDocumentOption(
          key: 'sale_agreement',
          label: 'Sale Agreement / Loan Agreement',
          requiresAsset: true,
        ),
        _HibahDocumentOption(
          key: 'insurance_policy',
          label: 'MRTT / MLTT / Takaful / Insurance policy documents',
          requiresAsset: true,
        ),
        _HibahDocumentOption(
          key: 'beneficiary_nric',
          label: 'Beneficiaries\' NRIC (front & back)',
        ),
        _HibahDocumentOption(
          key: 'guardian_nric',
          label: 'Guardian\'s NRIC (if beneficiary is under 18 / OKU)',
        ),
        _HibahDocumentOption(
          key: 'other_supporting',
          label: 'Any other supporting documents',
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkPaymentStatusOnResume());
    }
  }

  Future<void> _loadDetails() async {
    try {
      final groups = await HibahService.instance.getHibahGroups(
        widget.hibah.id,
      );
      final documents = await HibahService.instance.getHibahDocuments(
        widget.hibah.id,
      );
      final List<HibahPayment> paymentHistory =
          await HibahPaymentService.instance.getPaymentHistory(widget.hibah.id);
      final HibahPayment? latestPayment = paymentHistory.isEmpty
          ? null
          : paymentHistory.first;
      List<UserCoupon> hibahCoupons = <UserCoupon>[];
      try {
        hibahCoupons =
            await UserCouponService.instance.fetchActiveForProduct('hibah');
      } catch (_) {}
      if (!mounted) return;
      UserCoupon? keepCoupon;
      if (_selectedHibahCoupon != null) {
        final int idx = hibahCoupons.indexWhere(
          (UserCoupon c) => c.id == _selectedHibahCoupon!.id,
        );
        keepCoupon = idx >= 0 ? hibahCoupons[idx] : null;
      }
      setState(() {
        _groups = groups;
        _documents = documents;
        _latestPayment = latestPayment;
        _previousPaymentCount = paymentHistory.length;
        _activeHibahCoupons = hibahCoupons;
        _selectedHibahCoupon = keepCoupon;
        _isLoading = false;
      });
      _maybeAutoStartPayment();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
    }
  }

  void _maybeAutoStartPayment() {
    if (!widget.autoStartPayment) return;
    if (!mounted) return;
    if (_isLoading) return;
    if (_isStartingPayment) return;
    if (_groups.isEmpty) return;
    final bool paymentComplete = _latestPayment?.isSuccessful == true;
    if (paymentComplete) return;
    final HibahPaymentBreakdown estimate = HibahPaymentService.instance
        .calculatePayment(assetCount: _groups.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isStartingPayment) return;
      _startPayment(estimate, showConfirmationModal: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final DateFormat dateFormatter = DateFormat.yMMMMd().add_jm();
    final List<Widget> missingDocumentChecklist =
        _buildMissingDocumentChecklist();

    return Scaffold(
      appBar: AppBar(title: const Text('Hibah Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(dateFormatter, theme, scheme),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Assets',
                      subtitle:
                          'Review the property details and beneficiaries included in this hibah.',
                      trailing: _buildCountBadge(_groups.length),
                    ),
                    const SizedBox(height: 12),
                    if (_groups.isEmpty)
                      _buildEmptyStateCard('No assets added yet')
                    else
                      ..._groups.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final HibahGroup group = entry.value;
                        return _buildAssetCard(group, index + 1);
                      }),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Asset details are locked after submission so your payment stays consistent.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Documents',
                      subtitle:
                          'Upload supporting documents here whenever you are ready.',
                      trailing: FilledButton.icon(
                        onPressed: _showAddDocumentSheet,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Add document'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (missingDocumentChecklist.isNotEmpty)
                      ...missingDocumentChecklist,
                    if (missingDocumentChecklist.isNotEmpty)
                      const SizedBox(height: 8),
                    if (_documents.isEmpty)
                      _buildEmptyStateCard('No documents uploaded yet')
                    else
                      ..._documents.map((doc) => _buildDocumentCard(doc)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(
    DateFormat dateFormatter,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 210,
          child: Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
              ),
              Positioned(
                right: -18,
                bottom: -6,
                child: Icon(
                  Icons.home_work_outlined,
                  size: 132,
                  color: scheme.primary.withValues(alpha: 0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hibah certificate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color.fromRGBO(83, 61, 233, 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hibah.certificateId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_groups.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _groups.length == 1
                          ? 'Asset included'
                          : 'Assets included',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        _buildStatusBadge(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Created ${dateFormatter.format(widget.hibah.createdAt)}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Updated ${dateFormatter.format(widget.hibah.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final HibahPaymentBreakdown estimate = HibahPaymentService.instance
        .calculatePayment(assetCount: _groups.length);
    final int baseCents = estimate.totalAmountInCents;
    final String assetsValue =
        _groups.length == 1 ? '1 asset' : '${_groups.length} assets';
    final int? payableCents = _selectedHibahCoupon != null
        ? UserCoupon.discountedTotalCents(
            baseCents,
            _selectedHibahCoupon!.discountPercent,
          )
        : null;
    final String estimatedAmount = _formatCurrency(baseCents);
    final String? paymentStatus = _latestPayment?.status;
    final bool paymentComplete = _latestPayment?.isSuccessful == true;

    return CardDecorationHelper.styledCard(
      context: context,
      elevation: 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.payments_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Payment',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paymentComplete
                ? 'Your latest hibah payment has been received.'
                : 'Estimated fee based on ${_groups.length} asset${_groups.length == 1 ? '' : 's'}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Estimated amount',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      estimatedAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Assets',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      assetsValue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (estimate.description.trim().isNotEmpty &&
                    estimate.description.trim().toLowerCase() !=
                        assetsValue.toLowerCase())
                  Text(
                    estimate.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (payableCents != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        l10n.checkoutYouPay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatCurrency(payableCents),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (paymentStatus != null) ...<Widget>[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Latest status',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatPaymentStatus(paymentStatus),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _paymentStatusColor(paymentStatus),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!paymentComplete && _activeHibahCoupons.isNotEmpty) ...<Widget>[
            DropdownButtonFormField<UserCoupon?>(
              value: _selectedHibahCoupon,
              decoration: FormDecorationHelper.roundedInputDecoration(
                context: context,
                labelText: l10n.checkoutCouponLabel,
              ),
              items: <DropdownMenuItem<UserCoupon?>>[
                DropdownMenuItem<UserCoupon?>(
                  value: null,
                  child: Text(l10n.checkoutNoCoupon),
                ),
                ..._activeHibahCoupons.map(
                  (UserCoupon c) => DropdownMenuItem<UserCoupon?>(
                    value: c,
                    child: Text(
                      '${l10n.couponDiscountPercent(c.discountPercent)} · '
                      '${l10n.couponExpiresOn(_couponExpiryFormat.format(c.expiresAt.toLocal()))}',
                    ),
                  ),
                ),
              ],
              onChanged: (UserCoupon? v) {
                setState(() => _selectedHibahCoupon = v);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (paymentComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment received',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _groups.isEmpty || _isStartingPayment
                    ? null
                    : () => _startPayment(estimate),
                icon: const Icon(Icons.account_balance_wallet, size: 20),
                label: Text(
                  _isStartingPayment
                      ? 'Starting payment…'
                      : 'Continue to payment',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startPayment(
    HibahPaymentBreakdown breakdown, {
    bool showConfirmationModal = true,
  }) async {
    if (_groups.isEmpty || _isStartingPayment) return;

    if (showConfirmationModal) {
      final bool? shouldContinue = await _showHibahPaymentDetailsModal();
      if (shouldContinue != true) {
        return;
      }
    }

    setState(() => _isStartingPayment = true);

    try {
      await AnalyticsService.capture(
        'hibah payment started',
        properties: <String, Object>{
          'hibah_id': widget.hibah.id,
          'asset_count': _groups.length,
          'amount_cents': breakdown.totalAmountInCents,
        },
      );

      final String clientId = await HibahPaymentService.instance
          .getChipClient();
      final paymentResponse = await HibahPaymentService.instance.createPayment(
        hibahId: widget.hibah.id,
        certificateId: widget.hibah.certificateId,
        amount: breakdown.totalAmountInCents,
        clientId: clientId,
        userCouponId: _selectedHibahCoupon?.id,
      );

      final String url = paymentResponse.checkoutUrl;
      if (url.isEmpty) {
        throw Exception('No checkout URL received from payment provider');
      }

      final Uri uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        throw Exception('Unable to open payment page');
      }

      await AnalyticsService.capture(
        'hibah payment checkout opened',
        properties: <String, Object>{
          'hibah_id': widget.hibah.id,
          'amount_cents': breakdown.totalAmountInCents,
        },
      );

      setState(() => _awaitingPaymentResult = true);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We couldn\'t start payment right now: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingPayment = false);
    }
  }

  Future<bool?> _showHibahPaymentDetailsModal() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget row({
      required String label,
      required String value,
      String? subtitle,
      bool emphasize = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: emphasize ? scheme.primary : null,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        bool showFeeInfo = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.outline.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Review Hibah payment',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check the fee details before you continue to payment.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Property Documentation Fee',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'RM2,500',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  showFeeInfo = !showFeeInfo;
                                });
                              },
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    showFeeInfo
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment details',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showFeeInfo) ...<Widget>[
                              const SizedBox(height: 8),
                              Card(
                                color: scheme.surfaceContainerHighest,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Shariah-Compliant Home Gifting',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      row(
                                        label: 'Property Documentation Fee',
                                        value: 'RM2,500',
                                        emphasize: true,
                                        subtitle: 'One-time fee',
                                      ),
                                      row(
                                        label: 'Amendment/Cancellation',
                                        value: 'RM500',
                                        subtitle: 'Per request',
                                      ),
                                      row(
                                        label: 'Execution Fee',
                                        value:
                                            '0.5% of property value + stamp duty',
                                        subtitle: 'When execution is needed',
                                      ),
                                      const Divider(height: 20),
                                      Text(
                                        'Stamp duty',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      row(
                                        label: 'Stamp Duty - First RM 100,000',
                                        value: '1.0%',
                                      ),
                                      row(
                                        label:
                                            'Stamp Duty - RM 100,001 to RM 500,000',
                                        value: '2.0%',
                                      ),
                                      row(
                                        label:
                                            'Stamp Duty - RM 500,001 to RM 1,000,000',
                                        value: '3.0%',
                                      ),
                                      row(
                                        label: 'Stamp Duty - Above RM 1,000,001',
                                        value: '4.0%',
                                      ),
                                      row(
                                        label: 'Stamp Duty - Spouse to Spouse',
                                        value: 'FREE (Full exemption)',
                                      ),
                                      row(
                                        label: 'Stamp Duty - Family Members*',
                                        value:
                                            'FREE (First RM 1M), 50% (Excess)',
                                        subtitle: 'For eligible family transfer',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '*Family Members include: Parents, children, step-children, adopted children, grandparents, grandchildren',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Note: All fees are inclusive of applicable taxes. Stamp duty is a third-party cost.',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: scheme.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
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
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Continue to payment'),
                            ),
                          ),
                        ],
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

  Future<void> _checkPaymentStatusOnResume() async {
    if (!_awaitingPaymentResult && _latestPayment == null) {
      return;
    }

    try {
      final List<HibahPayment> paymentHistory = await HibahPaymentService
          .instance
          .getPaymentHistory(widget.hibah.id);
      final HibahPayment? updatedLatestPayment = paymentHistory.isEmpty
          ? null
          : paymentHistory.first;
      if (!mounted) return;

      final int currentPaymentCount = paymentHistory.length;
      final bool hasNewPayment = currentPaymentCount > _previousPaymentCount;
      final bool hasResolvedPendingPayment =
          _awaitingPaymentResult &&
          updatedLatestPayment != null &&
          (updatedLatestPayment.isSuccessful ||
              updatedLatestPayment.isFailed ||
              (updatedLatestPayment.status?.toLowerCase() == 'failed'));

      if (hasNewPayment || hasResolvedPendingPayment) {
        setState(() {
          _latestPayment = updatedLatestPayment;
          _previousPaymentCount = currentPaymentCount;
          _awaitingPaymentResult = false;
        });

        if (updatedLatestPayment != null && mounted) {
          final bool isSuccess = updatedLatestPayment.isSuccessful;
          await showDialog<void>(
            context: context,
            builder: (BuildContext context) => PaymentStatusModal(
              isSuccess: isSuccess,
              message: isSuccess
                  ? 'Your payment of ${_formatCurrency(updatedLatestPayment.amount)} has been processed successfully.'
                  : 'Your payment could not be processed. Please try again.',
            ),
          );
          if (!mounted) return;
          await _loadDetails();
        }
      } else {
        setState(() {
          _latestPayment = updatedLatestPayment;
          _previousPaymentCount = currentPaymentCount;
        });
      }
    } catch (_) {
      // Fail silently and let the user refresh naturally from the detail screen.
    }
  }

  Future<void> _editAsset(HibahGroup group) async {
    final HibahGroupRequest initial = HibahGroupRequest(
      tempId: group.id,
      propertyName: group.propertyName,
      assetType: group.assetType,
      registeredTitleNumber: group.registeredTitleNumber,
      propertyLocation: group.propertyLocation,
      estimatedValue: group.estimatedValue,
      loanStatus: group.loanStatus,
      bankName: group.bankName,
      outstandingLoanAmount: group.outstandingLoanAmount,
      landCategories: List<String>.from(group.landCategories),
      beneficiaries: group.beneficiaries
          .map(
            (HibahBeneficiary beneficiary) => HibahBeneficiaryRequest(
              belovedId: beneficiary.belovedId,
              name: beneficiary.name ?? '',
              relationship: beneficiary.relationship,
              sharePercentage: beneficiary.sharePercentage,
              notes: beneficiary.notes,
            ),
          )
          .toList(),
    );

    final HibahGroupRequest? updated = await Navigator.of(context)
        .push<HibahGroupRequest>(
          MaterialPageRoute<HibahGroupRequest>(
            builder: (_) => HibahAssetEditScreen(initial: initial),
          ),
        );

    if (updated == null) return;

    try {
      await HibahService.instance.updateGroup(
        groupId: group.id,
        group: updated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asset details updated')));
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We couldn\'t save those changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAssetCard(HibahGroup group, int assetNumber) {
    return CardDecorationHelper.styledCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Asset #$assetNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.propertyName ?? 'Unnamed property',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit asset',
                onPressed: () => _editAsset(group),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (group.assetType != null && group.assetType!.isNotEmpty)
                _buildMetaChip(Icons.apartment_outlined, group.assetType!),
              _buildMetaChip(
                Icons.account_balance_outlined,
                _loanStatusLabel(group.loanStatus),
              ),
              if (group.landCategories.isNotEmpty)
                _buildMetaChip(
                  Icons.category_outlined,
                  group.landCategories.join(', '),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Title number',
            value: group.registeredTitleNumber ?? '-',
          ),
          _InfoRow(label: 'Location', value: group.propertyLocation ?? '-'),
          _InfoRow(
            label: 'Estimated value',
            value: group.estimatedValue?.isNotEmpty == true
                ? 'RM ${group.estimatedValue}'
                : '-',
          ),
          _InfoRow(label: 'Bank', value: group.bankName ?? '-'),
          _InfoRow(
            label: 'Outstanding loan',
            value: group.outstandingLoanAmount?.isNotEmpty == true
                ? 'RM ${group.outstandingLoanAmount}'
                : '-',
          ),
          const SizedBox(height: 4),
          if (group.beneficiaries.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Beneficiaries',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildCountBadge(group.beneficiaries.length),
              ],
            ),
            const SizedBox(height: 10),
            ...group.beneficiaries.map((ben) {
              final double? share = ben.sharePercentage;
              final String shareText = share != null
                  ? '${_formatShare(share)}%'
                  : 'Not provided';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ben.name ?? 'Unnamed beneficiary',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ben.relationship?.isNotEmpty == true
                                ? ben.relationship!
                                : 'Relationship not provided',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        shareText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(HibahDocument doc) {
    final DateFormat dateFormatter = DateFormat.yMMMd().add_jm();
    final String docTypeLabel = _getDocumentTypeLabel(doc.documentType);

    // Find linked asset if applicable
    String? linkedAssetName;
    if (doc.hibahGroupId != null) {
      try {
        final linkedGroup = _groups.firstWhere((g) => g.id == doc.hibahGroupId);
        linkedAssetName = linkedGroup.propertyName;
      } catch (e) {
        // Group not found
        linkedAssetName = null;
      }
    }

    return CardDecorationHelper.styledCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.insert_drive_file_outlined,
            color: Color.fromRGBO(49, 24, 211, 1),
          ),
        ),
        title: Text(
          docTypeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(doc.fileName),
            const SizedBox(height: 4),
            Text(
              '${_formatFileSize(doc.fileSize)} • ${dateFormatter.format(doc.uploadedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (linkedAssetName != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Linked to $linkedAssetName',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showDocumentActions(doc),
        ),
      ),
    );
  }

  Future<void> _showAddDocumentSheet() async {
    final _NewHibahDocumentDraft? draft =
        await showModalBottomSheet<_NewHibahDocumentDraft>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return _HibahDetailDocumentSheet(
              groups: _groups,
              options: _documentOptions,
            );
          },
        );

    if (draft == null) return;

    try {
      await HibahService.instance.addDocument(
        hibahId: widget.hibah.id,
        documentType: draft.documentType,
        fileName: draft.file.name,
        bytes: draft.file.bytes!,
        mimeType: draft.mimeType,
        hibahGroupId: draft.hibahGroupId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document uploaded')));
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We couldn\'t upload the document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDocumentActions(HibahDocument doc) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Open document'),
                onTap: () => Navigator.of(context).pop('open'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete document'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'open') {
      await _downloadDocument(doc);
      return;
    }
    if (action == 'delete') {
      await _deleteDocument(doc);
    }
  }

  Future<void> _deleteDocument(HibahDocument doc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete document'),
          content: Text('Remove ${doc.fileName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await HibahService.instance.deleteDocument(doc);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document removed')));
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We couldn\'t delete the document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildMissingDocumentChecklist() {
    final List<Widget> widgets = <Widget>[];

    for (final HibahGroup group in _groups) {
      final Set<String> uploadedKeys = _documents
          .where((HibahDocument doc) => doc.hibahGroupId == group.id)
          .map((HibahDocument doc) => doc.documentType)
          .toSet();

      final List<String> missingForAsset = _documentOptions
          .where(
            (_HibahDocumentOption option) =>
                option.requiresAsset && !uploadedKeys.contains(option.key),
          )
          .map((_HibahDocumentOption option) => option.label)
          .toList();

      if (missingForAsset.isNotEmpty) {
        widgets.add(
          _buildChecklistCard(
            title: group.propertyName ?? 'Asset',
            items: missingForAsset,
          ),
        );
      }
    }

    final bool hasBeneficiaryDoc = _documents.any(
      (HibahDocument doc) => doc.documentType == 'beneficiary_nric',
    );
    final bool hasBeneficiaries = _groups.any(
      (HibahGroup group) => group.beneficiaries.isNotEmpty,
    );

    if (hasBeneficiaries && !hasBeneficiaryDoc) {
      widgets.add(
        _buildChecklistCard(
          title: 'Still helpful to add',
          items: const <String>['Beneficiaries\' NRIC (front & back)'],
        ),
      );
    }

    return widgets;
  }

  Widget _buildChecklistCard({
    required String title,
    required List<String> items,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return CardDecorationHelper.styledCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suggested documents still missing:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(alignment: Alignment.topRight, child: trailing),
          ),
        ],
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final ThemeData theme = Theme.of(context);
    final Color statusColor = _statusColor(context, widget.hibah.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(widget.hibah.status),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return CardDecorationHelper.styledCard(
      context: context,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Text(message)),
      ),
    );
  }

  Future<void> _downloadDocument(HibahDocument doc) async {
    try {
      final String publicUrl = SupabaseService.instance.client.storage
          .from('images')
          .getPublicUrl(doc.filePath);

      final Uri url = Uri.parse(publicUrl);
      if (await launchUriPreferInAppBrowser(url)) {
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open document')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _loanStatusLabel(String? status) {
    switch (status) {
      case 'fully_paid':
        return 'Fully Paid';
      case 'ongoing_financing':
        return 'Ongoing Financing';
      case 'no_financing':
        return 'No Financing';
      default:
        return '-';
    }
  }

  String _formatShare(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _getDocumentTypeLabel(String key) {
    for (final _HibahDocumentOption option in _documentOptions) {
      if (option.key == key) {
        return option.label;
      }
    }
    return key;
  }

  String _statusLabel(HibahStatus status) {
    switch (status) {
      case HibahStatus.draft:
        return 'Draft';
      case HibahStatus.pendingReview:
        return 'Pending Review';
      case HibahStatus.underReview:
        return 'Under Review';
      case HibahStatus.approved:
        return 'Approved';
      case HibahStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(BuildContext context, HibahStatus status) {
    switch (status) {
      case HibahStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case HibahStatus.pendingReview:
        return Colors.orange.shade700;
      case HibahStatus.underReview:
        return Colors.blue.shade600;
      case HibahStatus.approved:
        return Colors.green.shade700;
      case HibahStatus.rejected:
        return Colors.red.shade700;
    }
  }

  String _formatCurrency(int cents) {
    final double amount = cents / 100;
    return 'RM ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatPaymentStatus(String status) {
    final String normalised = status.replaceAll('_', ' ').trim();
    if (normalised.isEmpty) {
      return '-';
    }
    return normalised[0].toUpperCase() + normalised.substring(1);
  }

  Color _paymentStatusColor(String status) {
    final String normalised = status.toLowerCase();
    if (['paid', 'settled', 'cleared'].contains(normalised)) {
      return Colors.green.shade700;
    }
    if (['failed', 'error', 'expired', 'cancelled'].contains(normalised)) {
      return Colors.red.shade700;
    }
    return Colors.orange.shade700;
  }
}

class _HibahDocumentOption {
  final String key;
  final String label;
  final bool requiresAsset;

  const _HibahDocumentOption({
    required this.key,
    required this.label,
    this.requiresAsset = false,
  });
}

class _NewHibahDocumentDraft {
  final String documentType;
  final PlatformFile file;
  final String mimeType;
  final String? hibahGroupId;

  const _NewHibahDocumentDraft({
    required this.documentType,
    required this.file,
    required this.mimeType,
    this.hibahGroupId,
  });
}

class _HibahDetailDocumentSheet extends StatefulWidget {
  final List<HibahGroup> groups;
  final List<_HibahDocumentOption> options;

  const _HibahDetailDocumentSheet({
    required this.groups,
    required this.options,
  });

  @override
  State<_HibahDetailDocumentSheet> createState() =>
      _HibahDetailDocumentSheetState();
}

class _HibahDetailDocumentSheetState extends State<_HibahDetailDocumentSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PlatformFile? _selectedFile;
  String? _documentType;
  String? _hibahGroupId;
  bool _isPickingFile = false;

  InputDecoration _fieldDecoration(String label) {
    IconData? prefix;
    switch (label) {
      case 'Document type':
        prefix = Icons.file_present_outlined;
        break;
      case 'Link to asset':
      case 'Link to asset (optional)':
        prefix = Icons.home_work_outlined;
        break;
      default:
        prefix = null;
    }

    return FormDecorationHelper.roundedInputDecoration(
      context: context,
      labelText: label,
      prefixIcon: prefix,
    );
  }

  bool _requiresAsset(String? key) {
    if (key == null) return false;
    return widget.options.any(
      (_HibahDocumentOption option) =>
          option.key == key && option.requiresAsset,
    );
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = result.files.first);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile?.bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    final String mimeType =
        lookupMimeType(
          _selectedFile!.name,
          headerBytes: _selectedFile!.bytes,
        ) ??
        'application/octet-stream';

    Navigator.of(context).pop(
      _NewHibahDocumentDraft(
        documentType: _documentType!,
        file: _selectedFile!,
        mimeType: mimeType,
        hibahGroupId: _requiresAsset(_documentType) ? _hibahGroupId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add document',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can keep adding supporting documents here whenever you are ready.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: _documentType,
                          decoration: _fieldDecoration('Document type'),
                          isExpanded: true,
                          icon: SampulIcons.buildIcon(
                            SampulIcons.chevronDown,
                            width: 24,
                            height: 24,
                          ),
                          items: widget.options
                              .map(
                                (_HibahDocumentOption option) =>
                                    DropdownMenuItem<String>(
                                  value: option.key,
                                  child: Text(
                                    option.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _documentType = value;
                              if (!_requiresAsset(value)) {
                                _hibahGroupId = null;
                              } else if (_hibahGroupId == null &&
                                  widget.groups.isNotEmpty) {
                                _hibahGroupId = widget.groups.first.id;
                              }
                            });
                          },
                          validator: (String? value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _hibahGroupId,
                          decoration: _fieldDecoration(
                            _requiresAsset(_documentType)
                                ? 'Link to asset'
                                : 'Link to asset (optional)',
                          ),
                          isExpanded: true,
                          icon: SampulIcons.buildIcon(
                            SampulIcons.chevronDown,
                            width: 24,
                            height: 24,
                          ),
                          items: widget.groups
                              .map(
                                (HibahGroup group) => DropdownMenuItem<String>(
                                  value: group.id,
                                  child: Text(group.propertyName ?? 'Asset'),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) =>
                              setState(() => _hibahGroupId = value),
                          validator: (String? value) {
                            if (_requiresAsset(_documentType) &&
                                (value == null || value.isEmpty)) {
                              return 'Please link this document to an asset';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isPickingFile ? null : _pickFile,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(_selectedFile?.name ?? 'Select file'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_selectedFile != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _save,
                            icon: const Icon(Icons.attach_file_outlined),
                            label: Text(
                              'Upload document',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
