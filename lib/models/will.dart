class Will {
  final int? id;
  final String uuid;
  final String willCode;
  final String? nricName;
  final int? coSampul1;
  final int? coSampul2;
  final int? guardian1;
  final int? guardian2;
  final bool? isDraft;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Will({
    this.id,
    required this.uuid,
    required this.willCode,
    this.nricName,
    this.coSampul1,
    this.coSampul2,
    this.guardian1,
    this.guardian2,
    this.isDraft,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory Will.fromJson(Map<String, dynamic> json) {
    return Will(
      id: json['id'] as int?,
      uuid: json['uuid'] as String,
      willCode: json['will_code'] as String,
      nricName: json['nric_name'] as String?,
      coSampul1: json['co_sampul_1'] as int?,
      coSampul2: json['co_sampul_2'] as int?,
      guardian1: json['guardian_1'] as int?,
      guardian2: json['guardian_2'] as int?,
      isDraft: json['is_draft'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'will_code': willCode,
      'nric_name': nricName,
      'co_sampul_1': coSampul1,
      'co_sampul_2': coSampul2,
      'guardian_1': guardian1,
      'guardian_2': guardian2,
      'is_draft': isDraft,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  Will copyWith({
    int? id,
    String? uuid,
    String? willCode,
    String? nricName,
    int? coSampul1,
    int? coSampul2,
    int? guardian1,
    int? guardian2,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Will(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      willCode: willCode ?? this.willCode,
      nricName: nricName ?? this.nricName,
      coSampul1: coSampul1 ?? this.coSampul1,
      coSampul2: coSampul2 ?? this.coSampul2,
      guardian1: guardian1 ?? this.guardian1,
      guardian2: guardian2 ?? this.guardian2,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper method to check if will is complete
  bool get isComplete {
    return nricName != null && 
           nricName!.isNotEmpty &&
           (coSampul1 != null || coSampul2 != null) &&
           (guardian1 != null || guardian2 != null);
  }

  // Helper method to get status text
  String get statusText {
    if (isDraft == true) {
      return 'Draft';
    } else if (isComplete) {
      return 'Complete';
    } else {
      return 'Incomplete';
    }
  }
}

class WillBeneficiary {
  final int? id;
  final String name;
  final String? nricNo;
  final String? phoneNo;
  final String? email;
  final String relationship;
  final double percentage;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  WillBeneficiary({
    this.id,
    required this.name,
    this.nricNo,
    this.phoneNo,
    this.email,
    required this.relationship,
    required this.percentage,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  factory WillBeneficiary.fromJson(Map<String, dynamic> json) {
    return WillBeneficiary(
      id: json['id'] as int?,
      name: json['name'] as String,
      nricNo: json['nric_no'] as String?,
      phoneNo: json['phone_no'] as String?,
      email: json['email'] as String?,
      relationship: json['relationship'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      address1: json['address_1'] as String?,
      address2: json['address_2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nric_no': nricNo,
      'phone_no': phoneNo,
      'email': email,
      'relationship': relationship,
      'percentage': percentage,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
    };
  }
}

class WillAsset {
  final int? id;
  final String name;
  final String type; // 'physical' or 'digital'
  final double value;
  final String? description;
  final String? location;
  final String? accountNumber;
  final String? institution;
  final String? instructions;

  WillAsset({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    this.description,
    this.location,
    this.accountNumber,
    this.institution,
    this.instructions,
  });

  factory WillAsset.fromJson(Map<String, dynamic> json) {
    return WillAsset(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      description: json['description'] as String?,
      location: json['location'] as String?,
      accountNumber: json['account_number'] as String?,
      institution: json['institution'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'description': description,
      'location': location,
      'account_number': accountNumber,
      'institution': institution,
      'instructions': instructions,
    };
  }
}
