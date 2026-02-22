import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';
import '../services/supabase_service.dart';
import '../widgets/stepper_footer_controls.dart';
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
    if (!_validateRequiredDocuments()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final List<HibahDocumentRequest> docsPayload =
          await _prepareDocumentsForUpload();
      await HibahService.instance.createSubmission(
        groups: _assetGroups,
        documents: docsPayload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hibah submission created'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
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

  bool _validateRequiredDocuments() {
    for (final HibahGroupRequest asset in _assetGroups) {
      final List<_DocumentTypeOption> missing = _missingPropertyDocsForAsset(
        asset.tempId,
      );
      if (missing.isNotEmpty) {
        setState(() => _currentStep = 1);
        final String assetName = asset.propertyName ?? 'asset';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload ${missing.first.label} for $assetName before continuing.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    if (!_hasBeneficiaryIdentityDoc()) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload Beneficiaries\' NRIC (front & back) to continue.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
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
        title: const Text('Create Hibah'),
        actions: <Widget>[
          IconButton(
            tooltip: 'About Hibah',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HibahInfoScreen(fromHelpIcon: true)),
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
              'Each property must include its supporting documents. '
              'Upload the required files below.',
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
          Text('Required property documents', style: sectionStyle),
          const SizedBox(height: 8),
          ..._assetGroups.map(_buildAssetDocStatusCard),
        ],
        const SizedBox(height: 16),
        if (_hasBeneficiaries) _buildIdentityDocStatusCard(),
      ],
    );
  }

  Widget _buildReview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Assets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_assetGroups.isEmpty)
            const Text('No assets added')
          else
            ..._assetGroups.map((HibahGroupRequest asset) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        asset.propertyName ?? 'Asset',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (asset.assetType != null)
                        Text('Type: ${asset.assetType}'),
                      if (asset.propertyLocation != null)
                        Text('Location: ${asset.propertyLocation}'),
                      if (asset.estimatedValue != null)
                        Text('Estimated value: ${asset.estimatedValue}'),
                      const SizedBox(height: 8),
                      Text(
                        'Beneficiaries (${asset.beneficiaries.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...asset.beneficiaries.map((HibahBeneficiaryRequest b) {
                        final String percent = b.sharePercentage != null
                            ? '${b.sharePercentage!.toStringAsFixed(2)}%'
                            : '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${b.name} • $percent'),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          Text('Documents', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_documents.isEmpty)
            const Text('No documents uploaded')
          else
            ..._documents.map((_DocumentDraft doc) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(_getDocumentTypeLabel(doc.documentTypeKey)),
                subtitle: Text(doc.file.name),
              );
            }),
        ],
      ),
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
              : 'Required for every beneficiary submission.',
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

  String? _assetType;
  String? _loanStatus;
  List<String> _landCategories = <String>[];
  List<HibahBeneficiaryRequest> _beneficiaries = <HibahBeneficiaryRequest>[];

  static const List<String> _assetTypes = <String>[
    'Real estate',
    'Investment',
    'Savings',
    'Vehicle',
    'Others',
  ];

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
      _assetType = initial.assetType;
      _loanStatus = initial.loanStatus;
      _landCategories = List<String>.from(initial.landCategories);
      _beneficiaries = List<HibahBeneficiaryRequest>.from(
        initial.beneficiaries,
      );
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
      assetType: _assetType,
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
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildSectionCard(
              icon: Icons.domain,
              color: scheme.primary,
              title: 'Asset details',
              children: <Widget>[
                TextFormField(
                  controller: _propertyNameCtrl,
                  decoration: _fieldDecoration('Property / asset name *'),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _assetType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_outlined),
                  decoration: _fieldDecoration('Asset type'),
                  items: _assetTypes
                      .map(
                        (String type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _assetType = v),
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
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.account_balance,
              color: scheme.secondary,
              title: 'Loan & financing',
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _loanStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_outlined),
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
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.terrain,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save asset'),
              ),
            ),
          ],
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.initial == null ? 'Add beneficiary' : 'Edit beneficiary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (widget.belovedOptions.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _selectedBelovedId,
                  decoration: InputDecoration(labelText: 'Select from family',
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_outlined),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Full name'),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationshipCtrl,
                decoration: InputDecoration(labelText: 'Relationship'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shareCtrl,
                decoration: InputDecoration(labelText: 'Share (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Text('Save beneficiary'),
              ),
            ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add document'),
        actions: <Widget>[
          TextButton(onPressed: _save, child: const Text('ATTACH')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.file_present, color: const Color.fromRGBO(49, 24, 211, 1)),
                        const SizedBox(width: 8),
                        Text(
                          'Document details',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDocType,
                      decoration: _sheetDecoration('Document type'),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _linkedAssetId,
                      decoration: _sheetDecoration('Link to asset').copyWith(
                        helperText: _requiresAsset(_selectedDocType)
                            ? 'Mandatory for property documents'
                            : 'Optional',
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isPickingFile ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFile?.name ?? 'Select file'),
                    ),
                    if (_selectedFile != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • ${_selectedFile!.extension?.toUpperCase() ?? 'FILE'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Attach document'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _sheetDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
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
