enum TrustStatus { draft, submitted, approved, rejected }

class Trust {
  final int? id;
  final String? trustCode;
  final String? name;
  final String? nricNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? residentStatus;
  final String? nationality;
  final String? phoneNo;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? state;
  final String? country;
  final String? estimatedNetWorth;
  final String? sourceOfFund;
  final String? purposeOfTransaction;
  final String? employerName;
  final String? businessNature;
  final String? businessAddressLine1;
  final String? businessAddressLine2;
  final String? businessCity;
  final String? businessPostcode;
  final String? businessState;
  final String? businessCountry;
  final TrustStatus computedStatus;

  Trust({
    this.id,
    this.trustCode,
    this.name,
    this.nricNumber,
    this.dateOfBirth,
    this.gender,
    this.residentStatus,
    this.nationality,
    this.phoneNo,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.state,
    this.country,
    this.estimatedNetWorth,
    this.sourceOfFund,
    this.purposeOfTransaction,
    this.employerName,
    this.businessNature,
    this.businessAddressLine1,
    this.businessAddressLine2,
    this.businessCity,
    this.businessPostcode,
    this.businessState,
    this.businessCountry,
    this.computedStatus = TrustStatus.draft,
  });

  factory Trust.fromJson(Map<String, dynamic> json) {
    final String? docStatus = json['doc_status'] as String?;
    final TrustStatus mapped = _mapDocStatus(docStatus);
    return Trust(
      id: (json['id'] as num?)?.toInt(),
      trustCode: json['trust_code'] as String?,
      name: json['name'] as String?,
      nricNumber: json['nric_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : json['dob'] != null
              ? DateTime.tryParse(json['dob'] as String)
              : null,
      gender: json['gender'] as String?,
      residentStatus: json['resident_status'] as String?,
      nationality: json['nationality'] as String?,
      phoneNo: json['phone_no'] as String?,
      email: json['email'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      estimatedNetWorth: json['estimated_net_worth'] as String?,
      sourceOfFund: json['source_of_fund'] as String?,
      purposeOfTransaction: json['purpose_of_transaction'] as String?,
      employerName: json['employer_name'] as String?,
      businessNature: json['business_nature'] as String?,
      businessAddressLine1: json['business_address_line_1'] as String?,
      businessAddressLine2: json['business_address_line_2'] as String?,
      businessCity: json['business_city'] as String?,
      businessPostcode: json['business_postcode'] as String?,
      businessState: json['business_state'] as String?,
      businessCountry: json['business_country'] as String?,
      computedStatus: mapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'trust_code': trustCode,
      'name': name,
      'nric_number': nricNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'resident_status': residentStatus,
      'nationality': nationality,
      'phone_no': phoneNo,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postcode': postcode,
      'state': state,
      'country': country,
      'estimated_net_worth': estimatedNetWorth,
      'source_of_fund': sourceOfFund,
      'purpose_of_transaction': purposeOfTransaction,
      'employer_name': employerName,
      'business_nature': businessNature,
      'business_address_line_1': businessAddressLine1,
      'business_address_line_2': businessAddressLine2,
      'business_city': businessCity,
      'business_postcode': businessPostcode,
      'business_state': businessState,
      'business_country': businessCountry,
    };
  }
}

TrustStatus _mapDocStatus(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'submitted':
      return TrustStatus.submitted;
    case 'approved':
      return TrustStatus.approved;
    case 'rejected':
      return TrustStatus.rejected;
    case 'draft':
    default:
      return TrustStatus.draft;
  }
}


