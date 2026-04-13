import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/hibah_payment.dart';

void main() {
  group('HibahPayment status helpers', () {
    test('isSuccessful matches paid/settled/cleared (case-insensitive)', () {
      expect(const HibahPayment(id: '1', amount: 100, status: 'paid').isSuccessful, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'SETTLED').isSuccessful, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'Cleared').isSuccessful, true);
    });

    test('isFailed matches failed/error/expired/cancelled (case-insensitive)', () {
      expect(const HibahPayment(id: '1', amount: 100, status: 'failed').isFailed, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'ERROR').isFailed, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'Expired').isFailed, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'cancelled').isFailed, true);
    });

    test('isPending is true when status exists and is neither success nor failed', () {
      expect(const HibahPayment(id: '1', amount: 100, status: 'processing').isPending, true);
      expect(const HibahPayment(id: '1', amount: 100, status: 'paid').isPending, false);
      expect(const HibahPayment(id: '1', amount: 100, status: 'failed').isPending, false);
    });

    test('null status is not successful/failed/pending', () {
      const p = HibahPayment(id: '1', amount: 100, status: null);
      expect(p.isSuccessful, false);
      expect(p.isFailed, false);
      expect(p.isPending, false);
    });
  });

  group('HibahPayment.fromJson', () {
    test('parses fields and dates', () {
      final p = HibahPayment.fromJson(<String, dynamic>{
        'id': 'pay_1',
        'hibah_id': 'hibah_1',
        'user_id': 'user_1',
        'amount': 250000,
        'status': 'paid',
        'chip_payment_id': 'chip_1',
        'chip_client_id': 'client_1',
        'coupon_code': 'SAVE10',
        'discount_amount': 10.5,
        'original_amount': 20.0,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-02T00:00:00.000Z',
      });

      expect(p.id, 'pay_1');
      expect(p.hibahId, 'hibah_1');
      expect(p.userId, 'user_1');
      expect(p.amount, 250000);
      expect(p.status, 'paid');
      expect(p.chipPaymentId, 'chip_1');
      expect(p.chipClientId, 'client_1');
      expect(p.couponCode, 'SAVE10');
      expect(p.discountAmount, 10.5);
      expect(p.originalAmount, 20.0);
      expect(p.createdAt?.toUtc().toIso8601String(), '2026-03-01T00:00:00.000Z');
      expect(p.updatedAt?.toUtc().toIso8601String(), '2026-03-02T00:00:00.000Z');
      expect(p.isSuccessful, true);
    });
  });
}

