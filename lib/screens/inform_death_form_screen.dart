import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/file_upload_service.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/sampul_icons.dart';

class InformDeathFormScreen extends StatefulWidget {
  final int? recordId;
  final Map<String, dynamic>? initialRecord;

  const InformDeathFormScreen({
    super.key,
    this.recordId,
    this.initialRecord,
  });

  @override
  State<InformDeathFormScreen> createState() => _InformDeathFormScreenState();
}

class _InformDeathFormScreenState extends State<InformDeathFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoadingOwners = true;
  bool _isSubmitting = false;

  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _ownerNricCtrl = TextEditingController();
  final TextEditingController _certificateIdCtrl = TextEditingController();

  PlatformFile? _selectedFile;
  String? _uploadedStoragePath;
  String? _existingStoragePath;
  bool _removeExistingFile = false;
  String? _pendingRemoveStoragePath;

  String? _existingFileName() {
    final String? path = _existingStoragePath;
    if (path == null || path.trim().isEmpty) return null;
    final String file = path.split('/').last;
    return file.replaceFirst(RegExp(r'^\d+-'), '');
  }

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // No linked-account lookup anymore; just stop the loading state.
    final Map<String, dynamic>? r = widget.initialRecord;
    if (r != null) {
      _ownerNameCtrl.text = (r['nric_name'] as String?) ?? '';
      _ownerNricCtrl.text = (r['nric_no'] as String?) ?? '';
      _certificateIdCtrl.text = (r['certification_id'] as String?) ?? '';
      _existingStoragePath = (r['image_path'] as String?);
      _uploadedStoragePath = _existingStoragePath;
      _pendingRemoveStoragePath = null;
    }
    if (mounted) {
      setState(() {
        _isLoadingOwners = false;
      });
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final List<PlatformFile> files =
          await FileUploadService.pickMultipleFiles(allowImagesOnly: false, maxFiles: 1);
      if (files.isEmpty) return;
      final PlatformFile file = files.first;
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
        return;
      }
      setState(() {
        _selectedFile = file;
        _uploadedStoragePath = null;
        _removeExistingFile = false;
        _pendingRemoveStoragePath = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selection failed: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final User? user = AuthController.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to continue')),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final l10n = AppLocalizations.of(context)!;

      String? storagePath = _uploadedStoragePath;

      // If user chose to remove the existing uploaded file (without replacement).
      if (_removeExistingFile) {
        final String? oldPath = _pendingRemoveStoragePath;
        if (oldPath != null && oldPath.trim().isNotEmpty) {
          // Delete storage first, then clear DB field.
          await SupabaseService.instance.client.storage.from('images').remove(<String>[oldPath]);
        }
        storagePath = null;
        _uploadedStoragePath = null;
        _existingStoragePath = null;
        _removeExistingFile = false;
        _pendingRemoveStoragePath = null;
      }

      if (_selectedFile != null) {
        if (_selectedFile!.path == null) {
          throw Exception('Selected file path is not available');
        }
        final File file = File(_selectedFile!.path!);
        final FileUploadResult uploadResult = await FileUploadService.uploadAttachment(
          file: file,
          userId: user.id,
          conversationId: 'inform-death/certificate',
          bucket: 'images',
        );
        storagePath = uploadResult.storagePath;
        _uploadedStoragePath = storagePath;

        // If we're editing and replacing a file, remove the old one (best effort).
        final String? oldPath = _pendingRemoveStoragePath ?? _existingStoragePath;
        if (oldPath != null && oldPath.trim().isNotEmpty && oldPath != storagePath) {
          try {
            await SupabaseService.instance.client.storage.from('images').remove(<String>[oldPath]);
          } catch (_) {}
        }
        _existingStoragePath = storagePath;
        _pendingRemoveStoragePath = null;
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'uuid': user.id,
        'invite_user_uuid': null,
        'status': 'submitted',
        'nric_name': _ownerNameCtrl.text.trim().isEmpty ? null : _ownerNameCtrl.text.trim(),
        'nric_no': _ownerNricCtrl.text.trim().isEmpty ? null : _ownerNricCtrl.text.trim(),
        'certification_id':
            _certificateIdCtrl.text.trim().isEmpty ? null : _certificateIdCtrl.text.trim(),
        'image_path': storagePath,
      };

      final bool isEdit = widget.recordId != null;
      if (isEdit) {
        await SupabaseService.instance.client
            .from('inform_death')
            .update(payload)
            .eq('id', widget.recordId as int);
      } else {
        await SupabaseService.instance.client.from('inform_death').insert(payload);
      }

      if (!mounted) return;
      await NotificationService.instance.createNotification(
        title: l10n.informDeathTitle,
        body: isEdit
            ? 'Your inform death submission has been updated.'
            : 'Your inform death submission has been sent to the Sampul team.',
        type: 'inform_death_submitted',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your submission has been sent to the Sampul team.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Please try again. ($e)'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerNricCtrl.dispose();
    _certificateIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final bool isEdit = widget.recordId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.edit : l10n.informDeathTitle),
      ),
      body: SafeArea(
        child: _isLoadingOwners
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.informDeathOwnerSectionTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _ownerNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: FormDecorationHelper.roundedInputDecoration(
                                  context: context,
                                  labelText: l10n.informDeathOwnerNameLabel,
                                  prefixIconPath: SampulIcons.person,
                                ),
                                validator: (String? v) =>
                                    (v == null || v.trim().isEmpty) ? l10n.informDeathRequiredField : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ownerNricCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: FormDecorationHelper.roundedInputDecoration(
                                  context: context,
                                  labelText: l10n.informDeathOwnerNricLabel,
                                  prefixIconPath: SampulIcons.label,
                                ),
                                validator: (String? v) =>
                                    (v == null || v.trim().isEmpty) ? l10n.informDeathRequiredField : null,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.informDeathSupportingDocsSectionTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.informDeathSupportingDocsBody,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(FormDecorationHelper.formBorderRadius),
                                  border: Border.all(
                                    color: FormDecorationHelper.defaultBorderColor,
                                    width: FormDecorationHelper.defaultBorderWidth,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: SampulIcons.buildIcon(
                                        SampulIcons.assignment,
                                        width: 22,
                                        height: 22,
                                        color: const Color.fromRGBO(83, 61, 233, 1),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _selectedFile?.name ??
                                                _existingFileName() ??
                                                l10n.informDeathNoFileChosen,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.informDeathUploadHint,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: <Widget>[
                                                OutlinedButton.icon(
                                                  onPressed: _pickCertificate,
                                                  icon: SampulIcons.buildIconButtonIcon(
                                                    SampulIcons.add,
                                                    size: 18,
                                                    color: const Color.fromRGBO(83, 61, 233, 1),
                                                  ),
                                                  label: Text(l10n.informDeathChooseFile),
                                                  style: OutlinedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(
                                                        FormDecorationHelper.formBorderRadius,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (isEdit &&
                                                    (_selectedFile != null ||
                                                        (_existingStoragePath != null &&
                                                            _existingStoragePath!.trim().isNotEmpty)))
                                                  OutlinedButton.icon(
                                                    onPressed: () async {
                                                      final bool? confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          final l10nDialog =
                                                              AppLocalizations.of(context)!;
                                                          return AlertDialog(
                                                            title: Text(
                                                              l10nDialog.informDeathRemoveFileTitle,
                                                            ),
                                                            content: Text(
                                                              l10nDialog.informDeathRemoveFileBody,
                                                            ),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(context).pop(false),
                                                                child: Text(l10nDialog.cancel),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(context).pop(true),
                                                                child: Text(l10nDialog.delete),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                      if (confirm != true) return;
                                                      if (!mounted) return;
                                                      setState(() {
                                                        // Update UI immediately, but only delete from storage on submit.
                                                        _pendingRemoveStoragePath = _existingStoragePath;
                                                        _selectedFile = null;
                                                        _uploadedStoragePath = null;
                                                        _existingStoragePath = null;
                                                        _removeExistingFile = true;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.delete_outline),
                                                    label: Text(l10n.informDeathRemoveFile),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.red.shade700,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(
                                                          FormDecorationHelper.formBorderRadius,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _certificateIdCtrl,
                                textInputAction: TextInputAction.done,
                                decoration: FormDecorationHelper.roundedInputDecoration(
                                  context: context,
                                  labelText: l10n.informDeathCertificateIdLabel,
                                  prefixIconPath: SampulIcons.assignment,
                                ),
                                validator: (String? v) =>
                                    (v == null || v.trim().isEmpty) ? l10n.informDeathRequiredField : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(
                            l10n.informDeathSubmitCta,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

