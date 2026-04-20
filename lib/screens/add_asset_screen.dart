import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/brandfetch_service.dart';
import '../widgets/stepper_footer_controls.dart';
import '../utils/form_decoration_helper.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'asset_info_screen.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../utils/sampul_icons.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final GlobalKey<FormState> _physicalAssetNameFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();
  final TextEditingController _assetNameController = TextEditingController();
  final TextEditingController _declaredValueController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _brandSearchController = TextEditingController();

  BrandInfo? _brandInfo;
  bool _isCustomAsset = false;
  List<BrandInfo> _searchResults = <BrandInfo>[];
  bool _isSearching = false;
  bool _showAddCustomOption = false;
  Timer? _searchDebounce;
  String _lastQuery = '';
  final Map<String, List<BrandInfo>> _searchCache = <String, List<BrandInfo>>{};
  // Gift recipient (beloved) state
  final List<Map<String, dynamic>> _belovedOptions = <Map<String, dynamic>>[];
  int? _selectedBelovedId;
  bool _isLoadingBeloved = false;
  bool _isSubmitting = false;
  String? _selectedInstructionId;
  int _currentStep = 0;
  // Asset type: 'digital', 'physical', or 'debt'
  String? _assetType;
  // Physical asset category: 'property', 'vehicle', 'jewellery', 'cash', 'other'
  // This is mapped to legal classification ('movable' or 'immovable') behind the scenes
  String? _physicalAssetCategory;
  // For 'other' category, user must explicitly choose legal classification
  String? _otherAssetLegalClassification; // 'movable' or 'immovable'

  List<Map<String, String>> _getInstructions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_assetType == 'debt') {
      return <Map<String, String>>[
        {'id': 'settle', 'name': l10n.settleDebts},
      ];
    }
    final List<Map<String, String>> list = <Map<String, String>>[
      {'id': 'faraid', 'name': l10n.faraid},
      {'id': 'transfer_as_gift', 'name': l10n.transferAsGift},
      {'id': 'settle', 'name': l10n.settleDebts},
    ];
    // Terminate subscription only applies to digital assets; physical assets do not need it.
    if (_assetType != 'physical') {
      list.insert(1, {'id': 'terminate', 'name': l10n.terminateSubscriptions});
    }
    return list;
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _declaredValueController.dispose();
    _remarksController.dispose();
    _brandSearchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _showCustomAssetDialog() async {
    final TextEditingController nameController = TextEditingController(text: _brandSearchController.text.trim());
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final l10nDialog = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10nDialog.addCustomAsset),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10nDialog.assetName,
                      hintText: l10nDialog.assetNameHint,
                      prefixIconPath: SampulIcons.apps,
                    ),
                    validator: (String? v) => (v == null || v.trim().isEmpty) ? l10nDialog.required : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10nDialog.websiteUrlOptional,
                      hintText: l10nDialog.websiteUrlHint,
                      prefixIconPath: SampulIcons.link,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10nDialog.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(l10nDialog.add),
            ),
          ],
        );
      },
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      setState(() {
        _brandInfo = BrandInfo(
          name: nameController.text.trim(),
          websiteUrl: urlController.text.trim(),
          logoUrl: null,
        );
        _isCustomAsset = true;
        _assetNameController.text = nameController.text.trim();
        _searchResults = <BrandInfo>[];
        _showAddCustomOption = false;
      });
    }
  }

  Future<void> _loadBelovedOptions() async {
    if (_isLoadingBeloved) return;
    setState(() => _isLoadingBeloved = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('You must be signed in');
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name')
          .eq('uuid', user.id)
          .order('name');
      _belovedOptions
        ..clear()
        ..addAll(rows.cast<Map<String, dynamic>>());
      if (mounted) setState(() {});
    } catch (_) {
      // Ignore; user can retry by reselecting
    } finally {
      if (mounted) setState(() => _isLoadingBeloved = false);
    }
  }

  void _onSearchChanged(String v) {
    final String q = v.trim();
    _searchDebounce?.cancel();

    if (q.isEmpty) {
      setState(() {
        _searchResults = <BrandInfo>[];
        _isSearching = false;
        _showAddCustomOption = false;
      });
      return;
    }

    if (q.length < 3) {
      // Avoid API calls for very short inputs
      setState(() {
        _searchResults = <BrandInfo>[];
        _isSearching = false;
        _showAddCustomOption = false;
      });
      return;
    }

    // Use cached results if available
    final List<BrandInfo>? cached = _searchCache[q.toLowerCase()];
    if (cached != null) {
      setState(() {
        _searchResults = cached;
        _isSearching = false;
        _showAddCustomOption = q.length >= 3;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      // Skip if same as last request
      if (_lastQuery == q) {
        setState(() => _isSearching = false);
        return;
      }
      _lastQuery = q;
      try {
        final List<BrandInfo> results = await BrandfetchService.instance.searchBrands(q);
        if (!mounted) return;
        _searchCache[q.toLowerCase()] = results;
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showAddCustomOption = q.length >= 3;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _showAddCustomOption = q.length >= 3;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchFailed(e.toString()))),
        );
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Validate asset type
    if (_assetType == null) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAssetType)),
      );
      return;
    }

    // Validate based on asset type
    if (_assetType == 'digital') {
      if (_brandInfo == null) {
        setState(() => _currentStep = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectPlatformService)),
        );
        return;
      }
     } else if (_assetType == 'physical') {
       // Physical asset - validate category and name form
       if (_physicalAssetCategory == null) {
         setState(() => _currentStep = 1);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectAssetCategory)),
         );
         return;
       }
       // For 'other' category, validate legal classification is selected
       if (_physicalAssetCategory == 'other' && _otherAssetLegalClassification == null) {
         setState(() => _currentStep = 1);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectLegalClassification)),
         );
         return;
       }
       if (!(_physicalAssetNameFormKey.currentState?.validate() ?? false)) {
         setState(() => _currentStep = 1);
         return;
       }
     } else {
       // Debt - require a debt label/name
       if (!(_physicalAssetNameFormKey.currentState?.validate() ?? false)) {
         setState(() => _currentStep = 1);
         return;
       }
     }

    // Validate details form
    if (!(_detailsFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 2);
      return;
    }

    if (_selectedInstructionId == null) {
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectInstruction)),
      );
      return;
    }
    
    if (_selectedInstructionId == 'transfer_as_gift' && _selectedBelovedId == null) {
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.giftRecipientRequired)),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception(l10n.youMustBeSignedIn);
      }

      final String valueText = _declaredValueController.text.trim();
      final double declaredValue = valueText.isEmpty ? 0.0 : double.parse(valueText);
      final String instructions = _selectedInstructionId!;

      // Save to digital_assets table (for both digital and physical assets)
      final Map<String, dynamic> payload = <String, dynamic>{
        'uuid': user.id,
        'username': user.userMetadata?['username'] ?? user.email?.split('@').first,
        'email': user.email,
        'declared_value_myr': declaredValue,
        'instructions_after_death': instructions,
        // DB currently allows only 'digital' or 'physical'.
        // Debt is persisted as physical with settle instruction.
        'asset_type': _assetType == 'debt' ? 'physical' : _assetType,
      };

      if (_assetType == 'physical') {
        // Physical asset: use new_service_platform_name for asset name
        // Validate category is set
        if (_physicalAssetCategory == null) {
          throw Exception('Please select an asset category.');
        }

        // Persist the physical asset category so we can show the right icon later
        payload['physical_asset_category'] = _physicalAssetCategory;

        // Get asset display name
        final String assetDisplayName = _getAssetTypeDisplayName(_physicalAssetCategory);
        final String assetName = _assetNameController.text.trim();
        
        // Use custom name if provided, otherwise use category name
        payload['new_service_platform_name'] = assetName.isNotEmpty 
            ? assetName 
            : assetDisplayName;
        
        // Set is_custom to true for physical assets (they're always custom/manual entries)
        payload['is_custom'] = true;

        // Map user-friendly category to legal classification and store it explicitly
        final String legalCategory = _getLegalCategoryFromUserSelection(_physicalAssetCategory);
        payload['physical_legal_classification'] = legalCategory; // 'movable' or 'immovable'

        // Store user remarks as-is (without encoding legal classification into the text)
        final String remarks = _remarksController.text.trim();
        if (remarks.isNotEmpty) {
          payload['remarks'] = remarks;
        }

        // Set beloved_id if instruction requires it
        if (instructions == 'transfer_as_gift') {
          if (_selectedBelovedId == null) {
            // Try to get first beloved as default, or require user to select
            if (_belovedOptions.isEmpty) {
              await _loadBelovedOptions();
            }
            if (_belovedOptions.isEmpty) {
              throw Exception('Please add a family member first, or select a gift recipient for this asset.');
            }
            _selectedBelovedId = (_belovedOptions.first['id'] as num).toInt();
          }
          payload['beloved_id'] = _selectedBelovedId;
        }
      } else if (_assetType == 'debt') {
        payload['new_service_platform_name'] = _assetNameController.text.trim();
        payload['is_custom'] = true;
        payload['physical_asset_category'] = 'cash';
        payload['physical_legal_classification'] = 'movable';

        final String remarks = _remarksController.text.trim();
        if (remarks.isNotEmpty) {
          payload['remarks'] = remarks;
        }
      } else {
        // Digital asset: use brand info
        payload['new_service_platform_name'] = _brandInfo!.name;
        payload['is_custom'] = _isCustomAsset;

        // include brand details if available
        if (_brandInfo != null) {
          if (_brandInfo!.websiteUrl.isNotEmpty) {
            payload['new_service_platform_url'] = _brandInfo!.websiteUrl;
          }
          if ((_brandInfo!.logoUrl ?? '').isNotEmpty) {
            payload['new_service_platform_logo_url'] = BrandfetchService.instance.stripClientIdFromUrl(_brandInfo!.logoUrl);
          }
        }

        if (instructions == 'transfer_as_gift' && _selectedBelovedId != null) {
          payload['beloved_id'] = _selectedBelovedId;
        }

        final String remarks = _remarksController.text.trim();
        if (remarks.isNotEmpty) {
          payload['remarks'] = remarks;
        }
      }

      await SupabaseService.instance.client.from('digital_assets').insert(payload);

      if (!mounted) return;
      // Show success dialog instead of snackbar
      final bool? addAnother = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final l10nDialog = AppLocalizations.of(context)!;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return AlertDialog(
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  l10nDialog.assetAdded,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10nDialog.yourInstructionRecordedSecurely,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10nDialog.returnToDashboard),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10nDialog.addAnotherAsset),
                ),
              ],
            ),
          );
        },
      );
      
      if (addAnother == true) {
        // Reset form for adding another
        setState(() {
          _assetType = null;
          _physicalAssetCategory = null;
          _otherAssetLegalClassification = null;
          _brandInfo = null;
          _assetNameController.clear();
          _declaredValueController.clear();
          _remarksController.clear();
          _brandSearchController.clear();
          _selectedInstructionId = null;
          _selectedBelovedId = null;
          _currentStep = 0;
          _searchResults = <BrandInfo>[];
          _showAddCustomOption = false;
          _isCustomAsset = false;
        });
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToAddAsset(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAssetTypeSelector() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Digital Asset Option
        InkWell(
          onTap: () => setState(() => _assetType = 'digital'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _assetType == 'digital' 
                    ? colorScheme.primary 
                    : colorScheme.outline.withOpacity(0.3),
                width: _assetType == 'digital' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _assetType == 'digital' 
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Row(
              children: <Widget>[
                SampulIcons.buildIcon(
                  SampulIcons.apps,
                  width: 32,
                  height: 32,
                  color: _assetType == 'digital' 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.digitalAsset,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Online accounts, apps, subscriptions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_assetType == 'digital')
                  SampulIcons.buildIcon(SampulIcons.checkCircle, width: 20, height: 20, color: colorScheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Physical Asset Option
        InkWell(
          onTap: () => setState(() => _assetType = 'physical'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _assetType == 'physical' 
                    ? colorScheme.primary 
                    : colorScheme.outline.withOpacity(0.3),
                width: _assetType == 'physical' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _assetType == 'physical' 
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Row(
              children: <Widget>[
                SampulIcons.buildIcon(
                  SampulIcons.home,
                  width: 32,
                  height: 32,
                  color: _assetType == 'physical' 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.physicalAsset,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Property, vehicles, jewelry, collectibles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_assetType == 'physical')
                  SampulIcons.buildIcon(SampulIcons.checkCircle, width: 20, height: 20, color: colorScheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Register Debt Option
        InkWell(
          onTap: () => setState(() => _assetType = 'debt'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _assetType == 'debt'
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: _assetType == 'debt' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _assetType == 'debt'
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Row(
              children: <Widget>[
                SampulIcons.buildIcon(
                  SampulIcons.payment,
                  width: 32,
                  height: 32,
                  color: _assetType == 'debt'
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Register Debt',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loans, credit cards, and outstanding balances',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_assetType == 'debt')
                  SampulIcons.buildIcon(SampulIcons.checkCircle, width: 20, height: 20, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: _assetNameController,
          textInputAction: TextInputAction.next,
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: 'Debt name',
            hintText: 'e.g. Home loan, Credit card balance',
            prefixIconPath: SampulIcons.label,
          ),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addAsset),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.aboutAssets,
            icon: SampulIcons.buildIconButtonIcon(SampulIcons.help, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AssetInfoScreen(fromHelpIcon: true)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            // Use standardized fixed-footer controls instead.
            return const SizedBox.shrink();
          },
          steps: <Step>[
            // Step 0: Asset type selection
            Step(
              title: Text(l10n.selectAssetType),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: _buildAssetTypeSelector(),
            ),
            // Step 1: Platform selection (digital) or Asset info (physical)
            Step(
              title: _assetType == 'physical' 
                  ? Text(l10n.assetInfo)
                  : _assetType == 'debt'
                      ? const Text('Debt info')
                      : Text(l10n.selectPlatform),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: _assetType == 'physical'
                  ? Form(key: _physicalAssetNameFormKey, child: _buildPhysicalAssetNameForm())
                  : _assetType == 'debt'
                      ? Form(key: _physicalAssetNameFormKey, child: _buildDebtForm())
                      : _buildPlatformSelector(),
            ),
            // Step 2: Details
            Step(
              title: _assetType == 'physical'
                  ? Text(_assetNameController.text.isNotEmpty ? _assetNameController.text : l10n.details)
                  : (_assetType == 'debt'
                      ? Text(_assetNameController.text.isNotEmpty ? _assetNameController.text : l10n.details)
                      : (_brandInfo != null ? Text(_brandInfo!.name) : Text(l10n.details))),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
              content: Form(key: _detailsFormKey, child: _buildDetailsForm()),
            ),
            // Step 3: Review
            Step(
              title: Text(l10n.reviewThisAsset),
              state: StepState.indexed,
              isActive: _currentStep >= 3,
              content: _buildReview(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StepperFooterControls(
        currentStep: _currentStep,
        lastStep: 3,
        isBusy: _isSubmitting,
        onPrimaryPressed: () async {
          if (_currentStep == 0) {
            if (_assetType == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.pleaseSelectAssetType)),
              );
              return;
            }
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            if (_assetType == 'digital') {
              if (_brandInfo == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseSelectPlatformService)),
                );
                return;
              }
            } else if (_assetType == 'physical') {
              if (_physicalAssetCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseSelectAssetCategory)),
                );
                return;
              }
              if (_physicalAssetCategory == 'other' && _otherAssetLegalClassification == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseSelectLegalClassification)),
                );
                return;
              }
              if (!(_physicalAssetNameFormKey.currentState?.validate() ?? false)) return;
            } else {
              if (!(_physicalAssetNameFormKey.currentState?.validate() ?? false)) return;
            }
            setState(() => _currentStep = 2);
          } else if (_currentStep == 2) {
            if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
            if (_selectedInstructionId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.pleaseSelectInstruction)),
              );
              return;
            }
            if (_selectedInstructionId == 'transfer_as_gift' && _selectedBelovedId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.giftRecipientRequired)),
              );
              return;
            }
            setState(() => _currentStep = 3);
          } else {
            await _submit();
          }
        },
        onBackPressed: _currentStep > 0
            ? () => setState(() => _currentStep = _currentStep - 1)
            : null,
        primaryLabel: _currentStep == 3
            ? (_assetType == 'physical'
                ? l10n.savePhysicalAsset
                : (_assetType == 'debt' ? 'Save debt' : l10n.saveDigitalAsset))
            : null,
      ),
    );
  }

  /// Maps user-friendly asset type to legal classification
  String _getLegalCategoryFromUserSelection(String? userSelection) {
    // Immovable assets
    if (userSelection == 'land' || userSelection == 'houses_buildings' || 
        userSelection == 'farms_plantations') {
      return 'immovable';
    }
    // Movable assets
    if (userSelection == 'cash' || userSelection == 'vehicles' || 
        userSelection == 'jewellery' || userSelection == 'furniture_household' ||
        userSelection == 'financial_instruments') {
      return 'movable';
    }
    // For 'other', use the explicitly selected legal classification
    if (userSelection == 'other') {
      return _otherAssetLegalClassification ?? 'movable'; // Default to movable if not set
    }
    // Default to movable for safety
    return 'movable';
  }

  Widget _buildPhysicalAssetNameForm() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Helper function to get icon path for selected value
    String? _getSelectedIconPath() {
      switch (_physicalAssetCategory) {
        case 'land':
          return SampulIcons.land;
        case 'houses_buildings':
          return SampulIcons.home;
        case 'farms_plantations':
          return SampulIcons.farm;
        case 'cash':
          return SampulIcons.payment;
        case 'vehicles':
          return SampulIcons.car;
        case 'jewellery':
          return SampulIcons.diamond;
        case 'furniture_household':
          return SampulIcons.furniture;
        case 'financial_instruments':
          return SampulIcons.assets;
        case 'other':
          return SampulIcons.category;
        default:
          return null;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section header
        Text(
          l10n.whatTypeOfPhysicalAsset,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Asset type selection (dropdown) with improved styling
        DropdownButtonFormField<String>(
          value: _physicalAssetCategory,
          isExpanded: true,
          icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: 'Select asset type',
            prefixIconPath: _getSelectedIconPath() ?? SampulIcons.category,
          ),
          selectedItemBuilder: (BuildContext context) {
            return <Widget>[
              Text(l10n.land, overflow: TextOverflow.ellipsis),
              Text(l10n.housesBuildings, overflow: TextOverflow.ellipsis),
              Text(l10n.farmsPlantations, overflow: TextOverflow.ellipsis),
              Text(l10n.cash, overflow: TextOverflow.ellipsis),
              Text(l10n.vehicles, overflow: TextOverflow.ellipsis),
              Text(l10n.jewellery, overflow: TextOverflow.ellipsis),
              Text(l10n.furnitureHousehold, overflow: TextOverflow.ellipsis),
              Text(l10n.financialInstruments, overflow: TextOverflow.ellipsis),
              Text(l10n.otherPhysicalAsset, overflow: TextOverflow.ellipsis),
            ];
          },
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'land',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.land, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.land,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'houses_buildings',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.home, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.housesBuildings,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'farms_plantations',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.farm, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.farmsPlantations,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'cash',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.payment, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.cash,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'vehicles',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.car, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.vehicles,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'jewellery',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.diamond, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.jewellery,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'furniture_household',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.furniture, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.furnitureHousehold,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'financial_instruments',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.assets, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.financialInstruments,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'other',
              child: Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.category, width: 20, height: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.otherPhysicalAsset,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (String? value) {
            setState(() {
              _physicalAssetCategory = value;
              // Reset legal classification when switching away from 'other'
              if (value != 'other') {
                _otherAssetLegalClassification = null;
              }
            });
          },
          validator: (String? v) => v == null ? l10n.pleaseSelectAssetCategory : null,
        ),
        
        // Legal classification selection (only for 'other' category) - improved styling
        if (_physicalAssetCategory == 'other') ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SampulIcons.buildIcon(SampulIcons.help, width: 18, height: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.selectLegalClassification,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.legalClassificationExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // Movable option
                InkWell(
                  onTap: () => setState(() => _otherAssetLegalClassification = 'movable'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _otherAssetLegalClassification == 'movable' 
                            ? colorScheme.primary 
                            : colorScheme.outline.withOpacity(0.3),
                        width: _otherAssetLegalClassification == 'movable' ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _otherAssetLegalClassification == 'movable' 
                          ? colorScheme.primaryContainer.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _otherAssetLegalClassification == 'movable' 
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.swap_horiz_outlined,
                                size: 24,
                                color: _otherAssetLegalClassification == 'movable' 
                                    ? colorScheme.primary 
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                l10n.movableAsset,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: _otherAssetLegalClassification == 'movable' 
                                      ? FontWeight.bold 
                                      : FontWeight.w500,
                                  color: _otherAssetLegalClassification == 'movable' 
                                      ? colorScheme.onSurface 
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_otherAssetLegalClassification == 'movable')
                              SampulIcons.buildIcon(SampulIcons.checkCircle, width: 24, height: 24, color: colorScheme.primary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            l10n.movableAssetExplanation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Immovable option
                InkWell(
                  onTap: () => setState(() => _otherAssetLegalClassification = 'immovable'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _otherAssetLegalClassification == 'immovable' 
                            ? colorScheme.primary 
                            : colorScheme.outline.withOpacity(0.3),
                        width: _otherAssetLegalClassification == 'immovable' ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _otherAssetLegalClassification == 'immovable' 
                          ? colorScheme.primaryContainer.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _otherAssetLegalClassification == 'immovable' 
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.home_outlined,
                                size: 24,
                                color: _otherAssetLegalClassification == 'immovable' 
                                    ? colorScheme.primary 
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                l10n.immovableAsset,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: _otherAssetLegalClassification == 'immovable' 
                                      ? FontWeight.bold 
                                      : FontWeight.w500,
                                  color: _otherAssetLegalClassification == 'immovable' 
                                      ? colorScheme.onSurface 
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_otherAssetLegalClassification == 'immovable')
                              SampulIcons.buildIcon(SampulIcons.checkCircle, width: 24, height: 24, color: colorScheme.primary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            l10n.immovableAssetExplanation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 28),
        // Asset name field with improved spacing
        Text(
          l10n.enterPhysicalAssetName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _assetNameController,
          textInputAction: TextInputAction.next,
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: l10n.physicalAssetName,
            hintText: l10n.physicalAssetNameHint,
            prefixIconPath: SampulIcons.label,
          ),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
        ),
      ],
    );
  }

  Widget _buildPlatformSelector() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Subtext
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            l10n.chooseDigitalAccountToInclude,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextField(
          controller: _brandSearchController,
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: l10n.searchForPlatformOrService,
            hintText: l10n.searchPlatformHint,
            prefixIconPath: SampulIcons.search,
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (_isSearching) const LinearProgressIndicator(minHeight: 2),
        if (_searchResults.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final BrandInfo item = _searchResults[index];
              final bool selected = _brandInfo?.websiteUrl == item.websiteUrl && _brandInfo?.name == item.name;
              return ListTile(
                leading: (item.logoUrl ?? '').isNotEmpty
                    ? _Logo(url: BrandfetchService.instance.addClientIdToUrl(item.logoUrl)!, size: 28)
                    : SampulIcons.buildIcon(SampulIcons.apps, width: 28, height: 28),
                title: Text(item.name),
                subtitle: item.websiteUrl.isNotEmpty ? Text(item.websiteUrl) : null,
                trailing: selected ? SampulIcons.buildIcon(SampulIcons.checkCircle, width: 24, height: 24, color: Colors.green) : null,
                onTap: () async {
                  setState(() {
                    _brandInfo = item;
                    _isCustomAsset = false;
                    _assetNameController.text = item.name;
                    _searchResults = <BrandInfo>[];
                    _showAddCustomOption = false;
                  });
                  try {
                    final String domainOrName = item.websiteUrl.isNotEmpty ? item.websiteUrl : item.name;
                    final BrandInfo? detailed = await BrandfetchService.instance.fetchByDomain(domainOrName);
                    if (!mounted) return;
                    if (detailed != null) {
                      final String mergedName = detailed.name.isNotEmpty ? detailed.name : item.name;
                      final String mergedWebsite = detailed.websiteUrl.isNotEmpty ? detailed.websiteUrl : item.websiteUrl;
                      final String? mergedLogo = (detailed.logoUrl ?? item.logoUrl);
                      setState(() {
                        _brandInfo = BrandInfo(name: mergedName, websiteUrl: mergedWebsite, logoUrl: mergedLogo);
                      });
                    }
                  } catch (_) {
                    // ignore enrichment errors; keep basic selection
                  }
                },
              );
            },
          ),
        if (_showAddCustomOption && !_isSearching)
          Builder(
            builder: (BuildContext context) {
              final l10n = AppLocalizations.of(context)!;
              return ListTile(
                leading: SampulIcons.buildIcon(
                  SampulIcons.add,
                  width: 24,
                  height: 24,
                  color: const Color.fromRGBO(83, 61, 233, 1),
                ),
                title: Text(l10n.cantFindYourPlatform),
                subtitle: Text(l10n.addCustomPlatform),
                trailing: SampulIcons.buildIcon(SampulIcons.arrowRight, width: 16, height: 16),
                onTap: () => _showCustomAssetDialog(),
              );
            },
          ),
        // Footer note
        if (!_isSearching && _searchResults.isEmpty && !_showAddCustomOption && _brandInfo == null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.youllProvideInstructionsNextStep,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_brandInfo != null && _searchResults.isEmpty && !_showAddCustomOption) ...<Widget>[
          const SizedBox(height: 8),
          ListTile(
            leading: (_brandInfo!.logoUrl ?? '').isNotEmpty
                ? _Logo(url: BrandfetchService.instance.addClientIdToUrl(_brandInfo!.logoUrl)!, size: 40)
                : SampulIcons.buildIcon(SampulIcons.apps, width: 28, height: 28),
            title: Text(_brandInfo!.name),
            subtitle: _brandInfo!.websiteUrl.isNotEmpty ? Text(_brandInfo!.websiteUrl) : null,
            trailing: SampulIcons.buildIcon(SampulIcons.checkCircle, width: 24, height: 24, color: Colors.green),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsForm() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Asset confirmation at top
        if (_assetType == 'digital' && _brandInfo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  if ((_brandInfo!.logoUrl ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _Logo(url: BrandfetchService.instance.addClientIdToUrl(_brandInfo!.logoUrl)!, size: 32),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SampulIcons.buildIcon(SampulIcons.apps, width: 32, height: 32),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _brandInfo!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_brandInfo!.websiteUrl.isNotEmpty)
                          Text(
                            _brandInfo!.websiteUrl,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: Text(l10n.change),
                  ),
                ],
              ),
            ),
          ),
        if (_assetType == 'physical' && _assetNameController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SampulIcons.buildIcon(SampulIcons.home, width: 32, height: 32),
                  ),
                  Expanded(
                    child: Text(
                      _assetNameController.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: Text(l10n.change),
                  ),
                ],
              ),
            ),
          ),
        // Subtext
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            _assetType == 'physical'
                ? 'Define how this asset should be handled.'
                : _assetType == 'debt'
                    ? 'Define how this debt should be settled.'
                : l10n.defineHowThisAccountShouldBeHandled,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Estimated value section
        Row(
          children: <Widget>[
            Text(
              l10n.estimatedValue,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${l10n.optional})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.estimatedValueDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _declaredValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
          ],
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: l10n.enterEstimatedValue,
            hintText: l10n.estimatedValueHint,
            prefixIconPath: SampulIcons.payment,
          ),
          validator: (String? v) {
            final String value = (v ?? '').trim();
            if (value.isEmpty) return null; // Optional field
            final RegExp re = RegExp(r'^\d+(\.\d{1,2})?$');
            if (!re.hasMatch(value)) return l10n.enterValidAmountMaxDecimals;
            final double? val = double.tryParse(value);
            if (val == null || val < 0) return l10n.enterValidAmount;
            return null;
          },
        ),
        const SizedBox(height: 24),
        // What should happen to this account?
        Text(
          _assetType == 'debt' ? 'What should happen to this debt?' : l10n.whatShouldHappenToThisAccount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedInstructionId,
          isExpanded: true,
          icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
          items: _getInstructions(context)
              .map((Map<String, String> c) => DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(c['name'] ?? ''),
                  ))
              .toList(),
          onChanged: (String? v) async {
            setState(() {
              _selectedInstructionId = v;
              _selectedBelovedId = null;
            });
            if (v == 'transfer_as_gift' && _belovedOptions.isEmpty) {
              await _loadBelovedOptions();
            }
          },
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: l10n.instructionUponActivation,
            prefixIconPath: SampulIcons.assignment,
          ),
          validator: (String? v) => (v == null || v.isEmpty) ? l10n.required : null,
        ),
        const SizedBox(height: 12),
        if (_selectedInstructionId == 'transfer_as_gift')
          DropdownButtonFormField<int>(
            initialValue: _selectedBelovedId,
            isExpanded: true,
            icon: SampulIcons.buildIcon(SampulIcons.chevronDown, width: 24, height: 24),
            items: _belovedOptions
                .map((Map<String, dynamic> b) => DropdownMenuItem<int>(
                      value: (b['id'] as num).toInt(),
                      child: Text((b['name'] as String?) ?? l10n.unnamed),
                    ))
                .toList(),
            onChanged: _isLoadingBeloved ? null : (int? v) => setState(() => _selectedBelovedId = v),
            decoration: FormDecorationHelper.roundedInputDecoration(
              context: context,
              labelText: _isLoadingBeloved ? l10n.loadingRecipients : l10n.giftRecipient,
              prefixIconPath: SampulIcons.gift,
            ),
            validator: (int? v) {
              if (_selectedInstructionId == 'transfer_as_gift') {
                if (v == null) return l10n.giftRecipientRequired;
              }
              return null;
            },
          ),
        if (_selectedInstructionId == 'transfer_as_gift') const SizedBox(height: 12),
        
        // Additional notes section with guidance
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Text(
              l10n.additionalNotes,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${l10n.optional})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.additionalNotesDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _remarksController,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: FormDecorationHelper.roundedInputDecoration(
            context: context,
            labelText: l10n.remarksOptional,
            hintText: l10n.remarksHint,
            prefixIconPath: SampulIcons.note,
          ),
        ),
        const SizedBox(height: 12),
        // Helpful suggestions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SampulIcons.buildIcon(SampulIcons.lightbulb, width: 16, height: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.youMightWantToInclude,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_assetType == 'digital' 
                ? <Widget>[
                    _buildSuggestionItem('• ${l10n.remarksSuggestion1}'),
                    _buildSuggestionItem('• ${l10n.remarksSuggestion2}'),
                    _buildSuggestionItem('• ${l10n.remarksSuggestion3}'),
                  ]
                : <Widget>[
                    _buildSuggestionItem('• ${l10n.remarksSuggestionPhysical1}'),
                    _buildSuggestionItem('• ${l10n.remarksSuggestionPhysical2}'),
                    _buildSuggestionItem('• ${l10n.remarksSuggestionPhysical3}'),
                  ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Security reassurance
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.weDoNotStorePasswords,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.thisInformationOnlyAccessible,
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
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextStyle? label = theme.textTheme.bodySmall;
    final TextStyle? value = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    String? recipientName() {
      if (_selectedBelovedId == null) return null;
      for (final Map<String, dynamic> b in _belovedOptions) {
        if ((b['id'] as num).toInt() == _selectedBelovedId) return (b['name'] as String?) ?? l10n.unnamed;
      }
      return null;
    }
    Widget row(String k, String? v) {
      if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 120, child: Text(k, style: label)),
            const SizedBox(width: 12),
            Expanded(child: Text(v, style: value)),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Asset name/platform
            Row(
              children: <Widget>[
                if (_assetType == 'digital')
                  ((_brandInfo?.logoUrl ?? '').isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _Logo(url: BrandfetchService.instance.addClientIdToUrl(_brandInfo!.logoUrl)!, size: 40),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SampulIcons.buildIcon(SampulIcons.apps, width: 40, height: 40),
                        ))
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SampulIcons.buildIcon(SampulIcons.home, width: 40, height: 40),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _assetType == 'physical' ? 'Asset name' : 'Platform',
                        style: label,
                      ),
                      Text(
                        _assetType == 'physical' 
                            ? (_assetNameController.text.isNotEmpty ? _assetNameController.text : '-')
                            : (_brandInfo?.name ?? '-'),
                        style: value,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = _assetType == 'physical' ? 1 : 1),
                  child: Text(l10n.change),
                ),
              ],
            ),
            const Divider(height: 24),
            // Asset type
            row(
              'Asset type',
              _assetType == 'physical'
                  ? l10n.physicalAsset
                  : (_assetType == 'debt' ? 'Register Debt' : l10n.digitalAsset),
            ),
            // Asset type (physical only) - show user-friendly name with legal classification
            if (_assetType == 'physical' && _physicalAssetCategory != null)
              row('Asset type', _getAssetTypeDisplayNameWithClassification(_physicalAssetCategory)),
            // Estimated value (if entered)
            if (_declaredValueController.text.trim().isNotEmpty)
              row('Estimated value', 'RM ${_declaredValueController.text}'),
            // Website (digital only)
            if (_assetType == 'digital' && (_brandInfo?.websiteUrl ?? '').isNotEmpty)
              row(l10n.website, _brandInfo!.websiteUrl),
            // Instruction
            row('Instruction', _selectedInstructionLabel()),
            if (_selectedInstructionId == 'transfer_as_gift') row(l10n.giftRecipient, recipientName()),
            // Additional notes (if any)
            if (_remarksController.text.trim().isNotEmpty) row('Additional notes', _remarksController.text),
            const SizedBox(height: 16),
            // Security reminder (digital assets only)
            if (_assetType == 'digital')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.passwordsNotStoredInSampul,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _selectedInstructionLabel() {
    final String? id = _selectedInstructionId;
    if (id == null) return '';
    final Map<String, String> item = _getInstructions(context).firstWhere(
      (Map<String, String> e) => e['id'] == id,
      orElse: () => <String, String>{},
    );
    return item['name'] ?? id;
  }

  String _getAssetTypeDisplayName(String? category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'land':
        return l10n.land;
      case 'houses_buildings':
        return l10n.housesBuildings;
      case 'farms_plantations':
        return l10n.farmsPlantations;
      case 'cash':
        return l10n.cash;
      case 'vehicles':
        return l10n.vehicles;
      case 'jewellery':
        return l10n.jewellery;
      case 'furniture_household':
        return l10n.furnitureHousehold;
      case 'financial_instruments':
        return l10n.financialInstruments;
      case 'other':
        return l10n.otherPhysicalAsset;
      default:
        return category ?? '';
    }
  }

  String _getAssetTypeDisplayNameWithClassification(String? category) {
    final l10n = AppLocalizations.of(context)!;
    final String assetTypeName = _getAssetTypeDisplayName(category);
    final String legalCategory = _getLegalCategoryFromUserSelection(category);
    final String legalCategoryName = legalCategory == 'immovable' 
        ? l10n.immovableAsset 
        : l10n.movableAsset;
    return '$assetTypeName ($legalCategoryName)';
  }

  Widget _buildSuggestionItem(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String url;
  final double size;
  const _Logo({required this.url, required this.size});

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final Widget fallback = SampulIcons.buildIcon(SampulIcons.image, width: size, height: size);
    if (_isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        placeholderBuilder: (_) => SizedBox(width: size, height: size, child: const CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}



