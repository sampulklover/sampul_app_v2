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
  String get welcomeToSampul => 'Welcome to Sampul';

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
  String get appleSignInCancelled => 'Apple sign-in was cancelled or failed';

  @override
  String appleSignInFailed(String error) {
    return 'Apple sign-in failed: $error';
  }

  @override
  String get signingIn => 'Signing in…';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

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
  String get aboutYourWill => 'About Your Wasiat';

  @override
  String get letsCreateYourWill => 'Let\'s create your wasiat';

  @override
  String get willDescription =>
      'Bring your profile, family, assets, and wishes together in one clear wasiat document.';

  @override
  String get letsListYourDigitalAssets => 'Organise your assets';

  @override
  String get assetsDescription =>
      'Include your important assets—both digital accounts and physical items—so your instructions are clear and accessible when needed.';

  @override
  String get letsSetUpYourFamilyAccount => 'Set up your Family Account';

  @override
  String get trustDescription =>
      'Your wishes, clearly set out for the people you love.';

  @override
  String get letsPlanYourHibahGifts => 'Plan your Property Trust';

  @override
  String get hibahDescription =>
      'Decide who receives what—your home, savings, or investments—in one clear place.';

  @override
  String get aboutPropertyTrust => 'About Property Trust';

  @override
  String get propertyTrustWhatIs => 'What is a Property Trust?';

  @override
  String get propertyTrustAboutCopy =>
      'A Property Trust lets you name who receives specific assets during your lifetime. It\'s based on hibah and works alongside your will and estate plan.';

  @override
  String get propertyTrustBenefit1 =>
      'Choose who receives which assets—for example, a home, savings, or investments.';

  @override
  String get propertyTrustBenefit2 =>
      'Document your wishes clearly so everyone knows your intentions.';

  @override
  String get propertyTrustBenefit3 =>
      'Works alongside your will and estate plan—lifetime gifts and future plans together.';

  @override
  String get startPropertyTrust => 'Start setting up';

  @override
  String get supportingDocuments => 'Supporting documents';

  @override
  String get addDocument => 'Add document';

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
      'A professional executor helps ensure your wasiat is followed—calm, clear, and structured.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

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

  @override
  String get assalamualaikum => 'Assalamualaikum...';

  @override
  String assalamualaikumWithName(String name) {
    return 'Assalamualaikum, $name';
  }

  @override
  String get referrals => 'Referrals';

  @override
  String get myAssets => 'My Assets';

  @override
  String get seeAll => 'See All →';

  @override
  String get myFamily => 'My Family';

  @override
  String get submitted => 'Submitted';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get draft => 'Draft';

  @override
  String get yourPlanIsActive => 'Your plan is active';

  @override
  String get familyAccount => 'Family Account';

  @override
  String get homeMoreWithSampul => 'More with Sampul';

  @override
  String get homeFridayFundTitle => 'Friday Sadaqah Fund';

  @override
  String get homeFridayFundDescription =>
      'Give every Friday, with ongoing reward that continues for you over time.';

  @override
  String get createYourFirstTrustFund => 'Add Your First Family Account';

  @override
  String get addNewTrustFund => 'Add Your First Family Account';

  @override
  String get tapToGetStarted => 'Tap to get started';

  @override
  String get will => 'Wasiat';

  @override
  String get hibah => 'Property';

  @override
  String get trust => 'Trust';

  @override
  String get others => 'Others';

  @override
  String get assets => 'Assets';

  @override
  String get family => 'Family';

  @override
  String get checklist => 'Checklist';

  @override
  String get execution => 'Executor';

  @override
  String get pusaka => 'Executor';

  @override
  String get aftercare => 'Aftercare';

  @override
  String get informDeathTitle => 'Inform Death';

  @override
  String get informDeathStartCta => 'Start Inform Death';

  @override
  String get informDeathMenuLabel => 'Inform Death';

  @override
  String get informDeathDeleteDialogTitle => 'Delete Inform Death record';

  @override
  String get informDeathDeleteSuccess => 'Inform Death record deleted';

  @override
  String get informDeathHeroTitle => 'Inform Sampul of a death';

  @override
  String get informDeathHeroBody =>
      'If someone who uses Sampul has passed away, this page helps you let us know in a calm, structured way.';

  @override
  String get informDeathWhatYoullShareTitle => 'What you’ll share';

  @override
  String get informDeathWhatYoullShareBody =>
      'We’ll ask for the Sampul owner’s details and a copy of the death certificate. This helps us confirm the right person and support their family appropriately.';

  @override
  String get informDeathFeatureOwner =>
      'Owner’s full name and NRIC (as per NRIC).';

  @override
  String get informDeathFeatureCertNumber =>
      'Death certificate number so we can match the document.';

  @override
  String get informDeathFeatureCertImage =>
      'A clear photo or scan of the death certificate.';

  @override
  String get informDeathOwnerSectionTitle => 'Sampul owner’s details';

  @override
  String get informDeathOwnerNameLabel => 'Full name (as per NRIC)';

  @override
  String get informDeathOwnerNricLabel => 'NRIC number';

  @override
  String get informDeathSupportingDocsSectionTitle => 'Supporting documents';

  @override
  String get informDeathSupportingDocsBody =>
      'Attach the death certificate so our team can verify the information.';

  @override
  String get informDeathNoFileChosen => 'No file chosen';

  @override
  String get informDeathUploadHint =>
      'Upload a clear photo or scan of the death certificate.';

  @override
  String get informDeathChooseFile => 'Choose file';

  @override
  String get informDeathCertificateIdLabel => 'Death certificate ID';

  @override
  String get informDeathRequiredField => 'Required';

  @override
  String get informDeathSubmitCta => 'Submit to Sampul';

  @override
  String get informDeathStatusDraft => 'Draft';

  @override
  String get informDeathStatusSubmitted => 'Submitted';

  @override
  String get informDeathStatusUnderReview => 'Under review';

  @override
  String get informDeathStatusApproved => 'Approved';

  @override
  String get informDeathStatusRejected => 'Rejected';

  @override
  String get informDeathStatusUnknown => 'Submitted';

  @override
  String informDeathListNric(String nric) {
    return 'NRIC: $nric';
  }

  @override
  String informDeathListCertificateId(String certId) {
    return 'Certificate ID: $certId';
  }

  @override
  String informDeathListSubmittedOn(String date) {
    return 'Submitted on: $date';
  }

  @override
  String get informDeathInfoBannerBody => 'Need to inform Sampul of a death?';

  @override
  String get informDeathInfoBannerCta => 'New request';

  @override
  String get informDeathOpenFile => 'Open file';

  @override
  String get informDeathUnableToOpenFile => 'Unable to open file';

  @override
  String get informDeathRemoveFile => 'Remove file';

  @override
  String get informDeathRemoveFileTitle => 'Remove uploaded file?';

  @override
  String get informDeathRemoveFileBody =>
      'This will delete the uploaded file from this request.';

  @override
  String get add => 'Add';

  @override
  String get loading => 'Loading...';

  @override
  String get unknown => 'Unknown';

  @override
  String get faraid => 'Faraid';

  @override
  String get terminateSubscriptions => 'Terminate Subscriptions';

  @override
  String get transferAsGift => 'Transfer as Gift';

  @override
  String get settleDebts => 'Settle Debts';

  @override
  String get coSampul => 'Executor';

  @override
  String get beneficiary => 'Beneficiary';

  @override
  String get guardian => 'Guardian';

  @override
  String get account => 'Account';

  @override
  String get user => 'User';

  @override
  String get noEmail => 'No email';

  @override
  String get edit => 'Edit';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get checkingStatus => 'Checking status...';

  @override
  String get yourIdentityIsVerified => 'Your identity is verified';

  @override
  String get verificationInProgress => 'Verification in progress';

  @override
  String get verificationWasDeclined => 'Verification was declined';

  @override
  String get verificationWasRejected => 'Verification was rejected';

  @override
  String get verifyYourIdentity => 'Verify your identity';

  @override
  String get verified => 'Verified';

  @override
  String get pending => 'Pending';

  @override
  String get declined => 'Declined';

  @override
  String get changePassword => 'Change password';

  @override
  String get logOut => 'Log out';

  @override
  String get billing => 'Billing';

  @override
  String get plansAndSubscription => 'Plans & subscription';

  @override
  String get manageYourSampulPlan => 'Manage your Sampul plan';

  @override
  String get preferences => 'Preferences';

  @override
  String get yourCodeAndReferrals => 'Your code and referrals';

  @override
  String get aiChatSettings => 'AI Chat Settings';

  @override
  String get manageSampulAiResponses => 'Manage Sampul AI responses';

  @override
  String get teamAccess => 'Team access';

  @override
  String get teamAccessListSubtitle => 'Assign Marketing or Admin access';

  @override
  String get teamAccessDescription =>
      'Set Marketing or Admin for each person with a Sampul account.';

  @override
  String get teamAccessRoleLabel => 'Access level';

  @override
  String get teamAccessSearchHint => 'Search by email or name';

  @override
  String get teamAccessEmptySearch =>
      'No one matches that search. Try a different name or email.';

  @override
  String get teamAccessTryAgain => 'Try again';

  @override
  String get teamAccessRefreshTooltip => 'Refresh list';

  @override
  String get teamAccessInfoTooltip => 'Role guide';

  @override
  String get teamAccessInfoTitle => 'Role guide';

  @override
  String get teamAccessInfoStandard =>
      'Regular app use. No access to Team access or content admin tools.';

  @override
  String get teamAccessInfoMarketing =>
      'Can manage AI and learning content. Cannot assign roles.';

  @override
  String get teamAccessInfoAdmin =>
      'Full access to Team access, role assignment, and content admin tools.';

  @override
  String get teamAccessFilterLabel => 'Role';

  @override
  String get teamAccessFilterAll => 'All';

  @override
  String teamAccessLoadFailed(String error) {
    return 'We couldn’t load the team list. $error';
  }

  @override
  String get roleStandardUser => 'Standard';

  @override
  String get roleMarketing => 'Marketing';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get teamRoleSaved => 'Access updated.';

  @override
  String teamRoleSaveFailed(String error) {
    return 'We couldn’t update access. $error';
  }

  @override
  String get workspaceAccessNotAvailable =>
      'That area isn’t available with your current sign-in.';

  @override
  String get changeYourAccess => 'Change your access?';

  @override
  String get changeYourAccessAdminHint =>
      'You’re removing admin access from your own account. You’ll return to Settings after this saves.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get restartOnboarding => 'Restart onboarding';

  @override
  String get runTheSetupFlowAgain => 'Run the setup flow again';

  @override
  String get onboardingHasBeenReset => 'Onboarding has been reset';

  @override
  String failedToResetOnboarding(String error) {
    return 'Failed to reset onboarding: $error';
  }

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get reportBugsOrRequestFeatures =>
      'Report bugs or request new features';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App version';

  @override
  String get appVersionDemo => '1.0.0 (beta)';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsTappedDemo => 'Terms tapped (demo)';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyTappedDemo => 'Privacy tapped (demo)';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get enterCurrentPasswordAndChooseNew =>
      'Enter your current password and choose a new one';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get pleaseEnterCurrentPassword => 'Please enter your current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get pleaseEnterNewPassword => 'Please enter a new password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get pleaseConfirmNewPassword => 'Please confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get updatingPassword => 'Updating password...';

  @override
  String get cancel => 'Cancel';

  @override
  String get change => 'Change';

  @override
  String get optional => 'Optional';

  @override
  String get assetAdded => 'Asset added';

  @override
  String get copy => 'Copy';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully!';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get areYouSureDeleteAccount =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get areYouSureYouWantToLogOut => 'Are you sure you want to log out?';

  @override
  String get toConfirmTypeDelete =>
      'To confirm, please type \"DELETE\" in the box below:';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccountFeatureComingSoon =>
      'Delete account feature coming soon';

  @override
  String get creatingVerificationSession => 'Creating verification session...';

  @override
  String get couldNotOpenVerificationLink => 'Could not open verification link';

  @override
  String failedToStartVerification(String error) {
    return 'Failed to start verification: $error';
  }

  @override
  String get diditNotConfigured =>
      'Verification is not configured. Please set DIDIT_CLIENT_ID (API key) and DIDIT_WORKFLOW_ID in your .env file.';

  @override
  String get identityVerificationRequired =>
      'Identity verification is required to establish trust and ensure the legal validity of your wasiat.';

  @override
  String get legalValidity => 'Legal Validity';

  @override
  String get establishesLegalValidity =>
      'Establishes the legal validity of your wasiat';

  @override
  String get buildsTrust => 'Builds Trust';

  @override
  String get providesAssurance =>
      'Provides assurance to beneficiaries and your executor';

  @override
  String get regulatoryCompliance => 'Regulatory Compliance';

  @override
  String get ensuresCompliance =>
      'Ensures compliance with regulatory requirements';

  @override
  String get fraudProtection => 'Fraud Protection';

  @override
  String get protectsAgainstFraud =>
      'Protects against fraud and identity theft';

  @override
  String get yourInformationIsEncrypted =>
      'Your information is encrypted and secure';

  @override
  String get startVerification => 'Start Verification';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get youAreAllCaughtUp => 'You\'re all caught up.';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get clearAll => 'Clear all';

  @override
  String get removeNotificationTitle => 'Remove notification?';

  @override
  String get removeNotificationDescription =>
      'This removes the notification from your list.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get invalidImage =>
      'Invalid image. Please select a valid image file (max 5MB)';

  @override
  String get imageUploadedSuccessfully => 'Image uploaded successfully';

  @override
  String failedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String failedToUpdateProfile(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get uploading => 'Uploading...';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get username => 'Username';

  @override
  String get enterYourUsername => 'Enter your username';

  @override
  String get fullNameNric => 'Full Name (NRIC)';

  @override
  String get enterYourFullNameAsPerNric => 'Enter your full name as per NRIC';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get gender => 'Gender';

  @override
  String get religion => 'Religion';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get emailCannotBeChanged => 'Email cannot be changed';

  @override
  String get addressInformation => 'Address Information';

  @override
  String get addressLine1 => 'Address Line 1';

  @override
  String get enterYourAddress => 'Enter your address';

  @override
  String get addressLine2 => 'Address Line 2';

  @override
  String get enterAdditionalAddressDetails =>
      'Enter additional address details';

  @override
  String get city => 'City';

  @override
  String get enterCity => 'Enter city';

  @override
  String get state => 'State';

  @override
  String get enterState => 'State';

  @override
  String get postcode => 'Postcode';

  @override
  String get enterPostcode => 'Enter postcode';

  @override
  String get country => 'Country';

  @override
  String get myWill => 'My Wasiat';

  @override
  String get shareWill => 'Share Wasiat';

  @override
  String get whyCreateYourWillInSampul => 'Why create your wasiat in Sampul?';

  @override
  String get yourWillPullsFromProfile =>
      'Your wasiat pulls from your profile, family list, digital assets, and extra wishes so everything stays connected.';

  @override
  String get keepAllKeyInformation =>
      'Keep all key information (profile, family, assets) in one place.';

  @override
  String get generateStructuredWillDocument =>
      'Generate a structured wasiat document you can read, export, and share.';

  @override
  String get updateWillLater =>
      'Update your wasiat later whenever your life or assets change.';

  @override
  String get startMyWill => 'Start my wasiat';

  @override
  String get deleting => 'Deleting...';

  @override
  String get publish => 'Publish';

  @override
  String get unpublish => 'Unpublish';

  @override
  String get publishWill => 'Publish Wasiat';

  @override
  String publishWillConfirmation(String url) {
    return 'Are you sure you want to publish this wasiat?\n\nOnce published, this wasiat will be accessible to anyone with the share link:\n$url\n\nMake sure you only share this link with trusted family members or your executor.';
  }

  @override
  String get shareLinkCopiedToClipboard => 'Share link copied to clipboard';

  @override
  String get willPublishedSuccessfully => 'Certificate link is on';

  @override
  String get willUnpublishedSuccessfully => 'Certificate link is off';

  @override
  String get wasiatCertificateDialogTitle => 'Certificate';

  @override
  String get wasiatCertificateOn => 'Generate certificate';

  @override
  String get wasiatCertificateOff => 'Turn off link';

  @override
  String wasiatCertificateConfirmation(String url) {
    return 'Your certificate link is ready.\n\nYour full wasiat details stay private with Sampul.';
  }

  @override
  String get wasiatCertificateConfirmationPre =>
      'We’ll create a shareable certificate link.\n\nYour full wasiat details stay private with Sampul.';

  @override
  String get wasiatViewCertificateTab => 'Certificate';

  @override
  String get wasiatViewDetailsTab => 'Details';

  @override
  String get wasiatDetailsPrivateNote =>
      'Private. Kept with Sampul while your plan is active. Only released with a valid request.';

  @override
  String get wasiatDetailsLockedTitle => 'Details are locked';

  @override
  String get wasiatDetailsLockedBody =>
      'To view your full wasiat details, you’ll need an active yearly plan.';

  @override
  String get wasiatUpgradePlanCta => 'Upgrade plan';

  @override
  String get wasiatGeneratedHistoryTitle => 'Generated versions';

  @override
  String get wasiatGenerateNewVersionCta => 'Generate new version';

  @override
  String wasiatViewingGeneratedVersion(String date) {
    return 'Viewing: $date';
  }

  @override
  String get wasiatShareSheetTitle => 'Share certificate';

  @override
  String get wasiatShareSheetSubtitle =>
      'Share the certificate link. Your details stay private with Sampul.';

  @override
  String get wasiatShareSheetMore => 'More';

  @override
  String get wasiatShareSheetWhatsApp => 'WhatsApp';

  @override
  String get wasiatShareSheetTelegram => 'Telegram';

  @override
  String get wasiatShareSheetMessages => 'Message';

  @override
  String get wasiatShareSheetEmail => 'Email';

  @override
  String failedToPublishWill(String error) {
    return 'Failed to publish wasiat: $error';
  }

  @override
  String failedToUnpublishWill(String error) {
    return 'Failed to unpublish wasiat: $error';
  }

  @override
  String failedToDeleteWill(String error) {
    return 'Failed to delete wasiat: $error';
  }

  @override
  String failedToLoadWillData(String error) {
    return 'Failed to load wasiat data: $error';
  }

  @override
  String get wasiatPublishBlockedBody =>
      'To turn on your certificate link, you’ll need an active yearly plan.\n\nTap View plans to continue.';

  @override
  String get wasiatPublishBlockedByKyc =>
      'To generate your certificate, please complete your identity verification first.';

  @override
  String get wasiatPublishBlockedByDidit =>
      'We could not confirm your identity verification yet. Please complete verification and try again.';

  @override
  String get wasiatPublishVerificationChecklistTitle =>
      'Before generating a new certificate version, please complete all required checks.';

  @override
  String get wasiatPublishVerificationSettingsHint =>
      'Each new certificate generation needs a fresh identity verification. Start verification to continue.';

  @override
  String get wasiatEligibilityPlanStatusLabel => 'Yearly plan';

  @override
  String get wasiatEligibilityDiditKycStatusLabel => 'Identity verification';

  @override
  String get wasiatEligibilityKycStatusLabel => 'Identity verification (KYC)';

  @override
  String get wasiatEligibilityDiditStatusLabel =>
      'Re-authentication for this certificate';

  @override
  String get wasiatEligibilityStatusActive => 'Active';

  @override
  String get wasiatEligibilityStatusInactive => 'Inactive';

  @override
  String get wasiatEligibilityStatusComplete => 'Complete';

  @override
  String get wasiatEligibilityStatusNotComplete => 'Not complete';

  @override
  String wasiatPublishReadyUntil(String date) {
    return 'Plan active until $date';
  }

  @override
  String get wasiatPublishReadyShort => 'Your plan is active.';

  @override
  String get wasiatViewPlanAndPay => 'View plans';

  @override
  String get wasiatAccessBannerTitle => 'Plan required to publish';

  @override
  String get wasiatAccessBannerSubtitle => 'A yearly plan is needed.';

  @override
  String wasiatAccessActiveUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get wasiatAccessPanelTitle => 'Your plans';

  @override
  String get plansOverviewIntro => 'Plans, pricing, and payment history.';

  @override
  String get planSectionWasiatTitle => 'Wasiat';

  @override
  String get plansWasiatBadgeActive => 'Active';

  @override
  String get plansWasiatBadgeInactive => 'No access';

  @override
  String get plansWasiatBadgeEnded => 'Ended';

  @override
  String get planSectionPropertyTrustTitle => 'Property';

  @override
  String get planPropertyTrustSummary =>
      'From RM 2,500 for one asset. Larger bundles start from RM 2,500 with RM 500 per extra asset after 10. You will see the full amount before you pay.';

  @override
  String get planSectionTrustTitle => 'Family Account';

  @override
  String planTrustSummary(String amount) {
    return 'Minimum funding is $amount. Other fees are shown when you continue in Family Account.';
  }

  @override
  String get plansOpenPropertyTrust => 'Open Property';

  @override
  String get plansOpenTrustDashboard => 'Open Family Account';

  @override
  String get plansPaymentHistoryForPropertyTrust => 'Property payments';

  @override
  String get plansPaymentHistoryForTrust => 'Family Account payments';

  @override
  String get plansPaymentHistoryEmptyProduct => 'Nothing recorded yet.';

  @override
  String get plansPaymentHistorySubtitleEmpty => 'No payments yet';

  @override
  String plansPaymentHistorySubtitleCount(int count) {
    return '$count payments';
  }

  @override
  String plansPaymentTrustRefLabel(String id) {
    return 'Family Account #$id';
  }

  @override
  String get plansPaymentCertificateRefLabel => 'Certificate';

  @override
  String get plansOverviewLoadError =>
      'Something went wrong loading your plans. Please try again.';

  @override
  String get plansPaymentStatusRefunded => 'Refunded';

  @override
  String get wasiatAccessActiveNoEndDate => 'Access active';

  @override
  String get wasiatAccessInlineInactive => 'Upgrade plan';

  @override
  String get wasiatManagePlan => 'Details';

  @override
  String get wasiatPlanHeadline => 'Yearly access';

  @override
  String get wasiatPlanExplainerShort => 'Annual access. Renew anytime.';

  @override
  String wasiatPlanEndedOn(String date) {
    return 'Ended $date';
  }

  @override
  String get wasiatPlanPayChip => 'Pay with CHIP';

  @override
  String get wasiatPlanRenewEarly => 'Renew early';

  @override
  String get wasiatPlanPerYearLabel => 'per year';

  @override
  String get wasiatPaymentHistoryTitle => 'Payment history';

  @override
  String get wasiatPaymentHistoryEmpty => 'No payments yet.';

  @override
  String get wasiatPaymentStatusPaid => 'Paid';

  @override
  String get wasiatPaymentStatusFailed => 'Failed';

  @override
  String get wasiatPaymentStatusProcessing => 'Processing';

  @override
  String get code => 'Code';

  @override
  String warningsReviewRecommended(int count) {
    return '$count warning(s) - Review recommended';
  }

  @override
  String issuesActionRequired(int count) {
    return '$count issue(s) - Action required';
  }

  @override
  String get wasiatReviewSheetTitle => 'What to fix';

  @override
  String get wasiatReviewSheetIssues => 'Action required';

  @override
  String get wasiatReviewSheetWarnings => 'Optional';

  @override
  String get wasiatReviewSheetEditCta => 'Edit wasiat';

  @override
  String get published => 'Published';

  @override
  String get deleteWill => 'Delete Wasiat';

  @override
  String get areYouSureDeleteWill =>
      'Are you sure you want to delete your wasiat? This action cannot be undone.';

  @override
  String get createWill => 'Create Wasiat';

  @override
  String get editWill => 'Edit Wasiat';

  @override
  String get updateWill => 'Update Wasiat';

  @override
  String get executorsAndGuardians => 'Executor & guardian';

  @override
  String get executors => 'Executors';

  @override
  String get yourExecutor => 'Your executor';

  @override
  String get aboutPusaka => 'About executors';

  @override
  String get noPusakaYet => 'No executor yet';

  @override
  String get newToPusaka => 'New to executors?';

  @override
  String get submitPusaka => 'Submit executor';

  @override
  String get guardians => 'Guardians';

  @override
  String get yourGuardian => 'Your guardian';

  @override
  String get extraWishes => 'Extra Wishes';

  @override
  String get reviewSave => 'Review & Save';

  @override
  String get primaryExecutor => 'Primary executor';

  @override
  String get selectPrimaryExecutor =>
      'Select the primary executor to carry out your will';

  @override
  String get secondaryExecutor => 'Secondary executor';

  @override
  String get selectSecondaryExecutor => 'Optional: Select a secondary executor';

  @override
  String get primaryGuardian => 'Primary Guardian';

  @override
  String get selectPrimaryGuardian =>
      'Select guardian for minor children (if applicable)';

  @override
  String get secondaryGuardian => 'Secondary Guardian';

  @override
  String get selectSecondaryGuardian => 'Optional: Select a secondary guardian';

  @override
  String get selectFamilyMember => 'Select family member';

  @override
  String get noneSelected => 'None selected';

  @override
  String get notFound => 'Not found';

  @override
  String get yourAssets => 'Your Assets';

  @override
  String get manageAll => 'See all';

  @override
  String get noAssetsYet => 'No assets yet. Add one when you\'re ready.';

  @override
  String showMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get yourExtraWishes => 'Your Extra Wishes';

  @override
  String get noWishesYet =>
      'No wishes yet. Add your nazar, fidyah, organ donor pledge, and charitable allocations.';

  @override
  String get nazarWishes => 'Nazar wishes';

  @override
  String get nazarCost => 'Nazar cost';

  @override
  String get fidyahDays => 'Fidyah days';

  @override
  String get fidyahAmount => 'Fidyah amount';

  @override
  String get organDonorPledge => 'Organ donor pledge';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String waqf(int count, String total) {
    return 'Waqf: $count bodies • RM $total';
  }

  @override
  String charity(int count, String total) {
    return 'Charity';
  }

  @override
  String get name => 'Name';

  @override
  String get nric => 'NRIC';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get notProvided => 'Not provided';

  @override
  String totalAssets(String total) {
    return 'Total assets: RM $total';
  }

  @override
  String get yourWillUpdatesAutomatically =>
      'Your wasiat updates automatically with your profile, assets, and family changes.';

  @override
  String get willCreatedSuccessfully => 'Wasiat created successfully!';

  @override
  String get willUpdatedSuccessfully => 'Wasiat updated successfully!';

  @override
  String failedToSaveWill(String error) {
    return 'Failed to save wasiat: $error';
  }

  @override
  String failedToLoadInitialData(String error) {
    return 'Failed to load initial data: $error';
  }

  @override
  String get addAsset => 'Add Asset';

  @override
  String get aboutAssets => 'About Assets';

  @override
  String get platformService => 'Platform / Service';

  @override
  String get selectPlatform => 'Select a platform';

  @override
  String get chooseDigitalAccountToInclude =>
      'Choose the digital account you would like to include.';

  @override
  String get enterPhysicalAssetName => 'Enter the name of your physical asset';

  @override
  String get physicalAssetName => 'Asset name';

  @override
  String get assetInfo => 'Asset info';

  @override
  String get physicalAssetNameHint => 'e.g., My House, Car, Jewelry Collection';

  @override
  String get details => 'Details';

  @override
  String get review => 'Review';

  @override
  String get reviewThisDigitalAsset => 'Review this digital asset';

  @override
  String get reviewThisAsset => 'Review this asset';

  @override
  String get searchForPlatformOrService => 'Search for a platform or service';

  @override
  String get searchPlatformHint => 'e.g., Facebook, Google Drive, Maybank';

  @override
  String get addYourOwnAsset => 'Add your own asset';

  @override
  String useAsAssetName(String text) {
    return 'Use \"$text\" as the asset name';
  }

  @override
  String cantFindItAddAsCustom(String text) {
    return 'Can\'t find it? Add \"$text\" as custom';
  }

  @override
  String get addCustomAsset => 'Add Custom Asset';

  @override
  String get assetName => 'Asset Name *';

  @override
  String get assetNameHint => 'e.g., My Custom Platform';

  @override
  String get websiteUrlOptional => 'Website URL (optional)';

  @override
  String get websiteUrlHint => 'https://example.com';

  @override
  String get required => 'Required';

  @override
  String get declaredValueMyr => 'Declared Value (MYR)';

  @override
  String get estimatedCurrentValue => 'Estimated current value of this asset';

  @override
  String get enterValidAmountMaxDecimals =>
      'Enter a valid amount (max 2 decimals)';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get instructionsAfterDeath => 'Instructions After Death';

  @override
  String get instructionUponActivation => 'Instruction upon activation';

  @override
  String get whatShouldHappenToThisAccount =>
      'What should happen to this asset?';

  @override
  String get defineHowThisAccountShouldBeHandled =>
      'Define how this asset should be handled.';

  @override
  String get closeThisAccount => 'Close this account';

  @override
  String get transferAccessToExecutor => 'Transfer access to my executor';

  @override
  String get memorialiseIfApplicable => 'Memorialise (if applicable)';

  @override
  String get leaveSpecificInstructions => 'Leave specific instructions';

  @override
  String get provideDetailsBelow => 'Provide details below.';

  @override
  String get thisInformationOnlyAccessible =>
      'This information will only be accessible according to your estate instructions.';

  @override
  String get loadingRecipients => 'Loading recipients...';

  @override
  String get giftRecipient => 'Gift Recipient';

  @override
  String get giftRecipientRequired => 'Gift Recipient is required';

  @override
  String get estimatedValue => 'Estimated value (RM)';

  @override
  String get estimatedValueDescription =>
      'An approximate value helps your executor understand the asset\'s worth.';

  @override
  String get enterEstimatedValue => 'Enter estimated value (RM)';

  @override
  String get estimatedValueHint => 'e.g., 5000.00';

  @override
  String get remarksOptional => 'Additional notes';

  @override
  String get remarksHint =>
      'e.g., Account location, special instructions, or important details';

  @override
  String get additionalNotes => 'Additional notes';

  @override
  String get additionalNotesDescription =>
      'Add any extra details that will help your executor handle this asset.';

  @override
  String get youMightWantToInclude => 'You might want to include:';

  @override
  String get remarksSuggestion1 =>
      'Account location or where to find login details';

  @override
  String get remarksSuggestion2 => 'Special instructions or important details';

  @override
  String get remarksSuggestion3 => 'Contact information for account recovery';

  @override
  String get remarksSuggestionPhysical1 =>
      'Location or where the asset is kept';

  @override
  String get remarksSuggestionPhysical2 =>
      'Special instructions or important details';

  @override
  String get remarksSuggestionPhysical3 =>
      'Documentation or ownership papers location';

  @override
  String get assetWillBeIncludedInWill =>
      'This asset will be included in your will. Any changes you make will sync automatically.';

  @override
  String get website => 'Website';

  @override
  String get instruction => 'Instruction';

  @override
  String get remarks => 'Remarks';

  @override
  String get pleaseSelectPlatformService => 'Please select a platform/service';

  @override
  String get pleaseSelectAssetType => 'Please select an asset type';

  @override
  String get pleaseSelectInstruction => 'Please select an instruction';

  @override
  String get pleaseSelectGiftRecipient => 'Please select a gift recipient';

  @override
  String get assetAddedSuccessfully => 'Asset added';

  @override
  String failedToAddAsset(String error) {
    return 'Something went wrong. Please try again.';
  }

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get youMustBeSignedIn => 'You must be signed in';

  @override
  String get unnamed => 'Unnamed';

  @override
  String get editAsset => 'Edit Asset';

  @override
  String get changesHereUpdateWillAutomatically =>
      'Changes here update your wasiat automatically.';

  @override
  String get assetUpdated => 'Asset updated';

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get deleteAsset => 'Delete Asset';

  @override
  String get areYouSureDeleteAsset =>
      'Are you sure you want to delete this asset? This can\'t be undone.';

  @override
  String get assetDeleted => 'Asset deleted';

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get whyAddYourAssets => 'Why this matters';

  @override
  String get assetListConnectsToWill =>
      'Your asset list connects to your will and estate planning. Add both digital and physical assets so your executor knows exactly what to handle.';

  @override
  String get assetType => 'Asset type';

  @override
  String get digitalAsset => 'Digital asset';

  @override
  String get physicalAsset => 'Physical asset';

  @override
  String get selectAssetType => 'Select asset type';

  @override
  String get selectAssetCategory => 'What type of asset is this?';

  @override
  String get whatTypeOfPhysicalAsset => 'What type of physical asset is this?';

  @override
  String get land => 'Land (individual or joint title)';

  @override
  String get housesBuildings => 'Houses / buildings';

  @override
  String get farmsPlantations => 'Farms, plantations';

  @override
  String get cash => 'Cash';

  @override
  String get vehicles => 'Vehicles (car, motorcycle)';

  @override
  String get jewellery => 'Jewellery';

  @override
  String get furnitureHousehold => 'Furniture & household items';

  @override
  String get financialInstruments =>
      'Financial instruments (EPF, ASNB, Tabung Haji)';

  @override
  String get propertyOrLand => 'Property or land';

  @override
  String get propertyOrLandDescription =>
      'Land, houses, buildings, farms, plantations';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get vehicleDescription => 'Cars, motorcycles, boats, other vehicles';

  @override
  String get jewelleryOrValuables => 'Jewellery or valuables';

  @override
  String get jewelleryOrValuablesDescription =>
      'Jewelry, watches, art, collectibles, furniture, household items';

  @override
  String get cashOrInvestments => 'Cash or investments';

  @override
  String get cashOrInvestmentsDescription =>
      'Cash, EPF, ASNB, Tabung Haji, stocks, bonds, other financial instruments';

  @override
  String get otherPhysicalAsset => 'Other physical asset';

  @override
  String get otherPhysicalAssetDescription => 'Any other tangible asset';

  @override
  String get immovableAssetNote => 'Asset type: Property (Immovable asset)';

  @override
  String get selectLegalClassification =>
      'Is this a movable or immovable asset?';

  @override
  String get pleaseSelectLegalClassification =>
      'Please select whether this is a movable or immovable asset';

  @override
  String get legalClassificationExplanation =>
      'This helps us process your asset according to Malaysian inheritance law.';

  @override
  String get movableAsset => 'Movable asset';

  @override
  String get movableAssetExplanation =>
      'Items you can move or transfer easily, such as vehicles, cash, jewellery, furniture, or financial instruments.';

  @override
  String get immovableAsset => 'Immovable asset';

  @override
  String get immovableAssetExplanation =>
      'Property that stays in place, such as land, houses, buildings, farms, or plantations.';

  @override
  String get movableAssetDescription =>
      'Items you can move or transfer\n• Vehicles\n• Jewelry and valuables\n• Cash and investments\n• Art and collectibles';

  @override
  String get immovableAssetDescription =>
      'Property that stays in place\n• Land and property\n• Buildings and structures\n• Real estate';

  @override
  String get pleaseSelectAssetCategory => 'Please select an asset type';

  @override
  String get makeItEasyForExecutors => 'Prevent accounts from being lost';

  @override
  String get linkEachAssetToInstructions => 'Ensure proper closure or transfer';

  @override
  String get keepWillUpToDate => 'Avoid unpaid subscriptions';

  @override
  String get provideClearInstructionsToExecutor =>
      'Provide clear instructions to your executor';

  @override
  String get weDoNotStorePasswords =>
      'We do not store passwords or login credentials.';

  @override
  String get addAssetButton => 'Add asset';

  @override
  String get saveDigitalAsset => 'Save digital asset';

  @override
  String get saveAsset => 'Save asset';

  @override
  String get savePhysicalAsset => 'Save physical asset';

  @override
  String get returnToDashboard => 'Return to dashboard';

  @override
  String get addAnotherDigitalAsset => 'Add another digital asset';

  @override
  String get addAnotherAsset => 'Add another asset';

  @override
  String get yourInstructionRecordedSecurely =>
      'Your instruction has been recorded securely.';

  @override
  String get youCanReviewOrUpdateAnytime =>
      'You can review or update it anytime.';

  @override
  String get passwordsNotStoredInSampul =>
      'Passwords are not stored in Sampul.';

  @override
  String get cantFindYourPlatform => 'Can\'t find your platform?';

  @override
  String get addCustomPlatform => 'Add custom platform';

  @override
  String get youllProvideInstructionsNextStep =>
      'You\'ll provide instructions in the next step. We do not store passwords';

  @override
  String get aboutFamilyMembers => 'About Family Members';

  @override
  String get letsAddYourFamily => 'Let\'s add your family';

  @override
  String get addPeopleWhoMatterMost =>
      'Add the people who matter most — executors, beneficiaries, and guardians — so your will stays clear and connected.';

  @override
  String get whyAddFamilyMembers => 'Why add family members?';

  @override
  String get familyListConnectsToWill =>
      'Your family list connects to your will, trust, and Property Trust planning. Add executors, beneficiaries, and guardians.';

  @override
  String get assignExecutorsCoSampul =>
      'Assign executors who will carry out your will.';

  @override
  String get listBeneficiariesWhoReceive =>
      'List beneficiaries who will receive your assets.';

  @override
  String get designateGuardiansForMinors =>
      'Designate guardians for minor children if needed.';

  @override
  String get addFamilyMember => 'Add family member';

  @override
  String get waris => 'Waris';

  @override
  String get nonWaris => 'Non-Waris';

  @override
  String get legacy => 'Legacy';

  @override
  String get addFamilyMemberTitle => 'Add Family Member';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get fullName => 'Full Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get pleaseEnterValidName => 'Please enter a valid name';

  @override
  String get relationship => 'Relationship';

  @override
  String get relationshipRequired => 'Relationship is required';

  @override
  String get category => 'Category';

  @override
  String get coSampulExecutor => 'Executor';

  @override
  String get coSampulExecutorHelp =>
      'Executor: Someone you trust who carries out your will together with Sampul.';

  @override
  String get beneficiaryHelp =>
      'Beneficiary: A person who will inherit your selected assets.';

  @override
  String get guardianHelp =>
      'Guardian: A person responsible for the care of your dependents or minors.';

  @override
  String get percentage0To100 => 'Percentage (0 - 100)';

  @override
  String get otherInfoOptional => 'Other Info (optional)';

  @override
  String get icNricNumber => 'IC/NRIC Number';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get pleaseProvidePercentageForBeneficiary =>
      'Please provide percentage for beneficiary';

  @override
  String get beneficiaryShareFieldLabel => 'Their share (%)';

  @override
  String get beneficiaryShareHelperDefault =>
      'You can leave this blank for now. Use the Faraid calculator on My Family when you\'re ready.';

  @override
  String get faraidBannerTitle => 'Faraid calculator';

  @override
  String get faraidBannerSubtitle =>
      'Suggestions from your family details. Update when you’re ready.';

  @override
  String get faraidBannerCta => 'Calculate now';

  @override
  String get faraidSuggestShares => 'Faraid calculator';

  @override
  String get faraidPreviewTitle => 'Faraid preview';

  @override
  String get faraidPreviewIntro =>
      'Suggested shares from your family setup. Update when you’re ready.';

  @override
  String get faraidPreviewSave => 'Update';

  @override
  String get faraidPreviewTotal => 'Total';

  @override
  String faraidPreviewSkippedNote(int count) {
    return 'We did not update $count other beneficiary profile(s). Their share could not be auto-calculated.';
  }

  @override
  String faraidSuggestSharesUpdated(int count) {
    return 'Updated $count beneficiaries.';
  }

  @override
  String get faraidSuggestSharesNone =>
      'No beneficiary percentages were changed. Add missing relationships or set gender in Profile, then try again.';

  @override
  String get faraidSuggestSharesNeedGender =>
      'Add your gender in Profile first, then try again.';

  @override
  String get percentageMustBeBetween0And100 =>
      'Percentage must be between 0 and 100';

  @override
  String get contactId => 'Contact & ID';

  @override
  String get ifPersonPartOfWillSync =>
      'If this person is part of your wasiat, any updates you make here will automatically sync to your wasiat.';

  @override
  String get familyMemberAdded => 'Family member added';

  @override
  String failedToAdd(String error) {
    return 'Failed to add: $error';
  }

  @override
  String get invalidImageUseJpgPngWebp =>
      'Invalid image. Use JPG/PNG/WebP under 5MB.';

  @override
  String imageSelectionFailed(String error) {
    return 'Image selection failed: $error';
  }

  @override
  String get editFamilyMember => 'Edit Family Member';

  @override
  String get deleteFamilyMember => 'Delete Family Member';

  @override
  String get areYouSureDeleteFamilyMember =>
      'Are you sure you want to delete this family member? This action cannot be undone.';

  @override
  String get familyMemberDeleted => 'Family member deleted';

  @override
  String failedToDeleteFamilyMember(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String failedToSaveFamilyMember(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get basicInfoSection => 'Basic Info';

  @override
  String get contactIdSection => 'Contact & ID';

  @override
  String get addressSection => 'Address';

  @override
  String get addTask => 'Add Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get task => 'Task';

  @override
  String get deleteTask => 'Delete task?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get deleteAllTasks => 'Delete all tasks?';

  @override
  String get thisWillRemoveAllTasksPermanently =>
      'This will remove all tasks permanently.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get createYourChecklist => 'Create your checklist';

  @override
  String get organiseYourAftercareTasks =>
      'Organise your aftercare tasks and keep track of important steps.';

  @override
  String get whyUseAChecklist => 'Why use a checklist?';

  @override
  String get structuredChecklistHelps =>
      'A structured checklist helps you and your family stay on top of important after‑death tasks, one step at a time.';

  @override
  String get startQuicklyWithRecommended =>
      'Start quickly with a recommended set of essential aftercare tasks.';

  @override
  String get addYourOwnCustomTasks =>
      'Add your own custom tasks that fit your situation and culture.';

  @override
  String get trackProgressSoNothingForgotten =>
      'Track progress so nothing important is forgotten during a difficult time.';

  @override
  String get aboutChecklists => 'About checklists';

  @override
  String get defaultChecklistIncludes =>
      'The default checklist includes essential aftercare steps like:\n\n• Notifying family members\n• Managing bank accounts and assets\n• Handling legal matters and documents\n• Organising personal belongings\n• Updating beneficiaries and contacts\n\nYou can also create custom tasks specific to your needs.';

  @override
  String get gotIt => 'Got it';

  @override
  String get learnMoreAboutChecklists => 'Learn more about checklists';

  @override
  String get useDefaultChecklist => 'Use default checklist';

  @override
  String get createCustomTask => 'Create custom task';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get getStartedTitle => 'Get Started';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get setUpYourBasicInformation => 'Set up your basic information';

  @override
  String get addYourFirstFamilyMember => 'Add Your First Family Member';

  @override
  String get addSomeoneImportantToYourWill =>
      'Add someone important to your wasiat';

  @override
  String get addYourFirstAsset => 'Add your first asset';

  @override
  String get startTrackingYourDigitalAssets => 'List your assets';

  @override
  String get createYourWill => 'Create Your Wasiat';

  @override
  String get createYourWillWithSampul => 'Create your wasiat with Sampul';

  @override
  String get referralCode => 'Referral code';

  @override
  String get addReferralCodeOptional => 'Add a referral code (optional)';

  @override
  String get haveReferralCode => 'Have a referral code?';

  @override
  String get enterReferralCodeBelow =>
      'Enter your referral code below to unlock benefits';

  @override
  String get referralCodeLabel => 'Referral code';

  @override
  String get codeLooksTooShort => 'Code looks too short';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get referralCodeApplied => 'Referral code applied';

  @override
  String get setUpYourFamilyTrustAccount => 'Set up your Family Account';

  @override
  String get createFamilyAccountForLongTermSupport =>
      'Create a Family Account to manage long-term support (optional).';

  @override
  String get pleaseCompleteAllStepsBeforeFinishing =>
      'Please complete all steps before finishing';

  @override
  String failedToCompleteOnboarding(String error) {
    return 'Failed to complete onboarding: $error';
  }

  @override
  String pleaseComplete(String nextTitle) {
    return 'Please complete: $nextTitle';
  }

  @override
  String get completeSetup => 'Complete setup';

  @override
  String get theRemainingSteps => 'the remaining steps';

  @override
  String get familyTrustFund => 'Family Account';

  @override
  String get aboutFamilyTrustFund => 'About Family Account';

  @override
  String get noTrustFundsYet => 'No Family Accounts yet';

  @override
  String get createNew => 'Create New';

  @override
  String get createTrust => 'Create Family Account';

  @override
  String get trustCodeUnique => 'Trust code (unique)';

  @override
  String get all => 'All';

  @override
  String get aboutTrustFund => 'About Family Account';

  @override
  String get newToTrusts => 'New to trusts?';

  @override
  String get learnMore => 'Learn more';

  @override
  String get startSettingUp => 'Start setting up';

  @override
  String get whySetUpFamilyTrustFund => 'What a Family Account does for you';

  @override
  String get familyTrustFundDescription =>
      'A Family Account lets you decide how your money supports your family—healthcare, education, living expenses. You can update it whenever you want.';

  @override
  String get chooseHowMoneySpent =>
      'You choose how the fund is used—healthcare, education, donations, and more';

  @override
  String get changePlansAnytime => 'Update your plans anytime';

  @override
  String get familyKnowsExactly =>
      'Your family has clear guidance when they need it';

  @override
  String get sampulPartnerWithRakyat =>
      'Sampul works with Rakyat Trustee and Halogen Capital to manage your fund. ';

  @override
  String get learnMoreAboutPartners => 'Learn more about our partners';

  @override
  String get trustFundDetails => 'Family Account Details';

  @override
  String get deleteTrustFund => 'Delete Family Account';

  @override
  String get areYouSureDeleteTrustFund =>
      'Are you sure you want to delete this Family Account? This action cannot be undone.';

  @override
  String get trustFundDeleted => 'Family Account deleted';

  @override
  String failedToDeleteTrustFund(String error) {
    return 'Failed to delete Family Account: $error';
  }

  @override
  String get trustIdNotAvailable => 'Trust ID not available';

  @override
  String get trustIdCopiedToClipboard => 'Trust ID copied to clipboard';

  @override
  String get beneficiaries => 'Beneficiaries';

  @override
  String get whoFundWillBeDistributedTo =>
      'Who this fund will be distributed to';

  @override
  String get pleaseSaveTrustFirst =>
      'Please save the trust first before adding beneficiaries';

  @override
  String get beneficiaryAddedSuccessfully => 'Beneficiary added successfully';

  @override
  String failedToAddBeneficiary(String error) {
    return 'Failed to add beneficiary: $error';
  }

  @override
  String get beneficiaryUpdatedSuccessfully =>
      'Beneficiary updated successfully';

  @override
  String failedToUpdateBeneficiary(String error) {
    return 'Failed to update beneficiary: $error';
  }

  @override
  String get instructions => 'Instructions';

  @override
  String get allocateWhatTrustFundWillCover =>
      'Allocate what this Family Account will cover';

  @override
  String get education => 'Education';

  @override
  String get livingExpenses => 'Living Expenses';

  @override
  String get healthcare => 'Healthcare';

  @override
  String get charitable => 'Charity';

  @override
  String get debt => 'Debt';

  @override
  String get tapToSetUp => 'Tap to set up';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get familyAccountCreated => 'Family Account created';

  @override
  String get yourFamilyNowHasClearGuidance =>
      'Your family now has clear guidance, even if you\'re not around to explain.';

  @override
  String get whatHappensNow => 'What happens now';

  @override
  String get familyAccountSavedAndFollowed =>
      'This Family Account is saved and will be followed according to the rules you\'ve set.';

  @override
  String get nextSteps => 'Next steps';

  @override
  String get youMayReceiveConfirmationEmail =>
      'You may receive a confirmation email for your records (if enabled).';

  @override
  String get youCanAlwaysReturnHere =>
      'You can always return here to update your categories or amounts.';

  @override
  String get viewInstructions => 'View instructions';

  @override
  String get openTrust => 'Open Family Account';

  @override
  String get createTrustFund => 'Create Family Account';

  @override
  String get editTrustFund => 'Edit Family Account';

  @override
  String get weCouldNotLoadYourProfile =>
      'We could not load your profile automatically. Please fill the details manually.';

  @override
  String get dismiss => 'DISMISS';

  @override
  String get fundSupport => 'Fund Support';

  @override
  String get executorSelection => 'Executor selection';

  @override
  String get executorSelectionDisclaimer =>
      'By appointing this executor, you authorise Sampul to notify them and grant access to your account and estate information only upon a verified Triggering Event (death, coma, or mental incapacity), and for them to work with Rakyat Trustee Berhad (RTB) to administer your estate on behalf of your beneficiaries.';

  @override
  String get financialInformation => 'Financial Information';

  @override
  String get employmentBusinessInformation => 'Employment/Business Information';

  @override
  String get reviewSubmit => 'Review & Submit';

  @override
  String get livingExpensesSubtitle => 'Housing, food, utilities, daily needs';

  @override
  String get healthcareSubtitle => 'Medical bills, treatment';

  @override
  String get charitableSubtitle => 'Zakat, waqf, sadaqah, donations';

  @override
  String get debtSubtitle => 'Loan repayments, outstanding obligations';

  @override
  String get youCanSelectMoreThanOne =>
      'You can select more than one. You can change this anytime. This sets a rule. Funds move only when conditions are met.';

  @override
  String get forLabel => 'For';

  @override
  String untilTheyTurn(int age) {
    return 'Until they turn $age';
  }

  @override
  String get forTheirWholeLife => 'For their whole life';

  @override
  String get everyMonth => 'every month';

  @override
  String get every3Months => 'every 3 months';

  @override
  String get everyYear => 'every year';

  @override
  String get whenConditionsAreMet => 'when conditions are met';

  @override
  String get whenNeeded => 'When needed';

  @override
  String get allAtOnceAtTheEnd =>
      'All at once after a verified Triggering Event';

  @override
  String get someoneIKnow => 'Someone I Know';

  @override
  String get familyMemberCloseFriendOrTrustedAdvisor =>
      'Family member, close friend, or trusted advisor';

  @override
  String get freeUsually => 'Free (usually)';

  @override
  String get basicReportingAndAnalytics => 'Basic reporting and analytics';

  @override
  String get personalConflict => 'Personal conflict';

  @override
  String get administrativeBurden => 'Administrative burden';

  @override
  String get whosThisFamilyTrustAccountFor => 'Who\'s this Family Account for?';

  @override
  String get noFamilyMembersFound =>
      'No family members found. Add family members in your profile.';

  @override
  String get sampulsProfessionalExecutor => 'Sampul\'s Professional Executor';

  @override
  String get expertManagement => 'Expert management';

  @override
  String get neutralParty => 'Neutral party';

  @override
  String get estFeeR4320yr =>
      'Est. Fee: RM4,320/yr (Paid from Family Account funds)';

  @override
  String get executorGoodToKnow =>
      'Your executor acts as a safeguard — not a decision-maker. Choose someone organised and trustworthy. They should be at least 21 years old. If one of your beneficiaries is under 18, you’ll need at least two executors working together. We’ll remind you about this later.';

  @override
  String get estimatedNetWorth => 'Estimated Net Worth';

  @override
  String get sourceOfFund => 'Source of Fund';

  @override
  String get purposeOfTransaction => 'Purpose of Transaction';

  @override
  String get employerName => 'Employer Name';

  @override
  String get businessNature => 'Business Nature';

  @override
  String get businessAddressLine1 => 'Business Address Line 1';

  @override
  String get businessAddressLine2 => 'Business Address Line 2';

  @override
  String get accountFor => 'Account for';

  @override
  String get duration => 'Duration';

  @override
  String untilAge(int age) {
    return 'Until age $age';
  }

  @override
  String get theirEntireLifetime => 'Their entire lifetime';

  @override
  String get paymentType => 'Payment Type';

  @override
  String get regularPayments => 'Regular Payments';

  @override
  String get amount => 'Amount';

  @override
  String get frequency => 'Frequency';

  @override
  String get monthly => 'Monthly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get yearly => 'Yearly';

  @override
  String get whenConditions => 'When conditions';

  @override
  String get asNeededTrusteeDecides => 'As needed (trustee decides)';

  @override
  String get lumpSumAtTheEnd => 'Lump Sum';

  @override
  String get executorType => 'Executor type';

  @override
  String get selectedExecutors => 'Selected executors';

  @override
  String familyMembersSelected(int count) {
    return '$count family member(s) selected';
  }

  @override
  String get businessInformation => 'Business Information';

  @override
  String get employerCompanyName => 'Employer/Company Name';

  @override
  String get natureOfBusiness => 'Nature of Business';

  @override
  String get businessAddress => 'Business Address';

  @override
  String charitiesDonations(int count) {
    return 'Charities/Donations ($count)';
  }

  @override
  String get pleaseSelectAtLeastOneFundSupport =>
      'Please select at least one fund support category and set up its details';

  @override
  String get pleaseSelectAtLeastOneExecutor => 'Please select an executor';

  @override
  String get pleaseCompleteYourProfileFirst =>
      'Please complete your profile first';

  @override
  String get trustFundCreatedSuccessfully => 'Family Account created';

  @override
  String get trustFundUpdatedSuccessfully => 'Changes saved';

  @override
  String failedToCreateTrustFund(String error) {
    return 'Failed to create Family Account: $error';
  }

  @override
  String failedToUpdateTrustFund(String error) {
    return 'Failed to update Family Account: $error';
  }

  @override
  String charitiesSelected(int count) {
    return '$count charities selected';
  }

  @override
  String get charitySelected => '1 charity selected';

  @override
  String get pickOneMainPersonForCategory =>
      'Pick one main person for this category. You can still support others in other categories.';

  @override
  String get noFamilyMembersYet =>
      'No family members yet.\nTap \"Add New\" below to add the first person for this account.';

  @override
  String get addNew => 'Add New';

  @override
  String get saveYourChanges => 'Save your changes?';

  @override
  String get youHaveUnsavedChanges =>
      'You have unsaved changes on this page. Would you like to save this setup before you go back?';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get saveExit => 'Save & exit';

  @override
  String get supportForTuitionFees =>
      'Support for tuition fees, books, and educational expenses';

  @override
  String get coverDailyLivingExpenses =>
      'Cover daily living expenses and basic needs';

  @override
  String get medicalExpensesTreatments =>
      'Medical expenses, treatments, and healthcare services';

  @override
  String get donationsContributions =>
      'Donations and contributions to charitable organizations';

  @override
  String get paymentsOutstandingDebts =>
      'Payments for outstanding debts and financial obligations';

  @override
  String get fundSupportConfiguration =>
      'Fund support configuration for your trust';

  @override
  String get requestPending => 'Request Pending';

  @override
  String get paused => 'Paused';

  @override
  String get totalDonations => 'Total Donations';

  @override
  String get noCharitiesDonationsAddedYet => 'No charities/donations added yet';

  @override
  String get addCharitableOrganizations =>
      'Add charitable organizations to start making a difference';

  @override
  String get unnamedOrganization => 'Unnamed Organization';

  @override
  String get donationAmount => 'Donation Amount';

  @override
  String get annualTotal => 'Annual Total';

  @override
  String get monthlyAverage => 'Monthly Average';

  @override
  String get na => 'N/A';

  @override
  String get supportDuration => 'Support Duration';

  @override
  String endsInYear(int year, int years) {
    return 'Ends in Year $year ($years years from now)';
  }

  @override
  String get continuousSupportLifetime =>
      'Continuous support throughout their lifetime';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get asNeeded => 'As Needed';

  @override
  String get trusteeDecidesRelease =>
      'Trustee decides when to release funds based on approved purposes';

  @override
  String get lumpSum => 'Lump Sum';

  @override
  String get allFundsReleasedEnd =>
      'Everything released upon a verified Triggering Event (death, coma, or mental incapacity)';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get requestFund => 'Request Fund';

  @override
  String get areYouSureRequestFunds =>
      'Are you sure you want to request funds? This will notify your trustee to process the fund request.';

  @override
  String get fundRequestSubmittedSuccessfully =>
      'Fund request submitted successfully';

  @override
  String get areYouSureCancelRequest =>
      'Are you sure you want to cancel this fund request?';

  @override
  String get noKeepIt => 'No, Keep It';

  @override
  String get fundRequestCancelledSuccessfully =>
      'Fund request cancelled successfully';

  @override
  String get resumeInstruction => 'Resume Instruction';

  @override
  String get pauseInstruction => 'Pause Instruction';

  @override
  String areYouSureResumeInstruction(String category) {
    return 'Are you sure you want to resume the $category instruction? Payments will continue according to the schedule.';
  }

  @override
  String areYouSurePauseInstruction(String category) {
    return 'Are you sure you want to pause the $category instruction? This will temporarily stop all payments until you resume it.';
  }

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String instructionResumedSuccessfully(String category) {
    return '$category instruction resumed successfully';
  }

  @override
  String instructionPausedSuccessfully(String category) {
    return '$category instruction paused successfully';
  }

  @override
  String get howLongShouldThisLast => 'How long should this last?';

  @override
  String get untilSpecificAge => 'Until a specific age';

  @override
  String get age => 'Age';

  @override
  String thatsYearsFromNow(int years, int year) {
    return 'That\'s $years years from now (Year $year)';
  }

  @override
  String get paymentConfiguration => 'Payment Configuration';

  @override
  String get howOftenContribution =>
      'How often should this contribution be carried out?';

  @override
  String get yourTrusteeReleasesMoney =>
      'Your trustee releases money when needed for approved purposes';

  @override
  String get everythingReleasedEnd =>
      'Everything released upon a verified Triggering Event (death, coma, or mental incapacity)';

  @override
  String get thisIsAGuide =>
      'This is a guide. Your executor can adjust based on real needs.';

  @override
  String get addCharitableOrganizationsDonate =>
      'Add charitable organizations you would like to donate to';

  @override
  String get addCharity => 'Add Charity/Donation';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get setYourNewPassword => 'Set your new password';

  @override
  String get enterNewPasswordBelow =>
      'Enter your new password below to complete the reset process.';

  @override
  String get passwordUpdatedSuccessfully => 'Password updated successfully!';

  @override
  String failedToUpdatePasswordWithError(String error) {
    return 'Failed to update password: $error';
  }

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get enterEmailForResetLink =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get passwordResetEmailSent =>
      'Password reset email sent! Please check your email.';

  @override
  String failedToSendResetEmail(String error) {
    return 'Failed to send reset email: $error';
  }

  @override
  String get resetLinkExpired => 'Reset link expired';

  @override
  String get resetLinkExpiredDescription =>
      'This password reset link has expired or has already been used. Please request a new reset link.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get whatWouldYouLikeToOrganise =>
      'What would you like to organise today?';

  @override
  String get chooseWhatToTakeCareFirst =>
      'Choose what you\'d like to take care of first.';

  @override
  String get openFamilyAccount => 'Open Family Account';

  @override
  String get openFamilyAccountDescription =>
      'Organise your family, assets, and instructions in one place.';

  @override
  String get protectProperty => 'Protect Property';

  @override
  String get protectPropertyDescription =>
      'Set up instructions to protect your property.';

  @override
  String get managePusaka => 'Manage executors';

  @override
  String get managePusakaDescription =>
      'Guidance for managing inheritance matters.';

  @override
  String get writeWasiat => 'Write Wasiat';

  @override
  String get writeWasiatDescription =>
      'Document how your assets should be distributed.';

  @override
  String get executorInfoHeadline => 'Let\'s register as an executor';

  @override
  String get executorInfoSubtitle =>
      'Register to manage and distribute a deceased person\'s estate according to their will or the law.';

  @override
  String get executorInfoWhatIsTitle => 'What is an executor?';

  @override
  String get executorInfoWhatIsBody =>
      'An executor is appointed to manage and distribute the assets of a deceased person\'s estate. This involves handling legal matters, settling debts, and ensuring proper distribution to beneficiaries.';

  @override
  String get executorInfoFeatureManage =>
      'Manage the deceased person\'s estate and assets.';

  @override
  String get executorInfoFeatureSettle =>
      'Settle debts and handle legal matters.';

  @override
  String get executorInfoFeatureDistribute =>
      'Distribute assets to beneficiaries according to the will or law.';

  @override
  String get executorInfoCta => 'Register as executor';

  @override
  String get getGuidanceTitle => 'Get guidance';

  @override
  String get getGuidanceDescription =>
      'Ask Sampul AI or speak with a professional consultant.';

  @override
  String get notSureWhereToStart => 'Not sure where to start?';

  @override
  String get notSureDescription =>
      'We\'ll guide you through a few simple questions.';

  @override
  String get setUpPropertyTrustHibah => 'Set Up Property Trust';

  @override
  String get setUpHibahInstructionsForProperty =>
      'Protect your property with a trust';

  @override
  String get setUpExecution => 'Set up executors';

  @override
  String get setUpExecutionDescription =>
      'Appoint someone to manage your estate';

  @override
  String get readyForGuidance => 'Ready for guidance!';

  @override
  String get profileSetUpChatReady =>
      'Your profile is set up. You can now chat with Sampul AI or speak with a professional consultant.';

  @override
  String get chatWithSampulAI => 'Chat with Sampul AI';

  @override
  String get sampulAIDescription =>
      'Get personalized guidance from Sampul AI assistant';

  @override
  String get chatWelcomeSampulAi =>
      'Hello! I\'m Sampul AI, your estate planning assistant. How can I help you today?';

  @override
  String get chatErrorConnection =>
      'Sorry, I\'m having trouble connecting right now. Please try again later.';

  @override
  String get chatErrorNotConfigured =>
      'AI chat is not configured. Please check your environment variables.';

  @override
  String get chatErrorAuthFailed =>
      'Authentication failed. Please check your API key configuration.';

  @override
  String get chatErrorRateLimit =>
      'Rate limit exceeded. Please try again in a moment.';

  @override
  String get chatErrorServiceUnavailable =>
      'The AI service is temporarily unavailable. Please try again later.';

  @override
  String get chatComposerPlaceholder => 'Ask me anything…';

  @override
  String get setUpAftercare => 'Set Up Aftercare';

  @override
  String get aftercareDescription =>
      'Explore support resources and care team services';

  @override
  String get completeStepsFamilyAccount =>
      'Complete these steps to set up your Family Account.';

  @override
  String get completeStepsProtectProperty =>
      'Complete these steps to protect your property.';

  @override
  String get completeStepsManagePusaka =>
      'Complete these steps to set up your executors.';

  @override
  String get completeStepsWriteWasiat =>
      'Complete these steps to create your wasiat.';

  @override
  String get completeStepsGetGuidance =>
      'Complete this step to get personalized guidance.';

  @override
  String get completeStepsNotSure =>
      'Complete these steps to set up your Sampul account.';

  @override
  String get accountSetup => 'Account Setup';

  @override
  String continueWithFeature(String feature) {
    return 'Continue with $feature';
  }

  @override
  String get profile => 'Profile';

  @override
  String get propertyTrust => 'Property Trust';

  @override
  String get couponsMenuTitle => 'Offers & coupons';

  @override
  String get couponsMenuSubtitle => 'Checkout discounts';

  @override
  String get couponsScreenTitle => 'Your coupons';

  @override
  String get couponsScreenHeadline => 'Checkout savings';

  @override
  String get couponsScreenIntro =>
      'Use these when you pay. More may arrive from referrals and offers.';

  @override
  String get couponsGoToReferralsButton => 'Go to referrals';

  @override
  String get couponsSectionActive => 'Ready to use';

  @override
  String get couponsSectionPast => 'Used or expired';

  @override
  String get couponsEmptyActive => 'Referrals and offers can add coupons here.';

  @override
  String get couponsEmptyActiveTitle => 'No active coupons';

  @override
  String get couponsEmptyPast => 'Used and expired coupons appear here.';

  @override
  String get couponsEmptyPastTitle => 'No history yet';

  @override
  String get couponProductHibah => 'Hibah';

  @override
  String get couponProductWasiat => 'Wasiat';

  @override
  String get couponProductOther => 'Offer';

  @override
  String get couponDescriptionHibah =>
      'Hibah certificate fee. Choose it under Payment on your Hibah screen before checkout.';

  @override
  String couponDescriptionWasiat(String screenTitle) {
    return 'Wasiat yearly access. Choose it on $screenTitle before you pay.';
  }

  @override
  String get couponDescriptionOther =>
      'We’ll show where to use this at checkout.';

  @override
  String get couponStatusActive => 'Active';

  @override
  String get couponStatusUsed => 'Used';

  @override
  String get couponStatusExpired => 'Expired';

  @override
  String couponDiscountPercent(int percent) {
    return '$percent% off';
  }

  @override
  String couponExpiresOn(String date) {
    return 'Valid until $date';
  }

  @override
  String couponUsedOnDate(String date) {
    return 'Used on $date';
  }

  @override
  String get checkoutCouponLabel => 'Discount';

  @override
  String get checkoutNoCoupon => 'None';

  @override
  String get checkoutYouPay => 'You\'ll pay';
}
