import 'trust_payment.dart';

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
  final List<String>? fundSupportCategories;
  final Map<String, dynamic>? fundSupportConfigs; // Per-category configuration: Map<categoryId, config>
  final String? executorType; // 'someone_i_know' or 'sampul_professional'
  final List<int>? executorIds; // IDs of selected family members when executorType is 'someone_i_know'
  final TrustStatus computedStatus;
  final List<TrustPayment>? trustPayments; // Payment history

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
    this.fundSupportCategories,
    this.fundSupportConfigs,
    this.executorType,
    this.executorIds,
    this.computedStatus = TrustStatus.draft,
    this.trustPayments,
  });

  factory Trust.fromJson(Map<String, dynamic> json) {
    // Prefer new status column, fall back to legacy doc_status
    final String? rawStatus =
        (json['status'] ?? json['doc_status']) as String?;
    final TrustStatus mapped = _mapDocStatus(rawStatus);
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
      fundSupportCategories: json['fund_support_categories'] != null
          ? (json['fund_support_categories'] as List).isNotEmpty
              ? List<String>.from(json['fund_support_categories'] as List)
              : null
          : null,
      fundSupportConfigs: json['fund_support_configs'] != null
          ? Map<String, dynamic>.from(json['fund_support_configs'] as Map)
          : null,
      // Note: executorType and executorIds are stored in trust_executor table, not in trust table
      // These will be loaded separately if needed
      executorType: null,
      executorIds: null,
      computedStatus: mapped,
      trustPayments: json['trust_payments'] != null
          ? (json['trust_payments'] as List)
              .map((e) => TrustPayment.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
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
      if (fundSupportCategories != null && fundSupportCategories!.isNotEmpty)
        'fund_support_categories': fundSupportCategories,
      if (fundSupportConfigs != null && fundSupportConfigs!.isNotEmpty)
        'fund_support_configs': fundSupportConfigs,
      // Note: executorType and executorIds are stored in trust_executor table, not here
    };
  }

  // Calculate total paid amount in cents
  int get totalPaidInCents {
    if (trustPayments == null || trustPayments!.isEmpty) return 0;
    return trustPayments!
        .where((p) => p.isSuccessful)
        .fold(0, (sum, payment) => sum + payment.amount);
  }

  int get requiredFundingInCents {
    final configs = fundSupportConfigs;
    if (configs == null || configs.isEmpty) return 0;

    double totalRm = 0.0;

    for (final entry in configs.entries) {
      final categoryId = entry.key;
      final dynamic raw = entry.value;
      if (raw is! Map) continue;
      final config = Map<String, dynamic>.from(raw);

      // Debt: use captured total debt amount.
      if (categoryId == 'debt') {
        totalRm += (config['debtAmount'] as num?)?.toDouble() ?? 0.0;
        continue;
      }

      // Charitable: sum donation amounts.
      if (categoryId == 'charitable') {
        final charities = config['charities'];
        if (charities is List) {
          for (final c in charities) {
            if (c is! Map) continue;
            final charity = Map<String, dynamic>.from(c);
            final double donationAmount =
                (charity['donation_amount'] as num?)?.toDouble() ??
                (charity['donationAmount'] as num?)?.toDouble() ??
                0.0;
            final int multiplier = _charityAmountMultiplier(charity);
            totalRm += donationAmount * multiplier;
          }
        }
        continue;
      }

      // Regular payments: use the configured paymentAmount (RM).
      final isRegularPayments = config['isRegularPayments'] as bool?;
      if (isRegularPayments == true) {
        totalRm += (config['paymentAmount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Convert RM to cents.
    return (totalRm * 100).round();
  }

  // Calculate remaining amount in cents to reach minimum
  int get remainingInCents {
    final required = requiredFundingInCents;
    final remaining = required - totalPaidInCents;
    return remaining < 0 ? 0 : remaining;
  }

  // Calculate progress percentage (0-100)
  double get progressPercentage {
    final required = requiredFundingInCents;
    if (required <= 0) return 0.0;
    final percentage = (totalPaidInCents / required) * 100;
    return percentage.clamp(0.0, 100.0);
  }
}

int _charityAmountMultiplier(Map<String, dynamic> charity) {
  final String marker = ((charity['address_line_2'] ?? charity['addressLine2']) as String? ?? '')
      .trim()
      .toLowerCase();
  final String orgName = ((charity['organization_name'] ?? charity['organizationName']) as String? ?? '')
      .trim()
      .toLowerCase();
  final bool isSedekahJumaat = marker == 'sedekah_jumaat' || orgName.startsWith('sedekah jumaat');
  if (!isSedekahJumaat) return 1;

  final String yearsRaw =
      ((charity['address_line_1'] ?? charity['addressLine1']) as String? ?? '').trim();
  final RegExpMatch? match = RegExp(r'(\d+)').firstMatch(yearsRaw);
  final int years = int.tryParse(match?.group(1) ?? '') ?? 1;
  return years.clamp(1, 20) * 52;
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


