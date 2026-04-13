import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/analytics_screens.dart';
import '../l10n/app_localizations.dart';
import '../models/user_coupon.dart';
import '../services/user_coupon_service.dart';
import 'referral_dashboard_screen.dart';

/// Lists coupons (Hibah, Wasiat, and future types) with active vs past.
class UserCouponsScreen extends StatefulWidget {
  const UserCouponsScreen({super.key});

  @override
  State<UserCouponsScreen> createState() => _UserCouponsScreenState();
}

class _UserCouponsScreenState extends State<UserCouponsScreen> {
  bool _loading = true;
  List<UserCoupon> _coupons = <UserCoupon>[];

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static const Color _brandPurple = Color.fromRGBO(83, 61, 233, 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await UserCouponService.instance.fetchMine();
      if (!mounted) return;
      setState(() {
        _coupons = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _productTitle(AppLocalizations l10n, UserCoupon c) {
    if (c.isWasiat) return l10n.couponProductWasiat;
    if (c.isHibah) return l10n.couponProductHibah;
    return l10n.couponProductOther;
  }

  String _productDescription(AppLocalizations l10n, UserCoupon c) {
    if (c.isWasiat) {
      return l10n.couponDescriptionWasiat(l10n.wasiatAccessPanelTitle);
    }
    if (c.isHibah) {
      return l10n.couponDescriptionHibah;
    }
    return l10n.couponDescriptionOther;
  }

  IconData _leadingIcon(UserCoupon c) {
    if (c.isWasiat) return Icons.description_outlined;
    if (c.isHibah) return Icons.home_work_outlined;
    return Icons.local_offer_outlined;
  }

  String _statusLabel(AppLocalizations l10n, UserCoupon c) {
    if (c.status == 'used') return l10n.couponStatusUsed;
    if (c.status == 'expired' || !c.expiresAt.isAfter(DateTime.now())) {
      return l10n.couponStatusExpired;
    }
    return l10n.couponStatusActive;
  }

  Color _statusColor(ColorScheme cs, UserCoupon c) {
    if (c.status == 'used') return cs.outline;
    if (c.status == 'expired' || !c.expiresAt.isAfter(DateTime.now())) {
      return cs.error;
    }
    return _brandPurple;
  }

  Widget _roundedPanel({
    required ColorScheme cs,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _emptyBlock({
    required ThemeData theme,
    required ColorScheme cs,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _couponRows({
    required ThemeData theme,
    required ColorScheme cs,
    required AppLocalizations l10n,
    required List<UserCoupon> items,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(items.length, (int i) {
        final UserCoupon c = items[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.65),
              ),
            _couponEntry(theme: theme, cs: cs, l10n: l10n, c: c),
          ],
        );
      }),
    );
  }

  Widget _couponEntry({
    required ThemeData theme,
    required ColorScheme cs,
    required AppLocalizations l10n,
    required UserCoupon c,
  }) {
    final String status = _statusLabel(l10n, c);
    final Color stColor = _statusColor(cs, c);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Icon(
              _leadingIcon(c),
              color: _brandPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _productTitle(l10n, c),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: stColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.couponDiscountPercent(c.discountPercent),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _brandPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _productDescription(l10n, c),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.couponExpiresOn(_date.format(c.expiresAt.toLocal())),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (c.usedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.couponUsedOnDate(_date.format(c.usedAt!.toLocal())),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required ThemeData theme,
    required ColorScheme cs,
    required AppLocalizations l10n,
    required String heading,
    required List<UserCoupon> items,
    required String emptyTitle,
    required String emptyBody,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _roundedPanel(
          cs: cs,
          child: items.isEmpty
              ? _emptyBlock(
                  theme: theme,
                  cs: cs,
                  title: emptyTitle,
                  body: emptyBody,
                )
              : _couponRows(
                  theme: theme,
                  cs: cs,
                  l10n: l10n,
                  items: items,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final DateTime now = DateTime.now();
    bool usable(UserCoupon c) =>
        c.status == 'active' && c.expiresAt.isAfter(now);

    final List<UserCoupon> active = _coupons.where(usable).toList();
    final List<UserCoupon> past = _coupons.where((UserCoupon c) => !usable(c)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.couponsScreenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      l10n.couponsScreenHeadline,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.couponsScreenIntro,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(
                                name: AnalyticsScreens.referralDashboard,
                              ),
                              builder: (_) => const ReferralDashboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.card_giftcard_outlined),
                        label: Text(l10n.couponsGoToReferralsButton),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      theme: theme,
                      cs: cs,
                      l10n: l10n,
                      heading: l10n.couponsSectionActive,
                      items: active,
                      emptyTitle: l10n.couponsEmptyActiveTitle,
                      emptyBody: l10n.couponsEmptyActive,
                    ),
                    const SizedBox(height: 28),
                    _section(
                      theme: theme,
                      cs: cs,
                      l10n: l10n,
                      heading: l10n.couponsSectionPast,
                      items: past,
                      emptyTitle: l10n.couponsEmptyPastTitle,
                      emptyBody: l10n.couponsEmptyPast,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
