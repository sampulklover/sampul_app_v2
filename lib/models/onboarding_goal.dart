import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum OnboardingGoal {
  familyAccount,
  protectProperty,
  managePusaka,
  writeWasiat,
  getGuidance,
  notSure,
}

extension OnboardingGoalExtension on OnboardingGoal {
  String getTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case OnboardingGoal.familyAccount:
        return l10n.openFamilyAccount;
      case OnboardingGoal.protectProperty:
        return l10n.protectProperty;
      case OnboardingGoal.managePusaka:
        return l10n.managePusaka;
      case OnboardingGoal.writeWasiat:
        return l10n.writeWasiat;
      case OnboardingGoal.getGuidance:
        return l10n.getGuidanceTitle;
      case OnboardingGoal.notSure:
        return l10n.notSureWhereToStart;
    }
  }

  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case OnboardingGoal.familyAccount:
        return l10n.openFamilyAccountDescription;
      case OnboardingGoal.protectProperty:
        return l10n.protectPropertyDescription;
      case OnboardingGoal.managePusaka:
        return l10n.managePusakaDescription;
      case OnboardingGoal.writeWasiat:
        return l10n.writeWasiatDescription;
      case OnboardingGoal.getGuidance:
        return l10n.getGuidanceDescription;
      case OnboardingGoal.notSure:
        return l10n.notSureDescription;
    }
  }

  String get assetPath {
    switch (this) {
      case OnboardingGoal.familyAccount:
        return 'assets/trust-family-card.png';
      case OnboardingGoal.protectProperty:
        return 'assets/hibah-house-key.png';
      case OnboardingGoal.managePusaka:
        return 'assets/pusaka-color-box.png';
      case OnboardingGoal.writeWasiat:
        return 'assets/will-certificate-scroll.png';
      case OnboardingGoal.getGuidance:
        return 'assets/guidance-compass.png';
      case OnboardingGoal.notSure:
        return 'assets/stack-color-chart.png';
    }
  }

  List<OnboardingStepType> get requiredSteps {
    switch (this) {
      case OnboardingGoal.familyAccount:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.familyMember,
          OnboardingStepType.trust,
        ];
      case OnboardingGoal.protectProperty:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.asset,
          OnboardingStepType.hibah,
        ];
      case OnboardingGoal.managePusaka:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.familyMember,
          OnboardingStepType.execution,
        ];
      case OnboardingGoal.writeWasiat:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.familyMember,
          OnboardingStepType.asset,
          OnboardingStepType.will,
        ];
      case OnboardingGoal.getGuidance:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.sampulAI,
          OnboardingStepType.aftercare,
        ];
      case OnboardingGoal.notSure:
        return [
          OnboardingStepType.profile,
          OnboardingStepType.familyMember,
          OnboardingStepType.asset,
        ];
    }
  }

  int get minimumRequiredSteps {
    switch (this) {
      case OnboardingGoal.familyAccount:
        return 2; // profile, family (trust is optional)
      case OnboardingGoal.protectProperty:
        return 2; // profile, asset (hibah is optional enhancement)
      case OnboardingGoal.managePusaka:
        return 2; // profile, family (execution is optional)
      case OnboardingGoal.writeWasiat:
        return 3; // profile, family, asset (will is the final step)
      case OnboardingGoal.getGuidance:
        return 1; // just profile
      case OnboardingGoal.notSure:
        return 3; // profile, family, asset (standard flow)
    }
  }
}

enum OnboardingStepType {
  profile,
  familyMember,
  asset,
  will,
  trust,
  hibah,
  execution,
  sampulAI,
  aftercare,
}

extension OnboardingStepTypeExtension on OnboardingStepType {
  String getTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case OnboardingStepType.profile:
        return l10n.completeYourProfile;
      case OnboardingStepType.familyMember:
        return l10n.addYourFirstFamilyMember;
      case OnboardingStepType.asset:
        return l10n.addYourFirstAsset;
      case OnboardingStepType.will:
        return l10n.createYourWill;
      case OnboardingStepType.trust:
        return l10n.setUpYourFamilyTrustAccount;
      case OnboardingStepType.hibah:
        return l10n.setUpPropertyTrustHibah;
      case OnboardingStepType.execution:
        return l10n.setUpExecution;
      case OnboardingStepType.sampulAI:
        return l10n.chatWithSampulAI;
      case OnboardingStepType.aftercare:
        return l10n.setUpAftercare;
    }
  }

  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case OnboardingStepType.profile:
        return l10n.setUpYourBasicInformation;
      case OnboardingStepType.familyMember:
        return l10n.addSomeoneImportantToYourWill;
      case OnboardingStepType.asset:
        return l10n.startTrackingYourDigitalAssets;
      case OnboardingStepType.will:
        return l10n.createYourWillWithSampul;
      case OnboardingStepType.trust:
        return l10n.createFamilyAccountForLongTermSupport;
      case OnboardingStepType.hibah:
        return l10n.setUpHibahInstructionsForProperty;
      case OnboardingStepType.execution:
        return l10n.setUpExecutionDescription;
      case OnboardingStepType.sampulAI:
        return l10n.sampulAIDescription;
      case OnboardingStepType.aftercare:
        return l10n.aftercareDescription;
    }
  }

  IconData get icon {
    switch (this) {
      case OnboardingStepType.profile:
        return Icons.person_outline;
      case OnboardingStepType.familyMember:
        return Icons.family_restroom;
      case OnboardingStepType.asset:
        return Icons.account_balance_wallet_outlined;
      case OnboardingStepType.will:
        return Icons.description_outlined;
      case OnboardingStepType.trust:
        return Icons.account_balance_outlined;
      case OnboardingStepType.hibah:
        return Icons.home_outlined;
      case OnboardingStepType.execution:
        return Icons.assignment_turned_in_outlined;
      case OnboardingStepType.sampulAI:
        return Icons.chat_outlined;
      case OnboardingStepType.aftercare:
        return Icons.volunteer_activism_outlined;
    }
  }

  bool get isRequired {
    switch (this) {
      case OnboardingStepType.profile:
      case OnboardingStepType.familyMember:
      case OnboardingStepType.asset:
        return true;
      case OnboardingStepType.will:
      case OnboardingStepType.trust:
      case OnboardingStepType.hibah:
      case OnboardingStepType.execution:
      case OnboardingStepType.sampulAI:
      case OnboardingStepType.aftercare:
        return false;
    }
  }
}
