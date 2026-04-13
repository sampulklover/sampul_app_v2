import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';
import '../config/analytics_screens.dart';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/sampul_icons.dart';
import '../widgets/stepper_footer_controls.dart';
import 'hibah_detail_screen.dart';
import 'hibah_info_screen.dart';

/// Document type option with short key for database storage and full label for UI display.
/// Keys are stored in the database for easier filtering/querying.
/// Labels are shown to users for better readability.
class _DocumentTypeOption {
  final String key;
  final String label;
  final String group;
  final bool requiresAsset;
  final bool mandatory;
  const _DocumentTypeOption({
    required this.key,
    required this.label,
    required this.group,
    this.requiresAsset = false,
    this.mandatory = false,
  });
}

const String _beneficiaryNricDocLabel = 'Beneficiaries\' NRIC (front & back)';

const List<_DocumentTypeOption> _documentTypeOptions = <_DocumentTypeOption>[
  _DocumentTypeOption(
    key: 'title_deed',
    label: 'Title Deed / Strata Title',
    group: 'Property Documents',
    requiresAsset: true,
    mandatory: true,
  ),
  _DocumentTypeOption(
    key: 'assessment_tax',
    label: 'Assessment Tax / Land Tax',
    group: 'Property Documents',
    requiresAsset: true,
    mandatory: true,
  ),
  _DocumentTypeOption(
    key: 'sale_agreement',
    label: 'Sale Agreement / Loan Agreement',
    group: 'Property Documents',
    requiresAsset: true,
    mandatory: true,
  ),
  _DocumentTypeOption(
    key: 'insurance_policy',
    label: 'MRTT / MLTT / Takaful / Insurance policy documents',
    group: 'Property Documents',
    requiresAsset: true,
    mandatory: true,
  ),
  _DocumentTypeOption(
    key: 'beneficiary_nric',
    label: _beneficiaryNricDocLabel,
    group: 'Identity Documents',
    mandatory: true,
  ),
  _DocumentTypeOption(
    key: 'guardian_nric',
    label: 'Guardian\'s NRIC (if beneficiary is under 18 / OKU)',
    group: 'Identity Documents',
  ),
  _DocumentTypeOption(
    key: 'other_supporting',
    label: 'Any other supporting documents',
    group: 'Supporting Documents',
  ),
];

// Helper function to get label from key
String _getDocumentTypeLabel(String key) {
  final option = _documentTypeOptions.firstWhere(
    (opt) => opt.key == key,
    orElse: () => const _DocumentTypeOption(
      key: '',
      label: 'Unknown Document',
      group: '',
    ),
  );
  return option.label;
}

class HibahCreateScreen extends StatefulWidget {
  const HibahCreateScreen({super.key});

  @override
  State<HibahCreateScreen> createState() => _HibahCreateScreenState();
}

