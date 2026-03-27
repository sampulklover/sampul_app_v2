import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import '../utils/admin_utils.dart';

class TeamMemberAccess {
  TeamMemberAccess({
    required this.uuid,
    required this.email,
    this.username,
    this.role,
  });

  final String uuid;
  final String email;
  final String? username;

  /// Lowercase role from DB, e.g. `admin`, `marketing`, or null for standard app user.
  final String? role;
}

class TeamRolesService {
  TeamRolesService._();
  static final TeamRolesService instance = TeamRolesService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<TeamMemberAccess>> listMembersWithRoles({int limit = 500}) async {
    final List<dynamic> profiles = await _client
        .from('profiles')
        .select('uuid, email, username')
        .order('email')
        .limit(limit);

    final List<dynamic> roleRows =
        await _client.from('roles').select('uuid, role');

    final Map<String, String> roleByUuid = <String, String>{};
    for (final dynamic row in roleRows) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(row as Map);
      final String? uid = m['uuid'] as String?;
      final dynamic r = m['role'];
      if (uid != null && r != null) {
        roleByUuid[uid] = r.toString().toLowerCase();
      }
    }

    return profiles.map((dynamic raw) {
      final Map<String, dynamic> p = Map<String, dynamic>.from(raw as Map);
      final String uuid = p['uuid'] as String;
      return TeamMemberAccess(
        uuid: uuid,
        email: p['email'] as String? ?? '',
        username: p['username'] as String?,
        role: roleByUuid[uuid],
      );
    }).toList();
  }

  /// Removes the `roles` row when [role] is null; otherwise upserts admin or marketing.
  Future<void> setUserRole(String uuid, String? role) async {
    if (role == null || role.isEmpty) {
      await _client.from('roles').delete().eq('uuid', uuid);
      return;
    }
    final String? normalized = AdminUtils.normalizeRoleKey(role);
    if (normalized == null ||
        (normalized != AdminUtils.roleAdmin &&
            normalized != AdminUtils.roleMarketing)) {
      throw StateError('Invalid role');
    }
    await _client.from('roles').upsert(
      <String, dynamic>{'uuid': uuid, 'role': normalized},
      onConflict: 'uuid',
    );
  }
}
