/// Row from `wasiat_subscription_payments` (CHIP yearly Wasiat).
class WasiatSubscriptionPayment {
  final String id;
  final int amount;
  final String? status;
  final String? chipPaymentId;
  final int? originalAmountCents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WasiatSubscriptionPayment({
    required this.id,
    required this.amount,
    this.status,
    this.chipPaymentId,
    this.originalAmountCents,
    this.createdAt,
    this.updatedAt,
  });

  factory WasiatSubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return WasiatSubscriptionPayment(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      chipPaymentId: json['chip_payment_id'] as String?,
      originalAmountCents: (json['original_amount_cents'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  bool get isSuccessful {
    final String? s = status?.toLowerCase();
    return s != null &&
        <String>['paid', 'settled', 'cleared'].contains(s);
  }

  bool get isFailed {
    final String? s = status?.toLowerCase();
    return s != null &&
        <String>['failed', 'error', 'expired', 'cancelled'].contains(s);
  }
}
