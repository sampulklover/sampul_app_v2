import 'package:flutter/material.dart';
import '../services/executor_service.dart';
import '../models/executor.dart';
import '../config/executor_constants.dart';
import '../utils/form_decoration_helper.dart';
import '../widgets/stepper_footer_controls.dart';
import '../controllers/auth_controller.dart';
import '../models/executor_document.dart';
import '../services/executor_documents_service.dart';
import 'executor_document_form_screen.dart';
import '../services/supabase_service.dart';

class ExecutorEditScreen extends StatefulWidget {
  final Executor initial;

  const ExecutorEditScreen({super.key, required this.initial});

  @override
  State<ExecutorEditScreen> createState() => _ExecutorEditScreenState();
}

class _ExecutorEditScreenState extends State<ExecutorEditScreen> {
  final GlobalKey<FormState> _deceasedFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _claimantFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _documentsFormKey = GlobalKey<FormState>();

  // Deceased information controllers
  final TextEditingController _deceasedNameCtrl = TextEditingController();
  final TextEditingController _deceasedNricCtrl = TextEditingController();
  final TextEditingController _deceasedDobCtrl = TextEditingController();
  final TextEditingController _deceasedDodCtrl = TextEditingController();
  String? _selectedRelationship;

  // Claimant information controllers
  final TextEditingController _claimantNameCtrl = TextEditingController();
  final TextEditingController _claimantNricCtrl = TextEditingController();
  final TextEditingController _claimantDobCtrl = TextEditingController();
  final TextEditingController _claimantPhoneCtrl = TextEditingController();
  final TextEditingController _claimantEmailCtrl = TextEditingController();
  final TextEditingController _claimantAddress1Ctrl = TextEditingController();
  final TextEditingController _claimantAddress2Ctrl = TextEditingController();
  final TextEditingController _claimantCityCtrl = TextEditingController();
  final TextEditingController _claimantPostcodeCtrl = TextEditingController();
  final TextEditingController _claimantStateCtrl = TextEditingController();

