import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/brandfetch_service.dart';
import '../utils/sampul_icons.dart';
import 'edit_asset_screen.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';

class AssetPreviewScreen extends StatefulWidget {
  final int assetId;

  const AssetPreviewScreen({super.key, required this.assetId});

  @override
  State<AssetPreviewScreen> createState() => _AssetPreviewScreenState();
}

class _AssetPreviewScreenState extends State<AssetPreviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _asset;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select(
            'id,new_service_platform_name,new_service_platform_logo_url,new_service_platform_url,declared_value_myr,instructions_after_death,remarks,asset_type,physical_asset_category,physical_legal_classification',
          )
          .eq('id', widget.assetId)
          .limit(1);

      if (!mounted) return;

      if (rows.isEmpty) {
        // Asset no longer exists (possibly deleted from edit screen)
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _asset = rows.first as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_asset == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.details)),
        body: Center(
          child: Text(
            l10n.failedToLoadInitialData(''),
          ),
        ),
      );
    }

    final Map<String, dynamic> a = _asset!;
    final String name = (a['new_service_platform_name'] as String?) ?? '';
    final String? logoUrl = a['new_service_platform_logo_url'] as String?;
    final String? url = a['new_service_platform_url'] as String?;
    final double? value = (a['declared_value_myr'] as num?)?.toDouble();
    final String? instruction = a['instructions_after_death'] as String?;
    final String? remarks = a['remarks'] as String?;
    final String assetType = (a['asset_type'] as String?) ?? 'digital';
    final String? physicalCategory = a['physical_asset_category'] as String?;
    final String? physicalLegal = a['physical_legal_classification'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.details),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editAsset,
            onPressed: () async {
              final bool? updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => EditAssetScreen(assetId: widget.assetId),
                ),
              );
              if (updated == true) {
                await _loadAsset();
                if (mounted) {
                  // Inform caller that something changed
                  Navigator.of(context).pop(true);
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEAEAEA),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: (assetType == 'physical')
                        ? _PhysicalAssetIconPreview(
                            category: physicalCategory,
                            size: 36,
                          )
                        : (logoUrl != null && logoUrl.isNotEmpty)
                            ? Image.network(
                                BrandfetchService.instance.addClientIdToUrl(logoUrl) ?? logoUrl,
                                fit: BoxFit.cover,
                              )
                            : SampulIcons.buildIcon(
                                SampulIcons.apps,
                                width: 36,
                                height: 36,
                              ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if ((url ?? '').isNotEmpty)
                    Text(
                      url!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.details,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Asset overview
                    _InfoRow(
                      label: l10n.assetType,
                      value: assetType == 'physical'
                          ? l10n.physicalAsset
                          : l10n.digitalAsset,
                    ),
                    if (assetType == 'physical' && physicalCategory != null)
                      _InfoRow(
                        label: l10n.category,
                        value: _physicalAssetCategoryLabel(
                          physicalCategory,
                          physicalLegal,
                          context,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (value != null)
                      _InfoRow(
                        label: l10n.declaredValueMyr,
                        value: 'RM ${value.toStringAsFixed(2)}',
                      ),
                    if (value == null)
                      _InfoRow(
                        label: l10n.declaredValueMyr,
                        value: '-',
                      ),
                    const SizedBox(height: 12),
                    if (instruction != null && instruction.isNotEmpty)
                      _InfoRow(
                        label: l10n.instruction,
                        value: _prettyInstructionLabel(instruction, context),
                      ),
                    if (instruction == null || instruction.isEmpty)
                      _InfoRow(
                        label: l10n.instruction,
                        value: '-',
                      ),
                    const SizedBox(height: 12),
                    if (remarks != null && remarks.trim().isNotEmpty)
                      _InfoRow(
                        label: l10n.remarksOptional,
                        value: remarks.trim(),
                        isMultiline: true,
                      ),
                    if (remarks == null || remarks.trim().isEmpty)
                      _InfoRow(
                        label: l10n.remarksOptional,
                        value: '-',
                        isMultiline: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall;
    final TextStyle? valueStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(label, style: labelStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhysicalAssetIconPreview extends StatelessWidget {
  final String? category;
  final double size;

  const _PhysicalAssetIconPreview({
    required this.category,
    required this.size,
  });

  String _iconPathForCategory() {
    switch (category) {
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
        return SampulIcons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SampulIcons.buildIcon(
      _iconPathForCategory(),
      width: size,
      height: size,
    );
  }
}

String _physicalAssetCategoryLabel(
  String? category,
  String? physicalLegal,
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  String base;
  switch (category) {
    case 'land':
      base = l10n.land;
      break;
    case 'houses_buildings':
      base = l10n.housesBuildings;
      break;
    case 'farms_plantations':
      base = l10n.farmsPlantations;
      break;
    case 'cash':
      base = l10n.cash;
      break;
    case 'vehicles':
      base = l10n.vehicles;
      break;
    case 'jewellery':
      base = l10n.jewellery;
      break;
    case 'furniture_household':
      base = l10n.furnitureHousehold;
      break;
    case 'financial_instruments':
      base = l10n.financialInstruments;
      break;
    case 'other':
      base = l10n.otherPhysicalAsset;
      break;
    default:
      base = category ?? '';
      break;
  }

  String legalSuffix = '';
  if (physicalLegal == 'immovable') {
    legalSuffix = l10n.immovableAsset;
  } else if (physicalLegal == 'movable') {
    legalSuffix = l10n.movableAsset;
  }

  if (legalSuffix.isEmpty) {
    return base;
  }
  return '$base ($legalSuffix)';
}

String _prettyInstructionLabel(String key, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'faraid':
      return l10n.faraid;
    case 'terminate':
      return l10n.terminateSubscriptions;
    case 'transfer_as_gift':
      return l10n.transferAsGift;
    case 'settle':
      return l10n.settleDebts;
    default:
      return key;
  }
}

