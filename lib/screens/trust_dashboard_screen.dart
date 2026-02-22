import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../services/trust_service.dart';
import 'trust_edit_screen.dart';
import 'trust_beneficiary_form_screen.dart';
import 'fund_support_config_screen.dart';

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

class _TrustDashboardScreenState extends State<TrustDashboardScreen> {
  bool _isLoading = true;
  List<TrustBeneficiary> _beneficiaries = [];
  bool _isCopyCooldown = false;
  Timer? _cooldownTimer;
  /// Local copy of trust so we can refresh after editing fund support config.
  Trust? _currentTrust;

  Trust get _trust => _currentTrust ?? widget.trust;

  @override
  void initState() {
    super.initState();
    _currentTrust = widget.trust;
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
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.trust.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final beneficiaries = await TrustService.instance.getBeneficiariesByTrustId(widget.trust.id!);
      // Note: Charities are now stored in fundSupportConfigs['charitable']['charities']
      
      if (mounted) {
        setState(() {
          _beneficiaries = beneficiaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'RM 0.00';
    return 'RM ${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
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

  String _getStatusLabel(TrustStatus status) {
    switch (status) {
      case TrustStatus.submitted:
        return 'Submitted';
      case TrustStatus.approved:
        return 'Your plan is active';
      case TrustStatus.rejected:
        return 'Rejected';
      case TrustStatus.draft:
        return 'Draft';
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

  double _calculateTotalDistribution() {
    double total = 0.0;
    for (var beneficiary in _beneficiaries) {
      total += (beneficiary.monthlyDistributionLiving ?? 0).toDouble();
      total += (beneficiary.monthlyDistributionEducation ?? 0).toDouble();
    }
    return total;
  }

  double _calculateBeneficiaryPercentage(TrustBeneficiary beneficiary) {
    final total = _calculateTotalDistribution();
    if (total == 0) return 0.0;
    
    final beneficiaryTotal = (beneficiary.monthlyDistributionLiving ?? 0).toDouble() +
        (beneficiary.monthlyDistributionEducation ?? 0).toDouble();
    
    return (beneficiaryTotal / total) * 100;
  }

  Future<void> _copyTrustId() async {
    // Prevent abuse: silently ignore clicks during cooldown period
    if (_isCopyCooldown) {
      return;
    }

    final trustCode = _trust.trustCode;
    if (trustCode == null || trustCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trust ID not available'),
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
        const SnackBar(
          content: Text('Trust ID copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
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
                            'Family account created',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your family now has clear guidance, even if you’re not around to explain.',
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
                  'What happens now',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This family account is saved and will be followed according to the rules you’ve set.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Next steps',
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
                            'You may receive a confirmation email for your records (if enabled).',
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
                            'You can always return here to update beneficiaries, categories or amounts.',
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
                      'View instructions',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust Fund Details'),
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
                    return AlertDialog(
                      title: const Text('Delete Trust Fund'),
                      content: const Text('Are you sure you want to delete this trust fund? This action cannot be undone.'),
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
                if (confirm == true && widget.trust.id != null) {
                  try {
                    await TrustService.instance.deleteTrust(widget.trust.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trust Fund deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete trust fund: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                                                'Family Account',
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
                                          _getStatusLabel(_trust.computedStatus),
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

                    // Beneficiaries section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beneficiaries',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Who this fund will be distributed to',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _beneficiaries.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Add Beneficiary card
                                return _AddBeneficiaryCard(
                                  onTap: () async {
                                    if (widget.trust.id == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please save the trust first before adding beneficiaries'),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    final result = await Navigator.of(context).push<TrustBeneficiary>(
                                      MaterialPageRoute<TrustBeneficiary>(
                                        builder: (_) => const TrustBeneficiaryFormScreen(),
                                      ),
                                    );
                                    
                                    if (result != null && widget.trust.id != null) {
                                      try {
                                        await TrustService.instance.createBeneficiary(
                                          result.copyWith(trustId: widget.trust.id),
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Beneficiary added successfully'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          await _loadData();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to add beneficiary: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                );
                              }
                              
                              final beneficiary = _beneficiaries[index - 1];
                              final percentage = _calculateBeneficiaryPercentage(beneficiary);
                              
                              return _BeneficiaryCard(
                                beneficiary: beneficiary,
                                percentage: percentage,
                                onTap: () async {
                                  final result = await Navigator.of(context).push<TrustBeneficiary>(
                                    MaterialPageRoute<TrustBeneficiary>(
                                      builder: (_) => TrustBeneficiaryFormScreen(
                                        beneficiary: beneficiary,
                                      ),
                                    ),
                                  );
                                  
                                  if (result != null && beneficiary.id != null) {
                                    try {
                                      await TrustService.instance.updateBeneficiary(
                                        beneficiary.id!,
                                        result.toJson(),
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Beneficiary updated successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        await _loadData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to update beneficiary: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Instructions / categories section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Allocate what this trust fund will cover',
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
                            'title': 'Education',
                            'icon': Icons.school_outlined,
                            'calculateAmount': () => _calculateEducation(),
                          },
                          {
                            'id': 'living',
                            'title': 'Living Expenses',
                            'icon': Icons.home_outlined,
                            'calculateAmount': () => _calculateExpenses(),
                          },
                          {
                            'id': 'healthcare',
                            'title': 'Healthcare',
                            'icon': Icons.medical_services_outlined,
                            'calculateAmount': () => _calculateHealthcare(),
                          },
                          {
                            'id': 'charitable',
                            'title': 'Charitable',
                            'icon': Icons.volunteer_activism_outlined,
                            'calculateAmount': () => _calculateCharitable(),
                          },
                          {
                            'id': 'debt',
                            'title': 'Debt',
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
                            
                            return _CategoryCard(
                              title: title,
                              subtitle: isSelected ? _formatAmount(calculateAmount()) : 'Tap to set up',
                              icon: icon,
                              iconColor: isSelected 
                                  ? const Color.fromRGBO(49, 24, 211, 1)
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                              isUnselected: !isSelected,
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
                                        const SnackBar(
                                          content: Text('Settings saved'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to save: ${e.toString()}'),
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

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.isUnselected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 40,
                color: iconColor ?? const Color.fromRGBO(49, 24, 211, 1),
              ),
              const SizedBox(height: 8),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBeneficiaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBeneficiaryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer.withOpacity(0.4),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeneficiaryCard extends StatelessWidget {
  final TrustBeneficiary beneficiary;
  final double percentage;
  final VoidCallback onTap;

  const _BeneficiaryCard({
    required this.beneficiary,
    required this.percentage,
    required this.onTap,
  });

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = beneficiary.name ?? 'Unknown';
    final initials = _getInitials(name);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Percentage badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnershipSection extends StatelessWidget {
  const _PartnershipSection();

  @override
  Widget build(BuildContext context) {
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
                  const TextSpan(
                    text: 'Sampul partner with Rakyat Trustee and Halogen Capital ',
                  ),
                  const TextSpan(
                    text: 'to process your fund. ',
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to learn more page or open URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Learn more about our partners'),
                          ),
                        );
                      },
                      child: Text(
                        'Learn more',
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
