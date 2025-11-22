enum ExecutorStatus { draft, submitted, approved, rejected }

class Executor {
  final int? id;
  final String? executorCode;
  final String? name;
  final String? deceasedName;
  final String? deceasedNricNumber;
  final DateTime? deceasedDateOfBirth;
  final DateTime? deceasedDateOfDeath;
  final String? relationshipToDeceased;
  final String? claimantName;
  final String? claimantNricNumber;
  final DateTime? claimantDateOfBirth;
  final String? claimantPhoneNo;
  final String? claimantEmail;
  final String? claimantAddressLine1;
  final String? claimantAddressLine2;
  final String? claimantCity;
  final String? claimantPostcode;
  final String? claimantState;
  final String? claimantCountry;
  final String? supportingDocuments;
  final String? additionalNotes;
  final ExecutorStatus computedStatus;

  Executor({
    this.id,
    this.executorCode,
    this.name,
    this.deceasedName,
    this.deceasedNricNumber,
    this.deceasedDateOfBirth,
    this.deceasedDateOfDeath,
    this.relationshipToDeceased,
    this.claimantName,
    this.claimantNricNumber,
    this.claimantDateOfBirth,
    this.claimantPhoneNo,
    this.claimantEmail,
    this.claimantAddressLine1,
    this.claimantAddressLine2,
    this.claimantCity,
    this.claimantPostcode,
    this.claimantState,
    this.claimantCountry,
    this.supportingDocuments,
    this.additionalNotes,
    this.computedStatus = ExecutorStatus.draft,
  });

  factory Executor.fromJson(Map<String, dynamic> json) {
    final String? docStatus = json['doc_status'] as String?;
    final ExecutorStatus mapped = _mapDocStatus(docStatus);
    return Executor(
      id: (json['id'] as num?)?.toInt(),
      executorCode: json['executor_code'] as String?,
      name: json['name'] as String?,
      deceasedName: json['deceased_name'] as String?,
      deceasedNricNumber: json['deceased_nric_number'] as String?,
      deceasedDateOfBirth: json['deceased_date_of_birth'] != null
          ? DateTime.tryParse(json['deceased_date_of_birth'] as String)
          : null,
      deceasedDateOfDeath: json['deceased_date_of_death'] != null
          ? DateTime.tryParse(json['deceased_date_of_death'] as String)
          : null,
      relationshipToDeceased: json['relationship_to_deceased'] as String?,
      claimantName: json['claimant_name'] as String?,
      claimantNricNumber: json['claimant_nric_number'] as String?,
      claimantDateOfBirth: json['claimant_date_of_birth'] != null
          ? DateTime.tryParse(json['claimant_date_of_birth'] as String)
          : null,
      claimantPhoneNo: json['claimant_phone_no'] as String?,
      claimantEmail: json['claimant_email'] as String?,
      claimantAddressLine1: json['claimant_address_line_1'] as String?,
      claimantAddressLine2: json['claimant_address_line_2'] as String?,
      claimantCity: json['claimant_city'] as String?,
      claimantPostcode: json['claimant_postcode'] as String?,
      claimantState: json['claimant_state'] as String?,
      claimantCountry: json['claimant_country'] as String?,
      supportingDocuments: json['supporting_documents'] as String?,
      additionalNotes: json['additional_notes'] as String?,
      computedStatus: mapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'executor_code': executorCode,
      'name': name,
      'deceased_name': deceasedName,
      'deceased_nric_number': deceasedNricNumber,
      'deceased_date_of_birth': deceasedDateOfBirth?.toIso8601String().split('T').first,
      'deceased_date_of_death': deceasedDateOfDeath?.toIso8601String().split('T').first,
      'relationship_to_deceased': relationshipToDeceased,
      'claimant_name': claimantName,
      'claimant_nric_number': claimantNricNumber,
      'claimant_date_of_birth': claimantDateOfBirth?.toIso8601String().split('T').first,
      'claimant_phone_no': claimantPhoneNo,
      'claimant_email': claimantEmail,
      'claimant_address_line_1': claimantAddressLine1,
      'claimant_address_line_2': claimantAddressLine2,
      'claimant_city': claimantCity,
      'claimant_postcode': claimantPostcode,
      'claimant_state': claimantState,
      'claimant_country': claimantCountry,
      'supporting_documents': supportingDocuments,
      'additional_notes': additionalNotes,
    };
  }
}

ExecutorStatus _mapDocStatus(String? s) {
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

