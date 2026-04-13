import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/verification.dart';

void main() {
  group('Verification model', () {
    test('fromJson and copyWith preserve fields', () {
      final verification = Verification.fromJson(<String, dynamic>{
        'id': 1,
        'service_name': 'didit',
        'uuid': 'user_1',
        'session_id': 'session_1',
        'status': 'pending',
        'verification_url': 'https://example.com/verify',
        'metadata': <String, dynamic>{'step': 1},
      });

      final updated = verification.copyWith(status: 'verified');

      expect(verification.serviceName, 'didit');
      expect(verification.metadata?['step'], 1);
      expect(updated.status, 'verified');
      expect(updated.sessionId, 'session_1');
    });

    test('completed statuses are treated as completed', () {
      final verified = Verification(
        serviceName: 'didit',
        uuid: 'user_1',
        sessionId: 's1',
        status: 'verified',
      );
      final rejected = Verification(
        serviceName: 'didit',
        uuid: 'user_1',
        sessionId: 's2',
        status: 'rejected',
      );

      expect(verified.isCompleted, true);
      expect(rejected.isCompleted, true);
    });

    test('active status depends on completion and expiry', () {
      final active = Verification(
        serviceName: 'didit',
        uuid: 'user_1',
        sessionId: 's1',
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final expired = Verification(
        serviceName: 'didit',
        uuid: 'user_1',
        sessionId: 's2',
        status: 'pending',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(active.isExpired, false);
      expect(active.isActive, true);
      expect(expired.isExpired, true);
      expect(expired.isActive, false);
    });
  });
}
