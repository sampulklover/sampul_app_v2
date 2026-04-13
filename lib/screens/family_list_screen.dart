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
import '../services/faraid_beneficiary_share.dart';

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

  bool get _hasBeneficiaries =>
      _items.any((Map<String, dynamic> e) => e['type'] == 'future_owner');

  Future<void> _suggestFaraidShares() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String msgNeedGender = l10n.faraidSuggestSharesNeedGender;
    final String msgNone = l10n.faraidSuggestSharesNone;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final user = AuthController.instance.currentUser;
    if (user == null) return;

    final profile = await AuthController.instance.getUserProfile();
    if (!context.mounted) return;
    final String g = (profile?.gender ?? '').trim().toLowerCase();
    if (g != 'male' && g != 'female') {
      messenger.showSnackBar(SnackBar(content: Text(msgNeedGender)));
      return;
    }
    final bool deceasedMale = g == 'male';
    final List<Map<String, dynamic>> beneficiaries = _items
        .where((Map<String, dynamic> e) => e['type'] == 'future_owner')
        .cast<Map<String, dynamic>>()
        .toList();
    if (beneficiaries.isEmpty) return;

    final Map<int, double> updates = FaraidBeneficiaryShare.suggestedPercentagesForAllBeneficiaries(
      futureOwnerRows: beneficiaries,
      deceasedMale: deceasedMale,
    );
    if (updates.isEmpty) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(msgNone)));
      return;
    }

    if (!context.mounted) return;
    final bool? save = await _showFaraidPreviewDialog(
      l10n: l10n,
      updates: updates,
      beneficiaries: beneficiaries,
    );
    if (save != true || !context.mounted) return;

    final String msgUpdatedSnack = l10n.faraidSuggestSharesUpdated(updates.length);
    try {
      for (final MapEntry<int, double> e in updates.entries) {
        await SupabaseService.instance.client
            .from('beloved')
            .update(<String, dynamic>{'percentage': e.value})
            .eq('id', e.key)
            .eq('uuid', user.id);
      }
      if (!context.mounted) return;
      await _load();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(msgUpdatedSnack)));
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      final String errText = AppLocalizations.of(context)!.failedToSaveFamilyMember(e.toString());
      messenger.showSnackBar(SnackBar(content: Text(errText)));
    }
  }

  Future<bool?> _showFaraidPreviewDialog({
    required AppLocalizations l10n,
    required Map<int, double> updates,
    required List<Map<String, dynamic>> beneficiaries,
  }) async {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<_FaraidPreviewRow> rows = <_FaraidPreviewRow>[];
    for (final MapEntry<int, double> e in updates.entries) {
      Map<String, dynamic>? match;
      for (final Map<String, dynamic> x in beneficiaries) {
        if ((x['id'] as num).toInt() == e.key) {
          match = x;
          break;
        }
      }
      final String rawName = (match?['name'] as String?)?.trim() ?? '';
      final String rel = (match?['relationship'] as String?)?.trim() ?? '';
      final Relationship? rm = Relationship.getByValue(rel);
      rows.add(
        _FaraidPreviewRow(
          name: rawName.isEmpty ? l10n.unknown : rawName,
          relationshipLabel: rm?.displayName ?? (rel.isEmpty ? '' : rel),
          percent: e.value,
        ),
      );
    }
    rows.sort(
      (_FaraidPreviewRow a, _FaraidPreviewRow b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    final double total = updates.values.fold(0.0, (double s, double v) => s + v);
    final int skippedCount = beneficiaries.length - updates.length;

    if (!context.mounted) return null;
    // ignore: use_build_context_synchronously
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext _) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.38,
          maxChildSize: 0.92,
          builder: (BuildContext sheetContext, ScrollController scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 8, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.faraidPreviewTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close),
                          tooltip: MaterialLocalizations.of(sheetContext).closeButtonLabel,
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      children: <Widget>[
                        Text(
                          l10n.faraidPreviewIntro,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...rows.map(
                          (_FaraidPreviewRow r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        r.name,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      if (r.relationshipLabel.isNotEmpty)
                                        Text(
                                          r.relationshipLabel,
                                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${r.percent.toStringAsFixed(2)}%',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              l10n.faraidPreviewTotal,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${total.toStringAsFixed(2)}%',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (skippedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              l10n.faraidPreviewSkippedNote(skippedCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(sheetContext).pop(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: scheme.outline),
                                ),
                                child: Text(
                                  MaterialLocalizations.of(sheetContext).cancelButtonLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(sheetContext).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  l10n.faraidPreviewSave,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      appBar: AppBar(
        title: Text(l10n.myFamily),
        actions: <Widget>[
          if (_hasBeneficiaries)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'faraid') {
                  _suggestFaraidShares();
                }
              },
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'faraid',
                  child: Text(l10n.faraidSuggestShares),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Check if user has seen the about page before
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final bool hasSeenAbout = prefs.getBool('family_about_seen') ?? false;

          if (!context.mounted) return;
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_hasBeneficiaries) _buildFaraidBanner(l10n),
                        Expanded(
                          child: ListView.separated(
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
                      ],
                    ),
            ),
    );
  }

  Widget _buildFaraidBanner(AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: scheme.primaryContainer.withValues(alpha: 0.28),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.percent_rounded,
                      color: scheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.faraidBannerTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.faraidBannerSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _suggestFaraidShares,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(l10n.faraidBannerCta),
                ),
              ),
            ],
          ),
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
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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

class _FaraidPreviewRow {
  const _FaraidPreviewRow({
    required this.name,
    required this.relationshipLabel,
    required this.percent,
  });

  final String name;
  final String relationshipLabel;
  final double percent;
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


