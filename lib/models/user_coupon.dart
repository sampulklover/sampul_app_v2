/// Row from `user_coupons` (referral welcome / referrer rewards).
class UserCoupon {
  final String id;
  final String appliesTo;
  final int discountPercent;
  final String status;
  final String source;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;

  const UserCoupon({
    required this.id,
    required this.appliesTo,
    required this.discountPercent,
    required this.status,
    required this.source,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      id: json['id'] as String? ?? '',
      appliesTo: json['applies_to'] as String? ?? '',
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      source: json['source'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isHibah => appliesTo == 'hibah';
  bool get isWasiat => appliesTo == 'wasiat';

  bool get isActive {
    if (status != 'active') return false;
    return expiresAt.isAfter(DateTime.now());
  }

  /// Same formula as chip-create-payment (floor).
  static int discountedTotalCents(int baseCents, int discountPercent) {
    if (discountPercent <= 0) return baseCents;
    return (baseCents * (100 - discountPercent) / 100).floor();
  }
}
