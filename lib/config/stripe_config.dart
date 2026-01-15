library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeConfig {
  static String get publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get merchantDisplayName => dotenv.env['STRIPE_MERCHANT_DISPLAY_NAME'] ?? 'Sampul';
  static String get returnUrlScheme => dotenv.env['STRIPE_RETURN_URL_SCHEME'] ?? 'sampul';

  // Plan price IDs (Stripe Price IDs)
  static String get freePlanPriceId => dotenv.env['STRIPE_PRICE_ID_FREE'] ?? '';
  static String get securePlanPriceId => dotenv.env['STRIPE_PRICE_ID_SECURE'] ?? '';

  // Edge function names
  static const String createCheckoutFunction = 'create-checkout-session';
  static const String billingPortalFunction = 'create-billing-portal';
  static const String subscriptionStatusFunction = 'get-subscription';
  static const String listPlansFunction = 'list-plans';
}

