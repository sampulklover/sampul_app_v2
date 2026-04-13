import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/extra_wishes.dart';

void main() {
  group('ExtraWishes model', () {
    test('fromJson normalizes mixed body list formats', () {
      final wishes = ExtraWishes.fromJson(<String, dynamic>{
        'id': '1',
        'uuid': 'user_1',
        'nazar_est_cost_myr': '150.5',
        'fidyah_fast_left_days': '3',
        'fidyah_amout_due_myr': 45,
        'waqf_bodies': <dynamic>[
          <String, dynamic>{'bodies_id': '10', 'amount': '20.5'},
          <dynamic>[11, '30'],
          12,
        ],
        'charity_bodies': <dynamic>[
          <String, dynamic>{'bodies_id': 20},
        ],
      });

      expect(wishes.id, 1);
      expect(wishes.nazarEstimatedCostMyr, 150.5);
      expect(wishes.fidyahFastLeftDays, 3);
      expect(wishes.fidyahAmountDueMyr, 45);
      expect(wishes.waqfBodies, <Map<String, dynamic>>[
        <String, dynamic>{'bodies_id': 10, 'amount': 20.5},
        <String, dynamic>{'bodies_id': 11, 'amount': 30.0},
        <String, dynamic>{'bodies_id': 12},
      ]);
      expect(wishes.charityBodies, <Map<String, dynamic>>[
        <String, dynamic>{'bodies_id': 20},
      ]);
    });

    test('toJson keeps database field names', () {
      final wishes = ExtraWishes(
        uuid: 'user_2',
        fidyahAmountDueMyr: 99.9,
        waqfBodies: const <Map<String, dynamic>>[
          <String, dynamic>{'bodies_id': 1, 'amount': 50.0},
        ],
      );

      final json = wishes.toJson();
      expect(json['uuid'], 'user_2');
      expect(json['fidyah_amout_due_myr'], 99.9);
      expect(json['waqf_bodies'], isNotEmpty);
    });
  });
}
