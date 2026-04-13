library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'wasiat_chip_amount.dart';

class ChipConfig {
  // Edge function names
  static const String createClientFunction = 'chip-create-client';
  static const String createPaymentFunction = 'chip-create-payment';

  /// App URL scheme for post-checkout flows (`.env` key kept for compatibility).
  static String get returnUrlScheme => dotenv.env['STRIPE_RETURN_URL_SCHEME'] ?? 'sampul';

  // Payment constants
  static const int minTrustAmount = 10000000; // RM 100,000 in cents
  static const int maxTransactionAmount = 3000000; // RM 30,000 in cents

  /// Wasiat annual plan: RM 180 (see [kWasiatYearlyAmountCents]).
  static const int wasiatAnnualAmountCents = kWasiatYearlyAmountCents;
}
