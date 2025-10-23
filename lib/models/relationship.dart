class Relationship {
  final String value;
  final String displayName;
  final bool isWaris;
  final String? description;

  const Relationship({
    required this.value,
    required this.displayName,
    required this.isWaris,
    this.description,
  });

  // Waris relationships based on Islamic inheritance law (Faraid)
  static const List<Relationship> _warisRelationships = [
    Relationship(
      value: 'father',
      displayName: 'Father',
      isWaris: true,
      description: 'Gets 1/6 if deceased has children, 1/6 + residue if deceased has daughters only or is childless',
    ),
    Relationship(
      value: 'mother',
      displayName: 'Mother',
      isWaris: true,
      description: 'Gets 1/3 if deceased is childless, 1/6 if deceased has children',
    ),
    Relationship(
      value: 'husband',
      displayName: 'Husband',
      isWaris: true,
      description: 'Gets 1/2 if deceased is childless, 1/4 if deceased has children',
    ),
    Relationship(
      value: 'wife',
      displayName: 'Wife',
      isWaris: true,
      description: 'Gets 1/4 if deceased is childless, 1/8 if deceased has children',
    ),
    Relationship(
      value: 'son',
      displayName: 'Son',
      isWaris: true,
      description: 'Gets 2:1 ratio with daughter, or residue if only son',
    ),
    Relationship(
      value: 'daughter',
      displayName: 'Daughter',
      isWaris: true,
      description: 'Gets 1/2 if only daughter, 2/3 if daughters only, 1:2 ratio with son',
    ),
  ];

  // Non-waris relationships
  static const List<Relationship> _nonWarisRelationships = [
    Relationship(
      value: 'sibling',
      displayName: 'Sibling',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'grandparent',
      displayName: 'Grandparent',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'grandchild',
      displayName: 'Grandchild',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'uncle',
      displayName: 'Uncle',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'aunt',
      displayName: 'Aunt',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'nephew',
      displayName: 'Nephew',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'niece',
      displayName: 'Niece',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'cousin',
      displayName: 'Cousin',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'friend',
      displayName: 'Friend',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'colleague',
      displayName: 'Colleague',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'acquaintance',
      displayName: 'Acquaintance',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
    Relationship(
      value: 'others',
      displayName: 'Others',
      isWaris: false,
      description: 'Not entitled to inheritance under Faraid',
    ),
  ];

  // Legacy relationships (for backward compatibility with existing data)
  static const List<Relationship> _legacyRelationships = [
    Relationship(
      value: 'parent',
      displayName: 'Parent',
      isWaris: true, // Parents are generally waris, but we'll be more specific in new data
      description: 'Parent relationship (legacy) - consider updating to Father/Mother',
    ),
    Relationship(
      value: 'child',
      displayName: 'Child',
      isWaris: true, // Children are generally waris, but we'll be more specific in new data
      description: 'Child relationship (legacy) - consider updating to Son/Daughter',
    ),
    Relationship(
      value: 'spouse',
      displayName: 'Spouse',
      isWaris: true, // Spouse is generally waris, but we'll be more specific in new data
      description: 'Spouse relationship (legacy) - consider updating to Husband/Wife',
    ),
    Relationship(
      value: 'relative',
      displayName: 'Relative',
      isWaris: false,
      description: 'Relative relationship (legacy)',
    ),
  ];

  static List<Relationship> get allRelationships => [
    ..._warisRelationships,
    ..._nonWarisRelationships,
    ..._legacyRelationships,
  ];

  static List<Relationship> get warisRelationships => _warisRelationships;
  static List<Relationship> get nonWarisRelationships => _nonWarisRelationships;
  static List<Relationship> get legacyRelationships => _legacyRelationships;

  static Relationship? getByValue(String value) {
    try {
      return allRelationships.firstWhere((r) => r.value == value);
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if a relationship is legacy (for migration purposes)
  static bool isLegacyRelationship(String value) {
    return _legacyRelationships.any((r) => r.value == value);
  }

  // Helper method to get suggested modern equivalent for legacy relationships
  static List<Relationship> getSuggestedModernRelationships(String legacyValue) {
    switch (legacyValue) {
      case 'parent':
        return [_warisRelationships[0], _warisRelationships[1]]; // father, mother
      case 'child':
        return [_warisRelationships[4], _warisRelationships[5]]; // son, daughter
      case 'spouse':
        return [_warisRelationships[2], _warisRelationships[3]]; // husband, wife
      case 'relative':
        return _nonWarisRelationships.where((r) => 
          ['uncle', 'aunt', 'nephew', 'niece', 'cousin'].contains(r.value)
        ).toList();
      default:
        return [];
    }
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Relationship && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
