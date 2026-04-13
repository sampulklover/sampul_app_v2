import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/services/faraid_beneficiary_share.dart';

void main() {
  group('suggestedPercentagesForAllBeneficiaries', () {
    test('two sons each get half when no other heirs', () {
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'relationship': 'son'},
        <String, dynamic>{'id': 2, 'relationship': 'son'},
      ];
      final Map<int, double> m = FaraidBeneficiaryShare.suggestedPercentagesForAllBeneficiaries(
        futureOwnerRows: rows,
        deceasedMale: true,
      );
      expect(m.length, 2);
      expect(m[1], closeTo(50.0, 0.06));
      expect(m[2], closeTo(50.0, 0.06));
    });
  });

  group('FaraidBeneficiaryShare STMB-style sample', () {
    test('male deceased: 1 wife, 2 sons, 1 daughter, both parents', () {
      const FaraidHeirTally tally = FaraidHeirTally(
        wives: 1,
        fathers: 1,
        mothers: 1,
        sons: 2,
        daughters: 1,
      );
      const bool deceasedMale = true;

      expect(
        FaraidBeneficiaryShare.suggestedPercentageForRelationship(
          relationship: 'wife',
          tally: tally,
          deceasedMale: deceasedMale,
        ),
        closeTo(12.5, 0.06),
      );
      expect(
        FaraidBeneficiaryShare.suggestedPercentageForRelationship(
          relationship: 'father',
          tally: tally,
          deceasedMale: deceasedMale,
        ),
        closeTo(16.67, 0.06),
      );
      expect(
        FaraidBeneficiaryShare.suggestedPercentageForRelationship(
          relationship: 'mother',
          tally: tally,
          deceasedMale: deceasedMale,
        ),
        closeTo(16.67, 0.06),
      );
      expect(
        FaraidBeneficiaryShare.suggestedPercentageForRelationship(
          relationship: 'son',
          tally: tally,
          deceasedMale: deceasedMale,
        ),
        closeTo(21.67, 0.06),
      );
      expect(
        FaraidBeneficiaryShare.suggestedPercentageForRelationship(
          relationship: 'daughter',
          tally: tally,
          deceasedMale: deceasedMale,
        ),
        closeTo(10.83, 0.06),
      );
    });
  });

  group('FaraidHeirTally', () {
    test('fromRelationshipList maps spouse by deceased sex', () {
      final FaraidHeirTally maleDeceased = FaraidHeirTally.fromRelationshipList(
        <String?>['spouse', 'wife'],
        deceasedMale: true,
      );
      expect(maleDeceased.wives, 2);
      expect(maleDeceased.husbands, 0);

      final FaraidHeirTally femaleDeceased = FaraidHeirTally.fromRelationshipList(
        <String?>['spouse'],
        deceasedMale: false,
      );
      expect(femaleDeceased.husbands, 1);
      expect(femaleDeceased.wives, 0);
    });

    test('withExtraRelationship adds one heir', () {
      const FaraidHeirTally base = FaraidHeirTally(sons: 1);
      final FaraidHeirTally t = base.withExtraRelationship('daughter', deceasedMale: true);
      expect(t.sons, 1);
      expect(t.daughters, 1);
    });
  });
}
