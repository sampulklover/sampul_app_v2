import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_svg/flutter_svg.dart';
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

  Future<void> _publishWill() async {
    if (_will == null || _will!.id == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Will'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to publish this will?\n\n'
              'Once published, this will will be accessible to anyone with the share link:\n'
              'https://sampul.co/view-will?id=${_will!.willCode}\n\n'
              'Make sure you only share this link with trusted family members or executors.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'https://sampul.co/view-will?id=${_will!.willCode}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final String url = 'https://sampul.co/view-will?id=${_will!.willCode}';
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share link copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final updatedWill = await WillService.instance.updateWill(
        willId: _will!.id!,
        isDraft: false,
      );
      
      // Check if the will was actually published
      if (updatedWill.isDraft == true) {
        _showErrorSnackBar('Failed to publish will: Still marked as draft');
        return;
      }
      
      await _loadWillData();
      _showSuccessSnackBar('Will published successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to publish will: $e');
    }
  }

  Future<void> _unpublishWill() async {
    if (_will == null || _will!.id == null) return;
    try {
      final updatedWill = await WillService.instance.updateWill(
        willId: _will!.id!,
        isDraft: true,
      );
      
      // Check if the will was actually unpublished
      if (updatedWill.isDraft == false) {
        _showErrorSnackBar('Failed to unpublish will: Still marked as published');
        return;
      }
      
      await _loadWillData();
      _showSuccessSnackBar('Will unpublished successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to unpublish will: $e');
    }
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
    if (_will == null) return;
    final String url = 'https://sampul.co/view-will?id=${_will!.willCode}';
    await Clipboard.setData(ClipboardData(text: url));
    _showSuccessSnackBar('Share link copied to clipboard');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Will'),
        actions: [
          if (_will != null && _will!.isDraft == false)
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
              'Create Your Will',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Get started by creating your will to ensure your assets are distributed according to your wishes.',
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
                onPressed: _will!.isDraft == true ? _publishWill : _unpublishWill,
                icon: Icon(
                  _will!.isDraft == true ? Icons.publish_outlined : Icons.unpublished_outlined,
                  size: 16,
                ),
                label: Text(_will!.isDraft == true ? 'Publish' : 'Unpublish'),
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
                // Document Header - First Page
                _buildPaperHeader(),
                
                // Page Break
                Container(
                  width: double.infinity,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: CustomPaint(
                    painter: DottedLinePainter(),
                  ),
                ),
                
                // Page 2 Header
                Center(
                  child: Text(
                    'WASIAT ASET SAYA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 1. Mukaddimah
                _buildPaperSection(
                  '1. Mukaddimah',
                  [
                    'Dengan nama Allah, Yang Maha Pengasih, Lagi Maha Penyayang, saya, ${_will!.nricName ?? _userProfile?.displayName ?? 'Not provided'}, memegang NRIC ${_userProfile?.nricNo ?? 'Not provided'}, bermastautin di ${_formatAddress(_userProfile!)}, mengisytiharkan dokumen ini sebagai wasiat terakhir saya, memberi tumpuan kepada pengurusan aset saya.',
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Pengisytiharan
                _buildPaperSection(
                  '2. Pengisytiharan',
                  [
                    'Mengakui kepercayaan Islam saya, saya berazam untuk mengisytiharkan wasiat terakhir saya untuk aset saya, yang ditulis pada ${_formatDateMalay(DateTime.now())}.',
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Permintaan
                _buildPaperSection(
                  '3. Permintaan',
                  [
                    'Saya menyeru keluarga saya untuk menegakkan ketaqwaan kepada Allah S.W.T dan menunaikan perintah-Nya. Apabila saya meninggal dunia, harta saya hendaklah diuruskan dengan teliti mengikut prinsip Islam. Saya memohon harta pusaka saya sebagai keutamaan digunakan untuk mengendalikan perbelanjaan pengebumian dan menyelesaikan hutang kepada Allah S.W.T dan manusia, termasuk Zakat dan kewajipan agama lain.',
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Pembatalan
                _buildPaperSection(
                  '4. Pembatalan',
                  [
                    'Dokumen ini menggantikan semua wasiat terdahulu pada aset.',
                  ],
                ),

                const SizedBox(height: 20),

                // 5. Co-Sampul Utama
                _buildPaperSection(
                  '5. Co-Sampul Utama',
                  [
                    '${_getCoSampulUtama()}, ${_getCoSampulUtamaNric()} dilantik untuk menyimpan dan menyampaikan wasiat aset saya ini kepada waris saya.',
                  ],
                ),

                const SizedBox(height: 20),

                // 6. Co-Sampul Ganti
                _buildPaperSection(
                  '6. Co-Sampul Ganti',
                  [
                    'Jika perlu, ${_getCoSampulGanti()}, ${_getCoSampulGantiNric()} akan bertindak sebagai Co-Sampul Ganti.',
                  ],
                ),

                const SizedBox(height: 20),

                // 7. Penyelesaian Hutang dan Tanggungjawab Berkaitan Hutang
                _buildPaperSection(
                  '7. Penyelesaian Hutang dan Tanggungjawab Berkaitan Hutang',
                  [
                    'Saya berharap waris tersayang saya akan melunaskan hutang-hutang saya yang tidak mempunyai perlindungan Takaful seperti yang disenaraikan dalam Jadual 1 dan juga melunaskan tanggungjawab berkaitan hutang yang lain seperti Nazar/Kaffarah/Fidyah saya yang berbaki yang tidak sempat saya sempurnakan ketika hidup dan diambil daripada harta pusaka saya seperti berikut:',
                    '',
                    'Nazar/Kaffarah: -',
                    'Anggaran Kos: RM 0',
                    'Fidyah: 0 hari Anggaran',
                    'Kos: RM 0',
                    'Derma Organ: Saya dengan ini tidak bersetuju sebagai penderma organ.',
                  ],
                ),

                const SizedBox(height: 20),

                // 8. Penjelasan Kos Pentadbiran Harta Pusaka dan Agihan Pendahuluan
                _buildPaperSection(
                  '8. Penjelasan Kos Pentadbiran Harta Pusaka dan Agihan Pendahuluan',
                  [
                    'Saya membenarkan waris saya setelah melantik pentadbir atau pemegang amanah atau Wasi untuk menjelaskan segala perbelanjaan bagi pentadbiran harta pusaka daripada harta pusaka saya. Saya juga membenarkan sekiranya perlu dikeluarkan satu jumlah yang muhasabah sebagai nafkah perbelanjaan bulanan bagi waris di bawah tanggungan saya dan jumlah itu ditolak daripada bahagian harta pusaka yang akan diterima oleh waris saya semasa agihan akhir sekiranya proses tuntutan pusaka mengambil masa yang lama daripada sepatutnya.',
                  ],
                ),

                const SizedBox(height: 20),

                // 9. Pengagihan Aset
                _buildPaperSection(
                  '9. Pengagihan Aset',
                  [
                    'Sehingga ⅓: Aset tertentu kepada bukan waris atau disedekahkan atau diwaqafkan kepada pihak tertentu seperti di [Jadual 2].',
                    '',
                    'Penerima Hadiah (Hibah): Aset tertentu ditetapkan untuk penerima tertentu secara terus tertakluk kepada persetujuan waris Faraid yang berhak seperti di [Jadual 1]',
                    '',
                    'Faraid: Aset tertentu ditetapkan untuk penerima tertentu berdasarkan pembahagian Faraid seperti di [Jadual 1].',
                    '',
                    'Baki Harta: Selebihnya aset saya yang tidak dinyatakan secara khusus akan diagihkan sewajarnya sama ada kepada penerima tertentu tertakluk kepada persetujuan waris Faraid atau berdasarkan pembahagian Faraid.',
                  ],
                ),

                const SizedBox(height: 20),

                // 10. Penjagaan Anak
                _buildPaperSection(
                  '10. Penjagaan Anak',
                  [
                    'N/A',
                  ],
                ),

                const SizedBox(height: 20),

                // 11. Tanda Tangan
                _buildPaperSection(
                  '11. Tanda Tangan',
                  [
                    'Disediakan oleh',
                    '',
                    '',
                    '____________________',
                    '${_will!.nricName ?? _userProfile?.displayName ?? 'Not provided'}',
                    '${_userProfile?.nricNo ?? 'Not provided'}',
                    'pada ${_formatDateMalay(DateTime.now())}',
                  ],
                ),

                const SizedBox(height: 20),

                // 12. Notis
                _buildPaperSection(
                  '12. Notis',
                  [
                    'Walaupun platform kami menyediakan perkhidmatan digital untuk membuat wasiat, kami amat menggalakkan anda mencetak wasiat yang telah dilengkapkan dan menandatanganinya secara fizikal untuk simpanan peribadi anda. Sekiranya timbul sebarang pertikaian pada masa hadapan, salinan wasiat yang ditandatangani secara fizikal akan memberikan kepastian undang-undang. Salinan bercetak dan bertandatangan ini boleh bertindak sebagai sandaran kepada rekod digital anda.',
                  ],
                ),

                const SizedBox(height: 20),

                // 13. Saksi
                _buildPaperSection(
                  '13. Saksi',
                  [
                    'Diperakui oleh',
                    'Muhammad Arham Munir Merican bin Amir Feisal Merican',
                    '931011875001',
                    'Pengasas, SAMPUL',
                    'pada ${_formatDateMalay(DateTime.now())}',
                    '',
                    'Diperakui oleh',
                    'Mohammad Aiman bin Sulaiman',
                    '871013875003',
                    'Pengasas Bersama, SAMPUL',
                    'pada ${_formatDateMalay(DateTime.now())}',
                    '',
                    'Diperakui oleh',
                    '',
                    '____________________',
                    'Nama:',
                    'No IC:',
                    'Hubungan:',
                    'Tarikh:',
                    '',
                    'Diperakui oleh',
                    '',
                    '____________________',
                    'Nama:',
                    'No IC:',
                    'Hubungan:',
                    'Tarikh:',
                  ],
                ),

                // Page Break
                Container(
                  width: double.infinity,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: CustomPaint(
                    painter: DottedLinePainter(),
                  ),
                ),
                
                // Assets List
                _buildAssetsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperHeader() {
    return Container(
      height: 600, // Fixed height for first page
      child: Column(
        children: [
          // Top spacing
          const SizedBox(height: 60),
          
          // Sampul Logo
          Center(
            child: SvgPicture.network(
              'https://sampul.co/images/Logo.svg',
              height: 35,
              placeholderBuilder: (BuildContext context) => Container(
                height: 35,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            'WASIAT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Author section
          Column(
            children: [
              Text(
                'ditulis oleh',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _will!.nricName ?? _userProfile?.displayName ?? 'Not provided',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Will ID: ${_will!.willCode}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Website
          Text(
            'Securing Digital Legacies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'https://sampul.co',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          // Information notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Salinan sijil dan perincian penuh wasiat boleh didapati dalam peti simpanan digital Sampul. Sebarang maklumat dan pertanyaan, sila emel kepada hello@sampul.co',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),

          // Footer - End of first page
          Text(
            'Powered by Sampul',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
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


  String _formatAddress(UserProfile profile) {
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _formatDateMalay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogs', 'Sep', 'Okt', 'Nov', 'Dis'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  String _getCoSampulUtama() {
    if (_will?.coSampul1 == null) return '[PRIMARY CO-SAMPUL NAME/NICKNAME]';
    
    final executor = _familyMembers.firstWhere(
      (member) => member['id'] == _will!.coSampul1,
      orElse: () => {'name': '[PRIMARY CO-SAMPUL NAME/NICKNAME]'},
    );
    
    return executor['name'] ?? '[PRIMARY CO-SAMPUL NAME/NICKNAME]';
  }

  String _getCoSampulUtamaNric() {
    if (_will?.coSampul1 == null) return '[PRIMARY CO-SAMPUL NRIC NO]';
    
    final executor = _familyMembers.firstWhere(
      (member) => member['id'] == _will!.coSampul1,
      orElse: () => {'nric_no': '[PRIMARY CO-SAMPUL NRIC NO]'},
    );
    
    return executor['nric_no'] ?? '[PRIMARY CO-SAMPUL NRIC NO]';
  }

  String _getCoSampulGanti() {
    if (_will?.coSampul2 == null) return '[SECONDARY CO-SAMPUL NAME/NICKNAME]';
    
    final executor = _familyMembers.firstWhere(
      (member) => member['id'] == _will!.coSampul2,
      orElse: () => {'name': '[SECONDARY CO-SAMPUL NAME/NICKNAME]'},
    );
    
    return executor['name'] ?? '[SECONDARY CO-SAMPUL NAME/NICKNAME]';
  }

  String _getCoSampulGantiNric() {
    if (_will?.coSampul2 == null) return '[SECONDARY CO-SAMPUL NRIC NO]';
    
    final executor = _familyMembers.firstWhere(
      (member) => member['id'] == _will!.coSampul2,
      orElse: () => {'nric_no': '[SECONDARY CO-SAMPUL NRIC NO]'},
    );
    
    return executor['nric_no'] ?? '[SECONDARY CO-SAMPUL NRIC NO]';
  }

  Widget _buildAssetsList() {
    if (_assets.isEmpty) {
      return _buildPaperSection(
        'SENARAI ASET',
        [
          'Tiada aset didaftarkan pada masa ini.',
          '',
          'Untuk menambah aset, sila gunakan fungsi "Tambah Aset" dalam aplikasi.',
        ],
      );
    }

    final totalValue = _assets.fold<double>(0, (sum, asset) => sum + (asset['value'] as num).toDouble());
    
    final List<String> assetLines = [
      'JADUAL 1: SENARAI ASET TERPERINCI',
      '',
      'Jumlah Nilai Aset: RM ${totalValue.toStringAsFixed(2)}',
      'Bilangan Aset: ${_assets.length}',
      '',
      'ASET FIZIKAL:',
      '',
    ];

    // Separate physical and digital assets
    final physicalAssets = _assets.where((asset) => asset['type'] == 'physical').toList();
    final digitalAssets = _assets.where((asset) => asset['type'] == 'digital').toList();

    // Display physical assets
    if (physicalAssets.isNotEmpty) {
      for (int i = 0; i < physicalAssets.length; i++) {
        final asset = physicalAssets[i];
        final value = (asset['value'] as num).toDouble();
        final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
        final institution = asset['institution'] ?? 'N/A';
        final accountType = asset['account_type'] ?? 'N/A';
        final accountNo = asset['account_no'] ?? 'N/A';
        final loanCategory = asset['loan_category'] ?? 'N/A';
        final rate = asset['rate'] ?? 'N/A';
        final tenureStart = asset['tenure_start_date'] ?? 'N/A';
        final tenureEnd = asset['tenure_end_date'] ?? 'N/A';
        final remarks = asset['remarks'] ?? '';
        final instructions = _formatInstructions(asset['instructions_after_death']);
        
        assetLines.addAll([
          '${i + 1}. ${asset['name']}',
          '   Jenis: ${asset['type']}',
          '   Nilai: RM ${value.toStringAsFixed(2)} ($percentage%)',
          '   Institusi: $institution',
          '   Jenis Akaun: $accountType',
          '   Nombor Akaun: $accountNo',
          '   Kategori Pinjaman: $loanCategory',
          '   Kadar: $rate',
          '   Tempoh Mula: $tenureStart',
          '   Tempoh Tamat: $tenureEnd',
          if (instructions.isNotEmpty) '   Arahan Selepas Kematian: $instructions',
          if (remarks.isNotEmpty) '   Catatan: $remarks',
          '',
        ]);
      }
    } else {
      assetLines.add('Tiada aset fizikal didaftarkan.');
      assetLines.add('');
    }

    assetLines.add('ASET DIGITAL:');
    assetLines.add('');

    // Display digital assets
    if (digitalAssets.isNotEmpty) {
      for (int i = 0; i < digitalAssets.length; i++) {
        final asset = digitalAssets[i];
        final value = (asset['value'] as num).toDouble();
        final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
        final accountType = asset['account_type'] ?? 'N/A';
        final url = asset['url'] ?? '';
        final username = asset['username'] ?? '';
        final email = asset['email'] ?? '';
        final frequency = asset['frequency'] ?? 'N/A';
        final protection = asset['protection'] == true ? 'Ya' : 'Tidak';
        final remarks = asset['remarks'] ?? '';
        final instructions = _formatInstructions(asset['instructions_after_death']);
        
        assetLines.addAll([
          '${i + 1}. ${asset['name']}',
          '   Jenis: ${asset['type']}',
          '   Nilai: RM ${value.toStringAsFixed(2)} ($percentage%)',
          '   Jenis Akaun: $accountType',
          if (url.isNotEmpty) '   URL: $url',
          if (username.isNotEmpty) '   Nama Pengguna: $username',
          if (email.isNotEmpty) '   Emel: $email',
          '   Kekerapan: $frequency',
          '   Perlindungan: $protection',
          if (instructions.isNotEmpty) '   Arahan Selepas Kematian: $instructions',
          if (remarks.isNotEmpty) '   Catatan: $remarks',
          '',
        ]);
      }
    } else {
      assetLines.add('Tiada aset digital didaftarkan.');
      assetLines.add('');
    }

    assetLines.addAll([
      'JADUAL 2: PENGAGIHAN ASET MENGIKUT FARAID',
      '',
      'Aset akan diagihkan mengikut prinsip Faraid Islam berdasarkan waris yang layak.',
      '',
      'JADUAL 3: HADIAH (HIBAH) KHUSUS',
      '',
      'Tiada hadiah khusus ditetapkan pada masa ini.',
      '',
      'Nota: Senarai aset ini adalah berdasarkan maklumat yang didaftarkan pada ${_formatDateMalay(DateTime.now())}.',
      'Sila kemas kini senarai aset sekiranya terdapat perubahan.',
    ]);

    return _buildPaperSection(
      'SENARAI ASET',
      assetLines,
    );
  }

  String _formatInstructions(String? instruction) {
    switch ((instruction ?? '').toLowerCase()) {
      case 'faraid':
        return 'Faraid';
      case 'terminate':
        return 'Terminate Subscriptions';
      case 'transfer_as_gift':
        return 'Transfer as Gift';
      case 'settle':
        return 'Settle Debts';
      default:
        return instruction ?? '';
    }
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

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    const double dashWidth = 5;
    const double dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

