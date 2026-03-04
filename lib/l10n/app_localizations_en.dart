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
  String get aboutYourWill => 'About Your Wasiat';

  @override
  String get letsCreateYourWill => 'Let\'s create your wasiat';

  @override
  String get willDescription =>
      'Bring your profile, family, assets, and wishes together in one clear wasiat document.';

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
  String get letsPlanYourHibahGifts => 'Let\'s plan your Property Trust';

  @override
  String get hibahDescription =>
      'Decide clearly who should receive your Property Trust assets.';

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
      'A professional executor ensures your wasiat is followed—no family drama, no legal mess, just a smooth handover.';

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
  String get execution => 'Execution';

  @override
  String get aftercare => 'Aftercare';

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
  String get coSampul => 'Co-sampul';

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
  String get appVersionDemo => '1.0.0 (demo)';

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
      'Didit is not configured. Please set DIDIT_CLIENT_ID (API key) and DIDIT_WORKFLOW_ID in your .env file.';

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
      'Provides assurance to beneficiaries and executors';

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
    return 'Are you sure you want to publish this wasiat?\n\nOnce published, this wasiat will be accessible to anyone with the share link:\n$url\n\nMake sure you only share this link with trusted family members or executors.';
  }

  @override
  String get shareLinkCopiedToClipboard => 'Share link copied to clipboard';

  @override
  String get willPublishedSuccessfully => 'Wasiat published successfully';

  @override
  String get willUnpublishedSuccessfully => 'Wasiat unpublished successfully';

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
  String get executors => 'Executors';

  @override
  String get guardians => 'Guardians';

  @override
  String get extraWishes => 'Extra Wishes';

  @override
  String get reviewSave => 'Review & Save';

  @override
  String get primaryExecutor => 'Primary Executor';

  @override
  String get selectPrimaryExecutor =>
      'Select the primary person to execute your will';

  @override
  String get secondaryExecutor => 'Secondary Executor';

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
  String get manageAll => 'Manage All';

  @override
  String get noAssetsYet =>
      'No assets yet. Add at least one to include in your will.';

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
  String get details => 'Details';

  @override
  String get review => 'Review';

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
  String get loadingRecipients => 'Loading recipients...';

  @override
  String get giftRecipient => 'Gift Recipient';

  @override
  String get giftRecipientRequired => 'Gift Recipient is required';

  @override
  String get remarksOptional => 'Remarks (optional)';

  @override
  String get remarksHint => 'Any additional instructions or notes';

  @override
  String get assetWillBeIncludedInWill =>
      'This asset will be included in your will. Any changes you make will automatically sync to your will.';

  @override
  String get website => 'Website';

  @override
  String get instruction => 'Instruction';

  @override
  String get remarks => 'Remarks';

  @override
  String get pleaseSelectPlatformService => 'Please select a platform/service';

  @override
  String get pleaseSelectInstruction => 'Please select an instruction';

  @override
  String get pleaseSelectGiftRecipient => 'Please select a gift recipient';

  @override
  String get assetAddedSuccessfully => 'Asset added successfully';

  @override
  String failedToAddAsset(String error) {
    return 'Failed to add asset: $error';
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
      'Are you sure you want to delete this asset? This action cannot be undone.';

  @override
  String get assetDeleted => 'Asset deleted';

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get whyAddYourAssets => 'Why add your assets?';

  @override
  String get digitalAssetsInclude =>
      'Digital assets include bank apps, e‑wallets, subscriptions, social media, and other online accounts.';

  @override
  String get makeItEasyForExecutors =>
      'Make it easy for your executors to know which accounts you have.';

  @override
  String get linkEachAssetToInstructions =>
      'Link each asset to clear instructions (Faraid, terminate, transfer as gift, settle debts).';

  @override
  String get keepWillUpToDate =>
      'Keep your will and planning up to date as your online life changes.';

  @override
  String get addAssetButton => 'Add asset';

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
      'Your family list connects to your will, trust, and Property Trust planning. Add executors (Co-Sampul), beneficiaries, and guardians.';

  @override
  String get assignExecutorsCoSampul =>
      'Assign executors (Co-Sampul) who will carry out your will.';

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
  String get coSampulExecutor => 'Co-sampul (Executor)';

  @override
  String get coSampulExecutorHelp =>
      'Co-sampul (Executor): A trusted person who executes your will together with you.';

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
  String get addYourFirstAsset => 'Add Your First Asset';

  @override
  String get startTrackingYourDigitalAssets =>
      'Start tracking your digital assets';

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
  String get setUpYourFamilyTrustAccount => 'Set up your Family Trust account';

  @override
  String get createFamilyAccountForLongTermSupport =>
      'Create a family account to manage long-term support (optional).';

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
  String get familyTrustFund => 'Family Trust Fund';

  @override
  String get aboutFamilyTrustFund => 'About Family Trust Fund';

  @override
  String get noTrustFundsYet => 'No trust funds yet';

  @override
  String get createNew => 'Create New';

  @override
  String get createTrust => 'Create trust';

  @override
  String get trustCodeUnique => 'Trust code (unique)';

  @override
  String get all => 'All';

  @override
  String get aboutTrustFund => 'About Trust Fund';

  @override
  String get newToTrusts => 'New to trusts?';

  @override
  String get learnMore => 'Learn more';

  @override
  String get startSettingUp => 'Start setting up';

  @override
  String get whySetUpFamilyTrustFund => 'Why set up a Family Trust Fund?';

  @override
  String get familyTrustFundDescription =>
      'A Family Trust Fund lets you decide how your money is used for your family, even when you\'re not around.';

  @override
  String get chooseHowMoneySpent =>
      'Choose how your money is spent (healthcare, school fees, donations)';

  @override
  String get changePlansAnytime => 'Change your plans anytime you want';

  @override
  String get familyKnowsExactly =>
      'Your family knows exactly what to do — no confusion';

  @override
  String get sampulPartnerWithRakyat =>
      'Sampul partner with Rakyat Trustee and Halogen Capital to process your fund. ';

  @override
  String get learnMoreAboutPartners => 'Learn more about our partners';

  @override
  String get trustFundDetails => 'Trust Fund Details';

  @override
  String get deleteTrustFund => 'Delete Trust Fund';

  @override
  String get areYouSureDeleteTrustFund =>
      'Are you sure you want to delete this trust fund? This action cannot be undone.';

  @override
  String get trustFundDeleted => 'Trust Fund deleted';

  @override
  String failedToDeleteTrustFund(String error) {
    return 'Failed to delete trust fund: $error';
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
      'Allocate what this trust fund will cover';

  @override
  String get education => 'Education';

  @override
  String get livingExpenses => 'Living Expenses';

  @override
  String get healthcare => 'Healthcare';

  @override
  String get charitable => 'Charitable';

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
  String get familyAccountCreated => 'Family account created';

  @override
  String get yourFamilyNowHasClearGuidance =>
      'Your family now has clear guidance, even if you\'re not around to explain.';

  @override
  String get whatHappensNow => 'What happens now';

  @override
  String get familyAccountSavedAndFollowed =>
      'This family account is saved and will be followed according to the rules you\'ve set.';

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
  String get openTrust => 'Open trust';

  @override
  String get createTrustFund => 'Create Trust Fund';

  @override
  String get weCouldNotLoadYourProfile =>
      'We could not load your profile automatically. Please fill the details manually.';

  @override
  String get dismiss => 'DISMISS';

  @override
  String get fundSupport => 'Fund Support';

  @override
  String get executorSelection => 'Executor Selection';

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
  String get allAtOnceAtTheEnd => 'All at once at the end';

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
  String get whosThisFamilyTrustAccountFor =>
      'Who\'s this family trust account for?';

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
  String get estFeeR4320yr => 'Est. Fee: RM4,320/yr (Paid from trust funds)';

  @override
  String get executorGoodToKnow =>
      'Your executor acts as a safeguard — not a decision-maker. Choose someone organised and trustworthy. They should be at least 21 years old. At least 2 joint Executors are necessary when one of the beneficiaries is a minor. If one of your beneficiaries is under 18, you\'ll need at least two executors working together. We\'ll remind you about this later.';

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
  String get lumpSumAtTheEnd => 'Lump sum at the end';

  @override
  String get executorType => 'Executor Type';

  @override
  String get selectedExecutors => 'Selected Executors';

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
  String get pleaseSelectAtLeastOneExecutor =>
      'Please select at least one executor';

  @override
  String get pleaseCompleteYourProfileFirst =>
      'Please complete your profile first';

  @override
  String get trustFundCreatedSuccessfully => 'Trust Fund created successfully';

  @override
  String failedToCreateTrustFund(String error) {
    return 'Failed to create trust fund: $error';
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
      'All funds released when the trust period ends';

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
      'Everything released when the trust period ends';

  @override
  String get thisIsAGuide =>
      'This is a guide. Your executor can adjust based on real needs.';

  @override
  String get addCharitableOrganizationsDonate =>
      'Add charitable organizations you would like to donate to';

  @override
  String get addCharity => 'Add Charity/Donation';
}
