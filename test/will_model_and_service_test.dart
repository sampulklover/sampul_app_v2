import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/user_profile.dart';
import 'package:sampul_app_v2/models/will.dart';
import 'package:sampul_app_v2/services/will_service.dart';

void main() {
  group('Will model', () {
    test('isComplete is true when key fields are filled', () {
      final will = Will(
        uuid: 'user_1',
        willCode: 'W123',
        nricName: 'Jane Doe',
        coSampul1: 1,
        guardian1: 2,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        lastUpdated: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(will.isComplete, true);
      expect(will.statusText, 'Complete');
    });

    test('statusText prefers Draft when flagged as draft', () {
      final will = Will(
        uuid: 'user_1',
        willCode: 'W124',
        nricName: 'Jane Doe',
        isDraft: true,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        lastUpdated: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(will.statusText, 'Draft');
      expect(will.isComplete, false);
    });

    test('fromJson and toJson preserve important fields', () {
      final will = Will.fromJson(<String, dynamic>{
        'id': 10,
        'uuid': 'user_10',
        'will_code': 'W9999',
        'nric_name': 'John Doe',
        'co_sampul_1': 11,
        'guardian_1': 22,
        'is_draft': false,
        'created_at': '2026-02-01T00:00:00.000Z',
        'last_updated': '2026-02-02T00:00:00.000Z',
      });

      final json = will.toJson();
      expect(json['id'], 10);
      expect(json['uuid'], 'user_10');
      expect(json['will_code'], 'W9999');
      expect(json['nric_name'], 'John Doe');
      expect(json['co_sampul_1'], 11);
      expect(json['guardian_1'], 22);
      expect(json['is_draft'], false);
    });
  });

  group('WillService helpers', () {
    final service = WillService.instance;
    final profile = UserProfile(
      uuid: 'user_1',
      email: 'john@example.com',
      username: 'johnny',
      nricNo: '900101-01-1234',
      religion: 'islam',
      address1: '123 Main Street',
      city: 'Shah Alam',
      state: 'Selangor',
      postcode: '40100',
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    );

    final will = Will(
      uuid: 'user_1',
      willCode: 'W1234',
      nricName: 'John Testator',
      coSampul1: 1,
      guardian1: 2,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      lastUpdated: DateTime.parse('2026-01-01T00:00:00.000Z'),
    );

    final familyMembers = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'name': 'Amin',
        'relationship': 'Brother',
        'type': 'executor',
        'percentage': 0,
      },
      <String, dynamic>{
        'id': 2,
        'name': 'Sarah',
        'relationship': 'Sister',
        'type': 'guardian',
        'percentage': 0,
      },
      <String, dynamic>{
        'id': 3,
        'name': 'Ali',
        'relationship': 'Son',
        'type': 'future_owner',
        'percentage': '100',
      },
    ];

    final assets = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Maybank Account', 'type': 'digital', 'value': 3000},
      <String, dynamic>{'name': 'Family Home', 'type': 'physical', 'value': '7000'},
    ];

    test('validateWill reports missing required parts', () {
      final invalidWill = Will(
        uuid: 'user_2',
        willCode: 'W0001',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        lastUpdated: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final result = service.validateWill(invalidWill);

      expect(result['isValid'], false);
      expect(result['issues'], contains('Testator name is required'));
      expect(result['issues'], contains('At least one executor must be appointed'));
      expect(
        result['warnings'],
        contains('Consider appointing guardians for minor children'),
      );
    });

    test('validateWill accepts a basic valid will', () {
      final result = service.validateWill(will);

      expect(result['isValid'], true);
      expect(result['issues'], isEmpty);
    });

    test('generateWillDocument builds Muslim wording and includes data', () {
      final document = service.generateWillDocument(
        will,
        profile,
        familyMembers,
        assets,
      );

      expect(document, contains('WASIAT'));
      expect(document, contains('Saya, John Testator,'));
      expect(document, contains('NRIC: 900101-01-1234'));
      expect(document, contains('123 Main Street, Shah Alam, Selangor, 40100'));
      expect(document, contains('Amin (Brother)'));
      expect(document, contains('Sarah (Sister)'));
      expect(document, contains('Maybank Account (digital) - RM 3000.00 (30.0%)'));
      expect(document, contains('Family Home (physical) - RM 7000.00 (70.0%)'));
      expect(document, contains('Ali (Son) - 100.0%'));
      expect(document, contains('Will Code: W1234'));
    });

    test('generateWillDocument can force non-Muslim wording', () {
      final document = service.generateWillDocument(
        will,
        profile,
        familyMembers,
        assets,
        isMuslim: false,
      );

      expect(document, contains('WILL AND TESTAMENT'));
      expect(document, contains('I, John Testator,'));
      expect(
        document,
        contains(
          'Being of sound mind and memory, do hereby make, publish and declare this to be my Last Will and Testament',
        ),
      );
    });
  });
}
