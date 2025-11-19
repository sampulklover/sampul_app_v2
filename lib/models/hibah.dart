enum HibahStatus { draft, pendingReview, underReview, approved, rejected }

HibahStatus hibahStatusFromDb(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'draft':
      return HibahStatus.draft;
    case 'under_review':
      return HibahStatus.underReview;
    case 'approved':
      return HibahStatus.approved;
    case 'rejected':
      return HibahStatus.rejected;
    case 'pending_review':
    default:
      return HibahStatus.pendingReview;
  }
}

String hibahStatusToDb(HibahStatus status) {
  switch (status) {
    case HibahStatus.draft:
      return 'draft';
    case HibahStatus.pendingReview:
      return 'pending_review';
    case HibahStatus.underReview:
      return 'under_review';
    case HibahStatus.approved:
      return 'approved';
    case HibahStatus.rejected:
      return 'rejected';
  }
}

class Hibah {
  final String id;
  final String userId;
  final String certificateId;
  final HibahStatus status;
  final int totalSubmissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? finalAgreement;

  const Hibah({
    required this.id,
    required this.userId,
    required this.certificateId,
    required this.status,
    required this.totalSubmissions,
    required this.createdAt,
    required this.updatedAt,
    this.finalAgreement,
  });

  Hibah copyWith({
    String? id,
    String? userId,
    String? certificateId,
    HibahStatus? status,
    int? totalSubmissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? finalAgreement,
  }) {
    return Hibah(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificateId: certificateId ?? this.certificateId,
      status: status ?? this.status,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finalAgreement: finalAgreement ?? this.finalAgreement,
    );
  }

