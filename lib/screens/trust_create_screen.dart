import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../models/trust.dart';
import '../models/trust_beneficiary.dart';
import '../models/trust_charity.dart';
import '../models/user_profile.dart';
import '../services/trust_service.dart';
import '../services/supabase_service.dart';
import '../config/trust_constants.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/card_decoration_helper.dart';
import 'trust_info_screen.dart';
import 'edit_profile_screen.dart';
import 'fund_support_config_screen.dart';
import '../widgets/stepper_footer_controls.dart';

class TrustCreateScreen extends StatefulWidget {
  const TrustCreateScreen({super.key});

  @override
  State<TrustCreateScreen> createState() => _TrustCreateScreenState();
}

class _TrustCreateScreenState extends State<TrustCreateScreen> {
  final GlobalKey<FormState> _financialFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _businessFormKey = GlobalKey<FormState>();

  // Beneficiaries
  final List<TrustBeneficiary> _beneficiaries = [];

  // Fund Support Categories with per-category configuration
  final Set<String> _selectedFundSupports = {};
  // Per-category configuration: Map<categoryId, config>
  final Map<String, Map<String, dynamic>> _fundSupportConfigs = {};
  
  // Helper to get or create config for a category
  Map<String, dynamic> _getCategoryConfig(String categoryId) {
    if (!_fundSupportConfigs.containsKey(categoryId)) {
      _fundSupportConfigs[categoryId] = {
        'durationType': null, // 'age' or 'lifetime'
        'endAge': 24.0, // Default age, range 18-40
        'isRegularPayments': null, // null means not selected yet - no option selected by default
        'paymentAmount': 1000.0, // Default RM 1,000 (only used when isRegularPayments is true)
        'paymentFrequency': null, // 'monthly', 'quarterly', 'yearly', 'when_conditions'
        'releaseCondition': null, // 'as_needed' or 'lump_sum'
      };
    }
    return _fundSupportConfigs[categoryId]!;
  }

  // Executor Selection
  String? _executorType; // 'someone_i_know' or 'sampul_professional'
  final Set<int> _selectedExecutorIds = {}; // IDs of selected family members when executorType is 'someone_i_know'
  bool _showExecutorGoodToKnow = true; // Show/hide the executor "Good to Know" info box
  List<Map<String, dynamic>> _familyMembers = []; // Family members for executor selection
  bool _isLoadingFamilyMembers = false;

  // Personal and Contact information now comes from UserProfile

  // Financial Information
  String? _selectedEstimatedNetWorth;
  String? _selectedSourceOfFund;
  final TextEditingController _purposeOfTransactionCtrl = TextEditingController();

