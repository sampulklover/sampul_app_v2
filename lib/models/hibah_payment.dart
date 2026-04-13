class HibahPayment {
  final String id;
  final String? hibahId;
  final String? userId;
  final int amount;
  final String? status;
  final String? chipPaymentId;
  final String? chipClientId;
  final String? couponCode;
  final String? userCouponId;
  final double discountAmount;
  final double? originalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HibahPayment({
    required this.id,
    required this.amount,
    this.hibahId,
    this.userId,
    this.status,
    this.chipPaymentId,
    this.chipClientId,
    this.couponCode,
    this.userCouponId,
    this.discountAmount = 0,
    this.originalAmount,
    this.createdAt,
    this.updatedAt,
  });

  factory HibahPayment.fromJson(Map<String, dynamic> json) {
    return HibahPayment(
      id: json['id'] as String? ?? '',
      hibahId: json['hibah_id'] as String?,
      userId: json['user_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      chipPaymentId: json['chip_payment_id'] as String?,
      chipClientId: json['chip_client_id'] as String?,
      couponCode: json['coupon_code'] as String?,
      userCouponId: json['user_coupon_id'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      originalAmount: (json['original_amount'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  bool get isSuccessful {
    return status != null &&
        ['paid', 'settled', 'cleared'].contains(status!.toLowerCase());
  }

  bool get isFailed {
    return status != null &&
        ['failed', 'error', 'expired', 'cancelled'].contains(
          status!.toLowerCase(),
        );
  }

  bool get isPending {
    return status != null && !isSuccessful && !isFailed;
  }
}
