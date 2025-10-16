import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../models/will.dart';
import '../models/user_profile.dart';
import '../services/will_service.dart';
import '../controllers/auth_controller.dart';
import 'will_generation_screen.dart';

class WillManagementScreen extends StatefulWidget {
  const WillManagementScreen({super.key});

  @override
  State<WillManagementScreen> createState() => _WillManagementScreenState();
}

class _WillManagementScreenState extends State<WillManagementScreen> with SingleTickerProviderStateMixin {
  Will? _will;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isDeleting = false;
  String _willDocument = '';
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _assets = [];
  final ScrollController _scrollController = ScrollController();
  bool _showActionBar = true;
  double _lastScrollOffset = 0.0;
  late final AnimationController _actionBarController;
  late final Animation<double> _actionBarAnimation;

  @override
  void initState() {
    super.initState();
    _loadWillData();
    _scrollController.addListener(_onScroll);
    _actionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 420),
      value: 1.0,
    );
    _actionBarAnimation = CurvedAnimation(
      parent: _actionBarController,
      curve: Curves.easeInOutCubic,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final delta = current - _lastScrollOffset;
    _lastScrollOffset = current;

    // Standard behavior: hide on scroll down, show on scroll up, with small guard
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && current > kToolbarHeight && delta.abs() > 2 && _showActionBar) {
      _showActionBar = false;
      _actionBarController.reverse();
      setState(() {});
    } else if (direction == ScrollDirection.forward && delta.abs() > 2 && !_showActionBar) {
      _showActionBar = true;
      _actionBarController.forward();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _actionBarController.dispose();
    super.dispose();
  }

  

  Future<void> _loadWillData() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) return;

      final will = await WillService.instance.getUserWill(user.id);
      final profile = await AuthController.instance.getUserProfile();

      if (will != null && profile != null) {
        // Load family members and assets for will document generation
        final familyMembers = await WillService.instance.getFamilyMembers(user.id);
        final assets = await WillService.instance.getUserAssets(user.id);
        
        // Generate will document
        final willDocument = WillService.instance.generateWillDocument(
          will,
          profile,
          familyMembers,
          assets,
        );

        if (mounted) {
          setState(() {
            _will = will;
            _userProfile = profile;
            _familyMembers = familyMembers;
            _assets = assets;
            _willDocument = willDocument;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _will = will;
            _userProfile = profile;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load will data: $e');
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

  Future<void> _createNewWill() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => const WillGenerationScreen(),
      ),
    );

    if (result == true) {
      await _loadWillData();
    }
  }

  Future<void> _editWill() async {
    if (_will == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => WillGenerationScreen(existingWill: _will),
      ),
    );

    if (result == true) {
      await _loadWillData();
    }
  }

  Future<void> _copyWillDocument() async {
    if (_willDocument.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _willDocument));
    _showSuccessSnackBar('Will document copied to clipboard');
  }

  Future<void> _deleteWill() async {
    if (_will == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Will'),
        content: const Text('Are you sure you want to delete your will? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await WillService.instance.deleteWill(_will!.id!);
        _showSuccessSnackBar('Will deleted successfully');
        await _loadWillData();
      } catch (e) {
        _showErrorSnackBar('Failed to delete will: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }


  Future<void> _shareWillDocument() async {
    if (_willDocument.isEmpty) return;

    // This would typically use a sharing plugin
    // For now, we'll just copy to clipboard
    await _copyWillDocument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Will'),
        actions: [
          if (_will != null)
            IconButton(
              onPressed: _shareWillDocument,
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Will',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _will == null
              ? _buildNoWillState()
              : _buildWillState(),
    );
  }

  Widget _buildNoWillState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No Will Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your will to ensure your assets are distributed according to your wishes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createNewWill,
              icon: const Icon(Icons.add),
              label: const Text('Create My Will'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWillState() {
    final validation = WillService.instance.validateWill(_will!);

    return Column(
      children: [
        // Clean Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _will!.isDraft == true ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _will!.isDraft == true ? Icons.edit : Icons.check_circle,
                      color: _will!.isDraft == true ? Colors.orange.shade700 : Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _will!.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _will!.isDraft == true ? Colors.orange.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Code: ${_will!.willCode}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Compact Validation Alert
        if (!validation['isValid'] || (validation['warnings'] as List).isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: validation['isValid'] ? Colors.orange.shade50 : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  validation['isValid'] ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                  color: validation['isValid'] ? Colors.orange.shade600 : Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  validation['isValid'] 
                      ? '${(validation['warnings'] as List).length} warning(s) - Review recommended'
                      : '${(validation['issues'] as List).length} issue(s) - Action required',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: validation['isValid'] ? Colors.orange.shade700 : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // Data Sync Notice removed (redundant with review page)

        // Compact Action Bar (auto-hide on scroll)
        SizeTransition(
          sizeFactor: _actionBarAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              ),
            ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _editWill,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _isDeleting ? null : _deleteWill,
                icon: _isDeleting 
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyWillDocument,
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          ),
        ),

        // Will Document Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            controller: _scrollController,
            child: _buildPaperWill(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaperWill() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE), // Slightly off-white for paper effect
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Paper texture lines
          Positioned.fill(
            child: CustomPaint(
              painter: PaperTexturePainter(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Document Header
            _buildPaperHeader(),
            
            const SizedBox(height: 24),
            
            // Personal Information
            _buildPaperSection(
              'PERSONAL INFORMATION',
              [
                'I, ${_will!.nricName ?? _userProfile?.displayName ?? 'Not provided'},',
                'NRIC: ${_userProfile?.nricNo ?? 'Not provided'}',
                'Date of Birth: ${_userProfile?.dob != null ? _formatDate(_userProfile!.dob!) : 'Not provided'}',
                'Address: ${_formatAddress(_userProfile!)}',
                'Phone: ${_userProfile?.phoneNo ?? 'Not provided'}',
                'Email: ${_userProfile?.email ?? 'Not provided'}',
                '',
                'Being of sound mind and memory, do hereby make, publish and declare this to be my Last Will and Testament, hereby revoking all former wills and codicils made by me.',
                '',
                'I declare that I am not under any undue influence, fraud, or coercion in making this will, and that I understand the nature and effect of this document.',
              ],
            ),

            const SizedBox(height: 20),

            // Executors
            if (_will!.coSampul1 != null || _will!.coSampul2 != null)
              _buildPaperSection(
                'EXECUTORS',
                [
                  'I hereby appoint the following person(s) as my executor(s) to carry out the provisions of this will:',
                  '',
                  ..._getExecutorsInfo().map((executor) => '• $executor'),
                  '',
                  'I grant my executor(s) full power and authority to:',
                  '• Collect and manage my assets',
                  '• Pay all debts, taxes, and expenses',
                  '• Distribute my estate according to this will',
                  '• Make necessary decisions in the administration of my estate',
                ],
              ),

            if (_will!.coSampul1 != null || _will!.coSampul2 != null)
              const SizedBox(height: 20),

            // Guardians
            if (_will!.guardian1 != null || _will!.guardian2 != null)
              _buildPaperSection(
                'GUARDIANS',
                [
                  'I hereby appoint the following person(s) as guardian(s) for my minor children:',
                  '',
                  ..._getGuardiansInfo().map((guardian) => '• $guardian'),
                  '',
                  'I grant my guardian(s) full authority to:',
                  '• Provide care, custody, and control of my minor children',
                  '• Make decisions regarding their education, health, and welfare',
                  '• Manage any assets left to my minor children until they reach majority',
                ],
              ),

            if (_will!.guardian1 != null || _will!.guardian2 != null)
              const SizedBox(height: 20),

            // Assets
            if (_assets.isNotEmpty)
              _buildPaperSection(
                'ASSETS AND PROPERTY',
                [
                  'I hereby bequeath my assets and property as follows:',
                  '',
                  ..._getAssetsInfo(),
                  '',
                  'All assets not specifically mentioned herein shall be distributed according to the beneficiary percentages specified in the Beneficiaries section below.',
                ],
              ),

            if (_assets.isNotEmpty)
              const SizedBox(height: 20),

            // Beneficiaries
            if (_familyMembers.any((member) => 
              member['type'] == 'future_owner' || 
              ((member['percentage'] as num?)?.toDouble() ?? 0) > 0))
              _buildPaperSection(
                'BENEFICIARIES',
                [
                  'I hereby bequeath my estate to the following beneficiaries in the proportions specified:',
                  '',
                  ..._getBeneficiariesInfo().map((beneficiary) => '• $beneficiary'),
                  '',
                  'If any beneficiary predeceases me, their share shall be distributed equally among the surviving beneficiaries.',
                ],
              ),

            const SizedBox(height: 20),

            // Debts and Liabilities
            _buildPaperSection(
              'DEBTS AND LIABILITIES',
              [
                'I direct that all my just debts, funeral expenses, and administration costs be paid out of my estate before any distribution to beneficiaries.',
                '',
                'This includes but is not limited to:',
                '• Outstanding loans and mortgages',
                '• Credit card debts',
                '• Medical expenses',
                '• Funeral and burial expenses',
                '• Legal and administrative fees',
              ],
            ),

            const SizedBox(height: 20),

            // Special Instructions
            _buildPaperSection(
              'SPECIAL INSTRUCTIONS',
              [
                'I hereby provide the following special instructions:',
                '',
                '• Funeral Arrangements: I request a simple and dignified funeral service in accordance with my religious beliefs.',
                '• Organ Donation: I consent to organ donation if medically possible and beneficial.',
                '• Digital Assets: All my digital accounts and online presence should be managed according to the instructions provided to my executor.',
                '• Personal Effects: Personal items of sentimental value should be distributed among family members as deemed appropriate by my executor.',
                '',
                'My executor shall have the discretion to make reasonable decisions regarding any matters not specifically addressed in this will.',
              ],
            ),

            const SizedBox(height: 20),

            // Residuary Clause
            _buildPaperSection(
              'RESIDUARY CLAUSE',
              [
                'I give, devise, and bequeath all the rest, residue, and remainder of my estate, both real and personal, of whatsoever nature and wheresoever situate, to my beneficiaries in the proportions specified above.',
                '',
                'This includes any property acquired after the execution of this will that is not specifically mentioned herein.',
              ],
            ),

            const SizedBox(height: 24),

            // Closing
            _buildPaperSection(
              'IN WITNESS WHEREOF',
              [
                'IN WITNESS WHEREOF, I have hereunto set my hand this ${DateTime.now().day} day of ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}, in the presence of the witnesses whose signatures appear below.',
                '',
                'I declare that this is my Last Will and Testament, that I have read and understand its contents, and that I am executing it voluntarily and of my own free will.',
                '',
                'Testator: ${_will!.nricName ?? _userProfile?.displayName ?? 'Not provided'}',
                '',
                'Will Code: ${_will!.willCode}',
                'Generated on: ${DateTime.now().toIso8601String()}',
              ],
            ),

            const SizedBox(height: 24),

            // Signature Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Testator Signature
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Testator Signature',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Witness Signatures
                  Text(
                    'WITNESSES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Witness 1 Signature',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Witness 1 Name',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Witness 2 Signature',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Witness 2 Name',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'LEGAL NOTICE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This document is generated for informational purposes. For legal validity, please consult with a qualified legal professional and ensure proper witnessing and notarization according to local laws.',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 11,
                      height: 1.4,
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
    );
  }

  Widget _buildPaperHeader() {
    return Column(
      children: [
        // Decorative line
        Container(
          width: 60,
          height: 2,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 20),
        
        // Title
        Text(
          'WILL AND TESTAMENT',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 20),
        
        // Decorative line
        Container(
          width: 60,
          height: 2,
          color: Colors.grey.shade400,
        ),
        
        const SizedBox(height: 20),
        
        // Will Code
        Text(
          'Will Code: ${_will!.willCode}',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        
        Text(
          'Generated: ${_formatDate(DateTime.now())}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaperSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Section Content
        ...content.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        )),
      ],
    );
  }


  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  List<String> _getExecutorsInfo() {
    final executors = _familyMembers.where((member) => 
      member['id'] == _will!.coSampul1 || member['id'] == _will!.coSampul2
    ).toList();

    return executors.map((executor) => 
      '${executor['name']} (${executor['relationship'] ?? 'Family member'})'
    ).toList();
  }

  List<String> _getGuardiansInfo() {
    final guardians = _familyMembers.where((member) => 
      member['id'] == _will!.guardian1 || member['id'] == _will!.guardian2
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

class PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw subtle horizontal lines to simulate paper texture
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

