import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/executor.dart';
import 'package:sampul_app_v2/models/trust.dart';
import 'package:sampul_app_v2/models/trust_payment.dart';

void main() {
  group('Trust model', () {
    test('maps status and computes payment progress', () {
      final trust = Trust.fromJson(<String, dynamic>{
        'id': 1,
        'trust_code': 'T-001',
        'name': 'Family Trust',
        'status': 'approved',
        'trust_payments': <Map<String, dynamic>>[
          <String, dynamic>{'amount': 2500000, 'status': 'paid'},
          <String, dynamic>{'amount': 500000, 'status': 'failed'},
          <String, dynamic>{'amount': 1250000, 'status': 'settled'},
        ],
      });

      expect(trust.computedStatus, TrustStatus.approved);
      expect(trust.totalPaidInCents, 3750000);
      expect(trust.remainingInCents, 6250000);
      expect(trust.progressPercentage, 37.5);
    });

    test('toJson omits empty optional collections', () {
      final trust = Trust(
        trustCode: 'T-002',
        name: 'Draft Trust',
        fundSupportCategories: const <String>[],
        fundSupportConfigs: const <String, dynamic>{},
      );

      final json = trust.toJson();
      expect(json.containsKey('fund_support_categories'), false);
      expect(json.containsKey('fund_support_configs'), false);
    });
  });

  group('TrustPayment model', () {
    test('formats amounts and status helpers correctly', () {
      final payment = TrustPayment(
        amount: 12345678,
        status: 'cleared',
      );

      expect(payment.formattedAmount, 'RM 123456.78');
      expect(payment.formattedAmountWithCommas, 'RM 123,456.78');
      expect(payment.isSuccessful, true);
      expect(payment.isFailed, false);
      expect(payment.isPending, false);
    });

    test('recognizes refunded payments', () {
      final payment = TrustPayment(amount: 1000, status: 'refunded');

      expect(payment.isRefunded, true);
      expect(payment.isPending, false);
    });
  });

  group('Executor model', () {
    test('maps fallback doc_status and serializes dates', () {
      final executor = Executor.fromJson(<String, dynamic>{
        'id': 3,
        'executor_code': 'E-001',
        'name': 'Estate Claim',
        'claimant_name': 'Nur',
        'claimant_date_of_birth': '1990-05-01',
        'doc_status': 'submitted',
      });

      final json = executor.toJson();
      expect(executor.computedStatus, ExecutorStatus.submitted);
      expect(json['executor_code'], 'E-001');
      expect(json['claimant_name'], 'Nur');
      expect(json['claimant_date_of_birth'], '1990-05-01');
    });
  });
}
