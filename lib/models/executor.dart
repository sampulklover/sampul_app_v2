enum ExecutorStatus { draft, submitted, approved, rejected }

class Executor {
  final int? id;
  final String? executorCode;
  final String? name;
  final String? nricNumber;
  final String? phoneNo;
  final String? email;
  final String? relationshipWithDeceased;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? state;
  final String? country;
  final DateTime updatedAt;
  final DateTime createdAt;
  final ExecutorStatus computedStatus;

  Executor({
    this.id,
    this.executorCode,
    this.name,
    this.nricNumber,
    this.phoneNo,
    this.email,
    this.relationshipWithDeceased,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.state,
    this.country,
    DateTime? updatedAt,
    DateTime? createdAt,
    this.computedStatus = ExecutorStatus.draft,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory Executor.fromJson(Map<String, dynamic> json) {
    final String? rawStatus = (json['status'] ?? json['doc_status']) as String?;
    final ExecutorStatus mapped = _mapStatus(rawStatus);
    return Executor(
      id: (json['id'] as num?)?.toInt(),
      executorCode: json['executor_code'] as String?,
      name: json['name'] as String?,
      nricNumber: json['nric_number'] as String?,
      phoneNo: json['phone_no'] as String?,
      email: json['email'] as String?,
      relationshipWithDeceased: json['relationship_with_deceased'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
              DateTime.now(),
      computedStatus: mapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'executor_code': executorCode,
      'name': name,
      'nric_number': nricNumber,
      'phone_no': phoneNo,
      'email': email,
      'relationship_with_deceased': relationshipWithDeceased,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postcode': postcode,
      'state': state,
      'country': country,
    };
  }
}

ExecutorStatus _mapStatus(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'submitted':
      return ExecutorStatus.submitted;
    case 'approved':
      return ExecutorStatus.approved;
    case 'rejected':
      return ExecutorStatus.rejected;
    case 'draft':
    default:
      return ExecutorStatus.draft;
  }
}