  // Business Information
  final TextEditingController _employerNameCtrl = TextEditingController();
  final TextEditingController _businessNatureCtrl = TextEditingController();
  final TextEditingController _businessAddress1Ctrl = TextEditingController();
  final TextEditingController _businessAddress2Ctrl = TextEditingController();
  final TextEditingController _businessCityCtrl = TextEditingController();
  final TextEditingController _businessPostcodeCtrl = TextEditingController();
  final TextEditingController _businessStateCtrl = TextEditingController();
  String? _selectedBusinessCountry;

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  String? _profileError;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
    _fetchFamilyMembers();
  }

  Future<void> _fetchFamilyMembers() async {
    setState(() => _isLoadingFamilyMembers = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingFamilyMembers = false);
        return;
      }
      
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id, name, image_path, relationship, type')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _familyMembers = rows.cast<Map<String, dynamic>>();
          _isLoadingFamilyMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFamilyMembers = false);
      }
    }
  }

  @override
  void dispose() {
    _purposeOfTransactionCtrl.dispose();
    _employerNameCtrl.dispose();
    _businessNatureCtrl.dispose();
    _businessAddress1Ctrl.dispose();
    _businessAddress2Ctrl.dispose();
    _businessCityCtrl.dispose();
    _businessPostcodeCtrl.dispose();
    _businessStateCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillFromProfile() async {
    setState(() => _profileError = null);
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _profileError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  String _formatAddress(UserProfile? profile) {
    if (profile == null) return 'Not provided';
    
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  // Legacy beneficiary UI has been removed from the flow; beneficiaries are now
  // linked per fund-support category. The underlying list is kept only so we
  // can still pass any existing data through to the service if present.

  Widget _buildFundSupportStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fundSupportCategories = [
      {
        'id': 'education',
        'title': l10n.education,
        'subtitle': 'Tuition, books, school fees',
        'icon': Icons.school_outlined,
      },
      {
        'id': 'living',
        'title': l10n.livingExpenses,
        'subtitle': l10n.livingExpensesSubtitle,
        'icon': Icons.home_outlined,
      },
      {
        'id': 'healthcare',
        'title': l10n.healthcare,
        'subtitle': l10n.healthcareSubtitle,
        'icon': Icons.medical_services_outlined,
      },
      {
        'id': 'charitable',
        'title': l10n.charitable,
        'subtitle': l10n.charitableSubtitle,
        'icon': Icons.volunteer_activism_outlined,
      },
      {
        'id': 'debt',
        'title': l10n.debt,
        'subtitle': l10n.debtSubtitle,
        'icon': Icons.receipt_long_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...fundSupportCategories.map((category) {
          final categoryId = category['id'] as String;
          final isSelected = _selectedFundSupports.contains(categoryId);
          final config = _getCategoryConfig(categoryId);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Category selection card
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFundSupports.remove(categoryId);
                        _fundSupportConfigs.remove(categoryId);
                      } else {
                        _selectedFundSupports.add(categoryId);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['title'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category['subtitle'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                // Preview card (tappable to configure/edit) for selected categories
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  _buildConfigPreviewCard(
                    categoryId: categoryId,
                    category: category,
                    config: config,
                    onTap: () async {
                      final updatedConfig =
                          await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (context) => FundSupportConfigScreen(
                            categoryId: categoryId,
                            category: category,
                            initialConfig: Map<String, dynamic>.from(config),
                            // In create flow we only configure instructions;
                            // hide pause / request fund UI which is meant for
                            // live trusts.
                            showRequestActions: false,
                          ),
                        ),
                      );
                      if (updatedConfig != null) {
                        setState(() {
                          _fundSupportConfigs[categoryId] = updatedConfig;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.youCanSelectMoreThanOne,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  bool _hasConfiguration(Map<String, dynamic> config) {
    final Object? charities = config['charities'];
    final bool hasCharities = charities is List && charities.isNotEmpty;
    return hasCharities ||
           config['beneficiaryId'] != null ||
           config['durationType'] != null || 
           config['isRegularPayments'] != null || 
           config['releaseCondition'] != null;
  }

  /// Validates that at least one fund support category is selected and configured
  bool _validateFundSupport() {
    if (_selectedFundSupports.isEmpty) {
      return false;
    }
    // Check if at least one selected category has configuration
    for (final categoryId in _selectedFundSupports) {
      final config = _fundSupportConfigs[categoryId];
      if (config != null && _hasConfiguration(config)) {
        return true;
      }
    }
    return false;
  }

  /// Validates that executor selection is complete
  bool _validateExecutorSelection() {
    if (_executorType == null) {
      return false;
    }
    // If executor type is 'someone_i_know', must have at least one executor selected
    if (_executorType == 'someone_i_know' && _selectedExecutorIds.isEmpty) {
      return false;
    }
    return true;
  }

  Widget _buildConfigPreviewCard({
    required String categoryId,
    required Map<String, dynamic> category,
    required Map<String, dynamic> config,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasConfig = _hasConfiguration(config);
    
    final Object? rawBeneficiaryId = config['beneficiaryId'];
    int? beneficiaryId;
    if (rawBeneficiaryId is num) {
      beneficiaryId = rawBeneficiaryId.toInt();
    } else if (rawBeneficiaryId is String) {
      beneficiaryId = int.tryParse(rawBeneficiaryId);
    }

    // Resolve beneficiary details from loaded family members
    String? beneficiaryLine;
    if (beneficiaryId != null) {
      final Map<String, dynamic> member = _familyMembers.firstWhere(
        (m) => (m['id'] as num?)?.toInt() == beneficiaryId,
        orElse: () => <String, dynamic>{},
      );
      if (member.isNotEmpty) {
        // For preview, keep it short: just the name
        final String name = (member['name'] as String?) ?? 'Unknown';
        beneficiaryLine = name;
      }
    }

    final durationType = config['durationType'] as String?;
    final endAge = (config['endAge'] as num?)?.toDouble() ?? 24.0;
    final isRegularPayments = config['isRegularPayments'] as bool?;
    final paymentAmount = (config['paymentAmount'] as num?)?.toDouble() ?? 1000.0;
    final paymentFrequency = config['paymentFrequency'] as String?;
    final releaseCondition = config['releaseCondition'] as String?;

    final List<String> previewItems = [];

    // Beneficiary preview (who this is for)
    if (beneficiaryLine != null) {
      final l10n = AppLocalizations.of(context)!;
      previewItems.add('${l10n.forLabel} $beneficiaryLine');
    }

    // Special preview for charitable category: show selected charities
    if (categoryId == 'charitable') {
      final List<dynamic>? charitiesData = config['charities'] as List<dynamic>?;
      if (charitiesData != null && charitiesData.isNotEmpty) {
        final List<TrustCharity> charities = charitiesData
            .map((dynamic c) => TrustCharity.fromJson(c as Map<String, dynamic>))
            .toList();
        final l10n = AppLocalizations.of(context)!;
        if (charities.length == 1) {
          final String name = charities.first.organizationName ?? l10n.charitySelected;
          previewItems.add(name);
        } else {
          previewItems.add(l10n.charitiesSelected(charities.length));
        }
      }
    }

    // Duration preview
    final l10n = AppLocalizations.of(context)!;
    if (durationType == 'age') {
      previewItems.add(l10n.untilTheyTurn(endAge.round()));
    } else if (durationType == 'lifetime') {
      previewItems.add(l10n.forTheirWholeLife);
    }

    // Payment preview
    if (isRegularPayments == true) {
      final frequencyLabels = {
        'monthly': l10n.everyMonth,
        'quarterly': l10n.every3Months,
        'yearly': l10n.everyYear,
        'when_conditions': l10n.whenConditionsAreMet,
      };
      final frequencyLabel = frequencyLabels[paymentFrequency] ?? '';
      final formattedAmount = paymentAmount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      previewItems.add('RM $formattedAmount $frequencyLabel');
    } else if (releaseCondition == 'as_needed') {
      previewItems.add(l10n.whenNeeded);
    } else if (releaseCondition == 'lump_sum') {
      previewItems.add(l10n.allAtOnceAtTheEnd);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasConfig 
              ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
              : colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasConfig
                ? colorScheme.outline.withOpacity(0.1)
                : colorScheme.primary.withOpacity(0.3),
            width: hasConfig ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasConfig ? Icons.check_circle_outline : Icons.add_circle_outline,
              size: 18,
              color: hasConfig ? colorScheme.primary : colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasConfig
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: previewItems.asMap().entries.map((entry) {
                        final isLast = entry.key == previewItems.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Text(
                      l10n.tapToSetUp,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutorSelectionStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSomeoneIKnow = _executorType == 'someone_i_know';
    final isSampulProfessional = _executorType == 'sampul_professional';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Option 1: Someone I Know
        InkWell(
          onTap: () {
            setState(() {
              _executorType = 'someone_i_know';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSomeoneIKnow
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
              border: Border.all(
                color: isSomeoneIKnow
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.2),
                width: isSomeoneIKnow ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSomeoneIKnow
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSomeoneIKnow
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSomeoneIKnow
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.someoneIKnow,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSomeoneIKnow
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.familyMemberCloseFriendOrTrustedAdvisor,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Pros and Cons
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProConItem(Icons.check_circle_outline, l10n.freeUsually, Colors.green),
                          const SizedBox(height: 8),
                          _buildProConItem(Icons.check_circle_outline, l10n.basicReportingAndAnalytics, Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProConItem(Icons.warning_amber_outlined, l10n.personalConflict, Colors.orange),
                          const SizedBox(height: 8),
                          _buildProConItem(Icons.warning_amber_outlined, l10n.administrativeBurden, Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
                // Family members selection (when selected)
                if (isSomeoneIKnow) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.whosThisFamilyTrustAccountFor,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingFamilyMembers)
                    const Center(child: CircularProgressIndicator())
                  else if (_familyMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.noFamilyMembersFound,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._familyMembers.map((member) {
                      final memberId = (member['id'] as num?)?.toInt();
                      final isSelected = memberId != null && _selectedExecutorIds.contains(memberId);
                      final name = member['name'] as String? ?? 'Unknown';
                      final imagePath = member['image_path'] as String?;
                      final relationship = member['relationship'] as String?;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            if (memberId != null) {
                              setState(() {
                                if (isSelected) {
                                  _selectedExecutorIds.remove(memberId);
                                } else {
                                  _selectedExecutorIds.add(memberId);
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withOpacity(0.3)
                                  : colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Profile picture
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: imagePath != null && imagePath.isNotEmpty
                                      ? NetworkImage(
                                          SupabaseService.instance.getFullImageUrl(imagePath) ?? '',
                                        )
                                      : null,
                                  child: imagePath == null || imagePath.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (relationship != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          relationship,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: colorScheme.onPrimary,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Option 2: Sampul's Professional Executor
        InkWell(
          onTap: () {
            setState(() {
              _executorType = 'sampul_professional';
              _selectedExecutorIds.clear(); // Clear family member selections
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSampulProfessional
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
              border: Border.all(
                color: isSampulProfessional
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.2),
                width: isSampulProfessional ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSampulProfessional
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSampulProfessional
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSampulProfessional
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sampulsProfessionalExecutor,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSampulProfessional
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pros
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProConItem(Icons.check_circle_outline, l10n.expertManagement, Colors.green),
                    const SizedBox(height: 8),
                    _buildProConItem(Icons.check_circle_outline, l10n.neutralParty, Colors.green),
                    const SizedBox(height: 8),
                    _buildProConItem(Icons.info_outline, l10n.estFeeR4320yr, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Good to Know info box
        if (_showExecutorGoodToKnow)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.executorGoodToKnow,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showExecutorGoodToKnow = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProConItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // Legacy beneficiary add/edit/delete methods removed from UI flow.


  Widget _buildReviewStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Section
        CardDecorationHelper.styledCard(
          context: context,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: const Color.fromRGBO(83, 61, 233, 1)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.personalInformation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildReviewRow(l10n.fullName, _userProfile?.nricName ?? _userProfile?.username),
                _buildReviewRow(l10n.nric, _userProfile?.nricNo),
                _buildReviewRow(l10n.phone, _userProfile?.phoneNo),
                _buildReviewRow(l10n.email, _userProfile?.email),
                _buildReviewRow(l10n.address, _formatAddress(_userProfile)),
              ],
            ),
        ),
        
        const SizedBox(height: 16),
        
        // Fund Support Section with per-category configuration
        if (_selectedFundSupports.isNotEmpty)
          ..._selectedFundSupports.map((categoryId) {
            final categoryNames = {
              'education': l10n.education,
              'living': l10n.livingExpenses,
              'healthcare': l10n.healthcare,
              'charitable': l10n.charitable,
              'debt': l10n.debt,
            };
            final config = _fundSupportConfigs[categoryId];
            if (config == null) return const SizedBox.shrink();
            
            // Resolve beneficiary from per-category config
            final Object? rawBeneficiaryId = config['beneficiaryId'];
            int? beneficiaryId;
            if (rawBeneficiaryId is num) {
              beneficiaryId = rawBeneficiaryId.toInt();
            } else if (rawBeneficiaryId is String) {
              beneficiaryId = int.tryParse(rawBeneficiaryId);
            }

            String? beneficiaryName;
            if (beneficiaryId != null) {
              final Map<String, dynamic> member = _familyMembers.firstWhere(
                (m) => (m['id'] as num?)?.toInt() == beneficiaryId,
                orElse: () => <String, dynamic>{},
              );
              if (member.isNotEmpty) {
                beneficiaryName = (member['name'] as String?) ?? 'Unknown';
              }
            }

            final durationType = config['durationType'] as String?;
            final endAge = config['endAge'] as double?;
            final isRegularPayments = config['isRegularPayments'] as bool?;
            final paymentAmount = config['paymentAmount'] as double?;
            final paymentFrequency = config['paymentFrequency'] as String?;
            final releaseCondition = config['releaseCondition'] as String?;
            
            // Only show card if there's at least some configuration
            final hasConfig = durationType != null || 
                             isRegularPayments != null || 
                             releaseCondition != null;
            
            if (!hasConfig && beneficiaryName == null) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                color: const Color.fromRGBO(255, 255, 255, 1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_outlined, color: const Color.fromRGBO(83, 61, 233, 1)),
                          const SizedBox(width: 8),
                          Text(
                            categoryNames[categoryId] ?? categoryId,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (beneficiaryName != null)
                        _buildReviewRow(l10n.accountFor, beneficiaryName),
                      // Support Duration
                      if (durationType != null) ...[
                        _buildReviewRow(
                          l10n.duration,
                          durationType == 'age'
                              ? l10n.untilAge(endAge?.round() ?? 24)
                              : l10n.theirEntireLifetime,
                        ),
                      ],
                      // Payment Configuration
                      if (isRegularPayments == true && paymentAmount != null) ...[
                        _buildReviewRow(
                          l10n.paymentType,
                          l10n.regularPayments,
                        ),
                        _buildReviewRow(
                          l10n.amount,
                          'RM ${paymentAmount.toStringAsFixed(2).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )}',
                        ),
                        if (paymentFrequency != null)
                          _buildReviewRow(
                            l10n.frequency,
                            {
                              'monthly': l10n.monthly,
                              'quarterly': l10n.quarterly,
                              'yearly': l10n.yearly,
                              'when_conditions': l10n.whenConditions,
                            }[paymentFrequency] ?? paymentFrequency,
                          ),
                      ] else if (releaseCondition == 'as_needed') ...[
                        _buildReviewRow(
                          l10n.paymentType,
                          l10n.asNeededTrusteeDecides,
                        ),
                      ] else if (releaseCondition == 'lump_sum') ...[
                        _buildReviewRow(
                          l10n.paymentType,
                          l10n.lumpSumAtTheEnd,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        
        // Executor Selection Section
        if (_executorType != null)
          CardDecorationHelper.styledCard(
            context: context,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: const Color.fromRGBO(83, 61, 233, 1)),
                      const SizedBox(width: 8),
                      Text(
                        l10n.executorSelection,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow(
                    l10n.executorType,
                    _executorType == 'someone_i_know'
                        ? l10n.someoneIKnow
                        : _executorType == 'sampul_professional'
                            ? l10n.sampulsProfessionalExecutor
                            : null,
                  ),
                  if (_executorType == 'someone_i_know' && _selectedExecutorIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildReviewRow(
                      l10n.selectedExecutors,
                      l10n.familyMembersSelected(_selectedExecutorIds.length),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedExecutorIds.map((id) {
                      final member = _familyMembers.firstWhere(
                        (m) => (m['id'] as num?)?.toInt() == id,
                        orElse: () => <String, dynamic>{},
                      );
                      final name = member['name'] as String? ?? 'Unknown';
                      return Padding(
                        padding: const EdgeInsets.only(left: 140, top: 4),
                        child: Text(
                          '• $name',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
        
        if (_executorType != null)
          const SizedBox(height: 16),
        
        // Financial Information Section
          CardDecorationHelper.styledCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: const Color.fromRGBO(83, 61, 233, 1)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.financialInformation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildReviewRow(
                  l10n.estimatedNetWorth,
                  _selectedEstimatedNetWorth != null
                      ? TrustConstants.estimatedNetWorths
                          .firstWhere((e) => e['value'] == _selectedEstimatedNetWorth,
                              orElse: () => {'name': _selectedEstimatedNetWorth!})['name']
                      : null,
                ),
                _buildReviewRow(
                  l10n.sourceOfFund,
                  _selectedSourceOfFund != null
                      ? TrustConstants.sourceOfWealth
                          .firstWhere((e) => e['value'] == _selectedSourceOfFund,
                              orElse: () => {'name': _selectedSourceOfFund!})['name']
                      : null,
                ),
                _buildReviewRow(l10n.purposeOfTransaction, _purposeOfTransactionCtrl.text.trim().isEmpty ? null : _purposeOfTransactionCtrl.text.trim()),
              ],
            ),
        ),
        
        const SizedBox(height: 16),
        
        // Business Information Section
        if (_employerNameCtrl.text.trim().isNotEmpty ||
            _businessNatureCtrl.text.trim().isNotEmpty)
          CardDecorationHelper.styledCard(
            context: context,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: const Color.fromRGBO(83, 61, 233, 1)),
                      const SizedBox(width: 8),
                      Text(
                        l10n.businessInformation,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow(l10n.employerCompanyName, _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim()),
                  _buildReviewRow(l10n.natureOfBusiness, _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim()),
                  _buildReviewRow(l10n.businessAddress, _formatBusinessAddress()),
                ],
              ),
        ),
        
        if (_employerNameCtrl.text.trim().isNotEmpty ||
            _businessNatureCtrl.text.trim().isNotEmpty)
          const SizedBox(height: 16),
        
        // Charities Section (from charitable fund support config)
        Builder(
          builder: (context) {
            // Get charities from charitable fund support config
            final charitableConfig = _fundSupportConfigs['charitable'];
            final charitiesData = charitableConfig?['charities'] as List?;
            final charities = charitiesData != null
                ? charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList()
                : <TrustCharity>[];
            
            if (charities.isEmpty) return const SizedBox.shrink();
            
            return Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.volunteer_activism, color: const Color.fromRGBO(83, 61, 233, 1)),
                        const SizedBox(width: 8),
                        Text(
                          l10n.charitiesDonations(charities.length),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...charities.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.organizationName ?? 'Unnamed Organization',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (c.category != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                TrustConstants.donationCategories
                                    .firstWhere((cat) => cat['value'] == c.category,
                                        orElse: () => {'name': c.category!})['name']!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (c.donationAmount != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'RM ${c.donationAmount!.toStringAsFixed(2)} ${c.donationDuration != null ? "• ${TrustConstants.donationDurations.firstWhere((d) => d['value'] == c.donationDuration, orElse: () => {'name': c.donationDuration!})['name']}" : ""}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'Not provided',
              style: TextStyle(
                fontStyle: value?.isEmpty ?? true ? FontStyle.italic : FontStyle.normal,
                color: value?.isEmpty ?? true ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBusinessAddress() {
    final parts = <String>[];
    if (_businessAddress1Ctrl.text.trim().isNotEmpty) parts.add(_businessAddress1Ctrl.text.trim());
    if (_businessAddress2Ctrl.text.trim().isNotEmpty) parts.add(_businessAddress2Ctrl.text.trim());
    if (_businessCityCtrl.text.trim().isNotEmpty) parts.add(_businessCityCtrl.text.trim());
    if (_businessStateCtrl.text.trim().isNotEmpty) parts.add(_businessStateCtrl.text.trim());
    if (_businessPostcodeCtrl.text.trim().isNotEmpty) parts.add(_businessPostcodeCtrl.text.trim());
    if (_selectedBusinessCountry != null) {
      final countryName = TrustConstants.countries
          .firstWhere((c) => c['value'] == _selectedBusinessCountry,
              orElse: () => {'name': _selectedBusinessCountry!})['name'];
      if (countryName != null) parts.add(countryName);
    }
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildPersonalInfoStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.personalInformation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    // Refresh profile after returning
                    await _prefillFromProfile();
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(l10n.editProfile),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profile Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _userProfile?.imagePath != null && _userProfile!.imagePath!.isNotEmpty
                        ? Image.network(
                            SupabaseService.instance.getFullImageUrl(_userProfile!.imagePath!) ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 30,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 30,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Profile Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name', (_userProfile?.displayName ?? '').isNotEmpty ? _userProfile!.displayName : 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('NRIC', _userProfile?.nricNo ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Phone', _userProfile?.phoneNo ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Email', _userProfile?.email ?? 'Not provided'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Address', _formatAddress(_userProfile)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the "Continue/Submit" tap for the fixed footer controls.
  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      // Just move to next step, profile validation happens at submit
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Fund Support - validate at least one selected and configured
      final l10n = AppLocalizations.of(context)!;
      if (!_validateFundSupport()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectAtLeastOneFundSupport),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Executor Selection - validate executor is selected
      final l10n = AppLocalizations.of(context)!;
      if (!_validateExecutorSelection()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectAtLeastOneExecutor),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (!(_financialFormKey.currentState?.validate() ?? true)) return;
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      if (!(_businessFormKey.currentState?.validate() ?? true)) return;
      setState(() => _currentStep = 5);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    // Validate profile exists
    if (_userProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseCompleteYourProfileFirst), backgroundColor: Colors.orange),
      );
      setState(() => _currentStep = 0);
      return;
    }
    // Validate fund support - at least one selected and configured
    if (!_validateFundSupport()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectAtLeastOneFundSupport),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 1);
      return;
    }
    // Validate executor selection - at least one executor selected
    if (!_validateExecutorSelection()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectAtLeastOneExecutor),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 2);
      return;
    }
    // Validate financial information - required
    if (!(_financialFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 3);
      return;
    }
    if (!(_businessFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 4);
      return;
    }
    // Note: Beneficiaries and charities are optional; beneficiaries are now linked per category.

    setState(() => _isSubmitting = true);
    try {
      final createdTrust = await TrustService.instance.createTrust(
        Trust(
          // Personal info from profile
          name: _userProfile!.nricName ?? _userProfile!.username,
          nricNumber: _userProfile!.nricNo,
          dateOfBirth: _userProfile!.dob,
          gender: _userProfile!.gender,
          residentStatus: null, // Not in profile yet
          nationality: _userProfile!.country,
          phoneNo: _userProfile!.phoneNo,
          email: _userProfile!.email,
          addressLine1: _userProfile!.address1,
          addressLine2: _userProfile!.address2,
          city: _userProfile!.city,
          postcode: _userProfile!.postcode,
          state: _userProfile!.state,
          country: _userProfile!.country,
          // Financial info from form
          estimatedNetWorth: _selectedEstimatedNetWorth,
          sourceOfFund: _selectedSourceOfFund,
          purposeOfTransaction: _purposeOfTransactionCtrl.text.trim().isEmpty ? null : _purposeOfTransactionCtrl.text.trim(),
          // Business info from form
          employerName: _employerNameCtrl.text.trim().isEmpty ? null : _employerNameCtrl.text.trim(),
          businessNature: _businessNatureCtrl.text.trim().isEmpty ? null : _businessNatureCtrl.text.trim(),
          businessAddressLine1: _businessAddress1Ctrl.text.trim().isEmpty ? null : _businessAddress1Ctrl.text.trim(),
          businessAddressLine2: _businessAddress2Ctrl.text.trim().isEmpty ? null : _businessAddress2Ctrl.text.trim(),
          businessCity: _businessCityCtrl.text.trim().isEmpty ? null : _businessCityCtrl.text.trim(),
          businessPostcode: _businessPostcodeCtrl.text.trim().isEmpty ? null : _businessPostcodeCtrl.text.trim(),
          businessState: _businessStateCtrl.text.trim().isEmpty ? null : _businessStateCtrl.text.trim(),
          businessCountry: _selectedBusinessCountry,
          // Fund support categories
          fundSupportCategories: _selectedFundSupports.isNotEmpty ? _selectedFundSupports.toList() : null,
          // Fund support configurations (per-category)
          fundSupportConfigs: _fundSupportConfigs.isNotEmpty ? _fundSupportConfigs : null,
          // Executor selection
          executorType: _executorType,
          executorIds: _executorType == 'someone_i_know' && _selectedExecutorIds.isNotEmpty
              ? _selectedExecutorIds.toList()
              : null,
        ),
        beneficiaries: _beneficiaries.isNotEmpty ? _beneficiaries : null,
        charities: () {
          // Get charities from charitable fund support config
          final charitableConfig = _fundSupportConfigs['charitable'];
          final charitiesData = charitableConfig?['charities'] as List?;
          if (charitiesData == null || charitiesData.isEmpty) return null;
          return charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList();
        }(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trustFundCreatedSuccessfully), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Return the created trust so callers can navigate to its detail page.
      Navigator.of(context).pop(createdTrust);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToCreateTrustFund(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.createTrustFund)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTrustFund),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.aboutTrustFund,
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TrustInfoScreen(fromHelpIcon: true)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_profileError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: MaterialBanner(
                  elevation: 0,
                  content: Text(
                    '${l10n.weCouldNotLoadYourProfile}\n$_profileError',
                  ),
                  leading: const Icon(Icons.info_outline),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => setState(() => _profileError = null),
                      child: Text(l10n.dismiss),
                    )
                  ],
                ),
              ),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepTapped: (int i) => setState(() => _currentStep = i),
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  // Hide the built-in controls; we use a fixed footer instead.
                  return const SizedBox.shrink();
                },
                steps: <Step>[
                  Step(
                    title: Text(l10n.personalInformation),
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 0,
                    content: _buildPersonalInfoStep(),
                  ),
                  Step(
                    title: Text(l10n.fundSupport),
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 1,
                    content: _buildFundSupportStep(),
                  ),
                  Step(
                    title: Text(l10n.executorSelection),
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 2,
                    content: _buildExecutorSelectionStep(),
                  ),
                  Step(
                    title: Text(l10n.financialInformation),
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 3,
                    content: Form(
                      key: _financialFormKey,
                      child: Column(
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            value: _selectedEstimatedNetWorth,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.estimatedNetWorth,
                              prefixIcon: Icons.account_balance_wallet_outlined,
                            ),
                            items: TrustConstants.estimatedNetWorths
                                .map((Map<String, String> item) => DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedEstimatedNetWorth = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedSourceOfFund,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.sourceOfFund,
                              prefixIcon: Icons.payments_outlined,
                            ),
                            items: TrustConstants.sourceOfWealth
                                .map((Map<String, String> item) => DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() => _selectedSourceOfFund = v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _purposeOfTransactionCtrl,
                            maxLines: 3,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.purposeOfTransaction,
                              prefixIcon: Icons.description_outlined,
                            ).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: Text(l10n.employmentBusinessInformation),
                    state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                    isActive: _currentStep >= 4,
                    content: Form(
                      key: _businessFormKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _employerNameCtrl,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.employerName,
                              prefixIcon: Icons.business_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessNatureCtrl,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.businessNature,
                              prefixIcon: Icons.work_outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessAddress1Ctrl,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.businessAddressLine1,
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessAddress2Ctrl,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.businessAddressLine2,
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _businessCityCtrl,
                                  decoration: FormDecorationHelper.roundedInputDecoration(
                                    context: context,
                                    labelText: l10n.city,
                                    prefixIcon: Icons.location_city_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _businessPostcodeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: FormDecorationHelper.roundedInputDecoration(
                                    context: context,
                                    labelText: l10n.postcode,
                                    prefixIcon: Icons.local_post_office_outlined,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: _businessStateCtrl,
                                  decoration: FormDecorationHelper.roundedInputDecoration(
                                    context: context,
                                    labelText: l10n.state,
                                    prefixIcon: Icons.map_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBusinessCountry,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_outlined),
                                  decoration: FormDecorationHelper.roundedInputDecoration(
                                    context: context,
                                    labelText: l10n.country,
                                    prefixIcon: Icons.public_outlined,
                                  ),
                                  items: TrustConstants.countries
                                      .map((Map<String, String> item) => DropdownMenuItem<String>(
                                            value: item['value'],
                                            child: Text(item['name']!),
                                          ))
                                      .toList(),
                                  onChanged: (String? v) => setState(() => _selectedBusinessCountry = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: Text(l10n.reviewSubmit),
                    state: StepState.indexed,
                    isActive: _currentStep >= 5,
                    content: _buildReviewStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StepperFooterControls(
        currentStep: _currentStep,
        lastStep: 5,
        isBusy: _isSubmitting,
        onPrimaryPressed: () {
          _handleNext();
        },
        onBackPressed: _currentStep > 0
            ? () {
                setState(() {
                  _currentStep = _currentStep - 1;
                });
              }
            : null,
      ),
    );
  }
}
