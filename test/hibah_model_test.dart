import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/hibah.dart';

void main() {
  group('hibahStatusFromDb', () {
    test('maps known database values', () {
      expect(hibahStatusFromDb('draft'), HibahStatus.draft);
      expect(hibahStatusFromDb('submitted'), HibahStatus.pendingReview);
      expect(hibahStatusFromDb('pending_review'), HibahStatus.pendingReview);
      expect(hibahStatusFromDb('under_review'), HibahStatus.underReview);
      expect(hibahStatusFromDb('approved'), HibahStatus.approved);
      expect(hibahStatusFromDb('rejected'), HibahStatus.rejected);
    });

    test('defaults to pendingReview on unknown/null', () {
      expect(hibahStatusFromDb(null), HibahStatus.pendingReview);
      expect(hibahStatusFromDb(''), HibahStatus.pendingReview);
      expect(hibahStatusFromDb('something_else'), HibahStatus.pendingReview);
    });
  });

  group('hibahStatusToDb', () {
    test('maps to expected database values', () {
      expect(hibahStatusToDb(HibahStatus.draft), 'draft');
      expect(hibahStatusToDb(HibahStatus.pendingReview), 'submitted');
      expect(hibahStatusToDb(HibahStatus.underReview), 'under_review');
      expect(hibahStatusToDb(HibahStatus.approved), 'approved');
      expect(hibahStatusToDb(HibahStatus.rejected), 'rejected');
    });
  });

  group('Hibah', () {
    test('fromJson uses fallbacks and parses dates', () {
      final hibah = Hibah.fromJson(<String, dynamic>{
        'id': 'h_1',
        'uuid': 'user_1',
        'certificate_id': 'cert_1',
        'submission_status': 'under_review',
        'total_submissions': 2,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
        'final_agreement': <String, dynamic>{'ok': true},
      });

      expect(hibah.id, 'h_1');
      expect(hibah.userId, 'user_1');
      expect(hibah.certificateId, 'cert_1');
      expect(hibah.status, HibahStatus.underReview);
      expect(hibah.totalSubmissions, 2);
      expect(hibah.createdAt.toUtc().toIso8601String(), '2026-01-01T00:00:00.000Z');
      expect(hibah.updatedAt.toUtc().toIso8601String(), '2026-01-02T00:00:00.000Z');
      expect(hibah.finalAgreement?['ok'], true);
    });

    test('toJson round-trips key fields', () {
      final hibah = Hibah(
        id: 'h_2',
        userId: 'user_2',
        certificateId: 'cert_2',
        status: HibahStatus.approved,
        totalSubmissions: 1,
        createdAt: DateTime.parse('2026-02-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-02-02T10:00:00.000Z'),
        finalAgreement: const <String, dynamic>{'signed': true},
      );

      final json = hibah.toJson();
      expect(json['id'], 'h_2');
      expect(json['user_id'], 'user_2');
      expect(json['certificate_id'], 'cert_2');
      expect(json['status'], 'approved');
      expect(json['total_submissions'], 1);
      expect(json['final_agreement'], const <String, dynamic>{'signed': true});

      final hibah2 = Hibah.fromJson(json);
      expect(hibah2.id, hibah.id);
      expect(hibah2.userId, hibah.userId);
      expect(hibah2.certificateId, hibah.certificateId);
      expect(hibah2.status, hibah.status);
      expect(hibah2.totalSubmissions, hibah.totalSubmissions);
    });
  });

  group('HibahGroup.fromJson', () {
    test('parses land_categories and beneficiaries as lists', () {
      final group = HibahGroup.fromJson(<String, dynamic>{
        'id': 'g1',
        'hibah_id': 'h1',
        'hibah_index': 0,
        'land_categories': <dynamic>['A', 'B'],
        'beneficiaries': <dynamic>[
          <String, dynamic>{
            'name': 'Ada',
            'share_percentage': 50,
          },
        ],
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      });

      expect(group.landCategories, <String>['A', 'B']);
      expect(group.beneficiaries, hasLength(1));
      expect(group.beneficiaries.single.name, 'Ada');
      expect(group.beneficiaries.single.sharePercentage, 50);
    });

    test('accepts land_categories and beneficiaries as maps (JSONB quirk)', () {
      final group = HibahGroup.fromJson(<String, dynamic>{
        'id': 'g2',
        'hibah_id': 'h1',
        'hibah_index': 0,
        'land_categories': <String, dynamic>{'0': 'X', '1': 'Y'},
        'beneficiaries': <String, dynamic>{
          'name': 'Bob',
          'relationship': 'spouse',
        },
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      });

      expect(group.landCategories, containsAll(<String>['X', 'Y']));
      expect(group.beneficiaries, hasLength(1));
      expect(group.beneficiaries.single.name, 'Bob');
      expect(group.beneficiaries.single.relationship, 'spouse');
    });
  });
}

