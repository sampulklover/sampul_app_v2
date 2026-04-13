/// Names for PostHog **Screen** events. One list to keep analytics readable.
///
/// Use these with [AnalyticsService.logScreen] or [RouteSettings.name] so
/// the PostHog “URL / Screen” column shows plain words, not `root ('/')`.
abstract final class AnalyticsScreens {
  static const String app = 'App';
  static const String onboarding = 'Onboarding';
  static const String onboardingFlow = 'Onboarding checklist';
  static const String login = 'Login';
  static const String signUp = 'Sign up';
  static const String forgotPassword = 'Forgot password';
  static const String updatePassword = 'Update password';

  static const String editProfile = 'Edit profile';
  static const String referralDashboard = 'Referral dashboard';
  static const String coupons = 'Coupons';
  static const String adminAiSettings = 'Admin: AI settings';
  static const String adminLearningResources = 'Admin: learning resources';
  static const String adminTeamAccess = 'Admin: team access';
  static const String onboardingGoalSelection = 'Onboarding goal selection';

  static const String chatList = 'Chats';
  static const String plansOverview = 'Plans overview';

  static const String trustCreate = 'Create trust';
  static const String trustEdit = 'Edit trust';
  static const String trustInfo = 'About trust';
  static const String trustDashboard = 'Trust dashboard';
  static const String trustManagement = 'Trust management';
  static const String fundSupportConfig = 'Fund support config';

  static const String willManagement = 'Wasiat';
  static const String willGeneration = 'Create or edit will';
  static const String extraWishes = 'Extra wishes';

  static const String assetsList = 'Assets';
  static const String addAsset = 'Add asset';
  static const String editAsset = 'Edit asset';
  static const String aboutAssets = 'About assets';
  static const String assetPreview = 'Asset preview';

  static const String familyList = 'Family';
  static const String addFamilyMember = 'Add family member';
  static const String aboutFamily = 'About family';
  static const String editFamilyMember = 'Edit family member';

  static const String hibahManagement = 'Property trust';
  static const String hibahInfo = 'About property trust';
  static const String hibahCreate = 'Create property trust';
  static const String hibahDetail = 'Property trust detail';
  static const String hibahAssetForm = 'Property trust asset';
  static const String hibahDocumentForm = 'Property trust document';

  static const String executorManagement = 'Pusaka';
  static const String executorInfo = 'About Pusaka';

  static const String checklist = 'Checklist';
  static const String aftercare = 'Aftercare';

  static const String informDeath = 'Inform death';
  static const String informDeathManagement = 'Inform death records';

  static const String notifications = 'Notifications';

  static const String executorCreate = 'Set up executor';

  /// Main shell: default tab matches [mainHome].
  static const String mainHome = 'Home';
  static const String mainLearn = 'Learn';
  static const String mainWasiat = 'Wasiat';
  static const String mainSettings = 'Settings';

  static const String sampulAiChat = 'Sampul AI chat';
}
