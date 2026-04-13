import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/services/hibah_payment_service.dart';

void main() {
  final service = HibahPaymentService.instance;

  group('HibahPaymentService fee calculations', () {
    test('registration fee uses the first tier for one or fewer assets', () {
      expect(service.calculateRegistrationFeeInCents(0), 250000);
      expect(service.calculateRegistrationFeeInCents(1), 250000);
      expect(service.getRegistrationFeeDescription(1), '1 asset');
    });

    test('registration fee uses the middle tier up to ten assets', () {
      expect(service.calculateRegistrationFeeInCents(2), 850000);
      expect(service.calculateRegistrationFeeInCents(10), 850000);
      expect(service.getRegistrationFeeDescription(10), 'Up to 10 assets');
    });

    test('registration fee adds extra charges above ten assets', () {
      expect(service.calculateRegistrationFeeInCents(11), 900000);
      expect(service.calculateRegistrationFeeInCents(12), 950000);
      expect(
        service.getRegistrationFeeDescription(12),
        '12 assets (RM 8,500 + RM 500 x 2)',
      );
    });

    test('amendment fee scales per amendment', () {
      expect(service.calculateAmendmentFeeInCents(0), 0);
      expect(service.calculateAmendmentFeeInCents(3), 150000);
    });

    test('execution fee includes stamp duty', () {
      expect(
        service.calculateExecutionFeeInCents(100000, stampDutyInCents: 5000),
        55000,
      );
    });

    test('calculatePayment combines all fee parts', () {
      final breakdown = service.calculatePayment(
        assetCount: 12,
        amendmentCount: 2,
        propertyValue: 100000,
        stampDutyInCents: 5000,
      );

      expect(breakdown.assetCount, 12);
      expect(breakdown.registrationFeeInCents, 950000);
      expect(breakdown.amendmentFeeInCents, 100000);
      expect(breakdown.executionFeeInCents, 55000);
      expect(breakdown.stampDutyInCents, 5000);
      expect(breakdown.totalAmountInCents, 1105000);
      expect(breakdown.description, '12 assets (RM 8,500 + RM 500 x 2)');
    });

    test('calculatePayment skips execution fee when property value is zero', () {
      final breakdown = service.calculatePayment(assetCount: 1);

      expect(breakdown.registrationFeeInCents, 250000);
      expect(breakdown.amendmentFeeInCents, 0);
      expect(breakdown.executionFeeInCents, 0);
      expect(breakdown.totalAmountInCents, 250000);
    });
  });
}
