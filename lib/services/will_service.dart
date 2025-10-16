import 'dart:math';
import '../models/will.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class WillService {
  static WillService? _instance;
  static WillService get instance => _instance ??= WillService._();
  
  WillService._();
  
  final SupabaseService _supabase = SupabaseService.instance;

  /// Generate a unique will code
  String _generateWillCode() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'W$timestamp$randomNum';
  }

  /// Create a new will for the user
  Future<Will> createWill({
    required String uuid,
    String? nricName,
    int? coSampul1,
    int? coSampul2,
    int? guardian1,
    int? guardian2,
    bool isDraft = true,
  }) async {
    final willCode = _generateWillCode();
    final now = DateTime.now();
    
    final willData = {
      'uuid': uuid,
      'will_code': willCode,
      'nric_name': nricName,
      'co_sampul_1': coSampul1,
      'co_sampul_2': coSampul2,
      'guardian_1': guardian1,
      'guardian_2': guardian2,
      'is_draft': isDraft,
      'created_at': now.toIso8601String(),
      'last_updated': now.toIso8601String(),
    };

    final response = await _supabase.client
        .from('wills')
        .insert(willData)
        .select()
        .single();

    return Will.fromJson(response);
  }

  /// Get user's will
  Future<Will?> getUserWill(String uuid) async {
    try {
      final response = await _supabase.client
          .from('wills')
          .select()
          .eq('uuid', uuid)
          .maybeSingle();

      if (response == null) return null;
      return Will.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update an existing will
  Future<Will> updateWill({
    required int willId,
    String? nricName,
    int? coSampul1,
    int? coSampul2,
    int? guardian1,
    int? guardian2,
    bool? isDraft,
  }) async {
    final updateData = <String, dynamic>{
      'last_updated': DateTime.now().toIso8601String(),
    };

    if (nricName != null) updateData['nric_name'] = nricName;
    if (coSampul1 != null) updateData['co_sampul_1'] = coSampul1;
    if (coSampul2 != null) updateData['co_sampul_2'] = coSampul2;
    if (guardian1 != null) updateData['guardian_1'] = guardian1;
    if (guardian2 != null) updateData['guardian_2'] = guardian2;
    if (isDraft != null) updateData['is_draft'] = isDraft;

    final response = await _supabase.client
        .from('wills')
        .update(updateData)
        .eq('id', willId)
        .select()
        .single();

    return Will.fromJson(response);
  }

  /// Delete a will
  Future<void> deleteWill(int willId) async {
    await _supabase.client
        .from('wills')
        .delete()
        .eq('id', willId);
  }

  /// Get family members (beloved) for will assignment
  Future<List<Map<String, dynamic>>> getFamilyMembers(String uuid) async {
    try {
      final response = await _supabase.client
          .from('beloved')
          .select('id, name, type, relationship, percentage, image_path')
          .eq('uuid', uuid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get user's assets for will assignment
  Future<List<Map<String, dynamic>>> getUserAssets(String uuid) async {
    try {
      // Get physical assets
      final physicalAssets = await _supabase.client
          .from('physical_assets')
          .select('id, asset_name, declared_value_myr, account_type, institution')
          .eq('uuid', uuid);

      // Get digital assets
      final digitalAssets = await _supabase.client
          .from('digital_assets')
          .select('id, new_service_platform_name, declared_value_myr, account_type')
          .eq('uuid', uuid);

      final List<Map<String, dynamic>> allAssets = [];
      
      // Add physical assets
      for (final asset in physicalAssets) {
        allAssets.add({
          'id': asset['id'],
          'name': asset['asset_name'] ?? 'Unknown Asset',
          'type': 'physical',
          'value': (asset['declared_value_myr'] as num?)?.toDouble() ?? 0.0,
          'account_type': asset['account_type'],
          'institution': asset['institution'],
        });
      }

      // Add digital assets
      for (final asset in digitalAssets) {
        allAssets.add({
          'id': asset['id'],
          'name': asset['new_service_platform_name'] ?? 'Unknown Asset',
          'type': 'digital',
          'value': (asset['declared_value_myr'] as num?)?.toDouble() ?? 0.0,
          'account_type': asset['account_type'],
        });
      }

      return allAssets;
    } catch (e) {
      return [];
    }
  }

  /// Generate will document content
  String generateWillDocument(Will will, UserProfile userProfile, List<Map<String, dynamic>> familyMembers, List<Map<String, dynamic>> assets) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('WILL AND TESTAMENT');
    buffer.writeln('==================');
    buffer.writeln();
    
    // Personal Information
    buffer.writeln('I, ${will.nricName ?? userProfile.displayName},');
    buffer.writeln('NRIC: ${userProfile.nricNo ?? 'Not provided'}');
    buffer.writeln('Address: ${_formatAddress(userProfile)}');
    buffer.writeln();
    
    // Declaration
    buffer.writeln('Being of sound mind and memory, do hereby make, publish and declare this to be my Last Will and Testament, hereby revoking all former wills and codicils made by me.');
    buffer.writeln();
    
    // Executors
    if (will.coSampul1 != null || will.coSampul2 != null) {
      buffer.writeln('EXECUTORS:');
      buffer.writeln('I hereby appoint the following person(s) as my executor(s):');
      
      final executors = familyMembers.where((member) => 
        member['id'] == will.coSampul1 || member['id'] == will.coSampul2
      ).toList();
      
      for (final executor in executors) {
        buffer.writeln('- ${executor['name']} (${executor['relationship'] ?? 'Family member'})');
      }
      buffer.writeln();
    }
    
    // Guardians
    if (will.guardian1 != null || will.guardian2 != null) {
      buffer.writeln('GUARDIANS:');
      buffer.writeln('I hereby appoint the following person(s) as guardian(s) for my minor children:');
      
      final guardians = familyMembers.where((member) => 
        member['id'] == will.guardian1 || member['id'] == will.guardian2
      ).toList();
      
      for (final guardian in guardians) {
        buffer.writeln('- ${guardian['name']} (${guardian['relationship'] ?? 'Family member'})');
      }
      buffer.writeln();
    }
    
    // Assets Distribution
    if (assets.isNotEmpty) {
      buffer.writeln('ASSETS DISTRIBUTION:');
      buffer.writeln('I hereby bequeath my assets as follows:');
      buffer.writeln();
      
      final totalValue = assets.fold<double>(0, (sum, asset) => sum + (asset['value'] as num).toDouble());
      
      for (final asset in assets) {
        final value = (asset['value'] as num).toDouble();
        final percentage = totalValue > 0 ? (value / totalValue * 100).toStringAsFixed(1) : '0.0';
        
        buffer.writeln('- ${asset['name']} (${asset['type']}) - RM ${value.toStringAsFixed(2)} ($percentage%)');
      }
      buffer.writeln();
    }
    
    // Beneficiaries
    final beneficiaries = familyMembers.where((member) => 
      member['type'] == 'future_owner' || ((member['percentage'] as num?)?.toDouble() ?? 0) > 0
    ).toList();
    
    if (beneficiaries.isNotEmpty) {
      buffer.writeln('BENEFICIARIES:');
      buffer.writeln('I hereby bequeath my estate to the following beneficiaries:');
      buffer.writeln();
      
      for (final beneficiary in beneficiaries) {
        final percentage = (beneficiary['percentage'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln('- ${beneficiary['name']} (${beneficiary['relationship'] ?? 'Family member'}) - ${percentage.toStringAsFixed(1)}%');
      }
      buffer.writeln();
    }
    
    // Closing
    buffer.writeln('IN WITNESS WHEREOF, I have hereunto set my hand this ${DateTime.now().day} day of ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}.');
    buffer.writeln();
    buffer.writeln('Testator: ${will.nricName ?? userProfile.displayName}');
    buffer.writeln();
    buffer.writeln('Will Code: ${will.willCode}');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    
    return buffer.toString();
  }

  String _formatAddress(UserProfile profile) {
    final parts = <String>[];
    if (profile.address1?.isNotEmpty == true) parts.add(profile.address1!);
    if (profile.address2?.isNotEmpty == true) parts.add(profile.address2!);
    if (profile.city?.isNotEmpty == true) parts.add(profile.city!);
    if (profile.state?.isNotEmpty == true) parts.add(profile.state!);
    if (profile.postcode?.isNotEmpty == true) parts.add(profile.postcode!);
    return parts.join(', ');
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Validate will completeness
  Map<String, dynamic> validateWill(Will will) {
    final issues = <String>[];
    final warnings = <String>[];

    if (will.nricName?.isEmpty ?? true) {
      issues.add('Testator name is required');
    }

    if (will.coSampul1 == null && will.coSampul2 == null) {
      issues.add('At least one executor must be appointed');
    }

    if (will.guardian1 == null && will.guardian2 == null) {
      warnings.add('Consider appointing guardians for minor children');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
    };
  }
}
