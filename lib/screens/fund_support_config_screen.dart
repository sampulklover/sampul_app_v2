import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../models/trust_charity.dart';
import '../config/trust_constants.dart';
import '../services/supabase_service.dart';
import 'family_info_screen.dart';
import 'trust_charity_form_screen.dart';
import 'trust_charity_browse_screen.dart';
import '../utils/card_decoration_helper.dart';

class FundSupportConfigScreen extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> category;
  final Map<String, dynamic> initialConfig;
  /// When true, shows pause / request fund controls that are meant
  /// for live, active trusts. When creating a new trust, this should
  /// be false so the screen behaves purely as a configuration editor.
  final bool showRequestActions;

  const FundSupportConfigScreen({
    super.key,
    required this.categoryId,
    required this.category,
    required this.initialConfig,
    this.showRequestActions = true,
  });

  @override
  State<FundSupportConfigScreen> createState() => _FundSupportConfigScreenState();
}

class _FundSupportConfigScreenState extends State<FundSupportConfigScreen> {
  late Map<String, dynamic> _config;
  late List<TrustCharity> _charities;
  late String _initialConfigJson;
  // Family members for "Who's this account for?" selection
  List<Map<String, dynamic>> _familyMembers = <Map<String, dynamic>>[];
  bool _isLoadingFamilyMembers = false;
  int? _selectedFamilyMemberId;
  bool _isEditMode = false;
  Map<String, dynamic>? _savedConfig; // Track saved config to return when navigating back

  // Check if config is already set up (has meaningful data)
  bool get _isConfigSetUp {
    if (widget.initialConfig.isEmpty) return false;

    // For charitable category, treat as configured only when there are charities.
    if (widget.categoryId == 'charitable') {
      final List<dynamic>? charitiesData =
          widget.initialConfig['charities'] as List<dynamic>?;
      return charitiesData != null && charitiesData.isNotEmpty;
    }

    // For other categories, treat as configured only when key fields
    // actually have non-null values (not just present in the map).
    final Object? beneficiaryId = widget.initialConfig['beneficiaryId'];
    final String? durationType =
        widget.initialConfig['durationType'] as String?;
    final bool? isRegularPayments =
        widget.initialConfig['isRegularPayments'] as bool?;
    final String? releaseCondition =
        widget.initialConfig['releaseCondition'] as String?;

    return beneficiaryId != null ||
        durationType != null ||
        isRegularPayments != null ||
        releaseCondition != null;
  }

  @override
  void initState() {
    super.initState();
    // Deep copy the initial config to avoid modifying the original
    _config = Map<String, dynamic>.from(widget.initialConfig);
    _initialConfigJson = jsonEncode(_config);
    
    // Start in preview mode if config is already set up, otherwise start in edit mode
    _isEditMode = !_isConfigSetUp;
    
    // Initialize charities list from config (for charitable category)
    if (widget.categoryId == 'charitable') {
      final charitiesData = _config['charities'] as List?;
      _charities = charitiesData != null
          ? charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList()
          : [];
    } else {
      _charities = [];
    }
    // Pre-select previously chosen family member if exists
    final Object? rawId = _config['beneficiaryId'];
    if (rawId is num) {
      _selectedFamilyMemberId = rawId.toInt();
    } else if (rawId is String) {
      _selectedFamilyMemberId = int.tryParse(rawId);
    }

    _fetchFamilyMembers();
  }

  bool get _hasUnsavedChanges => jsonEncode(_config) != _initialConfigJson;

