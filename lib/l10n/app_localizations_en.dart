// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sampul';

  @override
  String get login => 'Login';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue to Sampul';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signInFailed => 'Sign in failed. Please try again.';

  @override
  String signInFailedWithError(String error) {
    return 'Sign in failed: $error';
  }

  @override
  String unexpectedError(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get googleSignInCancelled => 'Google sign-in was cancelled or failed';

  @override
  String googleSignInFailed(String error) {
    return 'Google sign-in failed: $error';
  }

  @override
  String get signingIn => 'Signing in…';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get or => 'OR';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get aboutYourWill => 'About Your Will';

  @override
  String get letsCreateYourWill => 'Let\'s create your will';

  @override
  String get willDescription =>
      'Bring your profile, family, assets, and wishes together in one clear document.';

  @override
  String get letsListYourDigitalAssets => 'Let\'s list your digital assets';

  @override
  String get assetsDescription =>
      'Keep important online accounts and platforms in one place so your will stays clear and up to date.';

  @override
  String get letsSetUpYourFamilyAccount => 'Let\'s set up your family account';

  @override
  String get trustDescription => 'Clear wishes, for the people you love.';

  @override
  String get letsPlanYourHibahGifts => 'Let\'s plan your Hibah gifts';

  @override
  String get hibahDescription =>
      'Decide clearly who should receive your assets as a lifetime gift.';

  @override
  String get onboardingTitle1 => 'Put your wealth in\nwriting';

  @override
  String get onboardingSubtitle1 =>
      'Without a Wasiat, your wealth could end up in the wrong hands. Get it sorted today—fast, legal, and dispute-free.';

  @override
  String get onboardingTitle2 => 'Do more with Sampul\nTrust';

  @override
  String get onboardingSubtitle2 =>
      'Lock in your assets, invest for the future, and ensure your loved ones get what\'s rightfully theirs.';

  @override
  String get onboardingTitle3 => 'Don\'t let emotions\ndecide.';

  @override
  String get onboardingSubtitle3 =>
      'A professional executor ensures your will is followed—no family drama, no legal mess, just a smooth handover.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get malay => 'Malay';

  @override
  String get languageChanged => 'Language changed';
}
