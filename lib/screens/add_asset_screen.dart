import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/brandfetch_service.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
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

  static const List<Map<String, String>> _instructions = <Map<String, String>>[
    {'id': 'faraid', 'name': 'Faraid'},
    {'id': 'terminate', 'name': 'Terminate Subscriptions'},
    {'id': 'transfer_as_gift', 'name': 'Transfer as Gift'},
    {'id': 'settle', 'name': 'Settle Debts'},
  ];

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
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Add Custom Asset'),
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
                  decoration: const InputDecoration(
                    labelText: 'Asset Name *',
                    hintText: 'e.g., My Custom Platform',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Website URL (optional)',
                    hintText: 'https://example.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    });
  }

  Future<void> _submit() async {
    // Validate step 0 selection
    if (_brandInfo == null) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a platform/service')),
      );
      return;
    }

    // Validate step 1 form
    if (!(_detailsFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 1);
      return;
    }

    if (_selectedInstructionId == null) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an instruction')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('You must be signed in');
      }

      // Persist minimal record to digital_assets table
      // Mapping category to instructions_after_death (enum) and using declared value
      final double declaredValue = double.parse(_declaredValueController.text.trim());
      final String instructions = _selectedInstructionId!; // backend enum should accept these ids

      final Map<String, dynamic> payload = <String, dynamic>{
        'uuid': user.id,
        'username': user.userMetadata?['username'] ?? user.email?.split('@').first,
        'email': user.email,
        'declared_value_myr': declaredValue,
        'instructions_after_death': instructions,
        'new_service_platform_name': _brandInfo!.name,
        'is_custom': _isCustomAsset,
      };

      // include brand details if available
      if (_brandInfo != null) {
        if (_brandInfo!.websiteUrl.isNotEmpty) {
          payload['new_service_platform_url'] = _brandInfo!.websiteUrl;
        }
        if ((_brandInfo!.logoUrl ?? '').isNotEmpty) {
          // Ensure client ID is stripped before storing
          payload['new_service_platform_logo_url'] = BrandfetchService.instance.stripClientIdFromUrl(_brandInfo!.logoUrl);
        }
      }

      if (instructions == 'transfer_as_gift') {
        if (_selectedBelovedId == null) {
          throw Exception('Please select a gift recipient');
        }
        payload['beloved_id'] = _selectedBelovedId;
      }

      final String remarks = _remarksController.text.trim();
      if (remarks.isNotEmpty) {
        payload['remarks'] = remarks;
      }

      await SupabaseService.instance.client.from('digital_assets').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add asset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Asset'),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final bool isLast = _currentStep == 2;
            return Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_currentStep == 0) {
                            if (_brandInfo == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a platform/service')),
                              );
                              return;
                            }
                            setState(() => _currentStep = 1);
                          } else if (_currentStep == 1) {
                            if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
                            if (_selectedInstructionId == 'transfer_as_gift' && _selectedBelovedId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gift Recipient is required')),
                              );
                              return;
                            }
                            setState(() => _currentStep = 2);
                          } else {
                            await _submit();
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isLast ? 'Save' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : () => setState(() => _currentStep = _currentStep - 1),
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: <Step>[
            Step(
              title: const Text('Platform / Service'),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: _buildPlatformSelector(),
            ),
            Step(
              title: const Text('Details'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(key: _detailsFormKey, child: _buildDetailsForm()),
            ),
            Step(
              title: const Text('Review'),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
              content: _buildReview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _brandSearchController,
          decoration: const InputDecoration(
            labelText: 'Search for a platform or service',
            hintText: 'e.g., Facebook, Google Drive, Maybank',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
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
                    : const Icon(Icons.apps_outlined),
                title: Text(item.name),
                subtitle: item.websiteUrl.isNotEmpty ? Text(item.websiteUrl) : null,
                trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
            title: const Text('Add your own asset'),
            subtitle: Text(
              _searchResults.isEmpty
                  ? 'Use "${_brandSearchController.text.trim()}" as the asset name'
                  : 'Can\'t find it? Add "${_brandSearchController.text.trim()}" as custom',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCustomAssetDialog(),
          ),
        if (_brandInfo != null && _searchResults.isEmpty && !_showAddCustomOption) ...<Widget>[
          const SizedBox(height: 8),
          ListTile(
            leading: (_brandInfo!.logoUrl ?? '').isNotEmpty
                ? _Logo(url: BrandfetchService.instance.addClientIdToUrl(_brandInfo!.logoUrl)!, size: 40)
                : const Icon(Icons.apps_outlined),
            title: Text(_brandInfo!.name),
            subtitle: _brandInfo!.websiteUrl.isNotEmpty ? Text(_brandInfo!.websiteUrl) : null,
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      children: <Widget>[
        TextFormField(
          controller: _declaredValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Declared Value (MYR)',
            helperText: 'Estimated current value of this asset',
            prefixIcon: Icon(Icons.payments_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (String? v) {
            final String value = (v ?? '').trim();
            if (value.isEmpty) return 'Required';
            final RegExp re = RegExp(r'^\d+(\.\d{1,2})?$');
            if (!re.hasMatch(value)) return 'Enter a valid amount (max 2 decimals)';
            final double? val = double.tryParse(value);
            if (val == null || val < 0) return 'Enter a valid amount';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedInstructionId,
          items: _instructions
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
          decoration: const InputDecoration(
            labelText: 'Instructions After Death',
            prefixIcon: Icon(Icons.list_alt_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (String? v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        if (_selectedInstructionId == 'transfer_as_gift')
          DropdownButtonFormField<int>(
            initialValue: _selectedBelovedId,
            items: _belovedOptions
                .map((Map<String, dynamic> b) => DropdownMenuItem<int>(
                      value: (b['id'] as num).toInt(),
                      child: Text((b['name'] as String?) ?? 'Unnamed'),
                    ))
                .toList(),
            onChanged: _isLoadingBeloved ? null : (int? v) => setState(() => _selectedBelovedId = v),
            decoration: InputDecoration(
              labelText: _isLoadingBeloved ? 'Loading recipients...' : 'Gift Recipient',
              prefixIcon: const Icon(Icons.card_giftcard_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: (int? v) {
              if (_selectedInstructionId == 'transfer_as_gift') {
                if (v == null) return 'Gift Recipient is required';
              }
              return null;
            },
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
            hintText: 'Any additional instructions or notes',
            prefixIcon: Icon(Icons.notes_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final TextStyle? label = Theme.of(context).textTheme.bodySmall;
    final TextStyle? value = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    String? recipientName() {
      if (_selectedBelovedId == null) return null;
      for (final Map<String, dynamic> b in _belovedOptions) {
        if ((b['id'] as num).toInt() == _selectedBelovedId) return (b['name'] as String?) ?? 'Unnamed';
      }
      return null;
    }
    Widget row(String k, String? v) {
      if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 150, child: Text(k, style: label)),
            const SizedBox(width: 8),
            Expanded(child: Text(v, style: value)),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Will Sync Notice in Review (moved above logo/name)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
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
                      'This asset will be included in your will. Any changes you make will automatically sync to your will.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                if ((_brandInfo?.logoUrl ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _Logo(url: BrandfetchService.instance.addClientIdToUrl(_brandInfo!.logoUrl)!, size: 40),
                  ),
                Expanded(child: Text(_brandInfo?.name ?? '-')),
              ],
            ),
            const SizedBox(height: 8),
            row('Website', (_brandInfo?.websiteUrl ?? '').isEmpty ? null : _brandInfo!.websiteUrl),
            row('Declared Value (MYR)', _declaredValueController.text),
            row('Instruction', _selectedInstructionLabel()),
            if (_selectedInstructionId == 'transfer_as_gift') row('Gift Recipient', recipientName()),
            row('Remarks', _remarksController.text),
          ],
        ),
      ),
    );
  }

  String _selectedInstructionLabel() {
    final String? id = _selectedInstructionId;
    if (id == null) return '';
    final Map<String, String> item = _instructions.firstWhere(
      (Map<String, String> e) => e['id'] == id,
      orElse: () => <String, String>{},
    );
    return item['name'] ?? id;
  }
}

class _Logo extends StatelessWidget {
  final String url;
  final double size;
  const _Logo({required this.url, required this.size});

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(Icons.image_outlined, size: size);
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



