import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

import '../config/stripe_config.dart';
import '../services/billing_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with WidgetsBindingObserver {
  bool _loading = true;
  bool _processing = false;
  BillingStatus _status = BillingStatus();
  List<BillingPlan> _plans = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh billing status when app comes back to foreground
    // This handles the case when user returns from Stripe checkout
    if (state == AppLifecycleState.resumed) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        BillingService.instance.fetchStatus(),
        BillingService.instance.fetchPlans(),
      ]);
      final status = results[0] as BillingStatus;
      final plans = results[1] as List<BillingPlan>;
      if (!mounted) return;
      setState(() {
        _status = status;
        _plans = plans;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Billing load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatPrice(int? amount, String? currency, String? interval) {
    if (amount == null || currency == null) return 'Price unavailable';
    final formatter = NumberFormat.simpleCurrency(
      name: currency.toUpperCase(),
      decimalDigits: 2,
    );
    final value = amount / 100; // Stripe uses smallest unit
    final intervalLabel = (interval == null || interval == 'one_time')
        ? 'one-time'
        : '/ $interval';
    return '${formatter.format(value)} $intervalLabel';
  }

  Future<void> _startCheckout(String priceId) async {
    final successUrl = '${StripeConfig.returnUrlScheme}://billing/success';
    final cancelUrl = '${StripeConfig.returnUrlScheme}://billing/cancel';
    setState(() => _processing = true);
    try {
      final url = await BillingService.instance.createCheckoutSession(
        priceId: priceId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start checkout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openPortal() async {
    final returnUrl = '${StripeConfig.returnUrlScheme}://billing/portal';
    setState(() => _processing = true);
    try {
      final url = await BillingService.instance.createBillingPortal(returnUrl: returnUrl);
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open billing portal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_plans.isEmpty)
                    const Center(child: Text('No plans available. Pull to refresh.'))
                  else ...[
                    for (final plan in _plans) ...[
                      _PlanCard(
                        name: plan.name,
                        priceLabel: _formatPrice(plan.amount, plan.currency, plan.interval),
                        description: plan.description ?? '',
                        features: const [],
                        isCurrent: _status.planId == plan.priceId,
                        isRecommended: plan.priceId == StripeConfig.securePlanPriceId,
                        actionLabel: _status.planId == plan.priceId && _status.isSubscribed
                            ? 'Manage subscription'
                            : 'Choose plan',
                        onAction: _processing
                            ? null
                            : () => _status.planId == plan.priceId && _status.isSubscribed
                                ? _openPortal()
                                : _startCheckout(plan.priceId),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (_status.status != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: Text('Current status: ${_status.status}'),
                        subtitle: Text(_status.planName != null
                            ? 'Plan: ${_status.planName}'
                            : 'Plan: unknown'),
                        trailing: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: _status.isSubscribed
          ? FloatingActionButton.extended(
              onPressed: _processing ? null : _openPortal,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage subscription'),
            )
          : null,
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.actionLabel,
    required this.onAction,
    this.isCurrent = false,
    this.isRecommended = false,
  });

  final String name;
  final String priceLabel;
  final String description;
  final List<String> features;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool isCurrent;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isRecommended ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current plan',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.isEmpty
                  ? [
                      Chip(
                        label: const Text('No feature list'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                    ]
                  : features
                      .map(
                        (f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                  foregroundColor: isRecommended ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

