enum HibahStatus { draft, submitted, approved, rejected }

class Hibah {
  final int? id;
  final String? hibahCode;
  final String? name;
  final String? nricNumber;
  final DateTime? dateOfBirth;
  final String? phoneNo;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? state;
  final String? country;
  final HibahStatus computedStatus;

  Hibah({
    this.id,
    this.hibahCode,
    this.name,
    this.nricNumber,
    this.dateOfBirth,
    this.phoneNo,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.state,
    this.country,
    this.computedStatus = HibahStatus.draft,
  });

  factory Hibah.fromJson(Map<String, dynamic> json) {
    final String? docStatus = json['doc_status'] as String?; // new document status column (optional)
    final HibahStatus mapped = _mapDocStatus(docStatus);
    return Hibah(
      id: (json['id'] as num?)?.toInt(),
      hibahCode: json['hibah_code'] as String?,
      name: json['name'] as String?,
      nricNumber: json['nric_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      phoneNo: json['phone_no'] as String?,
      email: json['email'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      // Prefer document status if present
      computedStatus: mapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'hibah_code': hibahCode,
      'name': name,
      'nric_number': nricNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'phone_no': phoneNo,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postcode': postcode,
      'state': state,
      'country': country,
    };
  }
}

HibahStatus _mapDocStatus(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'submitted':
      return HibahStatus.submitted;
    case 'approved':
      return HibahStatus.approved;
    case 'rejected':
      return HibahStatus.rejected;
    case 'draft':
    default:
      return HibahStatus.draft;
  }
}


