import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/models/relationship.dart';

void main() {
  group('Relationship helpers', () {
    test('getByValue returns expected relationship', () {
      final relationship = Relationship.getByValue('father');

      expect(relationship, isNotNull);
      expect(relationship!.displayName, 'Father');
      expect(relationship.isWaris, true);
    });

    test('legacy relationships are detected', () {
      expect(Relationship.isLegacyRelationship('parent'), true);
      expect(Relationship.isLegacyRelationship('father'), false);
    });

    test('suggested modern relationships map legacy values', () {
      final parentSuggestions =
          Relationship.getSuggestedModernRelationships('parent');
      final spouseSuggestions =
          Relationship.getSuggestedModernRelationships('spouse');

      expect(parentSuggestions.map((r) => r.value), containsAll(<String>['father', 'mother']));
      expect(spouseSuggestions.map((r) => r.value), containsAll(<String>['husband', 'wife']));
    });

    test('relationship equality uses value', () {
      const a = Relationship(
        value: 'friend',
        displayName: 'Friend',
        isWaris: false,
      );
      const b = Relationship(
        value: 'friend',
        displayName: 'Buddy',
        isWaris: false,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