class _HibahCreateScreenState extends State<HibahCreateScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingBeloved = false;

  final List<HibahGroupRequest> _assetGroups = <HibahGroupRequest>[];
  final List<_DocumentDraft> _documents = <_DocumentDraft>[];
  final List<_BelovedOption> _belovedOptions = <_BelovedOption>[];

  List<_DocumentTypeOption> get _requiredPropertyDocs => _documentTypeOptions
      .where((opt) => opt.requiresAsset && opt.mandatory)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadBelovedOptions();
  }

  Future<void> _loadBelovedOptions() async {
    if (_isLoadingBeloved) return;
    setState(() => _isLoadingBeloved = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name,relationship')
          .eq('uuid', user.id)
          .order('name');
      _belovedOptions
        ..clear()
        ..addAll(
          rows.map(
            (dynamic e) => _BelovedOption.fromMap(e as Map<String, dynamic>),
          ),
        );
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isLoadingBeloved = false);
    }
  }

  Future<void> _addAsset({HibahGroupRequest? initial}) async {
    final HibahGroupRequest? result = await Navigator.of(context)
        .push<HibahGroupRequest>(
          MaterialPageRoute<HibahGroupRequest>(
            settings: const RouteSettings(name: AnalyticsScreens.hibahAssetForm),
            builder: (_) => _HibahAssetFormScreen(
              belovedOptions: _belovedOptions,
              initial: initial,
            ),
          ),
        );
    if (result == null) return;
    setState(() {
      final int index = _assetGroups.indexWhere(
        (HibahGroupRequest element) => element.tempId == result.tempId,
      );
      if (index == -1) {
        _assetGroups.add(result);
      } else {
        _assetGroups[index] = result;
      }
    });
  }

  Future<void> _addDocument() async {
    final _DocumentDraft? draft = await Navigator.of(context)
        .push<_DocumentDraft>(
          MaterialPageRoute<_DocumentDraft>(
            settings: const RouteSettings(name: AnalyticsScreens.hibahDocumentForm),
            builder: (_) => _HibahDocumentFormScreen(
              assets: _assetGroups,
              options: _documentTypeOptions,
            ),
          ),
        );
    if (draft == null) return;
    setState(() => _documents.add(draft));
  }

  bool get _hasBeneficiaries =>
      _assetGroups.any((asset) => asset.beneficiaries.isNotEmpty);

  List<_DocumentDraft> _documentsForAsset(String tempId) {
    return _documents.where((doc) => doc.linkedAssetTempId == tempId).toList();
  }

  List<_DocumentTypeOption> _missingPropertyDocsForAsset(String tempId) {
    return _requiredPropertyDocs
        .where(
          (opt) => !_documents.any(
            (doc) =>
                doc.documentTypeKey == opt.key &&
                doc.linkedAssetTempId == tempId,
          ),
        )
        .toList();
  }

  bool _hasBeneficiaryIdentityDoc() {
    if (!_hasBeneficiaries) return true;
    return _documents.any(
      (doc) => doc.documentTypeKey == 'beneficiary_nric',
    );
  }

  Future<void> _submit() async {
    if (_assetGroups.isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one asset')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final List<HibahDocumentRequest> docsPayload =
          await _prepareDocumentsForUpload();
      final Hibah created = await HibahService.instance.createSubmission(
        groups: _assetGroups,
        documents: docsPayload,
      );
      if (!mounted) return;
      await AnalyticsService.capture('property trust submitted', properties: {
        'asset_group_count': _assetGroups.length,
        'document_count': docsPayload.length,
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute<bool>(
          settings: const RouteSettings(name: AnalyticsScreens.hibahDetail),
          builder: (_) => HibahDetailScreen(hibah: created),
        ),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<HibahDocumentRequest>> _prepareDocumentsForUpload() async {
    if (_documents.isEmpty) return <HibahDocumentRequest>[];
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to upload documents.');
    }
    final SupabaseStorageClient storage = SupabaseService.instance.storage;
    final List<HibahDocumentRequest> payloads = <HibahDocumentRequest>[];
    for (final _DocumentDraft doc in _documents) {
      final Uint8List? bytes = doc.file.bytes;
      if (bytes == null) {
        throw Exception(
          'Unable to read ${doc.file.name}. Please re-upload the file.',
        );
      }
      // Create unique file name to prevent duplicates (matching web format)
      final String originalName = doc.file.name;
      final String fileExtension = originalName.contains('.')
          ? originalName.split('.').last
          : 'bin';
      final String uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecondsSinceEpoch % 1000000000).toString()}.$fileExtension';
      final String key = '${user.id}/hibah-documents/$uniqueName';
      
      await storage
          .from('images')
          .uploadBinary(
            key,
            bytes,
            fileOptions: FileOptions(contentType: doc.mimeType, upsert: true),
          );
      payloads.add(
        HibahDocumentRequest(
          documentType: doc.documentTypeKey, // Store the key in DB
          fileName: doc.file.name,
          filePath: key,
          fileSize: doc.file.size,
          fileType: doc.mimeType,
          groupTempId: doc.linkedAssetTempId,
        ),
      );
    }
    return payloads;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Property Trust'),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Property Trust',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: AnalyticsScreens.hibahInfo),
                  builder: (_) => const HibahInfoScreen(fromHelpIcon: true),
                ),
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
            Step(
              title: const Text('Assets & Beneficiaries'),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: _buildAssetsStep(),
            ),
            Step(
              title: const Text('Documents'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: _buildDocumentsStep(),
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
      bottomNavigationBar: StepperFooterControls(
        currentStep: _currentStep,
        lastStep: 2,
        isBusy: _isSubmitting,
        onPrimaryPressed: () async {
          if (_currentStep == 0) {
            if (_assetGroups.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add at least one asset'),
                ),
              );
              return;
            }
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            setState(() => _currentStep = 2);
          } else {
            await _submit();
          }
        },
        onBackPressed: _currentStep > 0
            ? () {
                setState(() => _currentStep = _currentStep - 1);
              }
            : null,
      ),
    );
  }

  Widget _buildAssetsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_isLoadingBeloved)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (_assetGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No assets added yet. Tap the button below to start.'),
          )
        else
          ..._assetGroups.map((HibahGroupRequest group) {
            final int index = _assetGroups.indexOf(group) + 1;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(group.propertyName ?? 'Asset $index'),
                subtitle: Text(
                  '${group.beneficiaries.length} beneficiaries • ${group.assetType ?? 'Asset'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _addAsset(initial: group),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(
                          () => _assetGroups.removeWhere(
                            (HibahGroupRequest g) => g.tempId == group.tempId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _addAsset(),
            icon: const Icon(Icons.add),
            label: const Text('Add asset'),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    final TextStyle? sectionStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'You can upload supporting documents now or add them later. '
              'If you already have them ready, you can attach them below.',
            ),
          )
        else
          ..._documents.map((_DocumentDraft doc) {
            HibahGroupRequest? linkedAsset;
            for (final HibahGroupRequest asset in _assetGroups) {
              if (asset.tempId == doc.linkedAssetTempId) {
                linkedAsset = asset;
                break;
              }
            }
            final String subtitle = [
              doc.file.name,
              if (linkedAsset != null)
                'Linked to ${linkedAsset.propertyName ?? 'asset'}',
            ].join(' • ');
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(_getDocumentTypeLabel(doc.documentTypeKey)),
                subtitle: Text(subtitle),
                leading: const Icon(Icons.attachment_outlined),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(
                      () => _documents.removeWhere(
                        (_DocumentDraft d) => d.id == doc.id,
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addDocument,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Add document'),
        ),
        const SizedBox(height: 16),
        if (_assetGroups.isNotEmpty) ...<Widget>[
          Text('Suggested property documents', style: sectionStyle),
          const SizedBox(height: 8),
          ..._assetGroups.map(_buildAssetDocStatusCard),
        ],
        const SizedBox(height: 16),
        if (_hasBeneficiaries) _buildIdentityDocStatusCard(),
      ],
    );
  }

  Widget _buildReview() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final TextStyle? valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    Widget summaryRow(String label, String? value) {
      if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 120, child: Text(label, style: labelStyle)),
            const SizedBox(width: 12),
            Expanded(child: Text(value, style: valueStyle)),
          ],
        ),
      );
    }

    Widget sectionTitle(String text) {
      return Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionTitle('Assets'),
        const SizedBox(height: 8),
        if (_assetGroups.isEmpty)
          Text(
            'No assets added yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          ..._assetGroups.map((HibahGroupRequest asset) {
            final String assetName = (asset.propertyName ?? '').trim().isEmpty
                ? 'Asset'
                : asset.propertyName!.trim();

            String beneficiariesSummary() {
              if (asset.beneficiaries.isEmpty) return 'No beneficiaries added';
              return asset.beneficiaries.map((HibahBeneficiaryRequest b) {
                final String percent = b.sharePercentage != null
                    ? '${b.sharePercentage!.toStringAsFixed(2)}%'
                    : '-';
                return '${b.name} • $percent';
              }).join('\n');
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.domain_outlined, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            assetName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    summaryRow('Title no.', asset.registeredTitleNumber),
                    summaryRow('Location', asset.propertyLocation),
                    summaryRow('Estimated', asset.estimatedValue == null
                        ? null
                        : 'RM ${asset.estimatedValue}'),
                    summaryRow(
                      'Loan status',
                      asset.loanStatus?.replaceAll('_', ' '),
                    ),
                    summaryRow('Bank', asset.bankName),
                    summaryRow('Loan amount', asset.outstandingLoanAmount),
                    if (asset.landCategories.isNotEmpty)
                      summaryRow(
                        'Land',
                        asset.landCategories.join(', '),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Beneficiaries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      beneficiariesSummary(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        sectionTitle('Documents'),
        const SizedBox(height: 8),
        if (_documents.isEmpty)
          Text(
            'No documents uploaded yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ..._documents.map((_DocumentDraft doc) {
                    HibahGroupRequest? linkedAsset;
                    for (final HibahGroupRequest asset in _assetGroups) {
                      if (asset.tempId == doc.linkedAssetTempId) {
                        linkedAsset = asset;
                        break;
                      }
                    }
                    final String linkedLabel = linkedAsset == null
                        ? 'Not linked'
                        : 'Linked to ${linkedAsset.propertyName ?? 'asset'}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _getDocumentTypeLabel(doc.documentTypeKey),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doc.file.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  linkedLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssetDocStatusCard(HibahGroupRequest asset) {
    final List<_DocumentDraft> assetDocs = _documentsForAsset(asset.tempId);
    final Set<String> uploadedTypes = assetDocs
        .map((doc) => doc.documentTypeKey)
        .toSet();
    final List<_DocumentTypeOption> missing = _missingPropertyDocsForAsset(
      asset.tempId,
    );
    final bool complete = missing.isEmpty;
    final Color color = complete
        ? Colors.green.shade600
        : Colors.orange.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    asset.propertyName ?? 'Asset',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  complete ? Icons.check_circle : Icons.error_outline,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._requiredPropertyDocs.map((_DocumentTypeOption requirement) {
              final bool hasDoc = uploadedTypes.contains(requirement.label);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Icon(
                      hasDoc ? Icons.check : Icons.close,
                      size: 16,
                      color: hasDoc ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(requirement.label)),
                  ],
                ),
              );
            }),
            if (!complete)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Missing: ${missing.map((e) => e.label).join(', ')}',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityDocStatusCard() {
    final bool hasBeneficiaryDocs = _hasBeneficiaryIdentityDoc();
    final Color color = hasBeneficiaryDocs
        ? Colors.green.shade600
        : Colors.orange.shade700;
    return Card(
      child: ListTile(
        leading: Icon(Icons.badge_outlined, color: color),
        title: const Text("Beneficiaries' NRIC (front & back)"),
        subtitle: Text(
          hasBeneficiaryDocs
              ? 'Uploaded'
              : 'You can add this later if it is not ready yet.',
        ),
        trailing: Icon(
          hasBeneficiaryDocs ? Icons.check_circle : Icons.error_outline,
          color: color,
        ),
      ),
    );
  }
}

class _DocumentDraft {
  _DocumentDraft({
    required this.id,
    required this.documentTypeKey,
    required this.file,
    required this.mimeType,
    this.linkedAssetTempId,
  });

  final String id;
  final String documentTypeKey; // Stores the short key (e.g., 'title_deed')
  final PlatformFile file;
  final String mimeType;
  final String? linkedAssetTempId;
}

class _BelovedOption {
  final int id;
  final String name;
  final String? relationship;

  _BelovedOption({required this.id, required this.name, this.relationship});

  factory _BelovedOption.fromMap(Map<String, dynamic> map) {
    return _BelovedOption(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String? ?? 'Unnamed',
      relationship: map['relationship'] as String?,
    );
  }
}

class _HibahAssetFormScreen extends StatefulWidget {
  final List<_BelovedOption> belovedOptions;
  final HibahGroupRequest? initial;

  const _HibahAssetFormScreen({required this.belovedOptions, this.initial});

  @override
  State<_HibahAssetFormScreen> createState() => _HibahAssetFormScreenState();
}

class _HibahAssetFormScreenState extends State<_HibahAssetFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _propertyNameCtrl = TextEditingController();
  final TextEditingController _registeredTitleCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _estimatedValueCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _loanAmountCtrl = TextEditingController();

  String? _loanStatus;
  List<String> _landCategories = <String>[];
  List<HibahBeneficiaryRequest> _beneficiaries = <HibahBeneficiaryRequest>[];
  /// Existing physical assets (land, houses, farms) from digital_assets for pre-fill.
  List<Map<String, dynamic>> _existingPhysicalAssets = <Map<String, dynamic>>[];
  bool _loadingExistingAssets = false;
  /// Selected existing asset id; null means "add new" or no selection.
  String? _selectedExistingAssetId;

  static const List<String> _loanStatuses = <String>[
    'fully_paid',
    'ongoing_financing',
    'no_financing',
  ];

  static const List<String> _landCategoryOptions = <String>[
    'Residential',
    'Commercial',
    'Industrial',
    'Agriculture',
    'Mixed development',
  ];

  String? _normalizeLoanStatus(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == 'false' || v == 'no' || v == 'none' || v == 'no_loan') {
      return 'no_financing';
    }
    if (v == 'true' || v == 'yes' || v == 'under_loan') {
      return 'ongoing_financing';
    }
    if (v == 'paid' || v == 'fullypaid' || v == 'fully_paid') {
      return 'fully_paid';
    }
    if (_loanStatuses.contains(v)) return v;
    return null;
  }

  @override
  void initState() {
    super.initState();
    final HibahGroupRequest? initial = widget.initial;
    if (initial != null) {
      _propertyNameCtrl.text = initial.propertyName ?? '';
      _registeredTitleCtrl.text = initial.registeredTitleNumber ?? '';
      _locationCtrl.text = initial.propertyLocation ?? '';
      _estimatedValueCtrl.text = initial.estimatedValue ?? '';
      _bankNameCtrl.text = initial.bankName ?? '';
      _loanAmountCtrl.text = initial.outstandingLoanAmount ?? '';
      _loanStatus = _normalizeLoanStatus(initial.loanStatus);
      _landCategories = List<String>.from(initial.landCategories);
      _beneficiaries = List<HibahBeneficiaryRequest>.from(
        initial.beneficiaries,
      );
    } else {
      _loadExistingPhysicalAssets();
    }
  }

  /// Physical asset categories allowed for property trust: land, houses, farm.
  static const List<String> _propertyTrustPhysicalCategories = <String>[
    'land',
    'houses_buildings',
    'farms_plantations',
  ];

  Future<void> _loadExistingPhysicalAssets() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingExistingAssets = true);
    try {
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id, new_service_platform_name, declared_value_myr')
          .eq('uuid', user.id)
          .eq('asset_type', 'physical')
          .inFilter('physical_asset_category', _propertyTrustPhysicalCategories)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _existingPhysicalAssets = rows.cast<Map<String, dynamic>>();
        _loadingExistingAssets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _existingPhysicalAssets = <Map<String, dynamic>>[];
        _loadingExistingAssets = false;
      });
    }
  }

  @override
  void dispose() {
    _propertyNameCtrl.dispose();
    _registeredTitleCtrl.dispose();
    _locationCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _bankNameCtrl.dispose();
    _loanAmountCtrl.dispose();
    super.dispose();
  }

  double _currentShareTotal([HibahBeneficiaryRequest? exclude]) {
    return _beneficiaries
        .where((HibahBeneficiaryRequest b) => b != exclude)
        .fold(
          0.0,
          (double sum, HibahBeneficiaryRequest b) =>
              sum + (b.sharePercentage ?? 0),
        );
  }

  Future<void> _addOrEditBeneficiary({HibahBeneficiaryRequest? initial}) async {
    final _BeneficiaryFormResult? result =
        await showModalBottomSheet<_BeneficiaryFormResult>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _BeneficiaryForm(
            belovedOptions: widget.belovedOptions,
            initial: initial,
          ),
        );
    if (result == null) return;
    final double totalIfAdded =
        _currentShareTotal(initial) + (result.sharePercentage ?? 0);
    if (totalIfAdded > 100.0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shares exceed 100% (current total ${totalIfAdded.toStringAsFixed(2)}%)',
          ),
        ),
      );
      return;
    }
    setState(() {
      if (initial == null) {
        _beneficiaries.add(result.toRequest());
      } else {
        final int index = _beneficiaries.indexOf(initial);
        if (index != -1) _beneficiaries[index] = result.toRequest();
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_beneficiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one beneficiary')),
      );
      return;
    }
    final HibahGroupRequest result = HibahGroupRequest(
      tempId: widget.initial?.tempId ?? _generateTempId(),
      propertyName: _propertyNameCtrl.text.trim(),
      assetType: null,
      registeredTitleNumber: _registeredTitleCtrl.text.trim().isEmpty
          ? null
          : _registeredTitleCtrl.text.trim(),
      propertyLocation: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      estimatedValue: _estimatedValueCtrl.text.trim().isEmpty
          ? null
          : _estimatedValueCtrl.text.trim(),
      loanStatus: _loanStatus,
      bankName: _bankNameCtrl.text.trim().isEmpty
          ? null
          : _bankNameCtrl.text.trim(),
      outstandingLoanAmount: _loanAmountCtrl.text.trim().isEmpty
          ? null
          : _loanAmountCtrl.text.trim(),
      landCategories: _landCategories,
      beneficiaries: _beneficiaries,
    );
    Navigator.of(context).pop(result);
  }

  InputDecoration _fieldDecoration(String label) {
    IconData? prefix;
    switch (label) {
      case 'Select existing asset (optional)':
        prefix = Icons.home_work_outlined;
        break;
      case 'Property / asset name *':
        prefix = Icons.domain_outlined;
        break;
      case 'Registered title number':
        prefix = Icons.badge_outlined;
        break;
      case 'Property location':
        prefix = Icons.place_outlined;
        break;
      case 'Estimated value (MYR)':
        prefix = Icons.payments_outlined;
        break;
      case 'Loan status':
        prefix = Icons.account_balance_outlined;
        break;
      case 'Bank / financier':
        prefix = Icons.account_balance_outlined;
        break;
      case 'Outstanding loan amount':
        prefix = Icons.payments_outlined;
        break;
      default:
        prefix = null;
    }

    return FormDecorationHelper.roundedInputDecoration(
      context: context,
      labelText: label,
      prefixIcon: prefix,
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: const Color.fromRGBO(255, 255, 255, 1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiariesCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.group, color: const Color.fromRGBO(83, 61, 233, 1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beneficiaries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditBeneficiary(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_beneficiaries.isEmpty)
              Text(
                'No beneficiaries yet. Add at least one recipient.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ..._beneficiaries.asMap().entries.map((entry) {
                final int index = entry.key;
                final HibahBeneficiaryRequest b = entry.value;
                final String shareLabel =
                    '${(b.sharePercentage ?? 0).toStringAsFixed(2)}% share';
                return Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.name),
                      subtitle: Text(
                        b.relationship == null
                            ? shareLabel
                            : '${b.relationship} • $shareLabel',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _addOrEditBeneficiary(initial: b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _beneficiaries.remove(b)),
                          ),
                        ],
                      ),
                    ),
                    if (index != _beneficiaries.length - 1)
                      const Divider(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add asset' : 'Edit asset'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                      alignment: Alignment.center,
                      child: SampulIcons.buildIcon(
                        SampulIcons.home,
                        width: 36,
                        height: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _propertyNameCtrl.text.trim().isEmpty
                          ? 'Asset'
                          : _propertyNameCtrl.text.trim(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.domain_outlined,
                color: scheme.primary,
                title: 'Asset details',
                children: <Widget>[
                  if (_existingPhysicalAssets.isNotEmpty) ...[
                    Text(
                      'Use an asset you\'ve already added',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedExistingAssetId,
                      isExpanded: true,
                      icon: SampulIcons.buildIcon(
                        SampulIcons.chevronDown,
                        width: 24,
                        height: 24,
                      ),
                      decoration: _fieldDecoration(
                        'Select existing asset (optional)',
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Add new asset'),
                        ),
                        ..._existingPhysicalAssets.map((Map<String, dynamic> a) {
                          final String id = (a['id'] as Object?).toString();
                          final String name =
                              (a['new_service_platform_name'] as String?)
                                  ?.trim() ??
                              'Unnamed';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (String? v) {
                        setState(() {
                          _selectedExistingAssetId = v;
                          if (v != null) {
                            for (final Map<String, dynamic> a
                                in _existingPhysicalAssets) {
                              if ((a['id'] as Object?).toString() == v) {
                                _propertyNameCtrl.text =
                                    (a['new_service_platform_name'] as String?)
                                        ?.trim() ??
                                    '';
                                final num? val = a['declared_value_myr'] as num?;
                                _estimatedValueCtrl.text =
                                    val != null && val > 0
                                    ? val.toStringAsFixed(0)
                                    : '';
                                break;
                              }
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else if (_loadingExistingAssets)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_loadingExistingAssets) const SizedBox(height: 12),
                  TextFormField(
                    controller: _propertyNameCtrl,
                    decoration: _fieldDecoration('Property / asset name *'),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registeredTitleCtrl,
                    decoration: _fieldDecoration('Registered title number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: _fieldDecoration('Property location'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _estimatedValueCtrl,
                    decoration: _fieldDecoration('Estimated value (MYR)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.account_balance_outlined,
                color: scheme.secondary,
                title: 'Loan & financing',
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _loanStatus,
                    isExpanded: true,
                    icon: SampulIcons.buildIcon(
                      SampulIcons.chevronDown,
                      width: 24,
                      height: 24,
                    ),
                    decoration: _fieldDecoration('Loan status'),
                    items: _loanStatuses
                        .map(
                          (String status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) => setState(() => _loanStatus = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankNameCtrl,
                    decoration: _fieldDecoration('Bank / financier'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _loanAmountCtrl,
                    decoration: _fieldDecoration('Outstanding loan amount'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.terrain_outlined,
                color: scheme.tertiary,
                title: 'Land categories',
                children: <Widget>[
                  Text(
                    'Select one or more categories if the asset is land-based.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _landCategoryOptions.map((String option) {
                      final bool selected = _landCategories.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              _landCategories.add(option);
                            } else {
                              _landCategories.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBeneficiariesCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                'Save asset',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BeneficiaryFormResult {
  final int? belovedId;
  final String name;
  final String? relationship;
  final double? sharePercentage;
  final String? notes;

  _BeneficiaryFormResult({
    this.belovedId,
    required this.name,
    this.relationship,
    this.sharePercentage,
    this.notes,
  });

  HibahBeneficiaryRequest toRequest() {
    return HibahBeneficiaryRequest(
      belovedId: belovedId,
      name: name,
      relationship: relationship,
      sharePercentage: sharePercentage,
      notes: notes,
    );
  }
}

class _BeneficiaryForm extends StatefulWidget {
  final List<_BelovedOption> belovedOptions;
  final HibahBeneficiaryRequest? initial;

  const _BeneficiaryForm({required this.belovedOptions, this.initial});

  @override
  State<_BeneficiaryForm> createState() => _BeneficiaryFormState();
}

class _BeneficiaryFormState extends State<_BeneficiaryForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _relationshipCtrl = TextEditingController();
  final TextEditingController _shareCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  int? _selectedBelovedId;

  @override
  void initState() {
    super.initState();
    final HibahBeneficiaryRequest? initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.name;
      _relationshipCtrl.text = initial.relationship ?? '';
      _shareCtrl.text = initial.sharePercentage?.toString() ?? '';
      _notesCtrl.text = initial.notes ?? '';
      _selectedBelovedId = initial.belovedId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    _shareCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleBelovedChange(int? id) {
    setState(() => _selectedBelovedId = id);
    if (id == null) return;
    final _BelovedOption option = widget.belovedOptions.firstWhere(
      (opt) => opt.id == id,
    );
    _nameCtrl.text = option.name;
    if ((option.relationship ?? '').isNotEmpty) {
      _relationshipCtrl.text = option.relationship!;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final double? share = _shareCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_shareCtrl.text.trim());
    Navigator.of(context).pop(
      _BeneficiaryFormResult(
        belovedId: _selectedBelovedId,
        name: _nameCtrl.text.trim(),
        relationship: _relationshipCtrl.text.trim().isEmpty
            ? null
            : _relationshipCtrl.text.trim(),
        sharePercentage: share,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.initial == null
                            ? 'Add beneficiary'
                            : 'Edit beneficiary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose who should receive this hibah and how much they should receive.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (widget.belovedOptions.isNotEmpty)
                          DropdownButtonFormField<int>(
                            initialValue: _selectedBelovedId,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: 'Select from family',
                              prefixIcon: Icons.group_outlined,
                            ),
                            isExpanded: true,
                            icon: SampulIcons.buildIcon(
                              SampulIcons.chevronDown,
                              width: 24,
                              height: 24,
                            ),
                            items: widget.belovedOptions
                                .map(
                                  (option) => DropdownMenuItem<int>(
                                    value: option.id,
                                    child: Text(option.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _handleBelovedChange,
                          ),
                        if (widget.belovedOptions.isNotEmpty)
                          const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Full name',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _relationshipCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Relationship',
                            prefixIcon: Icons.family_restroom_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shareCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Share (%)',
                            hintText: 'For example, 50',
                            prefixIcon: Icons.percent_outlined,
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: FormDecorationHelper.roundedInputDecoration(
                            context: context,
                            labelText: 'Notes',
                            hintText: 'Add any helpful note',
                            prefixIcon: Icons.notes_outlined,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        'Save beneficiary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HibahDocumentFormScreen extends StatefulWidget {
  final List<HibahGroupRequest> assets;
  final List<_DocumentTypeOption> options;

  const _HibahDocumentFormScreen({required this.assets, required this.options});

  @override
  State<_HibahDocumentFormScreen> createState() =>
      _HibahDocumentFormScreenState();
}

class _HibahDocumentFormScreenState extends State<_HibahDocumentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PlatformFile? _selectedFile;
  String? _linkedAssetId;
  String? _selectedDocType;
  bool _isPickingFile = false;

  InputDecoration _fieldDecoration(String label) {
    IconData? prefix;
    switch (label) {
      case 'Document type':
        prefix = Icons.file_present_outlined;
        break;
      case 'Link to asset':
        prefix = Icons.home_work_outlined;
        break;
      default:
        prefix = null;
    }

    return FormDecorationHelper.roundedInputDecoration(
      context: context,
      labelText: label,
      prefixIcon: prefix,
    );
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = result.files.first);
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }
    if (_selectedDocType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a document type')));
      return;
    }
    final bool requiresAsset = _requiresAsset(_selectedDocType);
    if (requiresAsset && (_linkedAssetId == null || _linkedAssetId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link this document to a property')),
      );
      return;
    }
    final String mime =
        lookupMimeType(
          _selectedFile!.name,
          headerBytes: _selectedFile!.bytes,
        ) ??
        'application/octet-stream';
    Navigator.of(context).pop(
      _DocumentDraft(
        id: _generateTempId(),
        documentTypeKey: _selectedDocType!, // Store the key
        file: _selectedFile!,
        mimeType: mime,
        linkedAssetTempId: requiresAsset ? _linkedAssetId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add document'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 36,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Document',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a supporting document. You can link property documents to a specific asset.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.file_present_outlined,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Document details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDocType,
                        decoration: _fieldDecoration('Document type'),
                        isExpanded: true,
                        icon: SampulIcons.buildIcon(
                          SampulIcons.chevronDown,
                          width: 24,
                          height: 24,
                        ),
                        validator: (String? v) => v == null ? 'Required' : null,
                        items: _buildDocTypeItems(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedDocType = value;
                            if (_requiresAsset(value) &&
                                (_linkedAssetId == null ||
                                    _linkedAssetId!.isEmpty) &&
                                widget.assets.isNotEmpty) {
                              _linkedAssetId = widget.assets.first.tempId;
                            } else if (!_requiresAsset(value)) {
                              _linkedAssetId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _linkedAssetId,
                        decoration: _fieldDecoration('Link to asset').copyWith(
                          helperText: _requiresAsset(_selectedDocType)
                              ? 'Mandatory for property documents'
                              : 'Optional',
                        ),
                        isExpanded: true,
                        icon: SampulIcons.buildIcon(
                          SampulIcons.chevronDown,
                          width: 24,
                          height: 24,
                        ),
                        items: widget.assets
                            .map(
                              (HibahGroupRequest asset) =>
                                  DropdownMenuItem<String>(
                                value: asset.tempId,
                                child: Text(asset.propertyName ?? 'Asset'),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) =>
                            setState(() => _linkedAssetId = value),
                        validator: (String? value) {
                          if (_requiresAsset(_selectedDocType) &&
                              (value == null || value.isEmpty)) {
                            return 'Required for property documents';
                          }
                          return null;
                        },
                      ),
                      if (_requiresAsset(_selectedDocType) &&
                          widget.assets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Add at least one asset before uploading property documents.',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isPickingFile ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_selectedFile?.name ?? 'Select file'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_selectedFile != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • ${_selectedFile!.extension?.toUpperCase() ?? 'FILE'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _save,
              icon: const Icon(Icons.attach_file_outlined),
              label: Text(
                'Attach document',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _requiresAsset(String? docTypeKey) {
    if (docTypeKey == null) return false;
    return widget.options.any(
      (option) => option.key == docTypeKey && option.requiresAsset,
    );
  }

  List<DropdownMenuItem<String>> _buildDocTypeItems() {
    return widget.options
        .map(
          (_DocumentTypeOption option) => DropdownMenuItem<String>(
            value: option.key, // Store key as value
            child: Text(
              '${option.group}: ${option.label}', // Display label to user
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }
}

String _generateTempId() => DateTime.now().microsecondsSinceEpoch.toString();
