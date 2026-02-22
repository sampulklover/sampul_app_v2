import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Sampul'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Sampul'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @signInFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed: {error}'**
  String signInFailedWithError(String error);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String unexpectedError(String error);

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled or failed'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String googleSignInFailed(String error);

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @aboutYourWill.
  ///
  /// In en, this message translates to:
  /// **'About Your Will'**
  String get aboutYourWill;

  /// No description provided for @letsCreateYourWill.
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your will'**
  String get letsCreateYourWill;

  /// No description provided for @willDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your profile, family, assets, and wishes together in one clear document.'**
  String get willDescription;

  /// No description provided for @letsListYourDigitalAssets.
  ///
  /// In en, this message translates to:
  /// **'Let\'s list your digital assets'**
  String get letsListYourDigitalAssets;

  /// No description provided for @assetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep important online accounts and platforms in one place so your will stays clear and up to date.'**
  String get assetsDescription;

  /// No description provided for @letsSetUpYourFamilyAccount.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your family account'**
  String get letsSetUpYourFamilyAccount;

  /// No description provided for @trustDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear wishes, for the people you love.'**
  String get trustDescription;

  /// No description provided for @letsPlanYourHibahGifts.
  ///
  /// In en, this message translates to:
  /// **'Let\'s plan your Hibah gifts'**
  String get letsPlanYourHibahGifts;

  /// No description provided for @hibahDescription.
  ///
  /// In en, this message translates to:
  /// **'Decide clearly who should receive your assets as a lifetime gift.'**
  String get hibahDescription;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Put your wealth in\nwriting'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Without a Wasiat, your wealth could end up in the wrong hands. Get it sorted today—fast, legal, and dispute-free.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Do more with Sampul\nTrust'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Lock in your assets, invest for the future, and ensure your loved ones get what\'s rightfully theirs.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Don\'t let emotions\ndecide.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'A professional executor ensures your will is followed—no family drama, no legal mess, just a smooth handover.'**
  String get onboardingSubtitle3;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @malay.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get malay;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @assalamualaikum.
  ///
  /// In en, this message translates to:
  /// **'Assalamualaikum...'**
  String get assalamualaikum;

  /// No description provided for @assalamualaikumWithName.
  ///
  /// In en, this message translates to:
  /// **'Assalamualaikum, {name}'**
  String assalamualaikumWithName(String name);

  /// No description provided for @referrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referrals;

  /// No description provided for @myAssets.
  ///
  /// In en, this message translates to:
  /// **'My Assets'**
  String get myAssets;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All →'**
  String get seeAll;

  /// No description provided for @myFamily.
  ///
  /// In en, this message translates to:
  /// **'My Family'**
  String get myFamily;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @yourPlanIsActive.
  ///
  /// In en, this message translates to:
  /// **'Your plan is active'**
  String get yourPlanIsActive;

  /// No description provided for @familyAccount.
  ///
  /// In en, this message translates to:
  /// **'Family Account'**
  String get familyAccount;

  /// No description provided for @createYourFirstTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Trust Fund'**
  String get createYourFirstTrustFund;

  /// No description provided for @addNewTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Add New Trust Fund'**
  String get addNewTrustFund;

  /// No description provided for @tapToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Tap to get started'**
  String get tapToGetStarted;

  /// No description provided for @will.
  ///
  /// In en, this message translates to:
  /// **'Will'**
  String get will;

  /// No description provided for @hibah.
  ///
  /// In en, this message translates to:
  /// **'Hibah'**
  String get hibah;

  /// No description provided for @trust.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trust;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @execution.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get execution;

  /// No description provided for @aftercare.
  ///
  /// In en, this message translates to:
  /// **'Aftercare'**
  String get aftercare;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @faraid.
  ///
  /// In en, this message translates to:
  /// **'Faraid'**
  String get faraid;

  /// No description provided for @terminateSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Terminate Subscriptions'**
  String get terminateSubscriptions;

  /// No description provided for @transferAsGift.
  ///
  /// In en, this message translates to:
  /// **'Transfer as Gift'**
  String get transferAsGift;

  /// No description provided for @settleDebts.
  ///
  /// In en, this message translates to:
  /// **'Settle Debts'**
  String get settleDebts;

  /// No description provided for @coSampul.
  ///
  /// In en, this message translates to:
  /// **'Co-sampul'**
  String get coSampul;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @guardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardian;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
