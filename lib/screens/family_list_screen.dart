import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../models/relationship.dart';
import 'edit_family_member_screen.dart';
import 'family_info_screen.dart';

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
            MaterialPageRoute<bool>(builder: (_) => const FamilyInfoScreen()),
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
                  ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Let's add your family",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Add the people who matter most — executors, beneficiaries, and guardians — so your will stays clear and connected.",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Center(
                      child: Icon(
                        Icons.family_restroom,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Why add family members?",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Your family list connects to your will, trust, and hibah planning. Add executors (Co-Sampul), beneficiaries, and guardians.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FamilyFeatureItem(
                            text: "Assign executors (Co-Sampul) who will carry out your will.",
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _FamilyFeatureItem(
                            text: "List beneficiaries who will receive your assets.",
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _FamilyFeatureItem(
                            text: "Designate guardians for minor children if needed.",
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                child: ElevatedButton(
                  onPressed: () async {
                    final bool? added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const FamilyInfoScreen(),
                      ),
                    );
                    if (added == true) {
                      await _load();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Add family member",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyFeatureItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _FamilyFeatureItem({
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: colorScheme.onPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
      ],
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


