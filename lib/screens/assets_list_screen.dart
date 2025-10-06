import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'edit_asset_screen.dart';

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = <Map<String, dynamic>>[];

  String _prettyInstruction(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'faraid':
        return 'Faraid';
      case 'terminate':
        return 'Terminate Subscriptions';
      case 'transfer_as_gift':
        return 'Transfer as Gift';
      case 'settle':
        return 'Settle Debts';
      default:
        return '';
    }
  }

  Color _badgeBg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade50;
      case 'terminate':
        return Colors.red.shade50;
      case 'transfer_as_gift':
        return Colors.teal.shade50;
      case 'settle':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _badgeFg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade700;
      case 'terminate':
        return Colors.red.shade700;
      case 'transfer_as_gift':
        return Colors.teal.shade800;
      case 'settle':
        return Colors.orange.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id,new_service_platform_name,new_service_platform_logo_url,new_service_platform_url,declared_value_myr,created_at,instructions_after_death')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _assets = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Assets')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssets,
              child: _assets.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 200), Center(child: Text('No assets yet'))])
                  : ListView.separated(
                      itemCount: _assets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> a = _assets[index];
                        final int id = (a['id'] as num).toInt();
                        final String name = (a['new_service_platform_name'] as String?) ?? 'Unknown';
                        final String? logo = a['new_service_platform_logo_url'] as String?;
                        final String? url = a['new_service_platform_url'] as String?;
                        final double? value = (a['declared_value_myr'] as num?)?.toDouble();
                        final String? category = a['instructions_after_death'] as String?;
                        final String categoryText = _prettyInstruction(category);
                        return ListTile(
                          onTap: () async {
                            final bool? updated = await Navigator.of(context).push(
                              MaterialPageRoute<bool>(builder: (_) => EditAssetScreen(assetId: id)),
                            );
                            if (updated == true) {
                              await _loadAssets();
                            }
                          },
                          leading: _Logo(url: logo, size: 40),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (url != null && url.isNotEmpty) Text(url),
                              if (categoryText.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _badgeBg(category),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(categoryText, style: TextStyle(fontSize: 11, color: _badgeFg(category), fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          trailing: value != null ? Text('RM ${value.toStringAsFixed(2)}') : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final double size;
  const _Logo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAEAEA)),
        alignment: Alignment.center,
        child: const Icon(Icons.apps),
      );
    }
    final String u = url!;
    final bool isSvg = u.toLowerCase().endsWith('.svg');
    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAEAEA)),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined),
    );
    if (isSvg) {
      return ClipOval(
        child: SvgPicture.network(
          u,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
