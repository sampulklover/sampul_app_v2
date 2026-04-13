import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/analytics_screens.dart';
import '../config/trust_constants.dart';
import '../config/wasiat_chip_amount.dart';
import '../models/hibah_payment.dart';
import '../models/trust_payment.dart';
import '../models/user_coupon.dart';
import '../models/wasiat_subscription_payment.dart';
import '../services/analytics_service.dart';
import '../services/billing_service.dart';
import '../services/hibah_payment_service.dart';
import '../services/trust_payment_service.dart';
import '../services/user_coupon_service.dart';
import '../services/wasiat_subscription_payment_service.dart';
import '../utils/card_decoration_helper.dart';
import '../utils/form_decoration_helper.dart';
import '../widgets/payment_status_modal.dart';
import 'hibah_management_screen.dart';
import 'trust_management_screen.dart';

/// Per-product plan price, status (Wasiat), actions, and collapsible payment history.
class PlansOverviewScreen extends StatefulWidget {
  const PlansOverviewScreen({super.key});

  @override
  State<PlansOverviewScreen> createState() => _PlansOverviewScreenState();
}

class _PlansOverviewScreenState extends State<PlansOverviewScreen> with WidgetsBindingObserver {
  bool _loading = true;
  bool _processingWasiat = false;
  BillingStatus _status = const BillingStatus();
  bool? _lastIsSubscribed;
  bool _awaitingWasiatPaymentResult = false;

  /// Same PNG assets as the home screen action grid and Others menu.
  static const String _iconAssetWasiat = 'assets/will-certificate-scroll.png';
  static const String _iconAssetPropertyTrust = 'assets/property-colour-key.png';
  static const String _iconAssetTrust = 'assets/trust-family-card.png';

  static final NumberFormat _money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
  static final DateFormat _historyWhen = DateFormat('d MMM yyyy, h:mm a');

  List<WasiatSubscriptionPayment> _wasiatPayments = <WasiatSubscriptionPayment>[];
  List<HibahPayment> _hibahPayments = <HibahPayment>[];
  List<TrustPayment> _trustPayments = <TrustPayment>[];
  List<UserCoupon> _wasiatCoupons = <UserCoupon>[];
  UserCoupon? _selectedWasiatCoupon;

  static final DateFormat _couponExpiryFormat = DateFormat('d MMM y');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final List<Object> core = await Future.wait(<Future<Object>>[
        BillingService.instance.fetchStatus(),
        WasiatSubscriptionPaymentService.instance.fetchPaymentHistory(),
      ]);
      final BillingStatus status = core[0] as BillingStatus;
      final List<WasiatSubscriptionPayment> wasiatList =
          core[1] as List<WasiatSubscriptionPayment>;

      List<HibahPayment> hibahList = <HibahPayment>[];
      try {
        hibahList = await HibahPaymentService.instance.fetchAllPaymentsForCurrentUser();
      } catch (_) {
        /* RLS or network; keep Wasiat usable */
      }

      List<TrustPayment> trustList = <TrustPayment>[];
      try {
        trustList = await TrustPaymentService.instance.fetchAllPaymentsForCurrentUser();
      } catch (_) {
        /* RLS or network; keep Wasiat usable */
      }

      List<UserCoupon> wasiatCouponList = <UserCoupon>[];
      try {
        wasiatCouponList =
            await UserCouponService.instance.fetchActiveForProduct('wasiat');
      } catch (_) {}

      if (!mounted) return;
      UserCoupon? keepWasiat;
      if (_selectedWasiatCoupon != null) {
        final int idx = wasiatCouponList.indexWhere(
          (UserCoupon c) => c.id == _selectedWasiatCoupon!.id,
        );
        keepWasiat = idx >= 0 ? wasiatCouponList[idx] : null;
      }
      setState(() {
        _status = status;
        _wasiatPayments = wasiatList;
        _hibahPayments = hibahList;
        _trustPayments = trustList;
        _wasiatCoupons = wasiatCouponList;
        _selectedWasiatCoupon = keepWasiat;
      });

