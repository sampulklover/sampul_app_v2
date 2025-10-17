import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/executor.dart';
import 'supabase_service.dart';

class ExecutorService {
  ExecutorService._();
  static final ExecutorService instance = ExecutorService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Executor>> listUserExecutors() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <Executor>[];
    final List<dynamic> rows = await _client
        .from('executor')
        .select()
        .eq('uuid', user.id)
        .order('created_at', ascending: false);

    return rows.map((e) => Executor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Executor> createExecutor(Executor executor) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    // Ensure executor_code is present; generate if missing
    String code = (executor.executorCode ?? '').trim();
    if (code.isEmpty) {
      code = _generateExecutorId();
    }

    int attempts = 0;
    while (true) {
      try {
        final Map<String, dynamic> payload = {
          ...executor.toJson(),
          'executor_code': code,
          'uuid': user.id,
        };
        final List<dynamic> inserted = await _client.from('executor').insert(payload).select().limit(1);
        return Executor.fromJson(inserted.first as Map<String, dynamic>);
      } catch (e) {
        // Retry on unique violation by generating a new code
        final String msg = e.toString().toLowerCase();
        final bool isUniqueViolation = msg.contains('duplicate key') || msg.contains('unique') || msg.contains('23505');
        if (!isUniqueViolation || attempts >= 4) {
          rethrow;
        }
        attempts += 1;
        code = _generateExecutorId();
      }
    }
  }

  Future<Executor?> getExecutorById(int id) async {
    final List<dynamic> rows = await _client.from('executor').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return Executor.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> deleteExecutor(int id) async {
    await _client.from('executor').delete().eq('id', id);
  }

  Future<Executor> updateExecutor(int id, Map<String, dynamic> data) async {
    final List<dynamic> rows = await _client
        .from('executor')
        .update(data)
        .eq('id', id)
        .select()
        .limit(1);
    return Executor.fromJson(rows.first as Map<String, dynamic>);
  }
}

String _generateExecutorId() {
  final int currentYear = DateTime.now().year;
  // 10 random digits padded
  final int randomDigits = (DateTime.now().microsecondsSinceEpoch % 10000000000).toInt();
  final String padded = randomDigits.toString().padLeft(10, '0');
  return 'EXEC-$currentYear-$padded';
}