  /// Builds the "Who's this family trust account for?" selector per category.
  Widget _buildWhoIsThisForSection(ThemeData theme, ColorScheme colorScheme) {
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final TextStyle? helperStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    // Helper to render a single family card (radio style)
    Widget buildFamilyCard(Map<String, dynamic> member) {
      final int? id = (member['id'] as num?)?.toInt();
      final bool isSelected = id != null && id == _selectedFamilyMemberId;
      final String name = (member['name'] as String?) ?? 'Unknown';
      final String? relationship = member['relationship'] as String?;
      final String? type = member['type'] as String?;
      final String? imagePath = member['image_path'] as String?;

      // Build @handle style suffix from type (co_sampul, guardian, etc.)
      String? handle;
      if (type == 'guardian') {
        handle = '@Guardian';
      } else if (type == 'co_sampul') {
        handle = '@Co-Sampul';
      } else if (type == 'future_owner') {
        handle = '@Future Owner';
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: id == null
              ? null
              : () {
                  setState(() {
                    _selectedFamilyMemberId = id;
                    _config['beneficiaryId'] = id;
                  });
                },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundImage: imagePath != null && imagePath.isNotEmpty
                      ? NetworkImage(
                          SupabaseService.instance.getFullImageUrl(imagePath) ??
                              '',
                        )
                      : null,
                  child: (imagePath == null || imagePath.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name + relationship/handle
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (handle != null) ...[
                            Text(
                              handle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (relationship != null &&
                                relationship.trim().isNotEmpty)
                              const SizedBox(width: 4),
                          ],
                          if (relationship != null &&
                              relationship.trim().isNotEmpty)
                            Flexible(
                              child: Text(
                                relationship,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected ? colorScheme.primary : colorScheme.outline,
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
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whosThisFamilyTrustAccountFor,
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pickOneMainPersonForCategory,
          style: helperStyle,
        ),
        const SizedBox(height: 12),
        if (_isLoadingFamilyMembers)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_familyMembers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.noFamilyMembersYet,
              style: helperStyle,
            ),
          )
        else
          ..._familyMembers.map(buildFamilyCard).toList(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            final bool? added = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (context) => const FamilyInfoScreen(),
              ),
            );
            if (added == true) {
              await _fetchFamilyMembers();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addNew),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0),
          ),
        ),
      ],
    );
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

      if (!mounted) return;
      setState(() {
        _familyMembers = rows.cast<Map<String, dynamic>>();
        _isLoadingFamilyMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFamilyMembers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category['title'] as String? ?? AppLocalizations.of(context)!.fundSupport),
          actions: _isEditMode
              ? [
                  TextButton(
                    onPressed: () {
                      // Save charities to config if charitable category
                      if (widget.categoryId == 'charitable') {
                        _config['charities'] = _charities.map((c) => c.toJson()).toList();
                      }
                      // Save the config and switch back to preview mode
                      setState(() {
                        _savedConfig = Map<String, dynamic>.from(_config);
                        _initialConfigJson = jsonEncode(_config); // Update initial to reflect saved state
                        _isEditMode = false;
                        // Ensure charities list is synced with config for preview
                        if (widget.categoryId == 'charitable') {
                          final charitiesData = _config['charities'] as List?;
                          _charities = charitiesData != null
                              ? charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList()
                              : [];
                        }
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    tooltip: AppLocalizations.of(context)!.edit,
                  ),
                ],
        ),
        body: _isEditMode
            ? (widget.categoryId == 'charitable'
                ? _buildCharitableContent(theme, colorScheme)
                : _buildRegularContent(theme, colorScheme))
            : Column(
                children: [
                  Expanded(
                    child: widget.categoryId == 'charitable'
                        ? _buildCharitablePreview(theme, colorScheme)
                        : _buildRegularPreview(theme, colorScheme),
                  ),
                  if (widget.showRequestActions)
                    _buildActionButtonsFooter(theme, colorScheme),
                ],
              ),
      ),
    );
  }

  Future<bool> _handleWillPop() async {
    // In preview mode, return saved config if available, otherwise return null
    if (!_isEditMode) {
      if (_savedConfig != null) {
        // Return saved config when navigating back from preview
        Navigator.of(context).pop<Map<String, dynamic>>(_savedConfig);
        return false; // we've handled the pop manually
      }
      // No changes made, return null to indicate no updates
      Navigator.of(context).pop<Map<String, dynamic>?>(null);
      return false; // we've handled the pop manually
    }

    // In edit mode, check for unsaved changes
    if (!_hasUnsavedChanges) {
      // No unsaved changes, just go back to preview mode
      setState(() {
        _isEditMode = false;
      });
      return false; // Don't pop, just switch to preview
    }

    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.saveYourChanges),
          content: Text(
            l10n.youHaveUnsavedChanges,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('discard'),
              child: Text(l10n.discardChanges),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('save'),
              child: Text(l10n.saveExit),
            ),
          ],
        );
      },
    );

    if (action == 'discard') {
      // Discard changes and go back to preview mode
      setState(() {
        // Reset config to saved state or initial state
        if (_savedConfig != null) {
          _config = Map<String, dynamic>.from(_savedConfig!);
        } else {
          _config = Map<String, dynamic>.from(widget.initialConfig);
        }
        _initialConfigJson = jsonEncode(_config);
        // Reset charities if charitable category
        if (widget.categoryId == 'charitable') {
          final charitiesData = _config['charities'] as List?;
          _charities = charitiesData != null
              ? charitiesData.map((c) => TrustCharity.fromJson(c as Map<String, dynamic>)).toList()
              : [];
        }
        _isEditMode = false;
      });
      return false; // Don't pop, just switch to preview
    } else if (action == 'save') {
      // Save and go back to preview mode
      if (widget.categoryId == 'charitable') {
        _config['charities'] = _charities.map((c) => c.toJson()).toList();
      }
      setState(() {
        _savedConfig = Map<String, dynamic>.from(_config);
        _initialConfigJson = jsonEncode(_config);
        _isEditMode = false;
      });
      return false; // Don't pop, just switch to preview
    }

    return false; // Don't pop if dialog was cancelled
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'RM 0.00';
    return 'RM ${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _getCategoryDescription(String categoryId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryId) {
      case 'education':
        return l10n.supportForTuitionFees;
      case 'living':
        return l10n.coverDailyLivingExpenses;
      case 'healthcare':
        return l10n.medicalExpensesTreatments;
      case 'charitable':
        return l10n.donationsContributions;
      case 'debt':
        return l10n.paymentsOutstandingDebts;
      default:
        return l10n.fundSupportConfiguration;
    }
  }

  Widget _buildCharitablePreview(ThemeData theme, ColorScheme colorScheme) {
    // Calculate total donations
    double totalAmount = 0.0;
    for (var charity in _charities) {
      if (charity.donationAmount != null) {
        totalAmount += charity.donationAmount!;
      }
    }
    
    final isPaused = _config['isPaused'] as bool? ?? false;
    final hasPendingRequest = _config['hasPendingRequest'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCategoryDescription(widget.categoryId, context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasPendingRequest || isPaused) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (hasPendingRequest)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pending_outlined,
                                      size: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.requestPending,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isPaused)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_outline,
                                      size: 14,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.paused,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_charities.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalDonations,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(totalAmount),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _charities.length == 1 
                          ? '${_charities.length} ${AppLocalizations.of(context)!.charity}'
                          : AppLocalizations.of(context)!.charitiesSelected(_charities.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_charities.isEmpty)
            CardDecorationHelper.styledCard(
              context: context,
              padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      size: 64,
                      color: colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noCharitiesDonationsAddedYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.addCharitableOrganizations,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            )
          else
            ..._charities.map((charity) {
              // Build subtitle text
              String categoryText = '';
              if (charity.category != null) {
                final categoryName = TrustConstants.donationCategories
                    .firstWhere((c) => c['value'] == charity.category,
                        orElse: () => {'name': charity.category!})['name']!;
                categoryText = categoryName;
              }
              
              String durationText = '';
              if (charity.donationDuration != null) {
                durationText = TrustConstants.donationDurations
                    .firstWhere((d) => d['value'] == charity.donationDuration,
                        orElse: () => {'name': charity.donationDuration!})['name']!;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
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
                                  charity.organizationName ?? 'Unnamed Organization',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (categoryText.isNotEmpty || durationText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (categoryText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            categoryText,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      if (durationText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            durationText,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (charity.donationAmount != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.donationAmount,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _formatAmount(charity.donationAmount),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildRegularPreview(ThemeData theme, ColorScheme colorScheme) {
    final durationType = _config['durationType'] as String?;
    final endAge = (_config['endAge'] as num?)?.toDouble();
    final isRegularPayments = _config['isRegularPayments'] as bool?;
    final paymentAmount = (_config['paymentAmount'] as num?)?.toDouble();
    final paymentFrequency = _config['paymentFrequency'] as String?;
    final releaseCondition = _config['releaseCondition'] as String?;
    final beneficiaryId = _config['beneficiaryId'] as int?;
    final isPaused = _config['isPaused'] as bool? ?? false;
    final hasPendingRequest = _config['hasPendingRequest'] as bool? ?? false;

    // Get beneficiary info
    Map<String, dynamic>? beneficiaryData;
    if (beneficiaryId != null) {
      beneficiaryData = _familyMembers.firstWhere(
        (member) => (member['id'] as num?)?.toInt() == beneficiaryId,
        orElse: () => <String, dynamic>{},
      );
    }

    // Calculate years from now and end year
    final currentYear = DateTime.now().year;
    final yearsFromNow = endAge != null ? (endAge - 18).round() : null;
    final endYear = yearsFromNow != null ? currentYear + yearsFromNow : null;

    final paymentFrequencies = {
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'yearly': 'Yearly',
      'when_conditions': 'When conditions',
    };

    // Calculate payment summaries
    String? annualTotal;
    String? monthlyTotal;
    if (isRegularPayments == true && paymentAmount != null && paymentFrequency != null) {
      switch (paymentFrequency) {
        case 'monthly':
          annualTotal = _formatAmount(paymentAmount * 12);
          monthlyTotal = _formatAmount(paymentAmount);
          break;
        case 'quarterly':
          annualTotal = _formatAmount(paymentAmount * 4);
          monthlyTotal = _formatAmount(paymentAmount / 3);
          break;
        case 'yearly':
          annualTotal = _formatAmount(paymentAmount);
          monthlyTotal = _formatAmount(paymentAmount / 12);
          break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCategoryDescription(widget.categoryId, context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasPendingRequest || isPaused) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (hasPendingRequest)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pending_outlined,
                                      size: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.requestPending,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isPaused)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_outline,
                                      size: 14,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.paused,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (annualTotal != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.annualTotal,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          annualTotal,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.monthlyAverage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthlyTotal ?? AppLocalizations.of(context)!.na,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Beneficiary section with avatar
          if (beneficiaryData != null && beneficiaryData.isNotEmpty) ...[
            _buildBeneficiaryPreviewCard(theme, colorScheme, beneficiaryData),
            const SizedBox(height: 16),
          ],
          // Duration section
          if (durationType != null) ...[
            _buildEnhancedPreviewSection(
              theme,
              colorScheme,
              AppLocalizations.of(context)!.supportDuration,
              durationType == 'age'
                  ? AppLocalizations.of(context)!.untilAge(endAge?.round() ?? 0)
                  : AppLocalizations.of(context)!.theirEntireLifetime,
              durationType == 'age' && endYear != null
                  ? AppLocalizations.of(context)!.endsInYear(endYear, yearsFromNow!)
                  : AppLocalizations.of(context)!.continuousSupportLifetime,
              Icons.calendar_today_outlined,
              colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16),
          ],
          // Payment configuration section
          if (isRegularPayments == true && paymentAmount != null) ...[
            _buildEnhancedPreviewSection(
              theme,
              colorScheme,
              AppLocalizations.of(context)!.paymentMethod,
              AppLocalizations.of(context)!.regularPayments,
              '${_formatAmount(paymentAmount)} ${paymentFrequency != null ? paymentFrequencies[paymentFrequency] : ''}',
              Icons.payment_outlined,
              colorScheme.secondaryContainer,
            ),
          ] else if (releaseCondition == 'as_needed') ...[
            _buildEnhancedPreviewSection(
              theme,
              colorScheme,
              AppLocalizations.of(context)!.paymentMethod,
              AppLocalizations.of(context)!.asNeeded,
              AppLocalizations.of(context)!.trusteeDecidesRelease,
              Icons.payment_outlined,
              colorScheme.tertiaryContainer,
            ),
          ] else if (releaseCondition == 'lump_sum') ...[
            _buildEnhancedPreviewSection(
              theme,
              colorScheme,
              AppLocalizations.of(context)!.paymentMethod,
              AppLocalizations.of(context)!.lumpSum,
              AppLocalizations.of(context)!.allFundsReleasedEnd,
              Icons.payment_outlined,
              colorScheme.tertiaryContainer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtonsFooter(ThemeData theme, ColorScheme colorScheme) {
    final isPaused = _config['isPaused'] as bool? ?? false;
    final hasPendingRequest = _config['hasPendingRequest'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Pause/Resume Instruction button (icon only)
            OutlinedButton(
              onPressed: () => _handlePauseResume(theme, colorScheme, isPaused),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Icon(
                isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Request Fund / Cancel Request button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasPendingRequest
                    ? () => _handleCancelRequest(theme, colorScheme)
                    : () => _handleRequestFund(theme, colorScheme),
                icon: Icon(
                  hasPendingRequest ? Icons.cancel_outlined : Icons.request_quote_outlined,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  hasPendingRequest ? AppLocalizations.of(context)!.cancelRequest : AppLocalizations.of(context)!.requestFund,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPendingRequest
                      ? Colors.red
                      : colorScheme.primary,
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
      ),
    );
  }

  Future<void> _handleRequestFund(ThemeData theme, ColorScheme colorScheme) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.requestFund),
          content: Text(l10n.areYouSureRequestFunds),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.requestFund),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Update the config with pending request status
      setState(() {
        _config['hasPendingRequest'] = true;
        _savedConfig = Map<String, dynamic>.from(_config);
        _initialConfigJson = jsonEncode(_config);
      });

      // TODO: Implement actual fund request logic
      // This would typically involve:
      // 1. Creating a fund request record in the database
      // 2. Notifying the trustee
      // 3. Updating the UI state
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fundRequestSubmittedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleCancelRequest(ThemeData theme, ColorScheme colorScheme) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.cancelRequest),
          content: Text(l10n.areYouSureCancelRequest),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.noKeepIt),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.cancelRequest),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Update the config to remove pending request status
      setState(() {
        _config['hasPendingRequest'] = false;
        _savedConfig = Map<String, dynamic>.from(_config);
        _initialConfigJson = jsonEncode(_config);
      });

      // TODO: Implement actual cancel request logic
      // This would typically involve:
      // 1. Updating the fund request status in the database
      // 2. Notifying the trustee
      // 3. Updating the UI state
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fundRequestCancelledSuccessfully),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handlePauseResume(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPaused,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final categoryTitle = widget.category['title'] as String? ?? l10n.fundSupport;
    
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(isPaused ? l10n.resumeInstruction : l10n.pauseInstruction),
          content: Text(
            isPaused
                ? l10n.areYouSureResumeInstruction(categoryTitle)
                : l10n.areYouSurePauseInstruction(categoryTitle),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isPaused ? l10n.resume : l10n.pause),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Update the config with pause status
      setState(() {
        _config['isPaused'] = !isPaused;
        _savedConfig = Map<String, dynamic>.from(_config);
        _initialConfigJson = jsonEncode(_config);
      });

      // TODO: Implement actual pause/resume logic
      // This would typically involve:
      // 1. Updating the instruction status in the database
      // 2. Notifying the trustee
      // 3. Updating any scheduled payments
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPaused
                ? l10n.instructionResumedSuccessfully(categoryTitle)
                : l10n.instructionPausedSuccessfully(categoryTitle),
          ),
          backgroundColor: isPaused ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Widget _buildBeneficiaryPreviewCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> beneficiary,
  ) {
    final String name = (beneficiary['name'] as String?) ?? 'Unknown';
    final String? relationship = beneficiary['relationship'] as String?;
    final String? type = beneficiary['type'] as String?;
    final String? imagePath = beneficiary['image_path'] as String?;

    // Build @handle style suffix from type
    String? handle;
    if (type == 'guardian') {
      handle = '@Guardian';
    } else if (type == 'co_sampul') {
      handle = '@Co-Sampul';
    } else if (type == 'future_owner') {
      handle = '@Future Owner';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: imagePath != null && imagePath.isNotEmpty
                  ? NetworkImage(
                      SupabaseService.instance.getFullImageUrl(imagePath) ?? '',
                    )
                  : null,
              backgroundColor: colorScheme.primaryContainer,
              child: (imagePath == null || imagePath.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.beneficiary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (handle != null || relationship != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (handle != null)
                          Text(
                            handle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (relationship != null && relationship.trim().isNotEmpty)
                          Text(
                            relationship,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPreviewSection(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    String mainValue,
    String? subtitle,
    IconData icon,
    Color containerColor,
  ) {
    return CardDecorationHelper.styledCard(
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: containerColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mainValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildCharitableContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCategoryDescription(widget.categoryId, context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_charities.isEmpty)
            CardDecorationHelper.styledCard(
              context: context,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 48,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No charities/donations added yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.addCharitableOrganizationsDonate,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._charities.asMap().entries.map((entry) {
              final index = entry.key;
              final charity = entry.value;
              
              // Build subtitle text
              String subtitleText = '';
              if (charity.category != null) {
                final categoryName = TrustConstants.donationCategories
                    .firstWhere((c) => c['value'] == charity.category,
                        orElse: () => {'name': charity.category!})['name']!;
                subtitleText = categoryName;
              }
              if (charity.donationAmount != null) {
                final amountText = 'RM ${charity.donationAmount!.toStringAsFixed(2)}';
                final durationText = charity.donationDuration != null 
                    ? ' (${TrustConstants.donationDurations.firstWhere((d) => d['value'] == charity.donationDuration, orElse: () => {'name': charity.donationDuration!})['name']})'
                    : '';
                if (subtitleText.isNotEmpty) {
                  subtitleText += ' • $amountText$durationText';
                } else {
                  subtitleText = '$amountText$durationText';
                }
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(charity.organizationName ?? AppLocalizations.of(context)!.unnamedOrganization),
                  subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCharity(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCharity(index),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCharity,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addCharity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularContent(ThemeData theme, ColorScheme colorScheme) {
    final durationType = _config['durationType'] as String?;
    final endAge = (_config['endAge'] as num?)?.toDouble() ?? 24.0;
    final isRegularPayments = _config['isRegularPayments'] as bool?; // null means nothing selected
    final paymentAmount = (_config['paymentAmount'] as num?)?.toDouble() ?? 1000.0;
    final paymentFrequency = _config['paymentFrequency'] as String?;
    final releaseCondition = _config['releaseCondition'] as String?;

    final presetAmounts = [1000.0, 2000.0, 3000.0, 5000.0];
    final l10n = AppLocalizations.of(context)!;
    final paymentFrequencies = [
      {'value': 'monthly', 'label': l10n.monthly},
      {'value': 'quarterly', 'label': l10n.quarterly},
      {'value': 'yearly', 'label': l10n.yearly},
      {'value': 'when_conditions', 'label': l10n.whenConditions},
    ];

    // Calculate years from now and end year
    final currentYear = DateTime.now().year;
    final yearsFromNow = (endAge - 18).round();
    final endYear = currentYear + yearsFromNow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category['icon'] as IconData? ?? Icons.category_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['title'] as String? ?? 'Fund Support',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCategoryDescription(widget.categoryId, context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((widget.category['subtitle'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.category['subtitle'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Who is this family trust account for?
          _buildWhoIsThisForSection(theme, colorScheme),
          const SizedBox(height: 24),
          // Support Duration Section
          Text(
            AppLocalizations.of(context)!.howLongShouldThisLast,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Until a specific age option
          InkWell(
              onTap: () {
                setState(() {
                  _config['durationType'] = 'age';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: durationType == 'age'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: durationType == 'age'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: durationType == 'age' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: durationType == 'age'
                                ? colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: durationType == 'age'
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: durationType == 'age'
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.untilSpecificAge,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (durationType == 'age') ...[
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.age,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${endAge.round()}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: endAge,
                        min: 18,
                        max: 40,
                        divisions: 22,
                        label: '${endAge.round()}',
                        onChanged: (value) {
                          setState(() {
                            _config['endAge'] = value;
                          });
                        },
                      ),
                      Text(
                        AppLocalizations.of(context)!.thatsYearsFromNow(yearsFromNow, endYear),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Their entire lifetime option
          InkWell(
              onTap: () {
                setState(() {
                  _config['durationType'] = 'lifetime';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: durationType == 'lifetime'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: durationType == 'lifetime'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: durationType == 'lifetime' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: durationType == 'lifetime'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: durationType == 'lifetime'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: durationType == 'lifetime'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.theirEntireLifetime,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Payment Configuration Section
          Text(
              AppLocalizations.of(context)!.paymentConfiguration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          // Regular payments option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = true;
                  _config['releaseCondition'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == true
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == true
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == true ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRegularPayments == true
                                ? colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isRegularPayments == true
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: isRegularPayments == true
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.regularPayments,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isRegularPayments == true) ...[
                      const SizedBox(height: 16),
                      // Amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'RM',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paymentAmount.toStringAsFixed(2).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: paymentAmount,
                                  min: 100,
                                  max: 10000,
                                  divisions: 99,
                                  label: 'RM ${paymentAmount.toStringAsFixed(0)}',
                                  onChanged: (value) {
                                    setState(() {
                                      _config['paymentAmount'] = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: presetAmounts.map((amount) {
                                    final isSelected = (paymentAmount - amount).abs() < 0.01;
                                    return ChoiceChip(
                                      label: Text('RM ${amount.toStringAsFixed(0)}'),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _config['paymentAmount'] = amount;
                                          });
                                        }
                                      },
                                      selectedColor: colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.howOftenContribution,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: paymentFrequencies.map((freq) {
                                    final isSelected = paymentFrequency == freq['value'];
                                    return ChoiceChip(
                                      label: Text(freq['label']!),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _config['paymentFrequency'] = freq['value'] as String;
                                          });
                                        }
                                      },
                                      selectedColor: colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // As needed option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = false;
                  _config['releaseCondition'] = 'as_needed';
                  _config['paymentAmount'] = null;
                  _config['paymentFrequency'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == false && releaseCondition == 'as_needed'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == false && releaseCondition == 'as_needed'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == false && releaseCondition == 'as_needed' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRegularPayments == false && releaseCondition == 'as_needed'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isRegularPayments == false && releaseCondition == 'as_needed'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isRegularPayments == false && releaseCondition == 'as_needed'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.asNeededTrusteeDecides,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.yourTrusteeReleasesMoney,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Lump sum option
          InkWell(
              onTap: () {
                setState(() {
                  _config['isRegularPayments'] = false;
                  _config['releaseCondition'] = 'lump_sum';
                  _config['paymentAmount'] = null;
                  _config['paymentFrequency'] = null;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRegularPayments == false && releaseCondition == 'lump_sum'
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surface,
                  border: Border.all(
                    color: isRegularPayments == false && releaseCondition == 'lump_sum'
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    width: isRegularPayments == false && releaseCondition == 'lump_sum' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRegularPayments == false && releaseCondition == 'lump_sum'
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isRegularPayments == false && releaseCondition == 'lump_sum'
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isRegularPayments == false && releaseCondition == 'lump_sum'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.lumpSumAtTheEnd,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.everythingReleasedEnd,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.thisIsAGuide,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          ],
        ),
      );
  }

  Future<void> _addCharity() async {
    // New flow: browse from predefined charitable bodies and configure instruction.
    final TrustCharity? result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute<TrustCharity>(
        builder: (BuildContext context) => const TrustCharityBrowseScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities.add(result);
      });
    }
  }

  Future<void> _editCharity(int index) async {
    final result = await Navigator.push<TrustCharity>(
      context,
      MaterialPageRoute(
        builder: (context) => TrustCharityFormScreen(
          charity: _charities[index],
          index: index,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _charities[index] = result;
      });
    }
  }

  void _deleteCharity(int index) {
    setState(() {
      _charities.removeAt(index);
    });
  }
}
