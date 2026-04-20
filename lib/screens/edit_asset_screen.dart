import 'package:flutter/material.dart';
import '../utils/sampul_icons.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/brandfetch_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/form_decoration_helper.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';

class EditAssetScreen extends StatefulWidget {
  final int assetId;
  const EditAssetScreen({super.key, required this.assetId});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _declaredValueController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _instruction;
  String _name = '';
  String? _logoUrl;
  String? _url;
  String? _assetType;
  String? _physicalCategory;

  // Beloved (gift recipient)
  final List<Map<String, dynamic>> _belovedOptions = <Map<String, dynamic>>[];
  int? _selectedBelovedId;
  bool _isLoadingBeloved = false;

  List<Map<String, String>> _getInstructions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_assetType == 'debt' || _instruction == 'settle') {
      return <Map<String, String>>[
        {'id': 'settle', 'name': l10n.settleDebts},
      ];
    }
    return <Map<String, String>>[
      {'id': 'faraid', 'name': l10n.faraid},
      {'id': 'terminate', 'name': l10n.terminateSubscriptions},
      {'id': 'transfer_as_gift', 'name': l10n.transferAsGift},
      {'id': 'settle', 'name': l10n.settleDebts},
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadBelovedOptions() async {
    if (_isLoadingBeloved) return;
    setState(() => _isLoadingBeloved = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;
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
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingBeloved = false);
    }
  }

  Future<void> _loadAsset() async {
    try {
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id,new_service_platform_name,new_service_platform_logo_url,new_service_platform_url,declared_value_myr,instructions_after_death,remarks,beloved_id,asset_type,physical_asset_category')
          .eq('id', widget.assetId)
          .limit(1);
      if (!mounted) return;
      if (rows.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      final Map<String, dynamic> a = rows.first as Map<String, dynamic>;
      _name = (a['new_service_platform_name'] as String?) ?? '';
      _logoUrl = a['new_service_platform_logo_url'] as String?;
      _url = a['new_service_platform_url'] as String?;
      _assetType = a['asset_type'] as String?;
      _physicalCategory = a['physical_asset_category'] as String?;
      final double? value = (a['declared_value_myr'] as num?)?.toDouble();
      _declaredValueController.text = value != null ? value.toStringAsFixed(2) : '';
      _instruction = a['instructions_after_death'] as String?;
      _remarksController.text = (a['remarks'] as String?) ?? '';
      _selectedBelovedId = (a['beloved_id'] as num?)?.toInt();
      setState(() {
        _isLoading = false;
      });
      if (_instruction == 'transfer_as_gift') {
        await _loadBelovedOptions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_instruction == 'transfer_as_gift' && _selectedBelovedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectGiftRecipient)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> payload = <String, dynamic>{};
      if (_instruction != null && _instruction!.isNotEmpty) payload['instructions_after_death'] = _instruction;
      final String valueStr = _declaredValueController.text.trim();
      if (valueStr.isNotEmpty) payload['declared_value_myr'] = double.parse(valueStr);
      final String remarks = _remarksController.text.trim();
      payload['remarks'] = remarks;
      if (_instruction == 'transfer_as_gift') {
        payload['beloved_id'] = _selectedBelovedId;
      } else {
        payload['beloved_id'] = null;
      }

      await SupabaseService.instance.client
          .from('digital_assets')
          .update(payload)
          .eq('id', widget.assetId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetUpdated), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToUpdate(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editAsset),
        actions: <Widget>[
          IconButton(
            onPressed: _isSubmitting ? null : _onDeletePressed,
            icon: SampulIcons.buildIconButtonIcon(SampulIcons.delete, size: 24),
            tooltip: l10n.delete,
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAEAEA)),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: (_assetType == 'physical')
                          ? _PhysicalAssetIconEdit(category: _physicalCategory, size: 36)
                          : (_logoUrl != null && _logoUrl!.isNotEmpty)
                              ? Image.network(
                                  BrandfetchService.instance.addClientIdToUrl(_logoUrl) ?? _logoUrl!,
                                  fit: BoxFit.cover,
                                )
                              : SampulIcons.buildIcon(SampulIcons.apps, width: 36, height: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(_name, style: Theme.of(context).textTheme.titleMedium),
                    if ((_url ?? '').isNotEmpty)
                      Text(_url!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),

              const SizedBox(height: 16),

            // Will Sync Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.sync_alt,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.changesHereUpdateWillAutomatically,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l10n.details, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _instruction,
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
                            _instruction = v;
                            if (_instruction != 'transfer_as_gift') {
                              _selectedBelovedId = null;
                            }
                          });
                          if (v == 'transfer_as_gift' && _belovedOptions.isEmpty) {
                            await _loadBelovedOptions();
                          }
                        },
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: l10n.instructionsAfterDeath,
                          prefixIcon: Icons.assignment_outlined,
                        ),
                        validator: (String? v) => (v == null || v.isEmpty) ? l10n.required : null,
                      ),
                      const SizedBox(height: 12),
                      if (_instruction == 'transfer_as_gift')
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
                            prefixIcon: Icons.card_giftcard_outlined,
                          ),
                          validator: (int? v) {
                            if (_instruction == 'transfer_as_gift') {
                              if (v == null) return l10n.giftRecipientRequired;
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _declaredValueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: l10n.declaredValueMyr,
                          prefixIcon: Icons.payments_outlined,
                        ),
                        validator: (String? v) {
                          final String value = (v ?? '').trim();
                          if (value.isEmpty) return l10n.required;
                          final RegExp re = RegExp(r'^\d+(\.\d{1,2})?$');
                          if (!re.hasMatch(value)) return l10n.enterValidAmountMaxDecimals;
                          final double? val = double.tryParse(value);
                          if (val == null || val < 0) return l10n.enterValidAmount;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: l10n.remarksOptional,
                          prefixIcon: Icons.notes_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeletePressed() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final l10nDialog = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10nDialog.deleteAsset),
          content: Text(l10nDialog.areYouSureDeleteAsset),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10nDialog.cancel)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10nDialog.delete)),
          ],
        );
      },
    );
    if (confirm == true) {
      await _deleteAsset();
    }
  }

  Future<void> _deleteAsset() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.instance.client
          .from('digital_assets')
          .delete()
          .eq('id', widget.assetId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetDeleted), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToDelete(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _PhysicalAssetIconEdit extends StatelessWidget {
  final String? category;
  final double size;

  const _PhysicalAssetIconEdit({required this.category, required this.size});

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
