class TrustBeneficiary {
  final int? id;
  final String? name;
  final String? nricPassportNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? residentStatus;
  final String? nationality;
  final String? telephoneMobile;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? stateProvince;
  final String? country;
  final String? phoneNo;
  final String? relationship;
  final int? trustId;
  final int? monthlyDistributionLiving;
  final int? monthlyDistributionEducation;
  final bool? medicalExpenses;
  final bool? educationExpenses;
  final bool? settleOutstanding;
  final bool? investMarket;
  final bool? investUnit;
  final bool? mentallyIncapacitated;

  TrustBeneficiary({
    this.id,
    this.name,
    this.nricPassportNumber,
    this.dateOfBirth,
    this.gender,
    this.residentStatus,
    this.nationality,
    this.telephoneMobile,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.stateProvince,
    this.country,
    this.phoneNo,
    this.relationship,
    this.trustId,
    this.monthlyDistributionLiving,
    this.monthlyDistributionEducation,
    this.medicalExpenses,
    this.educationExpenses,
    this.settleOutstanding,
    this.investMarket,
    this.investUnit,
    this.mentallyIncapacitated,
  });

  factory TrustBeneficiary.fromJson(Map<String, dynamic> json) {
    return TrustBeneficiary(
      id: json['id'] as int?,
      name: json['name'] as String?,
      nricPassportNumber: json['nric_passport_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      residentStatus: json['resident_status'] as String?,
      nationality: json['nationality'] as String?,
      telephoneMobile: json['telephone_mobile'] as String?,
      email: json['email'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      stateProvince: json['state_province'] as String?,
      country: json['country'] as String?,
      phoneNo: json['phone_no'] as String?,
      relationship: json['relationship'] as String?,
      trustId: json['trust_id'] as int?,
      monthlyDistributionLiving: json['monthly_distribution_living'] as int?,
      monthlyDistributionEducation: json['monthly_distribution_education'] as int?,
      medicalExpenses: json['medical_expenses'] as bool?,
      educationExpenses: json['education_expenses'] as bool?,
      settleOutstanding: json['settle_outstanding'] as bool?,
      investMarket: json['invest_market'] as bool?,
      investUnit: json['invest_unit'] as bool?,
      mentallyIncapacitated: json['mentally_incapacitated'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'nric_passport_number': nricPassportNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'resident_status': residentStatus,
      'nationality': nationality,
      'telephone_mobile': telephoneMobile,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postcode': postcode,
      'state_province': stateProvince,
      'country': country,
      'phone_no': phoneNo,
      'relationship': relationship,
      if (trustId != null) 'trust_id': trustId,
      'monthly_distribution_living': monthlyDistributionLiving,
      'monthly_distribution_education': monthlyDistributionEducation,
      'medical_expenses': medicalExpenses,
      'education_expenses': educationExpenses,
      'settle_outstanding': settleOutstanding,
      'invest_market': investMarket,
      'invest_unit': investUnit,
      'mentally_incapacitated': mentallyIncapacitated,
    };
  }

  TrustBeneficiary copyWith({
    int? id,
    String? name,
    String? nricPassportNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? residentStatus,
    String? nationality,
    String? telephoneMobile,
    String? email,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? stateProvince,
    String? country,
    String? phoneNo,
    String? relationship,
    int? trustId,
    int? monthlyDistributionLiving,
    int? monthlyDistributionEducation,
    bool? medicalExpenses,
    bool? educationExpenses,
    bool? settleOutstanding,
    bool? investMarket,
    bool? investUnit,
    bool? mentallyIncapacitated,
  }) {
    return TrustBeneficiary(
      id: id ?? this.id,
      name: name ?? this.name,
      nricPassportNumber: nricPassportNumber ?? this.nricPassportNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      residentStatus: residentStatus ?? this.residentStatus,
      nationality: nationality ?? this.nationality,
      telephoneMobile: telephoneMobile ?? this.telephoneMobile,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      stateProvince: stateProvince ?? this.stateProvince,
      country: country ?? this.country,
      phoneNo: phoneNo ?? this.phoneNo,
      relationship: relationship ?? this.relationship,
      trustId: trustId ?? this.trustId,
      monthlyDistributionLiving: monthlyDistributionLiving ?? this.monthlyDistributionLiving,
      monthlyDistributionEducation: monthlyDistributionEducation ?? this.monthlyDistributionEducation,
      medicalExpenses: medicalExpenses ?? this.medicalExpenses,
      educationExpenses: educationExpenses ?? this.educationExpenses,
      settleOutstanding: settleOutstanding ?? this.settleOutstanding,
      investMarket: investMarket ?? this.investMarket,
      investUnit: investUnit ?? this.investUnit,
      mentallyIncapacitated: mentallyIncapacitated ?? this.mentallyIncapacitated,
    );
  }
}

