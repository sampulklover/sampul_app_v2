import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';
import '../services/supabase_service.dart';

class HibahDetailScreen extends StatefulWidget {
  final Hibah hibah;

  const HibahDetailScreen({super.key, required this.hibah});

  @override
  State<HibahDetailScreen> createState() => _HibahDetailScreenState();
}

class _HibahDetailScreenState extends State<HibahDetailScreen> {
  bool _isLoading = true;
  List<HibahGroup> _groups = [];
  List<HibahDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final groups =
          await HibahService.instance.getHibahGroups(widget.hibah.id);
      final documents =
          await HibahService.instance.getHibahDocuments(widget.hibah.id);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateFormat dateFormatter = DateFormat.yMMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hibah Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certificate Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_membership,
                                  color: scheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.hibah.certificateId,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            label: 'Status',
                            value: _statusLabel(widget.hibah.status),
                            valueColor: _statusColor(context, widget.hibah.status),
                          ),
                          _InfoRow(
                            label: 'Total Assets',
                            value: widget.hibah.totalSubmissions.toString(),
                          ),
                          _InfoRow(
                            label: 'Created',
                            value: dateFormatter.format(widget.hibah.createdAt),
                          ),
                          _InfoRow(
                            label: 'Last Updated',
                            value: dateFormatter.format(widget.hibah.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assets Section
                  Text(
                    'Assets (${_groups.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_groups.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No assets found')),
                      ),
                    )
                  else
                    ..._groups.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final HibahGroup group = entry.value;
                      return _buildAssetCard(group, index + 1);
                    }),
                  const SizedBox(height: 24),

                  // Documents Section
                  Text(
                    'Documents (${_documents.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_documents.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No documents found')),
                      ),
                    )
                  else
                    ..._documents.map((doc) => _buildDocumentCard(doc)),
                ],
              ),
            ),
    );
  }

  Widget _buildAssetCard(HibahGroup group, int assetNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Asset #$assetNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.propertyName ?? 'Unnamed Property',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Asset Type', value: group.assetType ?? '-'),
            if (group.registeredTitleNumber != null &&
                group.registeredTitleNumber!.isNotEmpty)
              _InfoRow(
                  label: 'Title Number', value: group.registeredTitleNumber!),
            if (group.propertyLocation != null &&
                group.propertyLocation!.isNotEmpty)
              _InfoRow(label: 'Location', value: group.propertyLocation!),
            if (group.estimatedValue != null && group.estimatedValue!.isNotEmpty)
              _InfoRow(label: 'Estimated Value', value: 'RM ${group.estimatedValue}'),
            _InfoRow(
                label: 'Loan Status',
                value: _loanStatusLabel(group.loanStatus)),
            if (group.bankName != null && group.bankName!.isNotEmpty)
              _InfoRow(label: 'Bank', value: group.bankName!),
            if (group.outstandingLoanAmount != null &&
                group.outstandingLoanAmount!.isNotEmpty)
              _InfoRow(
                  label: 'Outstanding Loan',
                  value: 'RM ${group.outstandingLoanAmount}'),
            if (group.landCategories.isNotEmpty)
              _InfoRow(
                label: 'Land Categories',
                value: group.landCategories.join(', '),
              ),
            
            // Beneficiaries
            if (group.beneficiaries.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Beneficiaries (${group.beneficiaries.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...group.beneficiaries.map((ben) {
                final double? share = ben.sharePercentage;
                final String shareText =
                    share != null ? '${_formatShare(share)}%' : 'Not provided';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${ben.name} (${ben.relationship ?? "Unknown"})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          shareText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(HibahDocument doc) {
    final DateFormat dateFormatter = DateFormat.yMMMd().add_jm();
    final String docTypeLabel = _getDocumentTypeLabel(doc.documentType);
    
    // Find linked asset if applicable
    String? linkedAssetName;
    if (doc.hibahGroupId != null) {
      try {
        final linkedGroup = _groups.firstWhere(
          (g) => g.id == doc.hibahGroupId,
        );
        linkedAssetName = linkedGroup.propertyName;
      } catch (e) {
        // Group not found
        linkedAssetName = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.insert_drive_file, color: const Color.fromRGBO(49, 24, 211, 1)),
        title: Text(
          docTypeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.fileName),
            Text(
              '${_formatFileSize(doc.fileSize)} • ${dateFormatter.format(doc.uploadedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (linkedAssetName != null)
              Text(
                'Linked to: $linkedAssetName',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadDocument(doc),
        ),
      ),
    );
  }

  Future<void> _downloadDocument(HibahDocument doc) async {
    try {
      final String publicUrl = SupabaseService.instance.client.storage
          .from('images')
          .getPublicUrl(doc.filePath);
      
      final Uri url = Uri.parse(publicUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open document')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _loanStatusLabel(String? status) {
    switch (status) {
      case 'fully_paid':
        return 'Fully Paid';
      case 'ongoing_financing':
        return 'Ongoing Financing';
      case 'no_financing':
        return 'No Financing';
      default:
        return '-';
    }
  }

  String _formatShare(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _getDocumentTypeLabel(String key) {
    const Map<String, String> labels = {
      'title_deed': 'Title Deed / Strata Title',
      'assessment_tax': 'Assessment Tax / Land Tax',
      'sale_agreement': 'Sale Agreement / Loan Agreement',
      'insurance_policy': 'MRTT / MLTT / Takaful / Insurance policy documents',
      'beneficiary_nric': 'Beneficiaries\' NRIC (front & back)',
      'guardian_nric': 'Guardian\'s NRIC (if beneficiary is under 18 / OKU)',
      'other_supporting': 'Any other supporting documents',
    };
    return labels[key] ?? key;
  }

  String _statusLabel(HibahStatus status) {
    switch (status) {
      case HibahStatus.draft:
        return 'Draft';
      case HibahStatus.pendingReview:
        return 'Pending Review';
      case HibahStatus.underReview:
        return 'Under Review';
      case HibahStatus.approved:
        return 'Approved';
      case HibahStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(BuildContext context, HibahStatus status) {
    switch (status) {
      case HibahStatus.draft:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case HibahStatus.pendingReview:
        return Colors.orange.shade700;
      case HibahStatus.underReview:
        return Colors.blue.shade600;
      case HibahStatus.approved:
        return Colors.green.shade700;
      case HibahStatus.rejected:
        return Colors.red.shade700;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

