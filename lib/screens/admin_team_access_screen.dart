import 'package:flutter/material.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';

import '../services/supabase_service.dart';
import '../services/team_roles_service.dart';
import '../utils/admin_utils.dart';
import '../utils/card_decoration_helper.dart';

/// Admins assign [AdminUtils.roleMarketing] or [AdminUtils.roleAdmin] per user.
class AdminTeamAccessScreen extends StatefulWidget {
  const AdminTeamAccessScreen({super.key});

  @override
  State<AdminTeamAccessScreen> createState() => _AdminTeamAccessScreenState();
}

class _AdminTeamAccessScreenState extends State<AdminTeamAccessScreen> {
  static const double _fieldRadius = 12;

  bool _isAdmin = false;
  bool _loadingGate = true;
  bool _loadingList = true;
  String? _loadError;
  List<TeamMemberAccess> _members = const [];
  String _query = '';
  String _roleFilter = _kFilterAll;
  final Set<String> _savingUuids = <String>{};

  @override
  void initState() {
    super.initState();
    _gateAndLoad();
  }

  Future<void> _gateAndLoad() async {
    final bool admin = await AdminUtils.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _loadingGate = false;
    });

    if (!admin) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workspaceAccessNotAvailable),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    await _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingList = true;
      _loadError = null;
    });
    try {
      final list = await TeamRolesService.instance.listMembersWithRoles();
      if (!mounted) return;
      setState(() {
        _members = list;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<TeamMemberAccess> get _filtered {
    final String q = _query.trim().toLowerCase();
    return _members.where((TeamMemberAccess m) {
      final String currentRole = _roleValueForUi(m.role) ?? _kStandardValue;
      final bool roleMatch =
          _roleFilter == _kFilterAll || currentRole == _roleFilter;
      if (!roleMatch) return false;

      if (q.isEmpty) return true;
      return m.email.toLowerCase().contains(q) ||
          (m.username ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String? _roleValueForUi(String? dbRole) {
    if (dbRole == null) return null;
    return AdminUtils.normalizeRoleKey(dbRole);
  }

  Future<void> _onRoleChosen(TeamMemberAccess member, String? newValue) async {
    final l10n = AppLocalizations.of(context)!;
    final String? current = _roleValueForUi(member.role);

    String? nextRole = newValue;
    if (newValue == _kStandardValue) {
      nextRole = null;
    }

    if (current == nextRole ||
        (current == null && (nextRole == null || nextRole.isEmpty))) {
      return;
    }

    final String? myId = SupabaseService.instance.currentUser?.id;
    final bool isSelf = myId != null && member.uuid == myId;
    if (isSelf && current == AdminUtils.roleAdmin && nextRole != AdminUtils.roleAdmin) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
          final ThemeData d = Theme.of(ctx);
          return AlertDialog(
            title: Text(l10n.changeYourAccess),
            content: Text(
              l10n.changeYourAccessAdminHint,
              style: d.textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.continueLabel),
              ),
            ],
          );
        },
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _savingUuids.add(member.uuid));
    try {
      await TeamRolesService.instance.setUserRole(member.uuid, nextRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamRoleSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadMembers();
      if (isSelf && nextRole != AdminUtils.roleAdmin && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      final ThemeData theme = Theme.of(context);
      final String msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamRoleSaveFailed(msg)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.errorContainer,
          action: SnackBarAction(
            label: l10n.teamAccessTryAgain,
            textColor: theme.colorScheme.onErrorContainer,
            onPressed: () => _onRoleChosen(member, newValue),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingUuids.remove(member.uuid));
      }
    }
  }

  static const String _kStandardValue = 'standard';
  static const String _kFilterAll = 'all';

  Future<void> _showRoleInfoDialog() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(l10n.teamAccessInfoTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _infoRow(
                icon: Icons.person_outline,
                label: l10n.roleStandardUser,
                description: l10n.teamAccessInfoStandard,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.campaign_outlined,
                label: l10n.roleMarketing,
                description: l10n.teamAccessInfoMarketing,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.admin_panel_settings_outlined,
                label: l10n.roleAdmin,
                description: l10n.teamAccessInfoAdmin,
                theme: theme,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              children: <TextSpan>[
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final Color borderColor = theme.colorScheme.outlineVariant;

    if (_loadingGate) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.teamAccess)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamAccess),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.teamAccessInfoTooltip,
            icon: const Icon(Icons.info_outline),
            onPressed: _showRoleInfoDialog,
          ),
          IconButton(
            tooltip: l10n.teamAccessRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _loadingList ? null : _loadMembers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            CardDecorationHelper.styledCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    onChanged: (String v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.teamAccessSearchHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_fieldRadius),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_fieldRadius),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_fieldRadius),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use -- controlled field for filter state
                    value: _roleFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: l10n.teamAccessFilterLabel,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_fieldRadius),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_fieldRadius),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: _kFilterAll,
                        child: Text(l10n.teamAccessFilterAll),
                      ),
                      DropdownMenuItem<String>(
                        value: _kStandardValue,
                        child: Text(l10n.roleStandardUser),
                      ),
                      DropdownMenuItem<String>(
                        value: AdminUtils.roleMarketing,
                        child: Text(l10n.roleMarketing),
                      ),
                      DropdownMenuItem<String>(
                        value: AdminUtils.roleAdmin,
                        child: Text(l10n.roleAdmin),
                      ),
                    ],
                    selectedItemBuilder: (BuildContext context) {
                      return <String>[
                        l10n.teamAccessFilterAll,
                        l10n.roleStandardUser,
                        l10n.roleMarketing,
                        l10n.roleAdmin,
                      ].map((String text) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (String? v) {
                      if (v == null) return;
                      setState(() => _roleFilter = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingList)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.teamAccessLoadFailed(_loadError!),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: _loadMembers,
                      child: Text(l10n.teamAccessTryAgain),
                    ),
                  ],
                ),
              )
            else
              ..._listSection(theme, l10n, borderColor),
          ],
        ),
      ),
    );
  }

  List<Widget> _listSection(
    ThemeData theme,
    AppLocalizations l10n,
    Color borderColor,
  ) {
    final List<TeamMemberAccess> rows = _filtered;
    final bool emptySearch =
        rows.isEmpty && _query.trim().isNotEmpty && _members.isNotEmpty;

    if (emptySearch) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            l10n.teamAccessEmptySearch,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    if (rows.isEmpty) {
      return <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 8),
      CardDecorationHelper.styledCard(
        context: context,
        padding: EdgeInsets.zero,
        child: Column(
          children: rows.asMap().entries.expand((MapEntry<int, TeamMemberAccess> e) {
            final TeamMemberAccess m = e.value;
            final bool last = e.key == rows.length - 1;
            final bool saving = _savingUuids.contains(m.uuid);
            final String? uiRole = _roleValueForUi(m.role);
            final String dropdownValue = uiRole ?? _kStandardValue;

            return <Widget>[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  m.email.isEmpty ? m.uuid : m.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: (m.username != null && m.username!.trim().isNotEmpty)
                    ? Text(
                        m.username!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: saving
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SizedBox(
                        width: 148,
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use — controlled value after save/reload
                          value: dropdownValue,
                          isDense: true,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: l10n.teamAccessRoleLabel,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_fieldRadius),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_fieldRadius),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: _kStandardValue,
                              child: Text(l10n.roleStandardUser),
                            ),
                            DropdownMenuItem<String>(
                              value: AdminUtils.roleMarketing,
                              child: Text(l10n.roleMarketing),
                            ),
                            DropdownMenuItem<String>(
                              value: AdminUtils.roleAdmin,
                              child: Text(l10n.roleAdmin),
                            ),
                          ],
                          selectedItemBuilder: (BuildContext context) {
                            return <String>[
                              l10n.roleStandardUser,
                              l10n.roleMarketing,
                              l10n.roleAdmin,
                            ].map((String text) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          onChanged: (String? v) {
                            if (v == null) return;
                            _onRoleChosen(m, v);
                          },
                        ),
                      ),
              ),
              if (!last) Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
            ];
          }).toList(),
        ),
      ),
    ];
  }
}
