import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/hibah.dart';
import 'supabase_service.dart';

class HibahService {
  HibahService._();
  static final HibahService instance = HibahService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Hibah>> listUserHibahs() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <Hibah>[];
    final List<dynamic> rows = await _client
        .from('hibah')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return rows
        .map((dynamic e) => Hibah.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Hibah> createSubmission({
    required List<HibahGroupRequest> groups,
    List<HibahDocumentRequest> documents = const <HibahDocumentRequest>[],
  }) async {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in');
    }
    if (groups.isEmpty) {
      throw Exception(
        'At least one asset is required to create a hibah submission.',
      );
    }

    int attempts = 0;
    while (attempts < 5) {
      final String certificateId = _generateCertificateId();
      try {
        final Map<String, dynamic> payload = <String, dynamic>{
          'user_id': user.id,
          'certificate_id': certificateId,
          'submission_status': hibahStatusToDb(HibahStatus.pendingReview),
          'total_submissions': groups.length,
        };
        final Map<String, dynamic> inserted = await _client
            .from('hibah')
            .insert(payload)
            .select()
            .single();
        final Hibah created = Hibah.fromJson(inserted);
        await _insertGroupsAndDocuments(created, groups, documents);
        return created.copyWith(totalSubmissions: groups.length);
      } catch (e) {
        final String msg = e.toString().toLowerCase();
        final bool isUniqueViolation =
            msg.contains('duplicate key') ||
            msg.contains('unique') ||
            msg.contains('23505');
        if (!isUniqueViolation) rethrow;
        attempts += 1;
        if (attempts >= 5) rethrow;
      }
    }
    throw Exception('Unable to create hibah submission. Please try again.');
  }

  Future<Hibah?> getHibahById(String id) async {
    final Map<String, dynamic>? row = await _client
        .from('hibah')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Hibah.fromJson(row);
  }

  Future<List<HibahGroup>> getHibahGroups(String hibahId) async {
    final List<dynamic> rows = await _client
        .from('hibah_group')
        .select()
        .eq('hibah_id', hibahId)
        .order('hibah_index');
    return rows
        .map((dynamic e) => HibahGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HibahDocument>> getHibahDocuments(String hibahId) async {
    final List<dynamic> rows = await _client
        .from('hibah_documents')
        .select()
        .eq('submission_id', hibahId)
        .order('uploaded_at');
    return rows
        .map((dynamic e) => HibahDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteHibah(String id) async {
    // First, get all documents to delete their files from storage
    final List<dynamic> docRows = await _client
        .from('hibah_documents')
        .select('file_path')
        .eq('submission_id', id);
    
    // Delete files from storage
    if (docRows.isNotEmpty) {
      final List<String> filePaths = docRows
          .map((dynamic row) => row['file_path'] as String)
          .toList();
      
      try {
        await _client.storage.from('images').remove(filePaths);
      } catch (e) {
        // Log error but continue with database cleanup
        print('Error deleting files from storage: $e');
      }
    }
    
    // Delete database records (cascading delete)
    await _client.from('hibah_documents').delete().eq('submission_id', id);
    await _client.from('hibah_group').delete().eq('hibah_id', id);
    await _client.from('hibah').delete().eq('id', id);
  }

  Future<void> _insertGroupsAndDocuments(
    Hibah hibah,
    List<HibahGroupRequest> groups,
    List<HibahDocumentRequest> documents,
  ) async {
    final Map<String, String> tempIdMap = <String, String>{};
    int index = 1;
    for (final HibahGroupRequest group in groups) {
      final Map<String, dynamic> payload = group.toInsertMap(
        hibahId: hibah.id,
        hibahIndex: index,
      );
      final Map<String, dynamic> row = await _client
          .from('hibah_group')
          .insert(payload)
          .select()
          .single();
      tempIdMap[group.tempId] = row['id'] as String;
      index += 1;
    }

    if (documents.isEmpty) return;

    final List<Map<String, dynamic>> docsPayload = <Map<String, dynamic>>[];
    for (final HibahDocumentRequest doc in documents) {
      docsPayload.add(
        doc.toInsertMap(
          submissionId: hibah.id,
          hibahGroupId: doc.groupTempId != null
              ? tempIdMap[doc.groupTempId]
              : null,
        ),
      );
    }
    await _client.from('hibah_documents').insert(docsPayload);
  }
}

String _generateCertificateId() {
  final int currentYear = DateTime.now().year;
  final int randomDigits = DateTime.now().microsecondsSinceEpoch.remainder(
    1000000000,
  );
  final String padded = randomDigits.toString().padLeft(9, '0');
  return 'CERT-$currentYear-$padded';
}
