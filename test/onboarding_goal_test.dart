import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/onboarding_goal.dart';

void main() {
  group('OnboardingGoal rules', () {
    test('writeWasiat flow includes will-related steps', () {
      expect(
        OnboardingGoal.writeWasiat.requiredSteps,
        <OnboardingStepType>[
          OnboardingStepType.profile,
          OnboardingStepType.familyMember,
          OnboardingStepType.asset,
          OnboardingStepType.will,
        ],
      );
      expect(OnboardingGoal.writeWasiat.minimumRequiredSteps, 3);
      expect(
        OnboardingGoal.writeWasiat.assetPath,
        'assets/will-certificate-scroll.png',
      );
    });

    test('protectProperty flow includes hibah path', () {
      expect(
        OnboardingGoal.protectProperty.requiredSteps,
        <OnboardingStepType>[
          OnboardingStepType.profile,
          OnboardingStepType.hibah,
        ],
      );
      expect(OnboardingGoal.protectProperty.minimumRequiredSteps, 1);
    });
  });

  group('OnboardingStepType rules', () {
    test('core setup steps are required', () {
      expect(OnboardingStepType.profile.isRequired, true);
      expect(OnboardingStepType.familyMember.isRequired, true);
      expect(OnboardingStepType.asset.isRequired, true);
    });

    test('advanced steps are optional', () {
      expect(OnboardingStepType.will.isRequired, false);
      expect(OnboardingStepType.trust.isRequired, false);
      expect(OnboardingStepType.hibah.isRequired, false);
      expect(OnboardingStepType.execution.isRequired, false);
      expect(OnboardingStepType.sampulAI.isRequired, false);
      expect(OnboardingStepType.aftercare.isRequired, false);
    });
  });
}
