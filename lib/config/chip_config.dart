library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChipConfig {
  // Edge function names
  static const String createClientFunction = 'chip-create-client';
  static const String createPaymentFunction = 'chip-create-payment';

  // Deep link scheme (same as Stripe)
  static String get returnUrlScheme => dotenv.env['STRIPE_RETURN_URL_SCHEME'] ?? 'sampul';

  // Payment constants
  static const int minTrustAmount = 10000000; // RM 100,000 in cents
  static const int maxTransactionAmount = 3000000; // RM 30,000 in cents
}
