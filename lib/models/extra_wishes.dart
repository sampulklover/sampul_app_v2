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
      id: (json['id'] as num?)?.toInt(),
      uuid: (json['uuid'] as String?) ?? '',
      nazarWishes: json['nazar_wishes'] as String?,
      nazarEstimatedCostMyr: (json['nazar_est_cost_myr'] as num?)?.toDouble(),
      fidyahFastLeftDays: (json['fidyah_fast_left_days'] as num?)?.toInt(),
      // Column name in DB is fidyah_amout_due_myr (note: amout typo retained)
      fidyahAmountDueMyr: (json['fidyah_amout_due_myr'] as num?)?.toDouble(),
      organDonorPledge: json['organ_donor_pledge'] as bool?,
      waqfBodies: _normalizeComboList(json['waqf_bodies']),
      charityBodies: _normalizeComboList(json['charity_bodies']),
    );
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
      final int? id = (it['bodies_id'] as num?)?.toInt();
      final double? amount = (it['amount'] as num?)?.toDouble();
      if (id != null) {
        out.add(<String, dynamic>{'bodies_id': id, if (amount != null) 'amount': amount});
      }
    } else if (it is List && it.length >= 1) {
      // Fallback if array is like [id, amount]
      final int? id = (it[0] as num?)?.toInt();
      final double? amount = it.length > 1 ? (it[1] as num?)?.toDouble() : null;
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