  factory Hibah.fromJson(Map<String, dynamic> json) {
    return Hibah(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['uuid'] as String? ?? '',
      certificateId: json['certificate_id'] as String? ?? '',
      status: hibahStatusFromDb(json['submission_status'] as String?),
      totalSubmissions: (json['total_submissions'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      finalAgreement: json['final_agreement'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'certificate_id': certificateId,
      'submission_status': hibahStatusToDb(status),
      'total_submissions': totalSubmissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'final_agreement': finalAgreement,
    };
  }
}

class HibahGroup {
  final String id;
  final String hibahId;
  final int hibahIndex;
  final String? assetType;
  final String? registeredTitleNumber;
  final String? propertyLocation;
  final String? estimatedValue;
  final String? loanStatus;
  final String? bankName;
  final String? outstandingLoanAmount;
  final List<String> landCategories;
  final List<HibahBeneficiary> beneficiaries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? propertyName;

  const HibahGroup({
    required this.id,
    required this.hibahId,
    required this.hibahIndex,
    required this.landCategories,
    required this.beneficiaries,
    required this.createdAt,
    required this.updatedAt,
    this.assetType,
    this.registeredTitleNumber,
    this.propertyLocation,
    this.estimatedValue,
    this.loanStatus,
    this.bankName,
    this.outstandingLoanAmount,
    this.propertyName,
  });

  factory HibahGroup.fromJson(Map<String, dynamic> json) {
    return HibahGroup(
      id: json['id'] as String,
      hibahId: json['hibah_id'] as String,
      hibahIndex: (json['hibah_index'] as num?)?.toInt() ?? 0,
      assetType: json['asset_type'] as String?,
      registeredTitleNumber: json['registered_title_number'] as String?,
      propertyLocation: json['property_location'] as String?,
      estimatedValue: json['estimated_value'] as String?,
      loanStatus: json['loan_status'] as String?,
      bankName: json['bank_name'] as String?,
      outstandingLoanAmount: json['outstanding_loan_amount'] as String?,
      landCategories: ((json['land_categories'] as List?) ?? const [])
          .map((dynamic e) => e?.toString() ?? '')
          .where((element) => element.isNotEmpty)
          .toList(),
      beneficiaries: ((json['beneficiaries'] as List?) ?? const [])
          .map(
            (dynamic e) =>
                HibahBeneficiary.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      propertyName: json['property_name'] as String?,
    );
  }
}

class HibahBeneficiary {
  final int? belovedId;
  final String? name;
  final String? relationship;
  final double? sharePercentage;
  final String? notes;

  const HibahBeneficiary({
    this.belovedId,
    this.name,
    this.relationship,
    this.sharePercentage,
    this.notes,
  });

  factory HibahBeneficiary.fromJson(Map<String, dynamic> json) {
    return HibahBeneficiary(
      belovedId: json['beloved_id'] as int?,
      name: json['name'] as String?,
      relationship: json['relationship'] as String?,
      sharePercentage: (json['share_percentage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beloved_id': belovedId,
      'name': name,
      'relationship': relationship,
      'share_percentage': sharePercentage,
      'notes': notes,
    };
  }
}

class HibahDocument {
  final String id;
  final String submissionId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final String documentType;
  final DateTime uploadedAt;
  final String? hibahGroupId;

  const HibahDocument({
    required this.id,
    required this.submissionId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.documentType,
    required this.uploadedAt,
    this.hibahGroupId,
  });

  factory HibahDocument.fromJson(Map<String, dynamic> json) {
    return HibahDocument(
      id: json['id'] as String,
      submissionId: json['submission_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      fileType: json['file_type'] as String,
      documentType: json['document_type'] as String,
      uploadedAt:
          DateTime.tryParse(json['uploaded_at'] as String? ?? '') ??
          DateTime.now(),
      hibahGroupId: json['hibah_group_id'] as String?,
    );
  }
}

class HibahGroupRequest {
  HibahGroupRequest({
    required this.tempId,
    this.propertyName,
    this.assetType,
    this.registeredTitleNumber,
    this.propertyLocation,
    this.estimatedValue,
    this.loanStatus,
    this.bankName,
    this.outstandingLoanAmount,
    List<String>? landCategories,
    List<HibahBeneficiaryRequest>? beneficiaries,
  }) : landCategories = landCategories ?? <String>[],
       beneficiaries = beneficiaries ?? <HibahBeneficiaryRequest>[];

  final String tempId;
  final String? assetType;
  final String? registeredTitleNumber;
  final String? propertyLocation;
  final String? estimatedValue;
  final String? loanStatus;
  final String? bankName;
  final String? outstandingLoanAmount;
  final List<String> landCategories;
  final List<HibahBeneficiaryRequest> beneficiaries;
  final String? propertyName;

  HibahGroupRequest copyWith({
    String? assetType,
    String? registeredTitleNumber,
    String? propertyLocation,
    String? estimatedValue,
    String? loanStatus,
    String? bankName,
    String? outstandingLoanAmount,
    List<String>? landCategories,
    List<HibahBeneficiaryRequest>? beneficiaries,
    String? propertyName,
  }) {
    return HibahGroupRequest(
      tempId: tempId,
      propertyName: propertyName ?? this.propertyName,
      assetType: assetType ?? this.assetType,
      registeredTitleNumber:
          registeredTitleNumber ?? this.registeredTitleNumber,
      propertyLocation: propertyLocation ?? this.propertyLocation,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      loanStatus: loanStatus ?? this.loanStatus,
      bankName: bankName ?? this.bankName,
      outstandingLoanAmount:
          outstandingLoanAmount ?? this.outstandingLoanAmount,
      landCategories: landCategories ?? List<String>.from(this.landCategories),
      beneficiaries:
          beneficiaries ??
          List<HibahBeneficiaryRequest>.from(this.beneficiaries),
    );
  }

  Map<String, dynamic> toInsertMap({
    required String hibahId,
    required int hibahIndex,
  }) {
    return {
      'hibah_id': hibahId,
      'hibah_index': hibahIndex,
      'asset_type': assetType,
      'registered_title_number': registeredTitleNumber,
      'property_location': propertyLocation,
      'estimated_value': estimatedValue,
      'loan_status': loanStatus,
      'bank_name': bankName,
      'outstanding_loan_amount': outstandingLoanAmount,
      'land_categories': landCategories,
      'beneficiaries': beneficiaries.map((e) => e.toJson()).toList(),
      'property_name': propertyName,
    };
  }
}

class HibahBeneficiaryRequest {
  HibahBeneficiaryRequest({
    this.belovedId,
    required this.name,
    this.relationship,
    this.sharePercentage,
    this.notes,
  });

  final int? belovedId;
  final String name;
  final String? relationship;
  final double? sharePercentage;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'beloved_id': belovedId,
      'name': name,
      'relationship': relationship,
      'share_percentage': sharePercentage,
      'notes': notes,
    };
  }
}

class HibahDocumentRequest {
  HibahDocumentRequest({
    required this.documentType,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    this.groupTempId,
  });

  final String documentType;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final String? groupTempId;

  Map<String, dynamic> toInsertMap({
    required String submissionId,
    String? hibahGroupId,
  }) {
    return {
      'submission_id': submissionId,
      'hibah_group_id': hibahGroupId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'document_type': documentType,
    };
  }
}
