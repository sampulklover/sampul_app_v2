import '../controllers/auth_controller.dart';
import '../models/user_coupon.dart';
import 'supabase_service.dart';

class UserCouponService {
  UserCouponService._();
  static final UserCouponService instance = UserCouponService._();

  /// All coupons for the signed-in user, newest first.
  Future<List<UserCoupon>> fetchMine() async {
    final user = AuthController.instance.currentUser;
    if (user == null) return <UserCoupon>[];

    final List<dynamic> rows = await SupabaseService.instance.client
        .from('user_coupons')
        .select(
          'id, applies_to, discount_percent, status, source, expires_at, used_at, created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((dynamic e) => UserCoupon.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  /// Active, non-expired coupons for checkout (`applies_to` is `hibah` or `wasiat`).
  Future<List<UserCoupon>> fetchActiveForProduct(String appliesTo) async {
    final all = await fetchMine();
    final now = DateTime.now();
    return all.where((UserCoupon c) {
      if (c.appliesTo != appliesTo) return false;
      if (c.status != 'active') return false;
      return c.expiresAt.isAfter(now);
    }).toList();
  }
}
