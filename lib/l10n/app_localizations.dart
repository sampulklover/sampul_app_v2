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

  /// Home screen header greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sampul'**
  String get welcomeToSampul;

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

  /// No description provided for @appleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was cancelled or failed'**
  String get appleSignInCancelled;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed: {error}'**
  String appleSignInFailed(String error);

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

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

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
  /// **'About Your Wasiat'**
  String get aboutYourWill;

  /// No description provided for @letsCreateYourWill.
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your wasiat'**
  String get letsCreateYourWill;

  /// No description provided for @willDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your profile, family, assets, and wishes together in one clear wasiat document.'**
  String get willDescription;

  /// No description provided for @letsListYourDigitalAssets.
  ///
  /// In en, this message translates to:
  /// **'Organise your assets'**
  String get letsListYourDigitalAssets;

  /// No description provided for @assetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Include your important assets—both digital accounts and physical items—so your instructions are clear and accessible when needed.'**
  String get assetsDescription;

  /// No description provided for @letsSetUpYourFamilyAccount.
  ///
  /// In en, this message translates to:
  /// **'Set up your Family Account'**
  String get letsSetUpYourFamilyAccount;

  /// No description provided for @trustDescription.
  ///
  /// In en, this message translates to:
  /// **'Your wishes, clearly set out for the people you love.'**
  String get trustDescription;

  /// No description provided for @letsPlanYourHibahGifts.
  ///
  /// In en, this message translates to:
  /// **'Plan your Property Trust'**
  String get letsPlanYourHibahGifts;

  /// No description provided for @hibahDescription.
  ///
  /// In en, this message translates to:
  /// **'Decide who receives what—your home, savings, or investments—in one clear place.'**
  String get hibahDescription;

  /// No description provided for @aboutPropertyTrust.
  ///
  /// In en, this message translates to:
  /// **'About Property Trust'**
  String get aboutPropertyTrust;

  /// No description provided for @propertyTrustWhatIs.
  ///
  /// In en, this message translates to:
  /// **'What is a Property Trust?'**
  String get propertyTrustWhatIs;

  /// No description provided for @propertyTrustAboutCopy.
  ///
  /// In en, this message translates to:
  /// **'A Property Trust lets you name who receives specific assets during your lifetime. It\'s based on hibah and works alongside your will and estate plan.'**
  String get propertyTrustAboutCopy;

  /// No description provided for @propertyTrustBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Choose who receives which assets—for example, a home, savings, or investments.'**
  String get propertyTrustBenefit1;

  /// No description provided for @propertyTrustBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Document your wishes clearly so everyone knows your intentions.'**
  String get propertyTrustBenefit2;

  /// No description provided for @propertyTrustBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Works alongside your will and estate plan—lifetime gifts and future plans together.'**
  String get propertyTrustBenefit3;

  /// No description provided for @startPropertyTrust.
  ///
  /// In en, this message translates to:
  /// **'Start setting up'**
  String get startPropertyTrust;

  /// No description provided for @supportingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Supporting documents'**
  String get supportingDocuments;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

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
  /// **'A professional executor helps ensure your wasiat is followed—calm, clear, and structured.'**
  String get onboardingSubtitle3;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

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

  /// No description provided for @homeMoreWithSampul.
  ///
  /// In en, this message translates to:
  /// **'More with Sampul'**
  String get homeMoreWithSampul;

  /// No description provided for @homeFridayFundTitle.
  ///
  /// In en, this message translates to:
  /// **'Friday Sadaqah Fund'**
  String get homeFridayFundTitle;

  /// No description provided for @homeFridayFundDescription.
  ///
  /// In en, this message translates to:
  /// **'Give every Friday, with ongoing reward that continues for you over time.'**
  String get homeFridayFundDescription;

  /// No description provided for @createYourFirstTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Family Account'**
  String get createYourFirstTrustFund;

  /// No description provided for @addNewTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Family Account'**
  String get addNewTrustFund;

  /// No description provided for @tapToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Tap to get started'**
  String get tapToGetStarted;

  /// No description provided for @will.
  ///
  /// In en, this message translates to:
  /// **'Wasiat'**
  String get will;

  /// No description provided for @hibah.
  ///
  /// In en, this message translates to:
  /// **'Property'**
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
  /// **'Executor'**
  String get execution;

  /// No description provided for @pusaka.
  ///
  /// In en, this message translates to:
  /// **'Executor'**
  String get pusaka;

  /// No description provided for @aftercare.
  ///
  /// In en, this message translates to:
  /// **'Aftercare'**
  String get aftercare;

  /// No description provided for @informDeathTitle.
  ///
  /// In en, this message translates to:
  /// **'Inform Death'**
  String get informDeathTitle;

  /// No description provided for @informDeathStartCta.
  ///
  /// In en, this message translates to:
  /// **'Start Inform Death'**
  String get informDeathStartCta;

  /// No description provided for @informDeathMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Inform Death'**
  String get informDeathMenuLabel;

  /// No description provided for @informDeathDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Inform Death record'**
  String get informDeathDeleteDialogTitle;

  /// No description provided for @informDeathDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Inform Death record deleted'**
  String get informDeathDeleteSuccess;

  /// No description provided for @informDeathHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Inform Sampul of a death'**
  String get informDeathHeroTitle;

  /// No description provided for @informDeathHeroBody.
  ///
  /// In en, this message translates to:
  /// **'If someone who uses Sampul has passed away, this page helps you let us know in a calm, structured way.'**
  String get informDeathHeroBody;

  /// No description provided for @informDeathWhatYoullShareTitle.
  ///
  /// In en, this message translates to:
  /// **'What you’ll share'**
  String get informDeathWhatYoullShareTitle;

  /// No description provided for @informDeathWhatYoullShareBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll ask for the Sampul owner’s details and a copy of the death certificate. This helps us confirm the right person and support their family appropriately.'**
  String get informDeathWhatYoullShareBody;

  /// No description provided for @informDeathFeatureOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner’s full name and NRIC (as per NRIC).'**
  String get informDeathFeatureOwner;

  /// No description provided for @informDeathFeatureCertNumber.
  ///
  /// In en, this message translates to:
  /// **'Death certificate number so we can match the document.'**
  String get informDeathFeatureCertNumber;

  /// No description provided for @informDeathFeatureCertImage.
  ///
  /// In en, this message translates to:
  /// **'A clear photo or scan of the death certificate.'**
  String get informDeathFeatureCertImage;

  /// No description provided for @informDeathOwnerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sampul owner’s details'**
  String get informDeathOwnerSectionTitle;

  /// No description provided for @informDeathOwnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name (as per NRIC)'**
  String get informDeathOwnerNameLabel;

  /// No description provided for @informDeathOwnerNricLabel.
  ///
  /// In en, this message translates to:
  /// **'NRIC number'**
  String get informDeathOwnerNricLabel;

  /// No description provided for @informDeathSupportingDocsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supporting documents'**
  String get informDeathSupportingDocsSectionTitle;

  /// No description provided for @informDeathSupportingDocsBody.
  ///
  /// In en, this message translates to:
  /// **'Attach the death certificate so our team can verify the information.'**
  String get informDeathSupportingDocsBody;

  /// No description provided for @informDeathNoFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get informDeathNoFileChosen;

  /// No description provided for @informDeathUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo or scan of the death certificate.'**
  String get informDeathUploadHint;

  /// No description provided for @informDeathChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get informDeathChooseFile;

  /// No description provided for @informDeathCertificateIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Death certificate ID'**
  String get informDeathCertificateIdLabel;

  /// No description provided for @informDeathRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get informDeathRequiredField;

  /// No description provided for @informDeathSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit to Sampul'**
  String get informDeathSubmitCta;

  /// No description provided for @informDeathStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get informDeathStatusDraft;

  /// No description provided for @informDeathStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get informDeathStatusSubmitted;

  /// No description provided for @informDeathStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get informDeathStatusUnderReview;

  /// No description provided for @informDeathStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get informDeathStatusApproved;

  /// No description provided for @informDeathStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get informDeathStatusRejected;

  /// No description provided for @informDeathStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get informDeathStatusUnknown;

  /// No description provided for @informDeathListNric.
  ///
  /// In en, this message translates to:
  /// **'NRIC: {nric}'**
  String informDeathListNric(String nric);

  /// No description provided for @informDeathListCertificateId.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID: {certId}'**
  String informDeathListCertificateId(String certId);

  /// No description provided for @informDeathListSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on: {date}'**
  String informDeathListSubmittedOn(String date);

  /// No description provided for @informDeathInfoBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Need to inform Sampul of a death?'**
  String get informDeathInfoBannerBody;

  /// No description provided for @informDeathInfoBannerCta.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get informDeathInfoBannerCta;

  /// No description provided for @informDeathOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get informDeathOpenFile;

  /// No description provided for @informDeathUnableToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to open file'**
  String get informDeathUnableToOpenFile;

  /// No description provided for @informDeathRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get informDeathRemoveFile;

  /// No description provided for @informDeathRemoveFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove uploaded file?'**
  String get informDeathRemoveFileTitle;

  /// No description provided for @informDeathRemoveFileBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete the uploaded file from this request.'**
  String get informDeathRemoveFileBody;

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
  /// **'Executor'**
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

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @checkingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking status...'**
  String get checkingStatus;

  /// No description provided for @yourIdentityIsVerified.
  ///
  /// In en, this message translates to:
  /// **'Your identity is verified'**
  String get yourIdentityIsVerified;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationInProgress;

  /// No description provided for @verificationWasDeclined.
  ///
  /// In en, this message translates to:
  /// **'Verification was declined'**
  String get verificationWasDeclined;

  /// No description provided for @verificationWasRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification was rejected'**
  String get verificationWasRejected;

  /// No description provided for @verifyYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get verifyYourIdentity;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @plansAndSubscription.
  ///
  /// In en, this message translates to:
  /// **'Plans & subscription'**
  String get plansAndSubscription;

  /// No description provided for @manageYourSampulPlan.
  ///
  /// In en, this message translates to:
  /// **'Manage your Sampul plan'**
  String get manageYourSampulPlan;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @yourCodeAndReferrals.
  ///
  /// In en, this message translates to:
  /// **'Your code and referrals'**
  String get yourCodeAndReferrals;

  /// No description provided for @aiChatSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Settings'**
  String get aiChatSettings;

  /// No description provided for @manageSampulAiResponses.
  ///
  /// In en, this message translates to:
  /// **'Manage Sampul AI responses'**
  String get manageSampulAiResponses;

  /// No description provided for @teamAccess.
  ///
  /// In en, this message translates to:
  /// **'Team access'**
  String get teamAccess;

  /// No description provided for @teamAccessListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Marketing or Admin access'**
  String get teamAccessListSubtitle;

  /// No description provided for @teamAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Set Marketing or Admin for each person with a Sampul account.'**
  String get teamAccessDescription;

  /// No description provided for @teamAccessRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Access level'**
  String get teamAccessRoleLabel;

  /// No description provided for @teamAccessSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or name'**
  String get teamAccessSearchHint;

  /// No description provided for @teamAccessEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No one matches that search. Try a different name or email.'**
  String get teamAccessEmptySearch;

  /// No description provided for @teamAccessTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get teamAccessTryAgain;

  /// No description provided for @teamAccessRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get teamAccessRefreshTooltip;

  /// No description provided for @teamAccessInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Role guide'**
  String get teamAccessInfoTooltip;

  /// No description provided for @teamAccessInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Role guide'**
  String get teamAccessInfoTitle;

  /// No description provided for @teamAccessInfoStandard.
  ///
  /// In en, this message translates to:
  /// **'Regular app use. No access to Team access or content admin tools.'**
  String get teamAccessInfoStandard;

  /// No description provided for @teamAccessInfoMarketing.
  ///
  /// In en, this message translates to:
  /// **'Can manage AI and learning content. Cannot assign roles.'**
  String get teamAccessInfoMarketing;

  /// No description provided for @teamAccessInfoAdmin.
  ///
  /// In en, this message translates to:
  /// **'Full access to Team access, role assignment, and content admin tools.'**
  String get teamAccessInfoAdmin;

  /// No description provided for @teamAccessFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get teamAccessFilterLabel;

  /// No description provided for @teamAccessFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teamAccessFilterAll;

  /// No description provided for @teamAccessLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load the team list. {error}'**
  String teamAccessLoadFailed(String error);

  /// No description provided for @roleStandardUser.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get roleStandardUser;

  /// No description provided for @roleMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get roleMarketing;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @teamRoleSaved.
  ///
  /// In en, this message translates to:
  /// **'Access updated.'**
  String get teamRoleSaved;

  /// No description provided for @teamRoleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t update access. {error}'**
  String teamRoleSaveFailed(String error);

  /// No description provided for @workspaceAccessNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'That area isn’t available with your current sign-in.'**
  String get workspaceAccessNotAvailable;

  /// No description provided for @changeYourAccess.
  ///
  /// In en, this message translates to:
  /// **'Change your access?'**
  String get changeYourAccess;

  /// No description provided for @changeYourAccessAdminHint.
  ///
  /// In en, this message translates to:
  /// **'You’re removing admin access from your own account. You’ll return to Settings after this saves.'**
  String get changeYourAccessAdminHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @restartOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding'**
  String get restartOnboarding;

  /// No description provided for @runTheSetupFlowAgain.
  ///
  /// In en, this message translates to:
  /// **'Run the setup flow again'**
  String get runTheSetupFlowAgain;

  /// No description provided for @onboardingHasBeenReset.
  ///
  /// In en, this message translates to:
  /// **'Onboarding has been reset'**
  String get onboardingHasBeenReset;

  /// No description provided for @failedToResetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset onboarding: {error}'**
  String failedToResetOnboarding(String error);

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @reportBugsOrRequestFeatures.
  ///
  /// In en, this message translates to:
  /// **'Report bugs or request new features'**
  String get reportBugsOrRequestFeatures;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @appVersionDemo.
  ///
  /// In en, this message translates to:
  /// **'1.0.0 (beta)'**
  String get appVersionDemo;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsTappedDemo.
  ///
  /// In en, this message translates to:
  /// **'Terms tapped (demo)'**
  String get termsTappedDemo;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyTappedDemo.
  ///
  /// In en, this message translates to:
  /// **'Privacy tapped (demo)'**
  String get privacyTappedDemo;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @enterCurrentPasswordAndChooseNew.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get enterCurrentPasswordAndChooseNew;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @pleaseConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get pleaseConfirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Updating password...'**
  String get updatingPassword;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @assetAdded.
  ///
  /// In en, this message translates to:
  /// **'Asset added'**
  String get assetAdded;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccessfully;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @areYouSureDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get areYouSureDeleteAccount;

  /// No description provided for @areYouSureYouWantToLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogOut;

  /// No description provided for @toConfirmTypeDelete.
  ///
  /// In en, this message translates to:
  /// **'To confirm, please type \"DELETE\" in the box below:'**
  String get toConfirmTypeDelete;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccountFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Delete account feature coming soon'**
  String get deleteAccountFeatureComingSoon;

  /// No description provided for @creatingVerificationSession.
  ///
  /// In en, this message translates to:
  /// **'Creating verification session...'**
  String get creatingVerificationSession;

  /// No description provided for @couldNotOpenVerificationLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open verification link'**
  String get couldNotOpenVerificationLink;

  /// No description provided for @failedToStartVerification.
  ///
  /// In en, this message translates to:
  /// **'Failed to start verification: {error}'**
  String failedToStartVerification(String error);

  /// No description provided for @diditNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Verification is not configured. Please set DIDIT_CLIENT_ID (API key) and DIDIT_WORKFLOW_ID in your .env file.'**
  String get diditNotConfigured;

  /// No description provided for @identityVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity verification is required to establish trust and ensure the legal validity of your wasiat.'**
  String get identityVerificationRequired;

  /// No description provided for @legalValidity.
  ///
  /// In en, this message translates to:
  /// **'Legal Validity'**
  String get legalValidity;

  /// No description provided for @establishesLegalValidity.
  ///
  /// In en, this message translates to:
  /// **'Establishes the legal validity of your wasiat'**
  String get establishesLegalValidity;

  /// No description provided for @buildsTrust.
  ///
  /// In en, this message translates to:
  /// **'Builds Trust'**
  String get buildsTrust;

  /// No description provided for @providesAssurance.
  ///
  /// In en, this message translates to:
  /// **'Provides assurance to beneficiaries and your executor'**
  String get providesAssurance;

  /// No description provided for @regulatoryCompliance.
  ///
  /// In en, this message translates to:
  /// **'Regulatory Compliance'**
  String get regulatoryCompliance;

  /// No description provided for @ensuresCompliance.
  ///
  /// In en, this message translates to:
  /// **'Ensures compliance with regulatory requirements'**
  String get ensuresCompliance;

  /// No description provided for @fraudProtection.
  ///
  /// In en, this message translates to:
  /// **'Fraud Protection'**
  String get fraudProtection;

  /// No description provided for @protectsAgainstFraud.
  ///
  /// In en, this message translates to:
  /// **'Protects against fraud and identity theft'**
  String get protectsAgainstFraud;

  /// No description provided for @yourInformationIsEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Your information is encrypted and secure'**
  String get yourInformationIsEncrypted;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @youAreAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get youAreAllCaughtUp;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @removeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove notification?'**
  String get removeNotificationTitle;

  /// No description provided for @removeNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the notification from your list.'**
  String get removeNotificationDescription;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @invalidImage.
  ///
  /// In en, this message translates to:
  /// **'Invalid image. Please select a valid image file (max 5MB)'**
  String get invalidImage;

  /// No description provided for @imageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploadedSuccessfully;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(String error);

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @fullNameNric.
  ///
  /// In en, this message translates to:
  /// **'Full Name (NRIC)'**
  String get fullNameNric;

  /// No description provided for @enterYourFullNameAsPerNric.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name as per NRIC'**
  String get enterYourFullNameAsPerNric;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religion;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @addressInformation.
  ///
  /// In en, this message translates to:
  /// **'Address Information'**
  String get addressInformation;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get addressLine2;

  /// No description provided for @enterAdditionalAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter additional address details'**
  String get enterAdditionalAddressDetails;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @enterState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get enterState;

  /// No description provided for @postcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode;

  /// No description provided for @enterPostcode.
  ///
  /// In en, this message translates to:
  /// **'Enter postcode'**
  String get enterPostcode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @myWill.
  ///
  /// In en, this message translates to:
  /// **'My Wasiat'**
  String get myWill;

  /// No description provided for @shareWill.
  ///
  /// In en, this message translates to:
  /// **'Share Wasiat'**
  String get shareWill;

  /// No description provided for @whyCreateYourWillInSampul.
  ///
  /// In en, this message translates to:
  /// **'Why create your wasiat in Sampul?'**
  String get whyCreateYourWillInSampul;

  /// No description provided for @yourWillPullsFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Your wasiat pulls from your profile, family list, digital assets, and extra wishes so everything stays connected.'**
  String get yourWillPullsFromProfile;

  /// No description provided for @keepAllKeyInformation.
  ///
  /// In en, this message translates to:
  /// **'Keep all key information (profile, family, assets) in one place.'**
  String get keepAllKeyInformation;

  /// No description provided for @generateStructuredWillDocument.
  ///
  /// In en, this message translates to:
  /// **'Generate a structured wasiat document you can read, export, and share.'**
  String get generateStructuredWillDocument;

  /// No description provided for @updateWillLater.
  ///
  /// In en, this message translates to:
  /// **'Update your wasiat later whenever your life or assets change.'**
  String get updateWillLater;

  /// No description provided for @startMyWill.
  ///
  /// In en, this message translates to:
  /// **'Start my wasiat'**
  String get startMyWill;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @publishWill.
  ///
  /// In en, this message translates to:
  /// **'Publish Wasiat'**
  String get publishWill;

  /// No description provided for @publishWillConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to publish this wasiat?\n\nOnce published, this wasiat will be accessible to anyone with the share link:\n{url}\n\nMake sure you only share this link with trusted family members or your executor.'**
  String publishWillConfirmation(String url);

  /// No description provided for @shareLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Share link copied to clipboard'**
  String get shareLinkCopiedToClipboard;

  /// No description provided for @willPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Certificate link is on'**
  String get willPublishedSuccessfully;

  /// No description provided for @willUnpublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Certificate link is off'**
  String get willUnpublishedSuccessfully;

  /// No description provided for @wasiatCertificateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get wasiatCertificateDialogTitle;

  /// No description provided for @wasiatCertificateOn.
  ///
  /// In en, this message translates to:
  /// **'Generate certificate'**
  String get wasiatCertificateOn;

  /// No description provided for @wasiatCertificateOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off link'**
  String get wasiatCertificateOff;

  /// No description provided for @wasiatCertificateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your certificate link is ready.\n\nYour full wasiat details stay private with Sampul.'**
  String wasiatCertificateConfirmation(String url);

  /// No description provided for @wasiatCertificateConfirmationPre.
  ///
  /// In en, this message translates to:
  /// **'We’ll create a shareable certificate link.\n\nYour full wasiat details stay private with Sampul.'**
  String get wasiatCertificateConfirmationPre;

  /// No description provided for @wasiatViewCertificateTab.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get wasiatViewCertificateTab;

  /// No description provided for @wasiatViewDetailsTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get wasiatViewDetailsTab;

  /// No description provided for @wasiatDetailsPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Private. Kept with Sampul while your plan is active. Only released with a valid request.'**
  String get wasiatDetailsPrivateNote;

  /// No description provided for @wasiatDetailsLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Details are locked'**
  String get wasiatDetailsLockedTitle;

  /// No description provided for @wasiatDetailsLockedBody.
  ///
  /// In en, this message translates to:
  /// **'To view your full wasiat details, you’ll need an active yearly plan.'**
  String get wasiatDetailsLockedBody;

  /// No description provided for @wasiatUpgradePlanCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get wasiatUpgradePlanCta;

  /// No description provided for @wasiatGeneratedHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Generated versions'**
  String get wasiatGeneratedHistoryTitle;

  /// No description provided for @wasiatGenerateNewVersionCta.
  ///
  /// In en, this message translates to:
  /// **'Generate new version'**
  String get wasiatGenerateNewVersionCta;

  /// No description provided for @wasiatViewingGeneratedVersion.
  ///
  /// In en, this message translates to:
  /// **'Viewing: {date}'**
  String wasiatViewingGeneratedVersion(String date);

  /// No description provided for @wasiatShareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share certificate'**
  String get wasiatShareSheetTitle;

  /// No description provided for @wasiatShareSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share the certificate link. Your details stay private with Sampul.'**
  String get wasiatShareSheetSubtitle;

  /// No description provided for @wasiatShareSheetMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get wasiatShareSheetMore;

  /// No description provided for @wasiatShareSheetWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get wasiatShareSheetWhatsApp;

  /// No description provided for @wasiatShareSheetTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get wasiatShareSheetTelegram;

  /// No description provided for @wasiatShareSheetMessages.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get wasiatShareSheetMessages;

  /// No description provided for @wasiatShareSheetEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get wasiatShareSheetEmail;

  /// No description provided for @failedToPublishWill.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish wasiat: {error}'**
  String failedToPublishWill(String error);

  /// No description provided for @failedToUnpublishWill.
  ///
  /// In en, this message translates to:
  /// **'Failed to unpublish wasiat: {error}'**
  String failedToUnpublishWill(String error);

  /// No description provided for @failedToDeleteWill.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete wasiat: {error}'**
  String failedToDeleteWill(String error);

  /// No description provided for @failedToLoadWillData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wasiat data: {error}'**
  String failedToLoadWillData(String error);

  /// No description provided for @wasiatPublishBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'To turn on your certificate link, you’ll need an active yearly plan.\n\nTap View plans to continue.'**
  String get wasiatPublishBlockedBody;

  /// No description provided for @wasiatPublishBlockedByKyc.
  ///
  /// In en, this message translates to:
  /// **'To generate your certificate, please complete your identity verification first.'**
  String get wasiatPublishBlockedByKyc;

  /// No description provided for @wasiatPublishBlockedByDidit.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your identity verification yet. Please complete verification and try again.'**
  String get wasiatPublishBlockedByDidit;

  /// No description provided for @wasiatPublishVerificationChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Before generating a new certificate version, please complete all required checks.'**
  String get wasiatPublishVerificationChecklistTitle;

  /// No description provided for @wasiatPublishVerificationSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Each new certificate generation needs a fresh identity verification. Start verification to continue.'**
  String get wasiatPublishVerificationSettingsHint;

  /// No description provided for @wasiatEligibilityPlanStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Yearly plan'**
  String get wasiatEligibilityPlanStatusLabel;

  /// No description provided for @wasiatEligibilityDiditKycStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get wasiatEligibilityDiditKycStatusLabel;

  /// No description provided for @wasiatEligibilityKycStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Identity verification (KYC)'**
  String get wasiatEligibilityKycStatusLabel;

  /// No description provided for @wasiatEligibilityDiditStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-authentication for this certificate'**
  String get wasiatEligibilityDiditStatusLabel;

  /// No description provided for @wasiatEligibilityStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get wasiatEligibilityStatusActive;

  /// No description provided for @wasiatEligibilityStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get wasiatEligibilityStatusInactive;

  /// No description provided for @wasiatEligibilityStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get wasiatEligibilityStatusComplete;

  /// No description provided for @wasiatEligibilityStatusNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Not complete'**
  String get wasiatEligibilityStatusNotComplete;

  /// No description provided for @wasiatPublishReadyUntil.
  ///
  /// In en, this message translates to:
  /// **'Plan active until {date}'**
  String wasiatPublishReadyUntil(String date);

  /// No description provided for @wasiatPublishReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Your plan is active.'**
  String get wasiatPublishReadyShort;

  /// No description provided for @wasiatViewPlanAndPay.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get wasiatViewPlanAndPay;

  /// No description provided for @wasiatAccessBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan required to publish'**
  String get wasiatAccessBannerTitle;

  /// No description provided for @wasiatAccessBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A yearly plan is needed.'**
  String get wasiatAccessBannerSubtitle;

  /// No description provided for @wasiatAccessActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String wasiatAccessActiveUntil(String date);

  /// No description provided for @wasiatAccessPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plans'**
  String get wasiatAccessPanelTitle;

  /// No description provided for @plansOverviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Plans, pricing, and payment history.'**
  String get plansOverviewIntro;

  /// No description provided for @planSectionWasiatTitle.
  ///
  /// In en, this message translates to:
  /// **'Wasiat'**
  String get planSectionWasiatTitle;

  /// No description provided for @plansWasiatBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get plansWasiatBadgeActive;

  /// No description provided for @plansWasiatBadgeInactive.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get plansWasiatBadgeInactive;

  /// No description provided for @plansWasiatBadgeEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get plansWasiatBadgeEnded;

  /// No description provided for @planSectionPropertyTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get planSectionPropertyTrustTitle;

  /// No description provided for @planPropertyTrustSummary.
  ///
  /// In en, this message translates to:
  /// **'From RM 2,500 for one asset. Larger bundles start from RM 2,500 with RM 500 per extra asset after 10. You will see the full amount before you pay.'**
  String get planPropertyTrustSummary;

  /// No description provided for @planSectionTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Account'**
  String get planSectionTrustTitle;

  /// No description provided for @planTrustSummary.
  ///
  /// In en, this message translates to:
  /// **'Minimum funding is {amount}. Other fees are shown when you continue in Family Account.'**
  String planTrustSummary(String amount);

  /// No description provided for @plansOpenPropertyTrust.
  ///
  /// In en, this message translates to:
  /// **'Open Property'**
  String get plansOpenPropertyTrust;

  /// No description provided for @plansOpenTrustDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open Family Account'**
  String get plansOpenTrustDashboard;

  /// No description provided for @plansPaymentHistoryForPropertyTrust.
  ///
  /// In en, this message translates to:
  /// **'Property payments'**
  String get plansPaymentHistoryForPropertyTrust;

  /// No description provided for @plansPaymentHistoryForTrust.
  ///
  /// In en, this message translates to:
  /// **'Family Account payments'**
  String get plansPaymentHistoryForTrust;

  /// No description provided for @plansPaymentHistoryEmptyProduct.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get plansPaymentHistoryEmptyProduct;

  /// No description provided for @plansPaymentHistorySubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get plansPaymentHistorySubtitleEmpty;

  /// No description provided for @plansPaymentHistorySubtitleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} payments'**
  String plansPaymentHistorySubtitleCount(int count);

  /// No description provided for @plansPaymentTrustRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Account #{id}'**
  String plansPaymentTrustRefLabel(String id);

  /// No description provided for @plansPaymentCertificateRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get plansPaymentCertificateRefLabel;

  /// No description provided for @plansOverviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your plans. Please try again.'**
  String get plansOverviewLoadError;

  /// No description provided for @plansPaymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get plansPaymentStatusRefunded;

  /// No description provided for @wasiatAccessActiveNoEndDate.
  ///
  /// In en, this message translates to:
  /// **'Access active'**
  String get wasiatAccessActiveNoEndDate;

  /// No description provided for @wasiatAccessInlineInactive.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get wasiatAccessInlineInactive;

  /// No description provided for @wasiatManagePlan.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get wasiatManagePlan;

  /// No description provided for @wasiatPlanHeadline.
  ///
  /// In en, this message translates to:
  /// **'Yearly access'**
  String get wasiatPlanHeadline;

  /// No description provided for @wasiatPlanExplainerShort.
  ///
  /// In en, this message translates to:
  /// **'Annual access. Renew anytime.'**
  String get wasiatPlanExplainerShort;

  /// No description provided for @wasiatPlanEndedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String wasiatPlanEndedOn(String date);

  /// No description provided for @wasiatPlanPayChip.
  ///
  /// In en, this message translates to:
  /// **'Pay with CHIP'**
  String get wasiatPlanPayChip;

  /// No description provided for @wasiatPlanRenewEarly.
  ///
  /// In en, this message translates to:
  /// **'Renew early'**
  String get wasiatPlanRenewEarly;

  /// No description provided for @wasiatPlanPerYearLabel.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get wasiatPlanPerYearLabel;

  /// No description provided for @wasiatPaymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get wasiatPaymentHistoryTitle;

  /// No description provided for @wasiatPaymentHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get wasiatPaymentHistoryEmpty;

  /// No description provided for @wasiatPaymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get wasiatPaymentStatusPaid;

  /// No description provided for @wasiatPaymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get wasiatPaymentStatusFailed;

  /// No description provided for @wasiatPaymentStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get wasiatPaymentStatusProcessing;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @warningsReviewRecommended.
  ///
  /// In en, this message translates to:
  /// **'{count} warning(s) - Review recommended'**
  String warningsReviewRecommended(int count);

  /// No description provided for @issuesActionRequired.
  ///
  /// In en, this message translates to:
  /// **'{count} issue(s) - Action required'**
  String issuesActionRequired(int count);

  /// No description provided for @wasiatReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What to fix'**
  String get wasiatReviewSheetTitle;

  /// No description provided for @wasiatReviewSheetIssues.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get wasiatReviewSheetIssues;

  /// No description provided for @wasiatReviewSheetWarnings.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get wasiatReviewSheetWarnings;

  /// No description provided for @wasiatReviewSheetEditCta.
  ///
  /// In en, this message translates to:
  /// **'Edit wasiat'**
  String get wasiatReviewSheetEditCta;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @deleteWill.
  ///
  /// In en, this message translates to:
  /// **'Delete Wasiat'**
  String get deleteWill;

  /// No description provided for @areYouSureDeleteWill.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your wasiat? This action cannot be undone.'**
  String get areYouSureDeleteWill;

  /// No description provided for @createWill.
  ///
  /// In en, this message translates to:
  /// **'Create Wasiat'**
  String get createWill;

  /// No description provided for @editWill.
  ///
  /// In en, this message translates to:
  /// **'Edit Wasiat'**
  String get editWill;

  /// No description provided for @updateWill.
  ///
  /// In en, this message translates to:
  /// **'Update Wasiat'**
  String get updateWill;

  /// No description provided for @executorsAndGuardians.
  ///
  /// In en, this message translates to:
  /// **'Executor & guardian'**
  String get executorsAndGuardians;

  /// No description provided for @executors.
  ///
  /// In en, this message translates to:
  /// **'Executors'**
  String get executors;

  /// No description provided for @yourExecutor.
  ///
  /// In en, this message translates to:
  /// **'Your executor'**
  String get yourExecutor;

  /// No description provided for @aboutPusaka.
  ///
  /// In en, this message translates to:
  /// **'About executors'**
  String get aboutPusaka;

  /// No description provided for @noPusakaYet.
  ///
  /// In en, this message translates to:
  /// **'No executor yet'**
  String get noPusakaYet;

  /// No description provided for @newToPusaka.
  ///
  /// In en, this message translates to:
  /// **'New to executors?'**
  String get newToPusaka;

  /// No description provided for @submitPusaka.
  ///
  /// In en, this message translates to:
  /// **'Submit executor'**
  String get submitPusaka;

  /// No description provided for @guardians.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get guardians;

  /// No description provided for @yourGuardian.
  ///
  /// In en, this message translates to:
  /// **'Your guardian'**
  String get yourGuardian;

  /// No description provided for @extraWishes.
  ///
  /// In en, this message translates to:
  /// **'Extra Wishes'**
  String get extraWishes;

  /// No description provided for @reviewSave.
  ///
  /// In en, this message translates to:
  /// **'Review & Save'**
  String get reviewSave;

  /// No description provided for @primaryExecutor.
  ///
  /// In en, this message translates to:
  /// **'Primary executor'**
  String get primaryExecutor;

  /// No description provided for @selectPrimaryExecutor.
  ///
  /// In en, this message translates to:
  /// **'Select the primary executor to carry out your will'**
  String get selectPrimaryExecutor;

  /// No description provided for @secondaryExecutor.
  ///
  /// In en, this message translates to:
  /// **'Secondary executor'**
  String get secondaryExecutor;

  /// No description provided for @selectSecondaryExecutor.
  ///
  /// In en, this message translates to:
  /// **'Optional: Select a secondary executor'**
  String get selectSecondaryExecutor;

  /// No description provided for @primaryGuardian.
  ///
  /// In en, this message translates to:
  /// **'Primary Guardian'**
  String get primaryGuardian;

  /// No description provided for @selectPrimaryGuardian.
  ///
  /// In en, this message translates to:
  /// **'Select guardian for minor children (if applicable)'**
  String get selectPrimaryGuardian;

  /// No description provided for @secondaryGuardian.
  ///
  /// In en, this message translates to:
  /// **'Secondary Guardian'**
  String get secondaryGuardian;

  /// No description provided for @selectSecondaryGuardian.
  ///
  /// In en, this message translates to:
  /// **'Optional: Select a secondary guardian'**
  String get selectSecondaryGuardian;

  /// No description provided for @selectFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Select family member'**
  String get selectFamilyMember;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @yourAssets.
  ///
  /// In en, this message translates to:
  /// **'Your Assets'**
  String get yourAssets;

  /// No description provided for @manageAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get manageAll;

  /// No description provided for @noAssetsYet.
  ///
  /// In en, this message translates to:
  /// **'No assets yet. Add one when you\'re ready.'**
  String get noAssetsYet;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more ({count})'**
  String showMore(int count);

  /// No description provided for @yourExtraWishes.
  ///
  /// In en, this message translates to:
  /// **'Your Extra Wishes'**
  String get yourExtraWishes;

  /// No description provided for @noWishesYet.
  ///
  /// In en, this message translates to:
  /// **'No wishes yet. Add your nazar, fidyah, organ donor pledge, and charitable allocations.'**
  String get noWishesYet;

  /// No description provided for @nazarWishes.
  ///
  /// In en, this message translates to:
  /// **'Nazar wishes'**
  String get nazarWishes;

  /// No description provided for @nazarCost.
  ///
  /// In en, this message translates to:
  /// **'Nazar cost'**
  String get nazarCost;

  /// No description provided for @fidyahDays.
  ///
  /// In en, this message translates to:
  /// **'Fidyah days'**
  String get fidyahDays;

  /// No description provided for @fidyahAmount.
  ///
  /// In en, this message translates to:
  /// **'Fidyah amount'**
  String get fidyahAmount;

  /// No description provided for @organDonorPledge.
  ///
  /// In en, this message translates to:
  /// **'Organ donor pledge'**
  String get organDonorPledge;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @waqf.
  ///
  /// In en, this message translates to:
  /// **'Waqf: {count} bodies • RM {total}'**
  String waqf(int count, String total);

  /// No description provided for @charity.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String charity(int count, String total);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nric.
  ///
  /// In en, this message translates to:
  /// **'NRIC'**
  String get nric;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total assets: RM {total}'**
  String totalAssets(String total);

  /// No description provided for @yourWillUpdatesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Your wasiat updates automatically with your profile, assets, and family changes.'**
  String get yourWillUpdatesAutomatically;

  /// No description provided for @willCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wasiat created successfully!'**
  String get willCreatedSuccessfully;

  /// No description provided for @willUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wasiat updated successfully!'**
  String get willUpdatedSuccessfully;

  /// No description provided for @failedToSaveWill.
  ///
  /// In en, this message translates to:
  /// **'Failed to save wasiat: {error}'**
  String failedToSaveWill(String error);

  /// No description provided for @failedToLoadInitialData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load initial data: {error}'**
  String failedToLoadInitialData(String error);

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// No description provided for @aboutAssets.
  ///
  /// In en, this message translates to:
  /// **'About Assets'**
  String get aboutAssets;

  /// No description provided for @platformService.
  ///
  /// In en, this message translates to:
  /// **'Platform / Service'**
  String get platformService;

  /// No description provided for @selectPlatform.
  ///
  /// In en, this message translates to:
  /// **'Select a platform'**
  String get selectPlatform;

  /// No description provided for @chooseDigitalAccountToInclude.
  ///
  /// In en, this message translates to:
  /// **'Choose the digital account you would like to include.'**
  String get chooseDigitalAccountToInclude;

  /// No description provided for @enterPhysicalAssetName.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of your physical asset'**
  String get enterPhysicalAssetName;

  /// No description provided for @physicalAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset name'**
  String get physicalAssetName;

  /// No description provided for @assetInfo.
  ///
  /// In en, this message translates to:
  /// **'Asset info'**
  String get assetInfo;

  /// No description provided for @physicalAssetNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My House, Car, Jewelry Collection'**
  String get physicalAssetNameHint;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewThisDigitalAsset.
  ///
  /// In en, this message translates to:
  /// **'Review this digital asset'**
  String get reviewThisDigitalAsset;

  /// No description provided for @reviewThisAsset.
  ///
  /// In en, this message translates to:
  /// **'Review this asset'**
  String get reviewThisAsset;

  /// No description provided for @searchForPlatformOrService.
  ///
  /// In en, this message translates to:
  /// **'Search for a platform or service'**
  String get searchForPlatformOrService;

  /// No description provided for @searchPlatformHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Facebook, Google Drive, Maybank'**
  String get searchPlatformHint;

  /// No description provided for @addYourOwnAsset.
  ///
  /// In en, this message translates to:
  /// **'Add your own asset'**
  String get addYourOwnAsset;

  /// No description provided for @useAsAssetName.
  ///
  /// In en, this message translates to:
  /// **'Use \"{text}\" as the asset name'**
  String useAsAssetName(String text);

  /// No description provided for @cantFindItAddAsCustom.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Add \"{text}\" as custom'**
  String cantFindItAddAsCustom(String text);

  /// No description provided for @addCustomAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Asset'**
  String get addCustomAsset;

  /// No description provided for @assetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name *'**
  String get assetName;

  /// No description provided for @assetNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Custom Platform'**
  String get assetNameHint;

  /// No description provided for @websiteUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Website URL (optional)'**
  String get websiteUrlOptional;

  /// No description provided for @websiteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get websiteUrlHint;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @declaredValueMyr.
  ///
  /// In en, this message translates to:
  /// **'Declared Value (MYR)'**
  String get declaredValueMyr;

  /// No description provided for @estimatedCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated current value of this asset'**
  String get estimatedCurrentValue;

  /// No description provided for @enterValidAmountMaxDecimals.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get enterValidAmountMaxDecimals;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @instructionsAfterDeath.
  ///
  /// In en, this message translates to:
  /// **'Instructions After Death'**
  String get instructionsAfterDeath;

  /// No description provided for @instructionUponActivation.
  ///
  /// In en, this message translates to:
  /// **'Instruction upon activation'**
  String get instructionUponActivation;

  /// No description provided for @whatShouldHappenToThisAccount.
  ///
  /// In en, this message translates to:
  /// **'What should happen to this asset?'**
  String get whatShouldHappenToThisAccount;

  /// No description provided for @defineHowThisAccountShouldBeHandled.
  ///
  /// In en, this message translates to:
  /// **'Define how this asset should be handled.'**
  String get defineHowThisAccountShouldBeHandled;

  /// No description provided for @closeThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Close this account'**
  String get closeThisAccount;

  /// No description provided for @transferAccessToExecutor.
  ///
  /// In en, this message translates to:
  /// **'Transfer access to my executor'**
  String get transferAccessToExecutor;

  /// No description provided for @memorialiseIfApplicable.
  ///
  /// In en, this message translates to:
  /// **'Memorialise (if applicable)'**
  String get memorialiseIfApplicable;

  /// No description provided for @leaveSpecificInstructions.
  ///
  /// In en, this message translates to:
  /// **'Leave specific instructions'**
  String get leaveSpecificInstructions;

  /// No description provided for @provideDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Provide details below.'**
  String get provideDetailsBelow;

  /// No description provided for @thisInformationOnlyAccessible.
  ///
  /// In en, this message translates to:
  /// **'This information will only be accessible according to your estate instructions.'**
  String get thisInformationOnlyAccessible;

  /// No description provided for @loadingRecipients.
  ///
  /// In en, this message translates to:
  /// **'Loading recipients...'**
  String get loadingRecipients;

  /// No description provided for @giftRecipient.
  ///
  /// In en, this message translates to:
  /// **'Gift Recipient'**
  String get giftRecipient;

  /// No description provided for @giftRecipientRequired.
  ///
  /// In en, this message translates to:
  /// **'Gift Recipient is required'**
  String get giftRecipientRequired;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value (RM)'**
  String get estimatedValue;

  /// No description provided for @estimatedValueDescription.
  ///
  /// In en, this message translates to:
  /// **'An approximate value helps your executor understand the asset\'s worth.'**
  String get estimatedValueDescription;

  /// No description provided for @enterEstimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Enter estimated value (RM)'**
  String get enterEstimatedValue;

  /// No description provided for @estimatedValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 5000.00'**
  String get estimatedValueHint;

  /// No description provided for @remarksOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get remarksOptional;

  /// No description provided for @remarksHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Account location, special instructions, or important details'**
  String get remarksHint;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get additionalNotes;

  /// No description provided for @additionalNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add any extra details that will help your executor handle this asset.'**
  String get additionalNotesDescription;

  /// No description provided for @youMightWantToInclude.
  ///
  /// In en, this message translates to:
  /// **'You might want to include:'**
  String get youMightWantToInclude;

  /// No description provided for @remarksSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Account location or where to find login details'**
  String get remarksSuggestion1;

  /// No description provided for @remarksSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Special instructions or important details'**
  String get remarksSuggestion2;

  /// No description provided for @remarksSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Contact information for account recovery'**
  String get remarksSuggestion3;

  /// No description provided for @remarksSuggestionPhysical1.
  ///
  /// In en, this message translates to:
  /// **'Location or where the asset is kept'**
  String get remarksSuggestionPhysical1;

  /// No description provided for @remarksSuggestionPhysical2.
  ///
  /// In en, this message translates to:
  /// **'Special instructions or important details'**
  String get remarksSuggestionPhysical2;

  /// No description provided for @remarksSuggestionPhysical3.
  ///
  /// In en, this message translates to:
  /// **'Documentation or ownership papers location'**
  String get remarksSuggestionPhysical3;

  /// No description provided for @assetWillBeIncludedInWill.
  ///
  /// In en, this message translates to:
  /// **'This asset will be included in your will. Any changes you make will sync automatically.'**
  String get assetWillBeIncludedInWill;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @pleaseSelectPlatformService.
  ///
  /// In en, this message translates to:
  /// **'Please select a platform/service'**
  String get pleaseSelectPlatformService;

  /// No description provided for @pleaseSelectAssetType.
  ///
  /// In en, this message translates to:
  /// **'Please select an asset type'**
  String get pleaseSelectAssetType;

  /// No description provided for @pleaseSelectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please select an instruction'**
  String get pleaseSelectInstruction;

  /// No description provided for @pleaseSelectGiftRecipient.
  ///
  /// In en, this message translates to:
  /// **'Please select a gift recipient'**
  String get pleaseSelectGiftRecipient;

  /// No description provided for @assetAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Asset added'**
  String get assetAddedSuccessfully;

  /// No description provided for @failedToAddAsset.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String failedToAddAsset(String error);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(String error);

  /// No description provided for @youMustBeSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in'**
  String get youMustBeSignedIn;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @editAsset.
  ///
  /// In en, this message translates to:
  /// **'Edit Asset'**
  String get editAsset;

  /// No description provided for @changesHereUpdateWillAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Changes here update your wasiat automatically.'**
  String get changesHereUpdateWillAutomatically;

  /// No description provided for @assetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Asset updated'**
  String get assetUpdated;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdate(String error);

  /// No description provided for @deleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Delete Asset'**
  String get deleteAsset;

  /// No description provided for @areYouSureDeleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this asset? This can\'t be undone.'**
  String get areYouSureDeleteAsset;

  /// No description provided for @assetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Asset deleted'**
  String get assetDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(String error);

  /// No description provided for @whyAddYourAssets.
  ///
  /// In en, this message translates to:
  /// **'Why this matters'**
  String get whyAddYourAssets;

  /// No description provided for @assetListConnectsToWill.
  ///
  /// In en, this message translates to:
  /// **'Your asset list connects to your will and estate planning. Add both digital and physical assets so your executor knows exactly what to handle.'**
  String get assetListConnectsToWill;

  /// No description provided for @assetType.
  ///
  /// In en, this message translates to:
  /// **'Asset type'**
  String get assetType;

  /// No description provided for @digitalAsset.
  ///
  /// In en, this message translates to:
  /// **'Digital asset'**
  String get digitalAsset;

  /// No description provided for @physicalAsset.
  ///
  /// In en, this message translates to:
  /// **'Physical asset'**
  String get physicalAsset;

  /// No description provided for @selectAssetType.
  ///
  /// In en, this message translates to:
  /// **'Select asset type'**
  String get selectAssetType;

  /// No description provided for @selectAssetCategory.
  ///
  /// In en, this message translates to:
  /// **'What type of asset is this?'**
  String get selectAssetCategory;

  /// No description provided for @whatTypeOfPhysicalAsset.
  ///
  /// In en, this message translates to:
  /// **'What type of physical asset is this?'**
  String get whatTypeOfPhysicalAsset;

  /// No description provided for @land.
  ///
  /// In en, this message translates to:
  /// **'Land (individual or joint title)'**
  String get land;

  /// No description provided for @housesBuildings.
  ///
  /// In en, this message translates to:
  /// **'Houses / buildings'**
  String get housesBuildings;

  /// No description provided for @farmsPlantations.
  ///
  /// In en, this message translates to:
  /// **'Farms, plantations'**
  String get farmsPlantations;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles (car, motorcycle)'**
  String get vehicles;

  /// No description provided for @jewellery.
  ///
  /// In en, this message translates to:
  /// **'Jewellery'**
  String get jewellery;

  /// No description provided for @furnitureHousehold.
  ///
  /// In en, this message translates to:
  /// **'Furniture & household items'**
  String get furnitureHousehold;

  /// No description provided for @financialInstruments.
  ///
  /// In en, this message translates to:
  /// **'Financial instruments (EPF, ASNB, Tabung Haji)'**
  String get financialInstruments;

  /// No description provided for @propertyOrLand.
  ///
  /// In en, this message translates to:
  /// **'Property or land'**
  String get propertyOrLand;

  /// No description provided for @propertyOrLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Land, houses, buildings, farms, plantations'**
  String get propertyOrLandDescription;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @vehicleDescription.
  ///
  /// In en, this message translates to:
  /// **'Cars, motorcycles, boats, other vehicles'**
  String get vehicleDescription;

  /// No description provided for @jewelleryOrValuables.
  ///
  /// In en, this message translates to:
  /// **'Jewellery or valuables'**
  String get jewelleryOrValuables;

  /// No description provided for @jewelleryOrValuablesDescription.
  ///
  /// In en, this message translates to:
  /// **'Jewelry, watches, art, collectibles, furniture, household items'**
  String get jewelleryOrValuablesDescription;

  /// No description provided for @cashOrInvestments.
  ///
  /// In en, this message translates to:
  /// **'Cash or investments'**
  String get cashOrInvestments;

  /// No description provided for @cashOrInvestmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Cash, EPF, ASNB, Tabung Haji, stocks, bonds, other financial instruments'**
  String get cashOrInvestmentsDescription;

  /// No description provided for @otherPhysicalAsset.
  ///
  /// In en, this message translates to:
  /// **'Other physical asset'**
  String get otherPhysicalAsset;

  /// No description provided for @otherPhysicalAssetDescription.
  ///
  /// In en, this message translates to:
  /// **'Any other tangible asset'**
  String get otherPhysicalAssetDescription;

  /// No description provided for @immovableAssetNote.
  ///
  /// In en, this message translates to:
  /// **'Asset type: Property (Immovable asset)'**
  String get immovableAssetNote;

  /// No description provided for @selectLegalClassification.
  ///
  /// In en, this message translates to:
  /// **'Is this a movable or immovable asset?'**
  String get selectLegalClassification;

  /// No description provided for @pleaseSelectLegalClassification.
  ///
  /// In en, this message translates to:
  /// **'Please select whether this is a movable or immovable asset'**
  String get pleaseSelectLegalClassification;

  /// No description provided for @legalClassificationExplanation.
  ///
  /// In en, this message translates to:
  /// **'This helps us process your asset according to Malaysian inheritance law.'**
  String get legalClassificationExplanation;

  /// No description provided for @movableAsset.
  ///
  /// In en, this message translates to:
  /// **'Movable asset'**
  String get movableAsset;

  /// No description provided for @movableAssetExplanation.
  ///
  /// In en, this message translates to:
  /// **'Items you can move or transfer easily, such as vehicles, cash, jewellery, furniture, or financial instruments.'**
  String get movableAssetExplanation;

  /// No description provided for @immovableAsset.
  ///
  /// In en, this message translates to:
  /// **'Immovable asset'**
  String get immovableAsset;

  /// No description provided for @immovableAssetExplanation.
  ///
  /// In en, this message translates to:
  /// **'Property that stays in place, such as land, houses, buildings, farms, or plantations.'**
  String get immovableAssetExplanation;

  /// No description provided for @movableAssetDescription.
  ///
  /// In en, this message translates to:
  /// **'Items you can move or transfer\n• Vehicles\n• Jewelry and valuables\n• Cash and investments\n• Art and collectibles'**
  String get movableAssetDescription;

  /// No description provided for @immovableAssetDescription.
  ///
  /// In en, this message translates to:
  /// **'Property that stays in place\n• Land and property\n• Buildings and structures\n• Real estate'**
  String get immovableAssetDescription;

  /// No description provided for @pleaseSelectAssetCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select an asset type'**
  String get pleaseSelectAssetCategory;

  /// No description provided for @makeItEasyForExecutors.
  ///
  /// In en, this message translates to:
  /// **'Prevent accounts from being lost'**
  String get makeItEasyForExecutors;

  /// No description provided for @linkEachAssetToInstructions.
  ///
  /// In en, this message translates to:
  /// **'Ensure proper closure or transfer'**
  String get linkEachAssetToInstructions;

  /// No description provided for @keepWillUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Avoid unpaid subscriptions'**
  String get keepWillUpToDate;

  /// No description provided for @provideClearInstructionsToExecutor.
  ///
  /// In en, this message translates to:
  /// **'Provide clear instructions to your executor'**
  String get provideClearInstructionsToExecutor;

  /// No description provided for @weDoNotStorePasswords.
  ///
  /// In en, this message translates to:
  /// **'We do not store passwords or login credentials.'**
  String get weDoNotStorePasswords;

  /// No description provided for @addAssetButton.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get addAssetButton;

  /// No description provided for @saveDigitalAsset.
  ///
  /// In en, this message translates to:
  /// **'Save digital asset'**
  String get saveDigitalAsset;

  /// No description provided for @saveAsset.
  ///
  /// In en, this message translates to:
  /// **'Save asset'**
  String get saveAsset;

  /// No description provided for @savePhysicalAsset.
  ///
  /// In en, this message translates to:
  /// **'Save physical asset'**
  String get savePhysicalAsset;

  /// No description provided for @returnToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to dashboard'**
  String get returnToDashboard;

  /// No description provided for @addAnotherDigitalAsset.
  ///
  /// In en, this message translates to:
  /// **'Add another digital asset'**
  String get addAnotherDigitalAsset;

  /// No description provided for @addAnotherAsset.
  ///
  /// In en, this message translates to:
  /// **'Add another asset'**
  String get addAnotherAsset;

  /// No description provided for @yourInstructionRecordedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Your instruction has been recorded securely.'**
  String get yourInstructionRecordedSecurely;

  /// No description provided for @youCanReviewOrUpdateAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can review or update it anytime.'**
  String get youCanReviewOrUpdateAnytime;

  /// No description provided for @passwordsNotStoredInSampul.
  ///
  /// In en, this message translates to:
  /// **'Passwords are not stored in Sampul.'**
  String get passwordsNotStoredInSampul;

  /// No description provided for @cantFindYourPlatform.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your platform?'**
  String get cantFindYourPlatform;

  /// No description provided for @addCustomPlatform.
  ///
  /// In en, this message translates to:
  /// **'Add custom platform'**
  String get addCustomPlatform;

  /// No description provided for @youllProvideInstructionsNextStep.
  ///
  /// In en, this message translates to:
  /// **'You\'ll provide instructions in the next step. We do not store passwords'**
  String get youllProvideInstructionsNextStep;

  /// No description provided for @aboutFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'About Family Members'**
  String get aboutFamilyMembers;

  /// No description provided for @letsAddYourFamily.
  ///
  /// In en, this message translates to:
  /// **'Let\'s add your family'**
  String get letsAddYourFamily;

  /// No description provided for @addPeopleWhoMatterMost.
  ///
  /// In en, this message translates to:
  /// **'Add the people who matter most — executors, beneficiaries, and guardians — so your will stays clear and connected.'**
  String get addPeopleWhoMatterMost;

  /// No description provided for @whyAddFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Why add family members?'**
  String get whyAddFamilyMembers;

  /// No description provided for @familyListConnectsToWill.
  ///
  /// In en, this message translates to:
  /// **'Your family list connects to your will, trust, and Property Trust planning. Add executors, beneficiaries, and guardians.'**
  String get familyListConnectsToWill;

  /// No description provided for @assignExecutorsCoSampul.
  ///
  /// In en, this message translates to:
  /// **'Assign executors who will carry out your will.'**
  String get assignExecutorsCoSampul;

  /// No description provided for @listBeneficiariesWhoReceive.
  ///
  /// In en, this message translates to:
  /// **'List beneficiaries who will receive your assets.'**
  String get listBeneficiariesWhoReceive;

  /// No description provided for @designateGuardiansForMinors.
  ///
  /// In en, this message translates to:
  /// **'Designate guardians for minor children if needed.'**
  String get designateGuardiansForMinors;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addFamilyMember;

  /// No description provided for @waris.
  ///
  /// In en, this message translates to:
  /// **'Waris'**
  String get waris;

  /// No description provided for @nonWaris.
  ///
  /// In en, this message translates to:
  /// **'Non-Waris'**
  String get nonWaris;

  /// No description provided for @legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get legacy;

  /// No description provided for @addFamilyMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMemberTitle;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @pleaseEnterValidName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name'**
  String get pleaseEnterValidName;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @relationshipRequired.
  ///
  /// In en, this message translates to:
  /// **'Relationship is required'**
  String get relationshipRequired;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @coSampulExecutor.
  ///
  /// In en, this message translates to:
  /// **'Executor'**
  String get coSampulExecutor;

  /// No description provided for @coSampulExecutorHelp.
  ///
  /// In en, this message translates to:
  /// **'Executor: Someone you trust who carries out your will together with Sampul.'**
  String get coSampulExecutorHelp;

  /// No description provided for @beneficiaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary: A person who will inherit your selected assets.'**
  String get beneficiaryHelp;

  /// No description provided for @guardianHelp.
  ///
  /// In en, this message translates to:
  /// **'Guardian: A person responsible for the care of your dependents or minors.'**
  String get guardianHelp;

  /// No description provided for @percentage0To100.
  ///
  /// In en, this message translates to:
  /// **'Percentage (0 - 100)'**
  String get percentage0To100;

  /// No description provided for @otherInfoOptional.
  ///
  /// In en, this message translates to:
  /// **'Other Info (optional)'**
  String get otherInfoOptional;

  /// No description provided for @icNricNumber.
  ///
  /// In en, this message translates to:
  /// **'IC/NRIC Number'**
  String get icNricNumber;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @pleaseProvidePercentageForBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Please provide percentage for beneficiary'**
  String get pleaseProvidePercentageForBeneficiary;

  /// No description provided for @beneficiaryShareFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Their share (%)'**
  String get beneficiaryShareFieldLabel;

  /// No description provided for @beneficiaryShareHelperDefault.
  ///
  /// In en, this message translates to:
  /// **'You can leave this blank for now. Use the Faraid calculator on My Family when you\'re ready.'**
  String get beneficiaryShareHelperDefault;

  /// No description provided for @faraidBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Faraid calculator'**
  String get faraidBannerTitle;

  /// No description provided for @faraidBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions from your family details. Update when you’re ready.'**
  String get faraidBannerSubtitle;

  /// No description provided for @faraidBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Calculate now'**
  String get faraidBannerCta;

  /// No description provided for @faraidSuggestShares.
  ///
  /// In en, this message translates to:
  /// **'Faraid calculator'**
  String get faraidSuggestShares;

  /// No description provided for @faraidPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Faraid preview'**
  String get faraidPreviewTitle;

  /// No description provided for @faraidPreviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Suggested shares from your family setup. Update when you’re ready.'**
  String get faraidPreviewIntro;

  /// No description provided for @faraidPreviewSave.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get faraidPreviewSave;

  /// No description provided for @faraidPreviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get faraidPreviewTotal;

  /// No description provided for @faraidPreviewSkippedNote.
  ///
  /// In en, this message translates to:
  /// **'We did not update {count} other beneficiary profile(s). Their share could not be auto-calculated.'**
  String faraidPreviewSkippedNote(int count);

  /// No description provided for @faraidSuggestSharesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} beneficiaries.'**
  String faraidSuggestSharesUpdated(int count);

  /// No description provided for @faraidSuggestSharesNone.
  ///
  /// In en, this message translates to:
  /// **'No beneficiary percentages were changed. Add missing relationships or set gender in Profile, then try again.'**
  String get faraidSuggestSharesNone;

  /// No description provided for @faraidSuggestSharesNeedGender.
  ///
  /// In en, this message translates to:
  /// **'Add your gender in Profile first, then try again.'**
  String get faraidSuggestSharesNeedGender;

  /// No description provided for @percentageMustBeBetween0And100.
  ///
  /// In en, this message translates to:
  /// **'Percentage must be between 0 and 100'**
  String get percentageMustBeBetween0And100;

  /// No description provided for @contactId.
  ///
  /// In en, this message translates to:
  /// **'Contact & ID'**
  String get contactId;

  /// No description provided for @ifPersonPartOfWillSync.
  ///
  /// In en, this message translates to:
  /// **'If this person is part of your wasiat, any updates you make here will automatically sync to your wasiat.'**
  String get ifPersonPartOfWillSync;

  /// No description provided for @familyMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'Family member added'**
  String get familyMemberAdded;

  /// No description provided for @failedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add: {error}'**
  String failedToAdd(String error);

  /// No description provided for @invalidImageUseJpgPngWebp.
  ///
  /// In en, this message translates to:
  /// **'Invalid image. Use JPG/PNG/WebP under 5MB.'**
  String get invalidImageUseJpgPngWebp;

  /// No description provided for @imageSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Image selection failed: {error}'**
  String imageSelectionFailed(String error);

  /// No description provided for @editFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Family Member'**
  String get editFamilyMember;

  /// No description provided for @deleteFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Delete Family Member'**
  String get deleteFamilyMember;

  /// No description provided for @areYouSureDeleteFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this family member? This action cannot be undone.'**
  String get areYouSureDeleteFamilyMember;

  /// No description provided for @familyMemberDeleted.
  ///
  /// In en, this message translates to:
  /// **'Family member deleted'**
  String get familyMemberDeleted;

  /// No description provided for @failedToDeleteFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDeleteFamilyMember(String error);

  /// No description provided for @failedToSaveFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSaveFamilyMember(String error);

  /// No description provided for @basicInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfoSection;

  /// No description provided for @contactIdSection.
  ///
  /// In en, this message translates to:
  /// **'Contact & ID'**
  String get contactIdSection;

  /// No description provided for @addressSection.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressSection;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTask;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @deleteAllTasks.
  ///
  /// In en, this message translates to:
  /// **'Delete all tasks?'**
  String get deleteAllTasks;

  /// No description provided for @thisWillRemoveAllTasksPermanently.
  ///
  /// In en, this message translates to:
  /// **'This will remove all tasks permanently.'**
  String get thisWillRemoveAllTasksPermanently;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @createYourChecklist.
  ///
  /// In en, this message translates to:
  /// **'Create your checklist'**
  String get createYourChecklist;

  /// No description provided for @organiseYourAftercareTasks.
  ///
  /// In en, this message translates to:
  /// **'Organise your aftercare tasks and keep track of important steps.'**
  String get organiseYourAftercareTasks;

  /// No description provided for @whyUseAChecklist.
  ///
  /// In en, this message translates to:
  /// **'Why use a checklist?'**
  String get whyUseAChecklist;

  /// No description provided for @structuredChecklistHelps.
  ///
  /// In en, this message translates to:
  /// **'A structured checklist helps you and your family stay on top of important after‑death tasks, one step at a time.'**
  String get structuredChecklistHelps;

  /// No description provided for @startQuicklyWithRecommended.
  ///
  /// In en, this message translates to:
  /// **'Start quickly with a recommended set of essential aftercare tasks.'**
  String get startQuicklyWithRecommended;

  /// No description provided for @addYourOwnCustomTasks.
  ///
  /// In en, this message translates to:
  /// **'Add your own custom tasks that fit your situation and culture.'**
  String get addYourOwnCustomTasks;

  /// No description provided for @trackProgressSoNothingForgotten.
  ///
  /// In en, this message translates to:
  /// **'Track progress so nothing important is forgotten during a difficult time.'**
  String get trackProgressSoNothingForgotten;

  /// No description provided for @aboutChecklists.
  ///
  /// In en, this message translates to:
  /// **'About checklists'**
  String get aboutChecklists;

  /// No description provided for @defaultChecklistIncludes.
  ///
  /// In en, this message translates to:
  /// **'The default checklist includes essential aftercare steps like:\n\n• Notifying family members\n• Managing bank accounts and assets\n• Handling legal matters and documents\n• Organising personal belongings\n• Updating beneficiaries and contacts\n\nYou can also create custom tasks specific to your needs.'**
  String get defaultChecklistIncludes;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @learnMoreAboutChecklists.
  ///
  /// In en, this message translates to:
  /// **'Learn more about checklists'**
  String get learnMoreAboutChecklists;

  /// No description provided for @useDefaultChecklist.
  ///
  /// In en, this message translates to:
  /// **'Use default checklist'**
  String get useDefaultChecklist;

  /// No description provided for @createCustomTask.
  ///
  /// In en, this message translates to:
  /// **'Create custom task'**
  String get createCustomTask;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @getStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedTitle;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @setUpYourBasicInformation.
  ///
  /// In en, this message translates to:
  /// **'Set up your basic information'**
  String get setUpYourBasicInformation;

  /// No description provided for @addYourFirstFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Family Member'**
  String get addYourFirstFamilyMember;

  /// No description provided for @addSomeoneImportantToYourWill.
  ///
  /// In en, this message translates to:
  /// **'Add someone important to your wasiat'**
  String get addSomeoneImportantToYourWill;

  /// No description provided for @addYourFirstAsset.
  ///
  /// In en, this message translates to:
  /// **'Add your first asset'**
  String get addYourFirstAsset;

  /// No description provided for @startTrackingYourDigitalAssets.
  ///
  /// In en, this message translates to:
  /// **'List your assets'**
  String get startTrackingYourDigitalAssets;

  /// No description provided for @createYourWill.
  ///
  /// In en, this message translates to:
  /// **'Create Your Wasiat'**
  String get createYourWill;

  /// No description provided for @createYourWillWithSampul.
  ///
  /// In en, this message translates to:
  /// **'Create your wasiat with Sampul'**
  String get createYourWillWithSampul;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCode;

  /// No description provided for @addReferralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a referral code (optional)'**
  String get addReferralCodeOptional;

  /// No description provided for @haveReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get haveReferralCode;

  /// No description provided for @enterReferralCodeBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your referral code below to unlock benefits'**
  String get enterReferralCodeBelow;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCodeLabel;

  /// No description provided for @codeLooksTooShort.
  ///
  /// In en, this message translates to:
  /// **'Code looks too short'**
  String get codeLooksTooShort;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @referralCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied'**
  String get referralCodeApplied;

  /// No description provided for @setUpYourFamilyTrustAccount.
  ///
  /// In en, this message translates to:
  /// **'Set up your Family Account'**
  String get setUpYourFamilyTrustAccount;

  /// No description provided for @createFamilyAccountForLongTermSupport.
  ///
  /// In en, this message translates to:
  /// **'Create a Family Account to manage long-term support (optional).'**
  String get createFamilyAccountForLongTermSupport;

  /// No description provided for @pleaseCompleteAllStepsBeforeFinishing.
  ///
  /// In en, this message translates to:
  /// **'Please complete all steps before finishing'**
  String get pleaseCompleteAllStepsBeforeFinishing;

  /// No description provided for @failedToCompleteOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete onboarding: {error}'**
  String failedToCompleteOnboarding(String error);

  /// No description provided for @pleaseComplete.
  ///
  /// In en, this message translates to:
  /// **'Please complete: {nextTitle}'**
  String pleaseComplete(String nextTitle);

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete setup'**
  String get completeSetup;

  /// No description provided for @theRemainingSteps.
  ///
  /// In en, this message translates to:
  /// **'the remaining steps'**
  String get theRemainingSteps;

  /// No description provided for @familyTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Family Account'**
  String get familyTrustFund;

  /// No description provided for @aboutFamilyTrustFund.
  ///
  /// In en, this message translates to:
  /// **'About Family Account'**
  String get aboutFamilyTrustFund;

  /// No description provided for @noTrustFundsYet.
  ///
  /// In en, this message translates to:
  /// **'No Family Accounts yet'**
  String get noTrustFundsYet;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @createTrust.
  ///
  /// In en, this message translates to:
  /// **'Create Family Account'**
  String get createTrust;

  /// No description provided for @trustCodeUnique.
  ///
  /// In en, this message translates to:
  /// **'Trust code (unique)'**
  String get trustCodeUnique;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @aboutTrustFund.
  ///
  /// In en, this message translates to:
  /// **'About Family Account'**
  String get aboutTrustFund;

  /// No description provided for @newToTrusts.
  ///
  /// In en, this message translates to:
  /// **'New to trusts?'**
  String get newToTrusts;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @startSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Start setting up'**
  String get startSettingUp;

  /// No description provided for @whySetUpFamilyTrustFund.
  ///
  /// In en, this message translates to:
  /// **'What a Family Account does for you'**
  String get whySetUpFamilyTrustFund;

  /// No description provided for @familyTrustFundDescription.
  ///
  /// In en, this message translates to:
  /// **'A Family Account lets you decide how your money supports your family—healthcare, education, living expenses. You can update it whenever you want.'**
  String get familyTrustFundDescription;

  /// No description provided for @chooseHowMoneySpent.
  ///
  /// In en, this message translates to:
  /// **'You choose how the fund is used—healthcare, education, donations, and more'**
  String get chooseHowMoneySpent;

  /// No description provided for @changePlansAnytime.
  ///
  /// In en, this message translates to:
  /// **'Update your plans anytime'**
  String get changePlansAnytime;

  /// No description provided for @familyKnowsExactly.
  ///
  /// In en, this message translates to:
  /// **'Your family has clear guidance when they need it'**
  String get familyKnowsExactly;

  /// No description provided for @sampulPartnerWithRakyat.
  ///
  /// In en, this message translates to:
  /// **'Sampul works with Rakyat Trustee and Halogen Capital to manage your fund. '**
  String get sampulPartnerWithRakyat;

  /// No description provided for @learnMoreAboutPartners.
  ///
  /// In en, this message translates to:
  /// **'Learn more about our partners'**
  String get learnMoreAboutPartners;

  /// No description provided for @trustFundDetails.
  ///
  /// In en, this message translates to:
  /// **'Family Account Details'**
  String get trustFundDetails;

  /// No description provided for @deleteTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Delete Family Account'**
  String get deleteTrustFund;

  /// No description provided for @areYouSureDeleteTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Family Account? This action cannot be undone.'**
  String get areYouSureDeleteTrustFund;

  /// No description provided for @trustFundDeleted.
  ///
  /// In en, this message translates to:
  /// **'Family Account deleted'**
  String get trustFundDeleted;

  /// No description provided for @failedToDeleteTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete Family Account: {error}'**
  String failedToDeleteTrustFund(String error);

  /// No description provided for @trustIdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trust ID not available'**
  String get trustIdNotAvailable;

  /// No description provided for @trustIdCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Trust ID copied to clipboard'**
  String get trustIdCopiedToClipboard;

  /// No description provided for @beneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Beneficiaries'**
  String get beneficiaries;

  /// No description provided for @whoFundWillBeDistributedTo.
  ///
  /// In en, this message translates to:
  /// **'Who this fund will be distributed to'**
  String get whoFundWillBeDistributedTo;

  /// No description provided for @pleaseSaveTrustFirst.
  ///
  /// In en, this message translates to:
  /// **'Please save the trust first before adding beneficiaries'**
  String get pleaseSaveTrustFirst;

  /// No description provided for @beneficiaryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary added successfully'**
  String get beneficiaryAddedSuccessfully;

  /// No description provided for @failedToAddBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Failed to add beneficiary: {error}'**
  String failedToAddBeneficiary(String error);

  /// No description provided for @beneficiaryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary updated successfully'**
  String get beneficiaryUpdatedSuccessfully;

  /// No description provided for @failedToUpdateBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Failed to update beneficiary: {error}'**
  String failedToUpdateBeneficiary(String error);

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @allocateWhatTrustFundWillCover.
  ///
  /// In en, this message translates to:
  /// **'Allocate what this Family Account will cover'**
  String get allocateWhatTrustFundWillCover;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @livingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Living Expenses'**
  String get livingExpenses;

  /// No description provided for @healthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get healthcare;

  /// No description provided for @charitable.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String get charitable;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @tapToSetUp.
  ///
  /// In en, this message translates to:
  /// **'Tap to set up'**
  String get tapToSetUp;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @familyAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Family Account created'**
  String get familyAccountCreated;

  /// No description provided for @yourFamilyNowHasClearGuidance.
  ///
  /// In en, this message translates to:
  /// **'Your family now has clear guidance, even if you\'re not around to explain.'**
  String get yourFamilyNowHasClearGuidance;

  /// No description provided for @whatHappensNow.
  ///
  /// In en, this message translates to:
  /// **'What happens now'**
  String get whatHappensNow;

  /// No description provided for @familyAccountSavedAndFollowed.
  ///
  /// In en, this message translates to:
  /// **'This Family Account is saved and will be followed according to the rules you\'ve set.'**
  String get familyAccountSavedAndFollowed;

  /// No description provided for @nextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get nextSteps;

  /// No description provided for @youMayReceiveConfirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'You may receive a confirmation email for your records (if enabled).'**
  String get youMayReceiveConfirmationEmail;

  /// No description provided for @youCanAlwaysReturnHere.
  ///
  /// In en, this message translates to:
  /// **'You can always return here to update your categories or amounts.'**
  String get youCanAlwaysReturnHere;

  /// No description provided for @viewInstructions.
  ///
  /// In en, this message translates to:
  /// **'View instructions'**
  String get viewInstructions;

  /// No description provided for @openTrust.
  ///
  /// In en, this message translates to:
  /// **'Open Family Account'**
  String get openTrust;

  /// No description provided for @createTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Create Family Account'**
  String get createTrustFund;

  /// No description provided for @editTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Edit Family Account'**
  String get editTrustFund;

  /// No description provided for @weCouldNotLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile automatically. Please fill the details manually.'**
  String get weCouldNotLoadYourProfile;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismiss;

  /// No description provided for @fundSupport.
  ///
  /// In en, this message translates to:
  /// **'Fund Support'**
  String get fundSupport;

  /// No description provided for @executorSelection.
  ///
  /// In en, this message translates to:
  /// **'Executor selection'**
  String get executorSelection;

  /// No description provided for @executorSelectionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'By appointing this executor, you authorise Sampul to notify them and grant access to your account and estate information only upon a verified Triggering Event (death, coma, or mental incapacity), and for them to work with Rakyat Trustee Berhad (RTB) to administer your estate on behalf of your beneficiaries.'**
  String get executorSelectionDisclaimer;

  /// No description provided for @financialInformation.
  ///
  /// In en, this message translates to:
  /// **'Financial Information'**
  String get financialInformation;

  /// No description provided for @employmentBusinessInformation.
  ///
  /// In en, this message translates to:
  /// **'Employment/Business Information'**
  String get employmentBusinessInformation;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewSubmit;

  /// No description provided for @livingExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Housing, food, utilities, daily needs'**
  String get livingExpensesSubtitle;

  /// No description provided for @healthcareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Medical bills, treatment'**
  String get healthcareSubtitle;

  /// No description provided for @charitableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat, waqf, sadaqah, donations'**
  String get charitableSubtitle;

  /// No description provided for @debtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loan repayments, outstanding obligations'**
  String get debtSubtitle;

  /// No description provided for @youCanSelectMoreThanOne.
  ///
  /// In en, this message translates to:
  /// **'You can select more than one. You can change this anytime. This sets a rule. Funds move only when conditions are met.'**
  String get youCanSelectMoreThanOne;

  /// No description provided for @forLabel.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get forLabel;

  /// No description provided for @untilTheyTurn.
  ///
  /// In en, this message translates to:
  /// **'Until they turn {age}'**
  String untilTheyTurn(int age);

  /// No description provided for @forTheirWholeLife.
  ///
  /// In en, this message translates to:
  /// **'For their whole life'**
  String get forTheirWholeLife;

  /// No description provided for @everyMonth.
  ///
  /// In en, this message translates to:
  /// **'every month'**
  String get everyMonth;

  /// No description provided for @every3Months.
  ///
  /// In en, this message translates to:
  /// **'every 3 months'**
  String get every3Months;

  /// No description provided for @everyYear.
  ///
  /// In en, this message translates to:
  /// **'every year'**
  String get everyYear;

  /// No description provided for @whenConditionsAreMet.
  ///
  /// In en, this message translates to:
  /// **'when conditions are met'**
  String get whenConditionsAreMet;

  /// No description provided for @whenNeeded.
  ///
  /// In en, this message translates to:
  /// **'When needed'**
  String get whenNeeded;

  /// No description provided for @allAtOnceAtTheEnd.
  ///
  /// In en, this message translates to:
  /// **'All at once after a verified Triggering Event'**
  String get allAtOnceAtTheEnd;

  /// No description provided for @someoneIKnow.
  ///
  /// In en, this message translates to:
  /// **'Someone I Know'**
  String get someoneIKnow;

  /// No description provided for @familyMemberCloseFriendOrTrustedAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Family member, close friend, or trusted advisor'**
  String get familyMemberCloseFriendOrTrustedAdvisor;

  /// No description provided for @freeUsually.
  ///
  /// In en, this message translates to:
  /// **'Free (usually)'**
  String get freeUsually;

  /// No description provided for @basicReportingAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Basic reporting and analytics'**
  String get basicReportingAndAnalytics;

  /// No description provided for @personalConflict.
  ///
  /// In en, this message translates to:
  /// **'Personal conflict'**
  String get personalConflict;

  /// No description provided for @administrativeBurden.
  ///
  /// In en, this message translates to:
  /// **'Administrative burden'**
  String get administrativeBurden;

  /// No description provided for @whosThisFamilyTrustAccountFor.
  ///
  /// In en, this message translates to:
  /// **'Who\'s this Family Account for?'**
  String get whosThisFamilyTrustAccountFor;

  /// No description provided for @noFamilyMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No family members found. Add family members in your profile.'**
  String get noFamilyMembersFound;

  /// No description provided for @sampulsProfessionalExecutor.
  ///
  /// In en, this message translates to:
  /// **'Sampul\'s Professional Executor'**
  String get sampulsProfessionalExecutor;

  /// No description provided for @expertManagement.
  ///
  /// In en, this message translates to:
  /// **'Expert management'**
  String get expertManagement;

  /// No description provided for @neutralParty.
  ///
  /// In en, this message translates to:
  /// **'Neutral party'**
  String get neutralParty;

  /// No description provided for @estFeeR4320yr.
  ///
  /// In en, this message translates to:
  /// **'Est. Fee: RM4,320/yr (Paid from Family Account funds)'**
  String get estFeeR4320yr;

  /// No description provided for @executorGoodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Your executor acts as a safeguard — not a decision-maker. Choose someone organised and trustworthy. They should be at least 21 years old. If one of your beneficiaries is under 18, you’ll need at least two executors working together. We’ll remind you about this later.'**
  String get executorGoodToKnow;

  /// No description provided for @estimatedNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Estimated Net Worth'**
  String get estimatedNetWorth;

  /// No description provided for @sourceOfFund.
  ///
  /// In en, this message translates to:
  /// **'Source of Fund'**
  String get sourceOfFund;

  /// No description provided for @purposeOfTransaction.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Transaction'**
  String get purposeOfTransaction;

  /// No description provided for @employerName.
  ///
  /// In en, this message translates to:
  /// **'Employer Name'**
  String get employerName;

  /// No description provided for @businessNature.
  ///
  /// In en, this message translates to:
  /// **'Business Nature'**
  String get businessNature;

  /// No description provided for @businessAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Business Address Line 1'**
  String get businessAddressLine1;

  /// No description provided for @businessAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Business Address Line 2'**
  String get businessAddressLine2;

  /// No description provided for @accountFor.
  ///
  /// In en, this message translates to:
  /// **'Account for'**
  String get accountFor;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @untilAge.
  ///
  /// In en, this message translates to:
  /// **'Until age {age}'**
  String untilAge(int age);

  /// No description provided for @theirEntireLifetime.
  ///
  /// In en, this message translates to:
  /// **'Their entire lifetime'**
  String get theirEntireLifetime;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @regularPayments.
  ///
  /// In en, this message translates to:
  /// **'Regular Payments'**
  String get regularPayments;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @whenConditions.
  ///
  /// In en, this message translates to:
  /// **'When conditions'**
  String get whenConditions;

  /// No description provided for @asNeededTrusteeDecides.
  ///
  /// In en, this message translates to:
  /// **'As needed (trustee decides)'**
  String get asNeededTrusteeDecides;

  /// No description provided for @lumpSumAtTheEnd.
  ///
  /// In en, this message translates to:
  /// **'Lump Sum'**
  String get lumpSumAtTheEnd;

  /// No description provided for @executorType.
  ///
  /// In en, this message translates to:
  /// **'Executor type'**
  String get executorType;

  /// No description provided for @selectedExecutors.
  ///
  /// In en, this message translates to:
  /// **'Selected executors'**
  String get selectedExecutors;

  /// No description provided for @familyMembersSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} family member(s) selected'**
  String familyMembersSelected(int count);

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @employerCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Employer/Company Name'**
  String get employerCompanyName;

  /// No description provided for @natureOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Nature of Business'**
  String get natureOfBusiness;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress;

  /// No description provided for @charitiesDonations.
  ///
  /// In en, this message translates to:
  /// **'Charities/Donations ({count})'**
  String charitiesDonations(int count);

  /// No description provided for @pleaseSelectAtLeastOneFundSupport.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one fund support category and set up its details'**
  String get pleaseSelectAtLeastOneFundSupport;

  /// No description provided for @pleaseSelectAtLeastOneExecutor.
  ///
  /// In en, this message translates to:
  /// **'Please select an executor'**
  String get pleaseSelectAtLeastOneExecutor;

  /// No description provided for @pleaseCompleteYourProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first'**
  String get pleaseCompleteYourProfileFirst;

  /// No description provided for @trustFundCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Family Account created'**
  String get trustFundCreatedSuccessfully;

  /// No description provided for @trustFundUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get trustFundUpdatedSuccessfully;

  /// No description provided for @failedToCreateTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Failed to create Family Account: {error}'**
  String failedToCreateTrustFund(String error);

  /// No description provided for @failedToUpdateTrustFund.
  ///
  /// In en, this message translates to:
  /// **'Failed to update Family Account: {error}'**
  String failedToUpdateTrustFund(String error);

  /// No description provided for @charitiesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} charities selected'**
  String charitiesSelected(int count);

  /// No description provided for @charitySelected.
  ///
  /// In en, this message translates to:
  /// **'1 charity selected'**
  String get charitySelected;

  /// No description provided for @pickOneMainPersonForCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick one main person for this category. You can still support others in other categories.'**
  String get pickOneMainPersonForCategory;

  /// No description provided for @noFamilyMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No family members yet.\nTap \"Add New\" below to add the first person for this account.'**
  String get noFamilyMembersYet;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @saveYourChanges.
  ///
  /// In en, this message translates to:
  /// **'Save your changes?'**
  String get saveYourChanges;

  /// No description provided for @youHaveUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes on this page. Would you like to save this setup before you go back?'**
  String get youHaveUnsavedChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @saveExit.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get saveExit;

  /// No description provided for @supportForTuitionFees.
  ///
  /// In en, this message translates to:
  /// **'Support for tuition fees, books, and educational expenses'**
  String get supportForTuitionFees;

  /// No description provided for @coverDailyLivingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Cover daily living expenses and basic needs'**
  String get coverDailyLivingExpenses;

  /// No description provided for @medicalExpensesTreatments.
  ///
  /// In en, this message translates to:
  /// **'Medical expenses, treatments, and healthcare services'**
  String get medicalExpensesTreatments;

  /// No description provided for @donationsContributions.
  ///
  /// In en, this message translates to:
  /// **'Donations and contributions to charitable organizations'**
  String get donationsContributions;

  /// No description provided for @paymentsOutstandingDebts.
  ///
  /// In en, this message translates to:
  /// **'Payments for outstanding debts and financial obligations'**
  String get paymentsOutstandingDebts;

  /// No description provided for @fundSupportConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Fund support configuration for your trust'**
  String get fundSupportConfiguration;

  /// No description provided for @requestPending.
  ///
  /// In en, this message translates to:
  /// **'Request Pending'**
  String get requestPending;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @totalDonations.
  ///
  /// In en, this message translates to:
  /// **'Total Donations'**
  String get totalDonations;

  /// No description provided for @noCharitiesDonationsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No charities/donations added yet'**
  String get noCharitiesDonationsAddedYet;

  /// No description provided for @addCharitableOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Add charitable organizations to start making a difference'**
  String get addCharitableOrganizations;

  /// No description provided for @unnamedOrganization.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Organization'**
  String get unnamedOrganization;

  /// No description provided for @donationAmount.
  ///
  /// In en, this message translates to:
  /// **'Donation Amount'**
  String get donationAmount;

  /// No description provided for @annualTotal.
  ///
  /// In en, this message translates to:
  /// **'Annual Total'**
  String get annualTotal;

  /// No description provided for @monthlyAverage.
  ///
  /// In en, this message translates to:
  /// **'Monthly Average'**
  String get monthlyAverage;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @supportDuration.
  ///
  /// In en, this message translates to:
  /// **'Support Duration'**
  String get supportDuration;

  /// No description provided for @endsInYear.
  ///
  /// In en, this message translates to:
  /// **'Ends in Year {year} ({years} years from now)'**
  String endsInYear(int year, int years);

  /// No description provided for @continuousSupportLifetime.
  ///
  /// In en, this message translates to:
  /// **'Continuous support throughout their lifetime'**
  String get continuousSupportLifetime;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'As Needed'**
  String get asNeeded;

  /// No description provided for @trusteeDecidesRelease.
  ///
  /// In en, this message translates to:
  /// **'Trustee decides when to release funds based on approved purposes'**
  String get trusteeDecidesRelease;

  /// No description provided for @lumpSum.
  ///
  /// In en, this message translates to:
  /// **'Lump Sum'**
  String get lumpSum;

  /// No description provided for @allFundsReleasedEnd.
  ///
  /// In en, this message translates to:
  /// **'Everything released upon a verified Triggering Event (death, coma, or mental incapacity)'**
  String get allFundsReleasedEnd;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @requestFund.
  ///
  /// In en, this message translates to:
  /// **'Request Fund'**
  String get requestFund;

  /// No description provided for @areYouSureRequestFunds.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request funds? This will notify your trustee to process the fund request.'**
  String get areYouSureRequestFunds;

  /// No description provided for @fundRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Fund request submitted successfully'**
  String get fundRequestSubmittedSuccessfully;

  /// No description provided for @areYouSureCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this fund request?'**
  String get areYouSureCancelRequest;

  /// No description provided for @noKeepIt.
  ///
  /// In en, this message translates to:
  /// **'No, Keep It'**
  String get noKeepIt;

  /// No description provided for @fundRequestCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Fund request cancelled successfully'**
  String get fundRequestCancelledSuccessfully;

  /// No description provided for @resumeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Resume Instruction'**
  String get resumeInstruction;

  /// No description provided for @pauseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Pause Instruction'**
  String get pauseInstruction;

  /// No description provided for @areYouSureResumeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resume the {category} instruction? Payments will continue according to the schedule.'**
  String areYouSureResumeInstruction(String category);

  /// No description provided for @areYouSurePauseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to pause the {category} instruction? This will temporarily stop all payments until you resume it.'**
  String areYouSurePauseInstruction(String category);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @instructionResumedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{category} instruction resumed successfully'**
  String instructionResumedSuccessfully(String category);

  /// No description provided for @instructionPausedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{category} instruction paused successfully'**
  String instructionPausedSuccessfully(String category);

  /// No description provided for @howLongShouldThisLast.
  ///
  /// In en, this message translates to:
  /// **'How long should this last?'**
  String get howLongShouldThisLast;

  /// No description provided for @untilSpecificAge.
  ///
  /// In en, this message translates to:
  /// **'Until a specific age'**
  String get untilSpecificAge;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @thatsYearsFromNow.
  ///
  /// In en, this message translates to:
  /// **'That\'s {years} years from now (Year {year})'**
  String thatsYearsFromNow(int years, int year);

  /// No description provided for @paymentConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Payment Configuration'**
  String get paymentConfiguration;

  /// No description provided for @howOftenContribution.
  ///
  /// In en, this message translates to:
  /// **'How often should this contribution be carried out?'**
  String get howOftenContribution;

  /// No description provided for @yourTrusteeReleasesMoney.
  ///
  /// In en, this message translates to:
  /// **'Your trustee releases money when needed for approved purposes'**
  String get yourTrusteeReleasesMoney;

  /// No description provided for @everythingReleasedEnd.
  ///
  /// In en, this message translates to:
  /// **'Everything released upon a verified Triggering Event (death, coma, or mental incapacity)'**
  String get everythingReleasedEnd;

  /// No description provided for @thisIsAGuide.
  ///
  /// In en, this message translates to:
  /// **'This is a guide. Your executor can adjust based on real needs.'**
  String get thisIsAGuide;

  /// No description provided for @addCharitableOrganizationsDonate.
  ///
  /// In en, this message translates to:
  /// **'Add charitable organizations you would like to donate to'**
  String get addCharitableOrganizationsDonate;

  /// No description provided for @addCharity.
  ///
  /// In en, this message translates to:
  /// **'Add Charity/Donation'**
  String get addCharity;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @setYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set your new password'**
  String get setYourNewPassword;

  /// No description provided for @enterNewPasswordBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below to complete the reset process.'**
  String get enterNewPasswordBelow;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @failedToUpdatePasswordWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password: {error}'**
  String failedToUpdatePasswordWithError(String error);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @enterEmailForResetLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get enterEmailForResetLink;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Please check your email.'**
  String get passwordResetEmailSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email: {error}'**
  String failedToSendResetEmail(String error);

  /// No description provided for @resetLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'Reset link expired'**
  String get resetLinkExpired;

  /// No description provided for @resetLinkExpiredDescription.
  ///
  /// In en, this message translates to:
  /// **'This password reset link has expired or has already been used. Please request a new reset link.'**
  String get resetLinkExpiredDescription;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @whatWouldYouLikeToOrganise.
  ///
  /// In en, this message translates to:
  /// **'What would you like to organise today?'**
  String get whatWouldYouLikeToOrganise;

  /// No description provided for @chooseWhatToTakeCareFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose what you\'d like to take care of first.'**
  String get chooseWhatToTakeCareFirst;

  /// No description provided for @openFamilyAccount.
  ///
  /// In en, this message translates to:
  /// **'Open Family Account'**
  String get openFamilyAccount;

  /// No description provided for @openFamilyAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Organise your family, assets, and instructions in one place.'**
  String get openFamilyAccountDescription;

  /// No description provided for @protectProperty.
  ///
  /// In en, this message translates to:
  /// **'Protect Property'**
  String get protectProperty;

  /// No description provided for @protectPropertyDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up instructions to protect your property.'**
  String get protectPropertyDescription;

  /// No description provided for @managePusaka.
  ///
  /// In en, this message translates to:
  /// **'Manage executors'**
  String get managePusaka;

  /// No description provided for @managePusakaDescription.
  ///
  /// In en, this message translates to:
  /// **'Guidance for managing inheritance matters.'**
  String get managePusakaDescription;

  /// No description provided for @writeWasiat.
  ///
  /// In en, this message translates to:
  /// **'Write Wasiat'**
  String get writeWasiat;

  /// No description provided for @writeWasiatDescription.
  ///
  /// In en, this message translates to:
  /// **'Document how your assets should be distributed.'**
  String get writeWasiatDescription;

  /// No description provided for @executorInfoHeadline.
  ///
  /// In en, this message translates to:
  /// **'Let\'s register as an executor'**
  String get executorInfoHeadline;

  /// No description provided for @executorInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register to manage and distribute a deceased person\'s estate according to their will or the law.'**
  String get executorInfoSubtitle;

  /// No description provided for @executorInfoWhatIsTitle.
  ///
  /// In en, this message translates to:
  /// **'What is an executor?'**
  String get executorInfoWhatIsTitle;

  /// No description provided for @executorInfoWhatIsBody.
  ///
  /// In en, this message translates to:
  /// **'An executor is appointed to manage and distribute the assets of a deceased person\'s estate. This involves handling legal matters, settling debts, and ensuring proper distribution to beneficiaries.'**
  String get executorInfoWhatIsBody;

  /// No description provided for @executorInfoFeatureManage.
  ///
  /// In en, this message translates to:
  /// **'Manage the deceased person\'s estate and assets.'**
  String get executorInfoFeatureManage;

  /// No description provided for @executorInfoFeatureSettle.
  ///
  /// In en, this message translates to:
  /// **'Settle debts and handle legal matters.'**
  String get executorInfoFeatureSettle;

  /// No description provided for @executorInfoFeatureDistribute.
  ///
  /// In en, this message translates to:
  /// **'Distribute assets to beneficiaries according to the will or law.'**
  String get executorInfoFeatureDistribute;

  /// No description provided for @executorInfoCta.
  ///
  /// In en, this message translates to:
  /// **'Register as executor'**
  String get executorInfoCta;

  /// No description provided for @getGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Get guidance'**
  String get getGuidanceTitle;

  /// No description provided for @getGuidanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask Sampul AI or speak with a professional consultant.'**
  String get getGuidanceDescription;

  /// No description provided for @notSureWhereToStart.
  ///
  /// In en, this message translates to:
  /// **'Not sure where to start?'**
  String get notSureWhereToStart;

  /// No description provided for @notSureDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll guide you through a few simple questions.'**
  String get notSureDescription;

  /// No description provided for @setUpPropertyTrustHibah.
  ///
  /// In en, this message translates to:
  /// **'Set Up Property Trust'**
  String get setUpPropertyTrustHibah;

  /// No description provided for @setUpHibahInstructionsForProperty.
  ///
  /// In en, this message translates to:
  /// **'Protect your property with a trust'**
  String get setUpHibahInstructionsForProperty;

  /// No description provided for @setUpExecution.
  ///
  /// In en, this message translates to:
  /// **'Set up executors'**
  String get setUpExecution;

  /// No description provided for @setUpExecutionDescription.
  ///
  /// In en, this message translates to:
  /// **'Appoint someone to manage your estate'**
  String get setUpExecutionDescription;

  /// No description provided for @readyForGuidance.
  ///
  /// In en, this message translates to:
  /// **'Ready for guidance!'**
  String get readyForGuidance;

  /// No description provided for @profileSetUpChatReady.
  ///
  /// In en, this message translates to:
  /// **'Your profile is set up. You can now chat with Sampul AI or speak with a professional consultant.'**
  String get profileSetUpChatReady;

  /// No description provided for @chatWithSampulAI.
  ///
  /// In en, this message translates to:
  /// **'Chat with Sampul AI'**
  String get chatWithSampulAI;

  /// No description provided for @sampulAIDescription.
  ///
  /// In en, this message translates to:
  /// **'Get personalized guidance from Sampul AI assistant'**
  String get sampulAIDescription;

  /// No description provided for @chatWelcomeSampulAi.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m Sampul AI, your estate planning assistant. How can I help you today?'**
  String get chatWelcomeSampulAi;

  /// No description provided for @chatErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I\'m having trouble connecting right now. Please try again later.'**
  String get chatErrorConnection;

  /// No description provided for @chatErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI chat is not configured. Please check your environment variables.'**
  String get chatErrorNotConfigured;

  /// No description provided for @chatErrorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your API key configuration.'**
  String get chatErrorAuthFailed;

  /// No description provided for @chatErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded. Please try again in a moment.'**
  String get chatErrorRateLimit;

  /// No description provided for @chatErrorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. Please try again later.'**
  String get chatErrorServiceUnavailable;

  /// No description provided for @chatComposerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything…'**
  String get chatComposerPlaceholder;

  /// No description provided for @setUpAftercare.
  ///
  /// In en, this message translates to:
  /// **'Set Up Aftercare'**
  String get setUpAftercare;

  /// No description provided for @aftercareDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore support resources and care team services'**
  String get aftercareDescription;

  /// No description provided for @completeStepsFamilyAccount.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to set up your Family Account.'**
  String get completeStepsFamilyAccount;

  /// No description provided for @completeStepsProtectProperty.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to protect your property.'**
  String get completeStepsProtectProperty;

  /// No description provided for @completeStepsManagePusaka.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to set up your executors.'**
  String get completeStepsManagePusaka;

  /// No description provided for @completeStepsWriteWasiat.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to create your wasiat.'**
  String get completeStepsWriteWasiat;

  /// No description provided for @completeStepsGetGuidance.
  ///
  /// In en, this message translates to:
  /// **'Complete this step to get personalized guidance.'**
  String get completeStepsGetGuidance;

  /// No description provided for @completeStepsNotSure.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to set up your Sampul account.'**
  String get completeStepsNotSure;

  /// No description provided for @accountSetup.
  ///
  /// In en, this message translates to:
  /// **'Account Setup'**
  String get accountSetup;

  /// No description provided for @continueWithFeature.
  ///
  /// In en, this message translates to:
  /// **'Continue with {feature}'**
  String continueWithFeature(String feature);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @propertyTrust.
  ///
  /// In en, this message translates to:
  /// **'Property Trust'**
  String get propertyTrust;

  /// No description provided for @couponsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers & coupons'**
  String get couponsMenuTitle;

  /// No description provided for @couponsMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout discounts'**
  String get couponsMenuSubtitle;

  /// No description provided for @couponsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your coupons'**
  String get couponsScreenTitle;

  /// No description provided for @couponsScreenHeadline.
  ///
  /// In en, this message translates to:
  /// **'Checkout savings'**
  String get couponsScreenHeadline;

  /// No description provided for @couponsScreenIntro.
  ///
  /// In en, this message translates to:
  /// **'Use these when you pay. More may arrive from referrals and offers.'**
  String get couponsScreenIntro;

  /// No description provided for @couponsGoToReferralsButton.
  ///
  /// In en, this message translates to:
  /// **'Go to referrals'**
  String get couponsGoToReferralsButton;

  /// No description provided for @couponsSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Ready to use'**
  String get couponsSectionActive;

  /// No description provided for @couponsSectionPast.
  ///
  /// In en, this message translates to:
  /// **'Used or expired'**
  String get couponsSectionPast;

  /// No description provided for @couponsEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'Referrals and offers can add coupons here.'**
  String get couponsEmptyActive;

  /// No description provided for @couponsEmptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active coupons'**
  String get couponsEmptyActiveTitle;

  /// No description provided for @couponsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'Used and expired coupons appear here.'**
  String get couponsEmptyPast;

  /// No description provided for @couponsEmptyPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get couponsEmptyPastTitle;

  /// No description provided for @couponProductHibah.
  ///
  /// In en, this message translates to:
  /// **'Hibah'**
  String get couponProductHibah;

  /// No description provided for @couponProductWasiat.
  ///
  /// In en, this message translates to:
  /// **'Wasiat'**
  String get couponProductWasiat;

  /// No description provided for @couponProductOther.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get couponProductOther;

  /// No description provided for @couponDescriptionHibah.
  ///
  /// In en, this message translates to:
  /// **'Hibah certificate fee. Choose it under Payment on your Hibah screen before checkout.'**
  String get couponDescriptionHibah;

  /// No description provided for @couponDescriptionWasiat.
  ///
  /// In en, this message translates to:
  /// **'Wasiat yearly access. Choose it on {screenTitle} before you pay.'**
  String couponDescriptionWasiat(String screenTitle);

  /// No description provided for @couponDescriptionOther.
  ///
  /// In en, this message translates to:
  /// **'We’ll show where to use this at checkout.'**
  String get couponDescriptionOther;

  /// No description provided for @couponStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get couponStatusActive;

  /// No description provided for @couponStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get couponStatusUsed;

  /// No description provided for @couponStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get couponStatusExpired;

  /// No description provided for @couponDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String couponDiscountPercent(int percent);

  /// No description provided for @couponExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String couponExpiresOn(String date);

  /// No description provided for @couponUsedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Used on {date}'**
  String couponUsedOnDate(String date);

  /// No description provided for @checkoutCouponLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get checkoutCouponLabel;

  /// No description provided for @checkoutNoCoupon.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get checkoutNoCoupon;

  /// No description provided for @checkoutYouPay.
  ///
  /// In en, this message translates to:
  /// **'You\'ll pay'**
  String get checkoutYouPay;
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
