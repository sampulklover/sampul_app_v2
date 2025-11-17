class TrustCharity {
  final int? id;
  final DateTime? createdAt;
  final String? organizationName;
  final String? uuid;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? state;
  final String? country;
  final String? category;
  final String? bank;
  final String? accountNumber;
  final double? donationAmount;
  final String? donationDuration;
  final String? email;
  final String? phoneNo;
  final int? trustId;

  TrustCharity({
    this.id,
    this.createdAt,
    this.organizationName,
    this.uuid,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.state,
    this.country,
    this.category,
    this.bank,
    this.accountNumber,
    this.donationAmount,
    this.donationDuration,
    this.email,
    this.phoneNo,
    this.trustId,
  });

  factory TrustCharity.fromJson(Map<String, dynamic> json) {
    return TrustCharity(
      id: json['id'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      organizationName: json['organization_name'] as String?,
      uuid: json['uuid'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      category: json['category'] as String?,
      bank: json['bank'] as String?,
      accountNumber: json['account_number'] as String?,
      donationAmount: json['donation_amount'] != null
          ? (json['donation_amount'] as num).toDouble()
          : null,
      donationDuration: json['donation_duration'] as String?,
      email: json['email'] as String?,
      phoneNo: json['phone_no'] as String?,
      trustId: json['trust_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (organizationName != null) 'organization_name': organizationName,
      if (uuid != null) 'uuid': uuid,
      if (addressLine1 != null) 'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      if (city != null) 'city': city,
      if (postcode != null) 'postcode': postcode,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (category != null) 'category': category,
      if (bank != null) 'bank': bank,
      if (accountNumber != null) 'account_number': accountNumber,
      if (donationAmount != null) 'donation_amount': donationAmount,
      if (donationDuration != null) 'donation_duration': donationDuration,
      if (email != null) 'email': email,
      if (phoneNo != null) 'phone_no': phoneNo,
      if (trustId != null) 'trust_id': trustId,
    };
  }

  TrustCharity copyWith({
    int? id,
    DateTime? createdAt,
    String? organizationName,
    String? uuid,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? state,
    String? country,
    String? category,
    String? bank,
    String? accountNumber,
    double? donationAmount,
    String? donationDuration,
    String? email,
    String? phoneNo,
    int? trustId,
  }) {
    return TrustCharity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      organizationName: organizationName ?? this.organizationName,
      uuid: uuid ?? this.uuid,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      state: state ?? this.state,
      country: country ?? this.country,
      category: category ?? this.category,
      bank: bank ?? this.bank,
      accountNumber: accountNumber ?? this.accountNumber,
      donationAmount: donationAmount ?? this.donationAmount,
      donationDuration: donationDuration ?? this.donationDuration,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      trustId: trustId ?? this.trustId,
    );
  }
}
