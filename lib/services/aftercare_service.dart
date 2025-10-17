import '../models/aftercare_task.dart';
import 'supabase_service.dart';

class AftercareService {
  static AftercareService? _instance;
  static AftercareService get instance => _instance ??= AftercareService._();

  AftercareService._();

  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<AftercareTask>> listTasks(String uuid) async {
    final List<dynamic> rows = await _supabase.client
        .from('aftercare')
        .select()
        .eq('uuid', uuid)
        .order('is_pinned', ascending: false)
        .order('sort_index', ascending: true)
        .order('created_at', ascending: false);
    return rows.map((e) => AftercareTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> seedDefaultTasks({required String uuid, int startIndex = 0}) async {
    final List<Map<String, dynamic>> defaults = <String>[
      '1. Manage the Burial',
      '2. Claim Khairat/Mutual Benevolent',
      '3. Apply for Death Certificate with National Registration Department (Jabatan Pendaftaran Negara)',
      '4. Apply for List of Asset, Debt, Wishes and Wasiat via Sampul.co',
      '5. Claim Takaful/Insurance',
      '6. Terminate Digital Accounts and Subscription',
      '7. Identify other Asset',
      '8. Identify other Debts to be Settled',
      '9. Legal consultation',
      '10. Get authority',
      '11. Manage assets',
      '12. Distribute to heirs',
      '13. Channel Charity and Waqf',
      '14. Continuous Prayers',
      '15. Process grief',
    ].asMap().entries.map((e) => <String, dynamic>{
          'uuid': uuid,
          'task': e.value,
          'is_completed': false,
          'is_pinned': false,
          'sort_index': startIndex + e.key,
        }).toList();

    if (defaults.isNotEmpty) {
      await _supabase.client.from('aftercare').insert(defaults);
    }
  }

  Future<void> updateTaskPosition({required int id, required int sortIndex}) async {
    await _supabase.client
        .from('aftercare')
        .update(<String, dynamic>{'sort_index': sortIndex})
        .eq('id', id);
  }

  Future<void> deleteAll({required String uuid}) async {
    await _supabase.client.from('aftercare').delete().eq('uuid', uuid);
  }

  Future<void> updatePositions({required String uuid, required List<int> orderedIds}) async {
    // Persist new order: index in orderedIds is the new sort_index
    for (int i = 0; i < orderedIds.length; i++) {
      final int id = orderedIds[i];
      await _supabase.client
          .from('aftercare')
          .update(<String, dynamic>{'sort_index': i})
          .eq('id', id)
          .eq('uuid', uuid);
    }
  }

  Future<AftercareTask> createTask({
    required String uuid,
    required String task,
  }) async {
    // Determine next sort_index for this user (append to bottom)
    final List<dynamic> maxRow = await _supabase.client
        .from('aftercare')
        .select('sort_index')
        .eq('uuid', uuid)
        .order('sort_index', ascending: false)
        .limit(1);
    final int nextIndex = maxRow.isEmpty
        ? 0
        : (((maxRow.first['sort_index'] as int?) ?? 0) + 1);
    final Map<String, dynamic> data = {
      'uuid': uuid,
      'task': task,
      'is_completed': false,
      'is_pinned': false,
      'sort_index': nextIndex,
    };
    final Map<String, dynamic> row = await _supabase.client
        .from('aftercare')
        .insert(data)
        .select()
        .single();
    return AftercareTask.fromJson(row);
  }

  Future<AftercareTask> updateTask({
    required int id,
    String? task,
    bool? isCompleted,
    bool? isPinned,
  }) async {
    final Map<String, dynamic> update = <String, dynamic>{};
    if (task != null) update['task'] = task;
    if (isCompleted != null) update['is_completed'] = isCompleted;
    if (isPinned != null) update['is_pinned'] = isPinned;
    final Map<String, dynamic> row = await _supabase.client
        .from('aftercare')
        .update(update)
        .eq('id', id)
        .select()
        .single();
    return AftercareTask.fromJson(row);
  }

  Future<void> deleteTask(int id) async {
    await _supabase.client.from('aftercare').delete().eq('id', id);
  }
}


