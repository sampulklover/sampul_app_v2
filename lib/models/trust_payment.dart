class TrustPayment {
  final int? id;
  final int? trustId;
  final String? uuid;
  final int amount; // Amount in cents
  final String? status;
  final String? chipPaymentId;
  final String? chipClientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TrustPayment({
    this.id,
    this.trustId,
    this.uuid,
    required this.amount,
    this.status,
    this.chipPaymentId,
    this.chipClientId,
    this.createdAt,
    this.updatedAt,
  });

  factory TrustPayment.fromJson(Map<String, dynamic> json) {
    return TrustPayment(
      id: (json['id'] as num?)?.toInt(),
      trustId: (json['trust_id'] as num?)?.toInt(),
      uuid: json['uuid'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      chipPaymentId: json['chip_payment_id'] as String?,
      chipClientId: json['chip_client_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (trustId != null) 'trust_id': trustId,
      if (uuid != null) 'uuid': uuid,
      'amount': amount,
      if (status != null) 'status': status,
      if (chipPaymentId != null) 'chip_payment_id': chipPaymentId,
      if (chipClientId != null) 'chip_client_id': chipClientId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper method to format amount
  String get formattedAmount {
    final amountInRinggit = amount / 100;
    return 'RM ${amountInRinggit.toStringAsFixed(2)}';
  }

  // Helper method to format amount with commas
  String get formattedAmountWithCommas {
    final amountInRinggit = amount / 100;
    return 'RM ${amountInRinggit.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // Helper method to check if payment is successful
  bool get isSuccessful {
    return status != null && ['paid', 'settled', 'cleared'].contains(status!.toLowerCase());
  }

  // Helper method to check if payment failed
  bool get isFailed {
    return status != null && ['failed', 'error', 'expired', 'cancelled'].contains(status!.toLowerCase());
  }

  // Helper method to check if payment was refunded
  bool get isRefunded {
    return status != null && ['refunded', 'chargeback'].contains(status!.toLowerCase());
  }

  // Helper method to check if payment is pending
  bool get isPending {
    return status != null && !isSuccessful && !isFailed && !isRefunded;
  }
}
