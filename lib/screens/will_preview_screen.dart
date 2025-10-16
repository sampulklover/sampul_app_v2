import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/will.dart';
import '../models/user_profile.dart';
import '../services/will_service.dart';

class WillPreviewScreen extends StatefulWidget {
  final Will will;
  final UserProfile userProfile;

  const WillPreviewScreen({
    super.key,
    required this.will,
    required this.userProfile,
  });

  @override
  State<WillPreviewScreen> createState() => _WillPreviewScreenState();
}

class _WillPreviewScreenState extends State<WillPreviewScreen> {
  String _willDocument = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _assets = [];

  @override
  void initState() {
    super.initState();
    _generateWillDocument();
  }

  Future<void> _generateWillDocument() async {
    try {
      // Load family members and assets
      final familyMembers = await WillService.instance.getFamilyMembers(widget.will.uuid);
      final assets = await WillService.instance.getUserAssets(widget.will.uuid);

      // Generate the will document
      final document = WillService.instance.generateWillDocument(
        widget.will,
        widget.userProfile,
        familyMembers,
        assets,
      );

      if (mounted) {
        setState(() {
          _familyMembers = familyMembers;
          _assets = assets;
          _willDocument = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to generate will document: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _copyWillDocument() async {
    await Clipboard.setData(ClipboardData(text: _willDocument));
    _showSuccessSnackBar('Will document copied to clipboard');
  }

  Future<void> _shareWillDocument() async {
    // This would typically use a sharing plugin
    // For now, we'll just copy to clipboard
    await _copyWillDocument();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Will Preview'),
        actions: [
          IconButton(
            onPressed: _copyWillDocument,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Document',
          ),
          IconButton(
            onPressed: _shareWillDocument,
            icon: const Icon(Icons.share),
            tooltip: 'Share Document',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Will Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Will Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            widget.will.isDraft == true ? Icons.edit : Icons.check_circle,
                            color: widget.will.isDraft == true ? Colors.orange : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.will.statusText,
                            style: TextStyle(
                              color: widget.will.isDraft == true ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Will Code: ${widget.will.willCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Will Document
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WILL AND TESTAMENT',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Will Code: ${widget.will.willCode}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Generated: ${_formatDate(DateTime.now())}',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Personal Information
                        _buildSection(
                          'Personal Information',
                          [
                            'Name: ${widget.will.nricName ?? widget.userProfile.displayName}',
                            'NRIC: ${widget.userProfile.nricNo ?? 'Not provided'}',
                            'Address: ${_formatAddress(widget.userProfile)}',
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Executors
                        if (widget.will.coSampul1 != null || widget.will.coSampul2 != null)
                          _buildSection(
                            'Executors',
                            _getExecutorsInfo(),
                          ),

                        if (widget.will.coSampul1 != null || widget.will.coSampul2 != null)
                          const SizedBox(height: 16),

                        // Guardians
                        if (widget.will.guardian1 != null || widget.will.guardian2 != null)
                          _buildSection(
                            'Guardians',
                            _getGuardiansInfo(),
                          ),

                        if (widget.will.guardian1 != null || widget.will.guardian2 != null)
                          const SizedBox(height: 16),

                        // Assets
                        if (_assets.isNotEmpty)
                          _buildSection(
                            'Assets',
                            _getAssetsInfo(),
                          ),

                        if (_assets.isNotEmpty)
                          const SizedBox(height: 16),

                        // Beneficiaries
                        if (_familyMembers.any((member) => 
                          member['type'] == 'future_owner' || 
                          ((member['percentage'] as num?)?.toDouble() ?? 0) > 0))
                          _buildSection(
                            'Beneficiaries',
                            _getBeneficiariesInfo(),
                          ),

                        const SizedBox(height: 24),

                        // Legal Notice
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.amber.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Legal Notice',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This document is generated for informational purposes. '
                                'For legal validity, please consult with a qualified legal professional '
                                'and ensure proper witnessing and notarization according to local laws.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyWillDocument,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Document'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareWillDocument,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            )).toList(),
          ),
        ),
      ],
    );
  }

  List<String> _getExecutorsInfo() {
    final executors = _familyMembers.where((member) => 
      member['id'] == widget.will.coSampul1 || member['id'] == widget.will.coSampul2
    ).toList();

    return executors.map((executor) => 
      '${executor['name']} (${executor['relationship'] ?? 'Family member'})'
    ).toList();
  }

  List<String> _getGuardiansInfo() {
    final guardians = _familyMembers.where((member) => 
      member['id'] == widget.will.guardian1 || member['id'] == widget.will.guardian2
    ).toList();

    return guardians.map((guardian) => 
      '${guardian['name']} (${guardian['relationship'] ?? 'Family member'})'
    ).toList();
  }

  List<String> _getAssetsInfo() {
    final totalValue = _assets.fold<double>(0, (sum, asset) => sum + (asset['value'] as num).toDouble());
    
    final assetInfo = _assets.map((asset) {
      final value = (asset['value'] as num).toDouble();
      final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
      return '${asset['name']} (${asset['type']}) - RM ${value.toStringAsFixed(2)} ($percentage%)';
    }).toList();

    assetInfo.insert(0, 'Total Assets Value: RM ${totalValue.toStringAsFixed(2)}');
    return assetInfo;
  }

  List<String> _getBeneficiariesInfo() {
    final beneficiaries = _familyMembers.where((member) => 
      member['type'] == 'future_owner' || ((member['percentage'] as num?)?.toDouble() ?? 0) > 0
    ).toList();

    return beneficiaries.map((beneficiary) {
      final percentage = (beneficiary['percentage'] as num?)?.toDouble() ?? 0.0;
      return '${beneficiary['name']} (${beneficiary['relationship'] ?? 'Family member'}) - ${percentage.toStringAsFixed(1)}%';
    }).toList();
  }

  String _formatAddress(UserProfile profile) {
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
