/// Counts of [future_owner] beneficiaries by Faraid role (deceased = the app user).
///
/// Maps the STMB-style heir grid to how Sampul stores people: one row per person.
/// Extended heirs (grandchildren via son, siblings, etc.) are not modelled in
/// [Relationship] yet; those cases fall back to manual percentage entry.
class FaraidHeirTally {
  final int husbands;
  final int wives;
  final int fathers;
  final int mothers;
  final int sons;
  final int daughters;

  const FaraidHeirTally({
    this.husbands = 0,
    this.wives = 0,
    this.fathers = 0,
    this.mothers = 0,
    this.sons = 0,
    this.daughters = 0,
  });

  bool get hasChildren => sons > 0 || daughters > 0;

  FaraidHeirTally copyWith({
    int? husbands,
    int? wives,
    int? fathers,
    int? mothers,
    int? sons,
    int? daughters,
  }) {
    return FaraidHeirTally(
      husbands: husbands ?? this.husbands,
      wives: wives ?? this.wives,
      fathers: fathers ?? this.fathers,
      mothers: mothers ?? this.mothers,
      sons: sons ?? this.sons,
      daughters: daughters ?? this.daughters,
    );
  }

  /// Merge [relationship] into a copy of this tally (e.g. the row being added).
  FaraidHeirTally withExtraRelationship(String relationship, {required bool deceasedMale}) {
    return _applyRelationship(this, relationship, deceasedMale: deceasedMale, delta: 1);
  }

  static FaraidHeirTally fromRelationshipList(
    Iterable<String?> relationships, {
    required bool deceasedMale,
  }) {
    FaraidHeirTally t = const FaraidHeirTally();
    for (final String? raw in relationships) {
      final String? r = raw?.trim().toLowerCase();
      if (r == null || r.isEmpty) continue;
      t = _applyRelationship(t, r, deceasedMale: deceasedMale, delta: 1);
    }
    return t;
  }

  static FaraidHeirTally _applyRelationship(
    FaraidHeirTally t,
    String relationship, {
    required bool deceasedMale,
    required int delta,
  }) {
    switch (relationship) {
      case 'husband':
        return t.copyWith(husbands: t.husbands + delta);
      case 'wife':
        return t.copyWith(wives: t.wives + delta);
      case 'father':
        return t.copyWith(fathers: t.fathers + delta);
      case 'mother':
        return t.copyWith(mothers: t.mothers + delta);
      case 'son':
        return t.copyWith(sons: t.sons + delta);
      case 'daughter':
        return t.copyWith(daughters: t.daughters + delta);
      case 'spouse':
        return deceasedMale
            ? t.copyWith(wives: t.wives + delta)
            : t.copyWith(husbands: t.husbands + delta);
      default:
        return t;
    }
  }
}

/// Suggested Faraid share for one beneficiary (percentage of estate, 0–100).
///
/// Covers the common Malaysian app pattern: spouse + parents + children, aligned
/// with STMB-style outputs when [sons] ≥ 1, and daughters-only cases with `awl`
/// when fixed shares exceed the estate. Not legal advice; edge cases may need
/// a qualified practitioner.
class FaraidBeneficiaryShare {
  FaraidBeneficiaryShare._();

  /// Returns null if automatic share is not supported for this combination.
  static double? suggestedPercentageForRelationship({
    required String relationship,
    required FaraidHeirTally tally,
    required bool deceasedMale,
  }) {
    final String r = relationship.trim().toLowerCase();
    if (!_isAutoWaris(r)) return null;
    if (!tally.hasChildren) return null;
    if (tally.sons > 0) {
      return _shareWithSonsPresent(r, tally, deceasedMale);
    }
    if (tally.daughters > 0) {
      return _daughtersOnlyPath(r, tally, deceasedMale);
    }
    return null;
  }

  static bool _isAutoWaris(String r) {
    return r == 'husband' ||
        r == 'wife' ||
        r == 'father' ||
        r == 'mother' ||
        r == 'son' ||
        r == 'daughter' ||
        r == 'spouse';
  }

  /// Spouse/parent auto-shares in this helper need at least one child in the tally
  /// (their fixed fractions differ when there are no children, which we do not auto-fill).
  static bool spouseOrParentShareNeedsChildrenFirst(String relationship) {
    switch (relationship.trim().toLowerCase()) {
      case 'wife':
      case 'husband':
      case 'father':
      case 'mother':
      case 'spouse':
      case 'parent':
        return true;
      default:
        return false;
    }
  }

