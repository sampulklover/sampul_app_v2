import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../models/trust_charity.dart';
import '../services/trust_service.dart';
import 'trust_edit_screen.dart';
import 'trust_beneficiary_form_screen.dart';

class TrustDashboardScreen extends StatefulWidget {
  final Trust trust;

  const TrustDashboardScreen({super.key, required this.trust});

  @override
  State<TrustDashboardScreen> createState() => _TrustDashboardScreenState();
}

class _TrustDashboardScreenState extends State<TrustDashboardScreen> {
  bool _isLoading = true;
  List<TrustBeneficiary> _beneficiaries = [];
  List<TrustCharity> _charities = [];
  bool _isCopyCooldown = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      final charities = await TrustService.instance.getCharitiesByTrustId(widget.trust.id!);
      
      if (mounted) {
        setState(() {
          _beneficiaries = beneficiaries;
          _charities = charities;
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

  double _calculateHealthcare() {
    // Sum of medical expenses from beneficiaries
    // For now, we'll use a placeholder calculation
    // In a real scenario, you might have specific medical expense amounts
    double total = 0.0;
    for (var beneficiary in _beneficiaries) {
      if (beneficiary.medicalExpenses == true) {
        // If there's a specific amount field, use it; otherwise use a default
        // This is a placeholder - adjust based on your data model
        total += 0.0; // Placeholder
      }
    }
    return total;
  }

  double _calculateEducation() {
    // Sum of education expenses from beneficiaries
    double total = 0.0;
    for (var beneficiary in _beneficiaries) {
      if (beneficiary.educationExpenses == true) {
        // Use monthly distribution education if available
        total += (beneficiary.monthlyDistributionEducation ?? 0).toDouble();
      }
    }
    return total;
  }

  double _calculateExpenses() {
    // Sum of monthly distribution living from beneficiaries
    double total = 0.0;
    for (var beneficiary in _beneficiaries) {
      total += (beneficiary.monthlyDistributionLiving ?? 0).toDouble();
    }
    return total;
  }

  double _calculateCharitable() {
    // Sum of donation amounts from charities
    double total = 0.0;
    for (var charity in _charities) {
      total += charity.donationAmount ?? 0.0;
    }
    return total;
  }

  double _calculateDebt() {
    // Sum of settle outstanding amounts
    // For now, this is a placeholder
    double total = 0.0;
    for (var beneficiary in _beneficiaries) {
      if (beneficiary.settleOutstanding == true) {
        // Placeholder - adjust based on your data model
        total += 0.0;
      }
    }
    return total;
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

    final trustCode = widget.trust.trustCode;
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
                    builder: (_) => TrustEditScreen(initial: widget.trust),
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
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              if (widget.trust.trustCode != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  widget.trust.trustCode!,
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
                                      _formatEstimatedNetWorth(widget.trust.estimatedNetWorth),
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
                                            color: _getStatusColor(widget.trust.computedStatus, context),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getStatusLabel(widget.trust.computedStatus),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _getStatusColor(widget.trust.computedStatus, context),
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

                    // Category cards grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        // Add Instruction card
                        _CategoryCard(
                          title: 'Add',
                          subtitle: 'Instruction',
                          icon: Icons.add,
                          onTap: () {
                            // TODO: Navigate to add instruction screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add Instruction feature coming soon')),
                            );
                          },
                          isAddCard: true,
                        ),
                        // Healthcare card
                        _CategoryCard(
                          title: 'Healthcare',
                          subtitle: _formatAmount(_calculateHealthcare()),
                          icon: Icons.medical_services_outlined,
                          iconColor: colorScheme.primary,
                          onTap: () {
                            // TODO: Navigate to healthcare details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Healthcare details coming soon')),
                            );
                          },
                        ),
                        // Expenses card
                        _CategoryCard(
                          title: 'Expenses',
                          subtitle: _formatAmount(_calculateExpenses()),
                          icon: Icons.people_outline,
                          iconColor: colorScheme.primary,
                          onTap: () {
                            // TODO: Navigate to expenses details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Expenses details coming soon')),
                            );
                          },
                        ),
                        // Charitable card
                        _CategoryCard(
                          title: 'Charitable',
                          subtitle: _formatAmount(_calculateCharitable()),
                          icon: Icons.favorite_outline,
                          iconColor: colorScheme.primary,
                          onTap: () {
                            // TODO: Navigate to charitable details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Charitable details coming soon')),
                            );
                          },
                        ),
                        // Education card
                        _CategoryCard(
                          title: 'Education',
                          subtitle: _formatAmount(_calculateEducation()),
                          icon: Icons.school_outlined,
                          iconColor: colorScheme.primary,
                          onTap: () {
                            // TODO: Navigate to education details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Education details coming soon')),
                            );
                          },
                        ),
                        // Debt card
                        _CategoryCard(
                          title: 'Debt',
                          subtitle: _formatAmount(_calculateDebt()),
                          icon: Icons.receipt_long_outlined,
                          iconColor: colorScheme.primary,
                          onTap: () {
                            // TODO: Navigate to debt details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debt details coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
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
  final VoidCallback onTap;
  final bool isAddCard;
  final Color? iconColor;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isAddCard = false,
    this.iconColor,
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
            color: isAddCard
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : colorScheme.primaryContainer.withOpacity(0.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isAddCard
                    ? colorScheme.onSurfaceVariant
                    : iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAddCard
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAddCard
                      ? colorScheme.onSurfaceVariant.withOpacity(0.7)
                      : colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
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
