import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../models/relationship.dart';
import 'edit_family_member_screen.dart';
import 'add_family_member_screen.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  String _prettyType(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'co_sampul':
        return 'Co-sampul';
      case 'future_owner':
        return 'Beneficiary';
      case 'guardian':
        return 'Guardian';
      default:
        return '';
    }
  }

  Color _badgeBg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade50;
      case 'future_owner':
        return Colors.teal.shade50;
      case 'guardian':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _badgeFg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade700;
      case 'future_owner':
        return Colors.teal.shade800;
      case 'guardian':
        return Colors.orange.shade800;
      default:
        return Colors.black87;
    }
  }

  Widget _buildRelationshipDisplay(String relationship) {
    final Relationship? rel = Relationship.getByValue(relationship);
    if (rel == null) {
      return Text(relationship);
    }
    
    // Only show waris tag for important relationships, skip legacy and non-waris tags
    if (rel.isWaris && !Relationship.isLegacyRelationship(relationship)) {
      return Row(
        children: [
          Text(rel.displayName),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Waris',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      );
    }
    
    // For all other relationships, just show the name without tags
    return Text(rel.displayName);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name,type,percentage,image_path,relationship')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _items = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Family')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? added = await Navigator.of(context).push(
            MaterialPageRoute<bool>(builder: (_) => const AddFamilyMemberScreen()),
          );
          if (added == true) {
            await _load();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 200), Center(child: Text('No family members yet'))])
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> b = _items[index];
                        final int id = (b['id'] as num).toInt();
                        final String name = (b['name'] as String?) ?? 'Unknown';
                        final String typeText = _prettyType(b['type'] as String?);
                        final double? pct = (b['percentage'] as num?)?.toDouble();
                        final String? relationship = b['relationship'] as String?;
                        final String? imagePath = b['image_path'] as String?;
                        return ListTile(
                          onTap: () async {
                            final bool? updated = await Navigator.of(context).push(
                              MaterialPageRoute<bool>(builder: (_) => EditFamilyMemberScreen(belovedId: id)),
                            );
                            if (updated == true) {
                              await _load();
                            }
                          },
                          leading: _Avatar(imagePath: imagePath),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (relationship != null && relationship.isNotEmpty) 
                                _buildRelationshipDisplay(relationship),
                              if (typeText.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _badgeBg(b['type'] as String?),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    typeText,
                                    style: TextStyle(fontSize: 11, color: _badgeFg(b['type'] as String?), fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          trailing: ((b['type'] as String?) == 'future_owner' && pct != null)
                              ? Text('${pct.toStringAsFixed(2)}%')
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imagePath;
  const _Avatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return const CircleAvatar(radius: 20, child: Icon(Icons.person));
    }
    final String? url = SupabaseService.instance.getFullImageUrl(imagePath);
    if (url == null || url.isEmpty) {
      return const CircleAvatar(radius: 20, child: Icon(Icons.person));
    }
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
    );
  }
}