      final bool isSubscribed = status.isSubscribed;
      if (_lastIsSubscribed != null && _lastIsSubscribed != isSubscribed) {
        await AnalyticsService.capture(
          isSubscribed ? 'subscription activated' : 'subscription inactive',
          properties: <String, Object>{
            'provider': 'chip',
            'has_chip_window': status.hasChipBillingWindow,
          },
        );
      }
      _lastIsSubscribed = isSubscribed;
    } catch (_) {
      if (mounted) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plansOverviewLoadError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) {
      unawaited(_maybeShowWasiatPaymentResult());
    }
  }

  /// After CHIP checkout, show the same result dialog as Hibah / Trust once the
  /// newest row is paid or failed (not still `initiated`).
  Future<void> _maybeShowWasiatPaymentResult() async {
    if (!_awaitingWasiatPaymentResult || !mounted) return;
    final WasiatSubscriptionPayment? latest =
        _wasiatPayments.isEmpty ? null : _wasiatPayments.first;
    if (latest == null) return;
    if (!latest.isSuccessful && !latest.isFailed) return;

    setState(() => _awaitingWasiatPaymentResult = false);
    if (!mounted) return;

    final bool isSuccess = latest.isSuccessful;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => PaymentStatusModal(
        isSuccess: isSuccess,
        message: isSuccess
            ? 'Your payment of ${_money.format(latest.amount / 100.0)} has been processed successfully.'
            : 'Your payment could not be processed. Please try again.',
      ),
    );
  }

  String _formatDate(DateTime d) {
    return DateFormat.yMMMd().format(d);
  }

  String _hibahStatusLabel(AppLocalizations l10n, HibahPayment p) {
    if (p.isSuccessful) return l10n.wasiatPaymentStatusPaid;
    if (p.isFailed) return l10n.wasiatPaymentStatusFailed;
    return l10n.wasiatPaymentStatusProcessing;
  }

  Color _hibahStatusColor(HibahPayment p, ColorScheme cs) {
    if (p.isSuccessful) return Colors.green.shade700;
    if (p.isFailed) return Colors.red.shade700;
    return cs.tertiary;
  }

  String _trustStatusLabel(AppLocalizations l10n, TrustPayment p) {
    if (p.isRefunded) return l10n.plansPaymentStatusRefunded;
    if (p.isSuccessful) return l10n.wasiatPaymentStatusPaid;
    if (p.isFailed) return l10n.wasiatPaymentStatusFailed;
    return l10n.wasiatPaymentStatusProcessing;
  }

  Color _trustStatusColor(TrustPayment p, ColorScheme cs) {
    if (p.isRefunded) return Colors.deepOrange.shade700;
    if (p.isSuccessful) return Colors.green.shade700;
    if (p.isFailed) return Colors.red.shade700;
    return cs.tertiary;
  }

  String _wasiatStatusLabel(AppLocalizations l10n, WasiatSubscriptionPayment p) {
    if (p.isSuccessful) return l10n.wasiatPaymentStatusPaid;
    if (p.isFailed) return l10n.wasiatPaymentStatusFailed;
    return l10n.wasiatPaymentStatusProcessing;
  }

  Color _wasiatStatusColor(WasiatSubscriptionPayment p, ColorScheme cs) {
    if (p.isSuccessful) return Colors.green.shade700;
    if (p.isFailed) return Colors.red.shade700;
    return cs.tertiary;
  }

  String _shortRef(String? ref) {
    if (ref == null || ref.isEmpty) return '';
    if (ref.length <= 10) return ref;
    return '${ref.substring(0, 6)}…${ref.substring(ref.length - 4)}';
  }

  Widget _paymentLine({
    required ThemeData theme,
    required ColorScheme cs,
    required String amountText,
    required String statusLabel,
    required Color statusColor,
    required String when,
    required String? refLine,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        amountText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  when,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (refLine != null && refLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    refLine,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
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

  static const double _btnRadius = 16;
  static const double _primaryBtnHeight = 52;
  static const double _secondaryBtnHeight = 48;

  /// Matches primary CTAs on checklist / will management (elevated, 16 radius).
  ButtonStyle _elevatedCtaStyle(ColorScheme cs) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, _primaryBtnHeight),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_btnRadius),
      ),
    );
  }

  /// Matches secondary CTAs (outlined, 16 radius).
  ButtonStyle _outlinedCtaStyle(ColorScheme cs) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, _secondaryBtnHeight),
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_btnRadius),
      ),
    );
  }

  Widget _planCardHeader({
    required ThemeData theme,
    required ColorScheme cs,
    required String iconAssetPath,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            iconAssetPath,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            cacheWidth: 88,
            cacheHeight: 88,
            errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: cs.primary, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  /// Plan access state at a glance (updates with billing).
  Widget _wasiatAccessBadge(AppLocalizations l10n, ThemeData theme, ColorScheme cs) {
    final DateTime? periodEnd = _status.periodEnd;
    final bool active = _status.isSubscribed;

    if (active) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
            ),
            child: Text(
              l10n.plansWasiatBadgeActive,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (periodEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.wasiatAccessActiveUntil(_formatDate(periodEnd)),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
        ],
      );
    }

    final bool showEndedDate = periodEnd != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            showEndedDate ? l10n.plansWasiatBadgeEnded : l10n.plansWasiatBadgeInactive,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showEndedDate) ...[
          const SizedBox(height: 4),
          Text(
            l10n.wasiatPlanEndedOn(_formatDate(periodEnd)),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _collapsiblePaymentSection({
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme cs,
    required String title,
    required int paymentCount,
    required Widget expandedChild,
  }) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: false,
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: cs.primary,
        collapsedIconColor: cs.onSurfaceVariant,
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          paymentCount == 0
              ? l10n.plansPaymentHistorySubtitleEmpty
              : l10n.plansPaymentHistorySubtitleCount(paymentCount),
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: expandedChild,
          ),
        ],
      ),
    );
  }

  Widget _wasiatHistoryBody(AppLocalizations l10n, ThemeData theme, ColorScheme cs) {
    if (_wasiatPayments.isEmpty) {
      return Text(
        l10n.wasiatPaymentHistoryEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _wasiatPayments.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
      itemBuilder: (BuildContext context, int i) {
        final WasiatSubscriptionPayment p = _wasiatPayments[i];
        final String when =
            p.createdAt != null ? _historyWhen.format(p.createdAt!.toLocal()) : '—';
        final String refShort = _shortRef(p.chipPaymentId);
        return _paymentLine(
          theme: theme,
          cs: cs,
          amountText: _money.format(p.amount / 100.0),
          statusLabel: _wasiatStatusLabel(l10n, p),
          statusColor: _wasiatStatusColor(p, cs),
          when: when,
          refLine: refShort.isNotEmpty ? 'Ref $refShort' : null,
        );
      },
    );
  }

  Widget _propertyTrustHistoryBody(AppLocalizations l10n, ThemeData theme, ColorScheme cs) {
    if (_hibahPayments.isEmpty) {
      return Text(
        l10n.plansPaymentHistoryEmptyProduct,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _hibahPayments.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
      itemBuilder: (BuildContext context, int i) {
        final HibahPayment p = _hibahPayments[i];
        final String when =
            p.createdAt != null ? _historyWhen.format(p.createdAt!.toLocal()) : '—';
        final String? hid = p.hibahId;
        final String extra = hid != null && hid.isNotEmpty
            ? '${l10n.plansPaymentCertificateRefLabel} ${_shortRef(hid)}'
            : '';
        final String refShort = _shortRef(p.chipPaymentId);
        final String refLine = <String>[
          if (extra.isNotEmpty) extra,
          if (refShort.isNotEmpty) 'Ref $refShort',
        ].join(' · ');
        return _paymentLine(
          theme: theme,
          cs: cs,
          amountText: _money.format(p.amount / 100.0),
          statusLabel: _hibahStatusLabel(l10n, p),
          statusColor: _hibahStatusColor(p, cs),
          when: when,
          refLine: refLine.isNotEmpty ? refLine : null,
        );
      },
    );
  }

  Widget _trustHistoryBody(AppLocalizations l10n, ThemeData theme, ColorScheme cs) {
    if (_trustPayments.isEmpty) {
      return Text(
        l10n.plansPaymentHistoryEmptyProduct,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trustPayments.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
      itemBuilder: (BuildContext context, int i) {
        final TrustPayment p = _trustPayments[i];
        final String when =
            p.createdAt != null ? _historyWhen.format(p.createdAt!.toLocal()) : '—';
        final int? tid = p.trustId;
        final String trustLine =
            tid != null ? l10n.plansPaymentTrustRefLabel(tid.toString()) : '';
        final String refShort = _shortRef(p.chipPaymentId);
        final String refLine = <String>[
          if (trustLine.isNotEmpty) trustLine,
          if (refShort.isNotEmpty) 'Ref $refShort',
        ].join(' · ');
        return _paymentLine(
          theme: theme,
          cs: cs,
          amountText: _money.format(p.amount / 100.0),
          statusLabel: _trustStatusLabel(l10n, p),
          statusColor: _trustStatusColor(p, cs),
          when: when,
          refLine: refLine.isNotEmpty ? refLine : null,
        );
      },
    );
  }

  Future<void> _startWasiatCheckout() async {
    setState(() => _processingWasiat = true);
    try {
      await AnalyticsService.capture(
        'checkout started',
        properties: <String, Object>{
          'provider': 'chip',
          'product': 'wasiat_annual',
          'amount_cents': kWasiatYearlyAmountCents,
        },
      );

      final String clientId = await TrustPaymentService.instance.getChipClient();
      final paymentResponse =
          await WasiatSubscriptionPaymentService.instance.createAnnualPayment(
        clientId: clientId,
        userCouponId: _selectedWasiatCoupon?.id,
      );

      if (paymentResponse.checkoutUrl.isEmpty) {
        throw Exception('No checkout URL received from payment provider');
      }

      final Uri uri = Uri.parse(paymentResponse.checkoutUrl);
      if (!await canLaunchUrl(uri)) {
        throw Exception('Unable to open payment page');
      }

      await AnalyticsService.capture(
        'checkout opened',
        properties: const <String, Object>{'provider': 'chip'},
      );

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _awaitingWasiatPaymentResult = true);
    } catch (e) {
      await AnalyticsService.capture(
        'checkout failed',
        properties: <String, Object>{
          'provider': 'chip',
          'error': e.toString(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We couldn\'t start checkout. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingWasiat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final double annualRm = kWasiatYearlyAmountCents / 100.0;
    final int? wasiatPayableCents = _selectedWasiatCoupon != null
        ? UserCoupon.discountedTotalCents(
            kWasiatYearlyAmountCents,
            _selectedWasiatCoupon!.discountPercent,
          )
        : null;
    final double? wasiatPayableRm =
        wasiatPayableCents != null ? wasiatPayableCents / 100.0 : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wasiatAccessPanelTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  CardDecorationHelper.styledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _planCardHeader(
                          theme: theme,
                          cs: cs,
                          iconAssetPath: _iconAssetWasiat,
                          title: l10n.planSectionWasiatTitle,
                          trailing: _wasiatAccessBadge(l10n, theme, cs),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_money.format(annualRm)} ${l10n.wasiatPlanPerYearLabel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        if (_wasiatCoupons.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<UserCoupon?>(
                            value: _selectedWasiatCoupon,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.checkoutCouponLabel,
                            ),
                            items: <DropdownMenuItem<UserCoupon?>>[
                              DropdownMenuItem<UserCoupon?>(
                                value: null,
                                child: Text(l10n.checkoutNoCoupon),
                              ),
                              ..._wasiatCoupons.map(
                                (UserCoupon c) => DropdownMenuItem<UserCoupon?>(
                                  value: c,
                                  child: Text(
                                    '${l10n.couponDiscountPercent(c.discountPercent)} · '
                                    '${l10n.couponExpiresOn(_couponExpiryFormat.format(c.expiresAt.toLocal()))}',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: _processingWasiat
                                ? null
                                : (UserCoupon? v) {
                                    setState(() => _selectedWasiatCoupon = v);
                                  },
                          ),
                        ],
                        if (wasiatPayableRm != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${l10n.checkoutYouPay}: ${_money.format(wasiatPayableRm)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _processingWasiat
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : _status.isSubscribed
                                ? OutlinedButton(
                                    style: _outlinedCtaStyle(cs),
                                    onPressed: _startWasiatCheckout,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.wasiatPlanRenewEarly,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20, color: cs.primary),
                                      ],
                                    ),
                                  )
                                : ElevatedButton(
                                    style: _elevatedCtaStyle(cs),
                                    onPressed: _startWasiatCheckout,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.wasiatPlanPayChip,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20, color: cs.onPrimary),
                                      ],
                                    ),
                                  ),
                        const SizedBox(height: 8),
                        Divider(height: 24, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.65)),
                        _collapsiblePaymentSection(
                          l10n: l10n,
                          theme: theme,
                          cs: cs,
                          title: l10n.wasiatPaymentHistoryTitle,
                          paymentCount: _wasiatPayments.length,
                          expandedChild: _wasiatHistoryBody(l10n, theme, cs),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CardDecorationHelper.styledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _planCardHeader(
                          theme: theme,
                          cs: cs,
                          iconAssetPath: _iconAssetPropertyTrust,
                          title: l10n.planSectionPropertyTrustTitle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.planPropertyTrustSummary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          style: _outlinedCtaStyle(cs),
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(name: AnalyticsScreens.hibahManagement),
                                builder: (_) => const HibahManagementScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.plansOpenPropertyTrust,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20, color: cs.primary),
                            ],
                          ),
                        ),
                        Divider(height: 24, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.65)),
                        _collapsiblePaymentSection(
                          l10n: l10n,
                          theme: theme,
                          cs: cs,
                          title: l10n.plansPaymentHistoryForPropertyTrust,
                          paymentCount: _hibahPayments.length,
                          expandedChild: _propertyTrustHistoryBody(l10n, theme, cs),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CardDecorationHelper.styledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _planCardHeader(
                          theme: theme,
                          cs: cs,
                          iconAssetPath: _iconAssetTrust,
                          title: l10n.planSectionTrustTitle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.planTrustSummary(
                            _money.format(TrustConstants.minTrustAmount / 100.0),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          style: _outlinedCtaStyle(cs),
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(name: AnalyticsScreens.trustManagement),
                                builder: (_) => const TrustManagementScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.plansOpenTrustDashboard,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20, color: cs.primary),
                            ],
                          ),
                        ),
                        Divider(height: 24, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.65)),
                        _collapsiblePaymentSection(
                          l10n: l10n,
                          theme: theme,
                          cs: cs,
                          title: l10n.plansPaymentHistoryForTrust,
                          paymentCount: _trustPayments.length,
                          expandedChild: _trustHistoryBody(l10n, theme, cs),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