  // Additional information controllers
  final List<ExecutorDocumentDraft> _supportingDocs = <ExecutorDocumentDraft>[];
  List<ExecutorDocument> _existingDocuments = <ExecutorDocument>[];
  bool _loadingExistingDocuments = false;
  Future<void> _addSupportingDocument() async {
    final ExecutorDocumentDraft? draft =
        await Navigator.of(context).push<ExecutorDocumentDraft>(
      MaterialPageRoute<ExecutorDocumentDraft>(
        builder: (_) => const ExecutorDocumentFormScreen(),
      ),
    );
    if (draft == null) return;
    setState(() => _supportingDocs.add(draft));
  }


  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadExistingDocuments();
  }

  Future<void> _loadExistingData() async {
    final int? executorId = widget.initial.id;
    if (executorId == null) return;
    try {
      final Map<String, dynamic>? exec = await SupabaseService.instance.client
          .from('executor')
          .select(
            'name,nric_number,phone_no,email,relationship_with_deceased,address_line_1,address_line_2,city,postcode,state',
          )
          .eq('id', executorId)
          .maybeSingle();

      final Map<String, dynamic>? deceased = await SupabaseService.instance.client
          .from('executor_deceased')
          .select('full_name,nric_new,date_of_death')
          .eq('executor_id', executorId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        // Applicant (stored in executor table)
        _claimantNameCtrl.text = (exec?['name'] as String?) ?? '';
        _claimantNricCtrl.text = (exec?['nric_number'] as String?) ?? '';
        _claimantPhoneCtrl.text = (exec?['phone_no'] as String?) ?? '';
        _claimantEmailCtrl.text = (exec?['email'] as String?) ?? '';
        _claimantAddress1Ctrl.text = (exec?['address_line_1'] as String?) ?? '';
        _claimantAddress2Ctrl.text = (exec?['address_line_2'] as String?) ?? '';
        _claimantCityCtrl.text = (exec?['city'] as String?) ?? '';
        _claimantPostcodeCtrl.text = (exec?['postcode'] as String?) ?? '';
        _claimantStateCtrl.text = (exec?['state'] as String?) ?? '';
        _selectedRelationship = (exec?['relationship_with_deceased'] as String?);

        // Deceased (stored in executor_deceased table)
        _deceasedNameCtrl.text = (deceased?['full_name'] as String?) ?? '';
        _deceasedNricCtrl.text = (deceased?['nric_new'] as String?) ?? '';
        _deceasedDodCtrl.text = (deceased?['date_of_death'] as String?) ?? '';

        // Not stored in current schema (keep visible but not persisted)
        _deceasedDobCtrl.text = '';
        _claimantDobCtrl.text = '';
      });
    } catch (_) {
      // If load fails, keep form usable with empty fields.
    }
  }

  Future<void> _loadExistingDocuments() async {
    final int? executorId = widget.initial.id;
    if (executorId == null) return;
    if (_loadingExistingDocuments) return;
    setState(() => _loadingExistingDocuments = true);
    try {
      final List<ExecutorDocument> docs =
          await ExecutorDocumentsService.instance.listForExecutor(executorId);
      if (!mounted) return;
      setState(() => _existingDocuments = docs);
    } finally {
      if (mounted) setState(() => _loadingExistingDocuments = false);
    }
  }

  Future<void> _deleteExistingDocument(ExecutorDocument doc) async {
    try {
      await ExecutorDocumentsService.instance.delete(doc);
      if (!mounted) return;
      setState(() {
        _existingDocuments =
            _existingDocuments.where((d) => d.id != doc.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _deceasedNameCtrl.dispose();
    _deceasedNricCtrl.dispose();
    _deceasedDobCtrl.dispose();
    _deceasedDodCtrl.dispose();
    _claimantNameCtrl.dispose();
    _claimantNricCtrl.dispose();
    _claimantDobCtrl.dispose();
    _claimantPhoneCtrl.dispose();
    _claimantEmailCtrl.dispose();
    _claimantAddress1Ctrl.dispose();
    _claimantAddress2Ctrl.dispose();
    _claimantCityCtrl.dispose();
    _claimantPostcodeCtrl.dispose();
    _claimantStateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_deceasedFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      return;
    }
    if (!(_claimantFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!(_documentsFormKey.currentState?.validate() ?? true)) {
      setState(() => _currentStep = 2);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('You must be signed in to upload documents.');
      }
      final int executorId = widget.initial.id!;
      // Upload new files and insert rows into executor_documents table
      for (final ExecutorDocumentDraft draft in _supportingDocs) {
        final bytes = draft.file.bytes;
        if (bytes == null) {
          throw Exception(
            'Unable to read ${draft.file.name}. Please remove and re-upload it.',
          );
        }
        await ExecutorDocumentsService.instance.uploadAndCreateRow(
          executorId: executorId,
          title: draft.title,
          bytes: bytes,
          fileName: draft.file.name,
          mimeType: draft.mimeType,
          documentType: 'supporting',
        );
      }
      // Refresh list and clear drafts
      await _loadExistingDocuments();
      if (mounted) {
        setState(() => _supportingDocs.clear());
      }

      // Update executor table (only real columns from DB_STRUCTURE.md)
      final Map<String, dynamic> executorUpdate = <String, dynamic>{
        // Required by DB constraints (NOT NULL)
        'name': _claimantNameCtrl.text.trim(),
        'nric_number': _claimantNricCtrl.text.trim(),
        'phone_no': _claimantPhoneCtrl.text.trim().isEmpty
            ? null
            : _claimantPhoneCtrl.text.trim(),
        // Required by DB constraints (NOT NULL)
        'email': _claimantEmailCtrl.text.trim(),
        'relationship_with_deceased': _selectedRelationship,
        'address_line_1': _claimantAddress1Ctrl.text.trim().isEmpty
            ? null
            : _claimantAddress1Ctrl.text.trim(),
        'address_line_2': _claimantAddress2Ctrl.text.trim().isEmpty
            ? null
            : _claimantAddress2Ctrl.text.trim(),
        'city': _claimantCityCtrl.text.trim().isEmpty
            ? null
            : _claimantCityCtrl.text.trim(),
        'postcode': _claimantPostcodeCtrl.text.trim().isEmpty
            ? null
            : _claimantPostcodeCtrl.text.trim(),
        'state': _claimantStateCtrl.text.trim().isEmpty
            ? null
            : _claimantStateCtrl.text.trim(),
      };

      await ExecutorService.instance.updateExecutor(executorId, executorUpdate);

      // Update executor_deceased table (only real columns from DB_STRUCTURE.md)
      await SupabaseService.instance.client.from('executor_deceased').update(
        <String, dynamic>{
          'full_name': _deceasedNameCtrl.text.trim(),
          'nric_new': _deceasedNricCtrl.text.trim().isEmpty
              ? null
              : _deceasedNricCtrl.text.trim(),
          'date_of_death': _deceasedDodCtrl.text.trim().isEmpty
              ? null
              : _deceasedDodCtrl.text.trim(),
        },
      ).eq('executor_id', executorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Executor updated successfully'), backgroundColor: Colors.green),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update executor: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Executor')),
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
              title: const Text('Deceased Information'),
              state: StepState.indexed,
              isActive: _currentStep >= 0,
              content: Form(
                key: _deceasedFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _deceasedNameCtrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Deceased Name *',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedNricCtrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Deceased IC/NRIC Number',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedDobCtrl,
                      readOnly: true,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        prefixIcon: Icons.calendar_today_outlined,
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _deceasedDobCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deceasedDodCtrl,
                      readOnly: true,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Date of Death (YYYY-MM-DD) *',
                        prefixIcon: Icons.calendar_today_outlined,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final DateTime? date = DateTime.tryParse(v);
                        if (date == null) return 'Please enter a valid date';
                        return null;
                      },
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _deceasedDodCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRelationship,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Relationship with Deceased *',
                        prefixIcon: Icons.people_outline,
                      ),
                      items: ExecutorConstants.executorRelationships
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r['value'],
                              child: Text(r['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRelationship = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Your Information'),
              state: StepState.indexed,
              isActive: _currentStep >= 1,
              content: Form(
                key: _claimantFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _claimantNameCtrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Your Full Name *',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Please enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantNricCtrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Your IC/NRIC Number *',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantDobCtrl,
                      readOnly: true,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Your Date of Birth (YYYY-MM-DD)',
                        prefixIcon: Icons.calendar_today_outlined,
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _claimantDobCtrl.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Phone Number *',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Email Address *',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (String? v) {
                        final String value = (v ?? '').trim();
                        if (value.isEmpty) return 'Required';
                        final RegExp re = RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", caseSensitive: false);
                        if (!re.hasMatch(value)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantAddress1Ctrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Address Line 1 *',
                        prefixIcon: Icons.home_outlined,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantAddress2Ctrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'Address Line 2',
                        prefixIcon: Icons.home_work_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _claimantCityCtrl,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: 'City *',
                              prefixIcon: Icons.location_city_outlined,
                            ),
                            validator: (String? v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _claimantPostcodeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: 'Postcode *',
                              prefixIcon: Icons.local_post_office_outlined,
                            ),
                            validator: (String? v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _claimantStateCtrl,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: 'State *',
                        prefixIcon: Icons.map_outlined,
                      ),
                      validator: (String? v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Supporting Documents'),
              state: StepState.indexed,
              isActive: _currentStep >= 2,
              content: Form(
                key: _documentsFormKey,
                child: Column(
                  children: <Widget>[
                    if (_loadingExistingDocuments)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (_existingDocuments.isNotEmpty)
                      ..._existingDocuments.map((ExecutorDocument doc) {
                        final String title =
                            (doc.title ?? '').trim().isEmpty ? 'Document' : doc.title!.trim();
                        final String subtitle =
                            '${(doc.fileSize / 1024).toStringAsFixed(1)} KB • ${doc.fileType}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(title),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteExistingDocument(doc),
                            ),
                          ),
                        );
                      }),
                    if (_supportingDocs.isNotEmpty)
                      ..._supportingDocs.map((ExecutorDocumentDraft doc) {
                        final String subtitle = [
                          doc.file.name,
                          '${(doc.file.size / 1024).toStringAsFixed(1)} KB',
                        ].join(' • ');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.attachment_outlined),
                            title: Text(doc.title),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(
                                  () => _supportingDocs.removeWhere((d) => d.id == doc.id),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _addSupportingDocument,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Add document'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: const Text('Review & Update'),
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
        primaryLabel: _currentStep == 3 ? 'Update Executor' : null,
        onPrimaryPressed: () async {
          if (_currentStep == 0) {
            if (!(_deceasedFormKey.currentState?.validate() ?? false)) return;
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            if (!(_claimantFormKey.currentState?.validate() ?? false)) return;
            setState(() => _currentStep = 2);
          } else if (_currentStep == 2) {
            if (!(_documentsFormKey.currentState?.validate() ?? true)) return;
            setState(() => _currentStep = 3);
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

  Widget _buildReview() {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final TextStyle? valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    Widget summaryRow(String label, String? value) {
      final String v = (value ?? '').trim();
      if (v.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 130, child: Text(label, style: labelStyle)),
            const SizedBox(width: 10),
            Expanded(child: Text(v, style: valueStyle)),
          ],
        ),
      );
    }

    Widget sectionCard({
      required IconData icon,
      required String title,
      required VoidCallback onEdit,
      required List<Widget> children,
    }) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      );
    }

    final String relationshipLabel = _selectedRelationship == null
        ? ''
        : (ExecutorConstants.executorRelationships
                .firstWhere(
                  (r) => r['value'] == _selectedRelationship,
                  orElse: () => const <String, String>{},
                )['name'] ??
            _selectedRelationship!);

    final List<String> uploadedTitles = _existingDocuments
        .map((d) => (d.title ?? '').trim().isEmpty ? d.fileName : d.title!.trim())
        .toList(growable: false);
    final List<String> pendingTitles =
        _supportingDocs.map((d) => d.title.trim()).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionCard(
          icon: Icons.person_outline,
          title: 'Your information',
          onEdit: () => setState(() => _currentStep = 1),
          children: <Widget>[
            summaryRow('Name', _claimantNameCtrl.text),
            summaryRow('IC/NRIC', _claimantNricCtrl.text),
            summaryRow('Phone', _claimantPhoneCtrl.text),
            summaryRow('Email', _claimantEmailCtrl.text),
            summaryRow('Address 1', _claimantAddress1Ctrl.text),
            summaryRow('Address 2', _claimantAddress2Ctrl.text),
            summaryRow('City', _claimantCityCtrl.text),
            summaryRow('Postcode', _claimantPostcodeCtrl.text),
            summaryRow('State', _claimantStateCtrl.text),
          ],
        ),
        const SizedBox(height: 12),
        sectionCard(
          icon: Icons.account_circle_outlined,
          title: 'Deceased information',
          onEdit: () => setState(() => _currentStep = 0),
          children: <Widget>[
            summaryRow('Name', _deceasedNameCtrl.text),
            summaryRow('IC/NRIC', _deceasedNricCtrl.text),
            summaryRow('Date of death', _deceasedDodCtrl.text),
            summaryRow('Relationship', relationshipLabel),
          ],
        ),
        const SizedBox(height: 12),
        sectionCard(
          icon: Icons.insert_drive_file_outlined,
          title: 'Supporting documents',
          onEdit: () => setState(() => _currentStep = 2),
          children: <Widget>[
            summaryRow('Uploaded', uploadedTitles.isEmpty ? 'None' : '${uploadedTitles.length} file(s)'),
            if (uploadedTitles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  uploadedTitles.take(5).join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            summaryRow('Pending', pendingTitles.isEmpty ? 'None' : '${pendingTitles.length} file(s)'),
            if (pendingTitles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  pendingTitles.take(5).join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

