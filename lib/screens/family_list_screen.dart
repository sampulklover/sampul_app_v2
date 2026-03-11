import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../models/relationship.dart';
import '../l10n/app_localizations.dart';
import 'edit_family_member_screen.dart';
import 'family_info_screen.dart';
import 'add_family_member_screen.dart';
import '../utils/sampul_icons.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  String _prettyType(String? t, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch ((t ?? '').toLowerCase()) {
      case 'co_sampul':
        return l10n.coSampul;
      case 'future_owner':
        return l10n.beneficiary;
      case 'guardian':
        return l10n.guardian;
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
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.waris,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                );
              },
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myFamily)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Check if user has seen the about page before
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final bool hasSeenAbout = prefs.getBool('family_about_seen') ?? false;
          
          // If user hasn't seen about page, show it first
          // Otherwise, go directly to add family member page
          final bool? added = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => hasSeenAbout 
                  ? const AddFamilyMemberScreen() 
                  : const FamilyInfoScreen(),
            ),
          );
          if (added == true) {
            await _load();
          }
        },
        child: SampulIcons.buildIcon(SampulIcons.add, width: 24, height: 24, color: Colors.white),
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
                        final String name = (b['name'] as String?) ?? l10n.unknown;
                        final String typeText = _prettyType(b['type'] as String?, context);
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
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.letsAddYourFamily,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.addPeopleWhoMatterMost,
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
                              l10n.whyAddFamilyMembers,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.familyListConnectsToWill,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _FamilyFeatureItem(
                              text: l10n.assignExecutorsCoSampul,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _FamilyFeatureItem(
                              text: l10n.listBeneficiariesWhoReceive,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _FamilyFeatureItem(
                              text: l10n.designateGuardiansForMinors,
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
                        l10n.addFamilyMember,
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
      return CircleAvatar(
        radius: 20,
        child: SampulIcons.buildIcon(SampulIcons.person, width: 24, height: 24),
      );
    }
    final String? url = SupabaseService.instance.getFullImageUrl(imagePath);
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 20,
        child: SampulIcons.buildIcon(SampulIcons.person, width: 24, height: 24),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
    );
  }
}


