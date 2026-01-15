class ExtraWishes {
  final int? id;
  final String uuid;
  final String? nazarWishes;
  final double? nazarEstimatedCostMyr;
  final int? fidyahFastLeftDays;
  final double? fidyahAmountDueMyr;
  final bool? organDonorPledge;
  // Each entry: { bodies_id: int, amount: double }
  final List<Map<String, dynamic>> waqfBodies;
  final List<Map<String, dynamic>> charityBodies;

  ExtraWishes({
    this.id,
    required this.uuid,
    this.nazarWishes,
    this.nazarEstimatedCostMyr,
    this.fidyahFastLeftDays,
    this.fidyahAmountDueMyr,
    this.organDonorPledge,
    List<Map<String, dynamic>>? waqfBodies,
    List<Map<String, dynamic>>? charityBodies,
  })  : waqfBodies = waqfBodies ?? <Map<String, dynamic>>[],
        charityBodies = charityBodies ?? <Map<String, dynamic>>[];

  factory ExtraWishes.fromJson(Map<String, dynamic> json) {
    return ExtraWishes(
      id: _parseInt(json['id']),
      uuid: (json['uuid'] as String?) ?? '',
      nazarWishes: json['nazar_wishes'] as String?,
      nazarEstimatedCostMyr: _parseDouble(json['nazar_est_cost_myr']),
      fidyahFastLeftDays: _parseInt(json['fidyah_fast_left_days']),
      // Column name in DB is fidyah_amout_due_myr (note: amout typo retained)
      fidyahAmountDueMyr: _parseDouble(json['fidyah_amout_due_myr']),
      organDonorPledge: json['organ_donor_pledge'] as bool?,
      waqfBodies: _normalizeComboList(json['waqf_bodies']),
      charityBodies: _normalizeComboList(json['charity_bodies']),
    );
  }

  /// Helper to safely parse int from dynamic (handles String and num)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper to safely parse double from dynamic (handles String and num)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'nazar_wishes': nazarWishes,
      'nazar_est_cost_myr': nazarEstimatedCostMyr,
      'fidyah_fast_left_days': fidyahFastLeftDays,
      // Keep DB column name with original spelling
      'fidyah_amout_due_myr': fidyahAmountDueMyr,
      'organ_donor_pledge': organDonorPledge,
      'waqf_bodies': waqfBodies,
      'charity_bodies': charityBodies,
    };
  }
}

List<Map<String, dynamic>> _normalizeComboList(dynamic raw) {
  final List<dynamic> list = (raw as List?) ?? const <dynamic>[];
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic it in list) {
    if (it is Map<String, dynamic>) {
      final int? id = _parseIntFromDynamic(it['bodies_id']);
      final double? amount = _parseDoubleFromDynamic(it['amount']);
      if (id != null) {
        out.add(<String, dynamic>{'bodies_id': id, if (amount != null) 'amount': amount});
      }
    } else if (it is List && it.length >= 1) {
      // Fallback if array is like [id, amount]
      final int? id = _parseIntFromDynamic(it[0]);
      final double? amount = it.length > 1 ? _parseDoubleFromDynamic(it[1]) : null;
      if (id != null) {
        out.add(<String, dynamic>{'bodies_id': id, if (amount != null) 'amount': amount});
      }
    } else if (it is num) {
      // Fallback: only id
      out.add(<String, dynamic>{'bodies_id': it.toInt()});
    }
  }
  return out;
}

/// Helper to safely parse int from dynamic (handles String and num)
int? _parseIntFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Helper to safely parse double from dynamic (handles String and num)
double? _parseDoubleFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}



