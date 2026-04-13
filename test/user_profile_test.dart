import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/user_profile.dart';

void main() {
  group('UserProfile helpers', () {
    test('displayName prefers username then nricName then email prefix', () {
      final withUsername = UserProfile(
        uuid: '1',
        email: 'user@example.com',
        username: 'jane',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );
      final withNricName = UserProfile(
        uuid: '2',
        email: 'user2@example.com',
        nricName: 'Jane Name',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );
      final fallback = UserProfile(
        uuid: '3',
        email: 'prefix@example.com',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(withUsername.displayName, 'jane');
      expect(withNricName.displayName, 'Jane Name');
      expect(fallback.displayName, 'prefix');
    });

    test('isMuslim only returns true for islam', () {
      final muslim = UserProfile(
        uuid: '1',
        email: 'muslim@example.com',
        religion: 'Islam',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );
      final nonMuslim = UserProfile(
        uuid: '2',
        email: 'other@example.com',
        religion: 'christianity',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(muslim.isMuslim, true);
      expect(nonMuslim.isMuslim, false);
    });

    test('toJson formats dob as yyyy-mm-dd', () {
      final profile = UserProfile(
        uuid: '1',
        email: 'user@example.com',
        dob: DateTime.parse('1990-05-01T10:30:00.000Z'),
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(profile.toJson()['dob'], '1990-05-01');
    });
  });
}
