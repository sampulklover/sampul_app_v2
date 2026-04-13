import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../utils/url_launch_helper.dart';
import 'inform_death_form_screen.dart';

class InformDeathDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const InformDeathDetailScreen({super.key, required this.record});

  String _prettyFileNameFromPath(String storagePath) {
    final String file = storagePath.split('/').last;
    // Path convention: userId/conversationId/timestamp-originalName
    // If it matches, strip the timestamp prefix so we only show the original name.
    final RegExp tsPrefix = RegExp(r'^\d+-');
    return file.replaceFirst(tsPrefix, '');
  }

  bool _looksLikeImage(String pathOrUrl) {
    final String p = pathOrUrl.toLowerCase();
    return p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.webp');
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'draft':
        return l10n.informDeathStatusDraft;
      case 'submitted':
        return l10n.informDeathStatusSubmitted;
      case 'under_review':
        return l10n.informDeathStatusUnderReview;
      case 'approved':
        return l10n.informDeathStatusApproved;
      case 'rejected':
        return l10n.informDeathStatusRejected;
      default:
        return l10n.informDeathStatusUnknown;
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await launchUriPreferInAppBrowser(uri)) {
      return;
    } else {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.informDeathUnableToOpenFile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String name = (record['nric_name'] as String?) ?? l10n.unknown;
    final String nric = (record['nric_no'] as String?) ?? '-';
    final String certId = (record['certification_id'] as String?) ?? '-';
    final String status = ((record['status'] as String?) ?? 'submitted').toLowerCase();

    final DateTime? createdAt = record['created_at'] != null
        ? DateTime.tryParse(record['created_at'] as String)
        : null;
    final String createdLabel = createdAt != null
        ? DateFormat.yMMMd().add_jm().format(createdAt.toLocal())
        : '-';

    final String? imagePath = record['image_path'] as String?;
    final String? publicUrl = (imagePath == null || imagePath.trim().isEmpty)
        ? null
        : SupabaseService.instance.client.storage.from('images').getPublicUrl(imagePath);
    final String? fileName = (imagePath == null || imagePath.trim().isEmpty)
        ? null
        : _prettyFileNameFromPath(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.informDeathTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final int? id = (record['id'] as num?)?.toInt();
              if (id == null) return;
              final bool? updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => InformDeathFormScreen(
                    recordId: id,
                    initialRecord: record,
                  ),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop('updated');
              }
            },
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final int? id = (record['id'] as num?)?.toInt();
              if (id == null) return;

              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  final l10nDialog = AppLocalizations.of(context)!;
                  return AlertDialog(
                    title: Text(l10nDialog.informDeathDeleteDialogTitle),
                    content: const Text(
                      'Are you sure you want to delete this record? This action cannot be undone.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10nDialog.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10nDialog.delete),
                      ),
                    ],
                  );
                },
              );
              if (confirm != true) return;

              try {
                // Delete file first (common practice), then DB record.
                if (imagePath != null && imagePath.trim().isNotEmpty) {
                  await SupabaseService.instance.client.storage.from('images').remove(<String>[
                    imagePath,
                  ]);
                }
                await SupabaseService.instance.client.from('inform_death').delete().eq('id', id);

                if (!context.mounted) return;
                Navigator.of(context).pop('deleted');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete record: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(l10n, status),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: l10n.informDeathOwnerNricLabel, value: nric),
                    const SizedBox(height: 8),
                    _DetailRow(label: l10n.informDeathCertificateIdLabel, value: certId),
                    const SizedBox(height: 8),
                    _DetailRow(label: l10n.submitted, value: createdLabel),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.informDeathSupportingDocsSectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (publicUrl == null) ...<Widget>[
              Text(
                l10n.informDeathNoFileChosen,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_looksLikeImage(publicUrl)) ...<Widget>[
              if (fileName != null) ...<Widget>[
                Text(
                  fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.network(
                        publicUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) {
                          return Container(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _openUrl(context, publicUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l10n.informDeathOpenFile),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...<Widget>[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(fileName ?? l10n.informDeathUploadHint),
                  trailing: IconButton(
                    tooltip: l10n.informDeathOpenFile,
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openUrl(context, publicUrl),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