  /// Spouse + parents fixed shares; residue to children 2:1 (male:female).
  static double? _shareWithSonsPresent(
    String r,
    FaraidHeirTally t,
    bool deceasedMale,
  ) {
    final double spouseTotal = _totalSpouseShare(t, deceasedMale);
    final double fatherFixed = t.fathers > 0 ? 1.0 / 6.0 : 0.0;
    final double motherFixed = t.mothers > 0 ? 1.0 / 6.0 : 0.0;
    final double fixedSum = spouseTotal + fatherFixed + motherFixed;
    final double residue = 1.0 - fixedSum;
    if (residue <= 0) return null;

    final double units = 2.0 * t.sons + t.daughters;
    if (units <= 0) return null;

    switch (r) {
      case 'wife':
        if (!deceasedMale || t.wives <= 0) return null;
        return _pct(spouseTotal / t.wives);
      case 'husband':
        if (deceasedMale || t.husbands <= 0) return null;
        return _pct(spouseTotal / t.husbands);
      case 'spouse':
        if (deceasedMale) {
          if (t.wives <= 0) return null;
          return _pct(spouseTotal / t.wives);
        }
        if (t.husbands <= 0) return null;
        return _pct(spouseTotal / t.husbands);
      case 'father':
        if (t.fathers <= 0) return null;
        return _pct(fatherFixed / t.fathers);
      case 'mother':
        if (t.mothers <= 0) return null;
        return _pct(motherFixed / t.mothers);
      case 'son':
        if (t.sons <= 0) return null;
        return _pct((residue * 2.0 / units) / 1.0);
      case 'daughter':
        if (t.daughters <= 0) return null;
        return _pct((residue * 1.0 / units) / 1.0);
      default:
        return null;
    }
  }

  /// Daughters only: spouse + parents + daughter pool (1/2 or 2/3); optional `awl`;
  /// residue to father as asaba when sum &lt; 1.
  static double? _daughtersOnlyPath(String r, FaraidHeirTally t, bool deceasedMale) {
    final double spouseTotal = _totalSpouseShare(t, deceasedMale);
    final double motherF = t.mothers > 0 ? 1.0 / 6.0 : 0.0;
    final double daughterPool = t.daughters == 1 ? 0.5 : (t.daughters >= 2 ? 2.0 / 3.0 : 0.0);
    if (daughterPool <= 0) return null;

    double fatherFurud = t.fathers > 0 ? 1.0 / 6.0 : 0.0;
    double w = spouseTotal;
    double m = motherF;
    double dPool = daughterPool;
    double fFixed = fatherFurud;

    double sum = w + m + dPool + fFixed;
    if (sum > 1.0 + 1e-9) {
      final double scale = 1.0 / sum;
      w *= scale;
      m *= scale;
      dPool *= scale;
      fFixed *= scale;
      sum = 1.0;
    }

    double fatherExtra = 0.0;
    if (sum < 1.0 - 1e-9 && t.fathers > 0) {
      fatherExtra = 1.0 - sum;
      sum = 1.0;
    }

    if (sum < 1.0 - 1e-9) {
      return null;
    }

    final double fatherTotal = t.fathers > 0 ? fFixed + fatherExtra : 0.0;

    switch (r) {
      case 'wife':
        if (!deceasedMale || t.wives <= 0) return null;
        return _pct(w / t.wives);
      case 'husband':
        if (deceasedMale || t.husbands <= 0) return null;
        return _pct(w / t.husbands);
      case 'spouse':
        if (deceasedMale) {
          if (t.wives <= 0) return null;
          return _pct(w / t.wives);
        }
        if (t.husbands <= 0) return null;
        return _pct(w / t.husbands);
      case 'mother':
        if (t.mothers <= 0) return null;
        return _pct(m / t.mothers);
      case 'father':
        if (t.fathers <= 0) return null;
        return _pct(fatherTotal / t.fathers);
      case 'daughter':
        if (t.daughters <= 0) return null;
        return _pct(dPool / t.daughters);
      case 'son':
        return null;
      default:
        return null;
    }
  }

  static double _totalSpouseShare(FaraidHeirTally t, bool deceasedMale) {
    if (deceasedMale) {
      if (t.wives <= 0) return 0.0;
      return t.hasChildren ? 1.0 / 8.0 : 1.0 / 4.0;
    }
    if (t.husbands <= 0) return 0.0;
    return t.hasChildren ? 1.0 / 4.0 : 1.0 / 2.0;
  }

  static double _pct(double fractionOfEstate) {
    if (fractionOfEstate <= 0 || fractionOfEstate.isNaN) return 0;
    final double p = fractionOfEstate * 100.0;
    return double.parse(p.clamp(0.0, 100.0).toStringAsFixed(2));
  }

  /// One [tally] for all beneficiaries, then a suggested % per row (same relationship ⇒ same %).
  /// Rows we cannot calculate are omitted from the map.
  static Map<int, double> suggestedPercentagesForAllBeneficiaries({
    required List<Map<String, dynamic>> futureOwnerRows,
    required bool deceasedMale,
  }) {
    final List<String?> rels = futureOwnerRows
        .map((Map<String, dynamic> e) => e['relationship'] as String?)
        .toList();
    final FaraidHeirTally tally = FaraidHeirTally.fromRelationshipList(rels, deceasedMale: deceasedMale);
    final Map<int, double> out = <int, double>{};
    for (final Map<String, dynamic> row in futureOwnerRows) {
      final int? id = (row['id'] as num?)?.toInt();
      final String? rel = row['relationship'] as String?;
      if (id == null || rel == null || rel.trim().isEmpty) continue;
      final double? p = suggestedPercentageForRelationship(
        relationship: rel,
        tally: tally,
        deceasedMale: deceasedMale,
      );
      if (p != null) {
        out[id] = p;
      }
    }
    return out;
  }
}
