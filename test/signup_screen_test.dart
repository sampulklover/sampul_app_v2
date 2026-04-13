import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/screens/login_screen.dart';
import 'package:sampul_app_v2/screens/signup_screen.dart';

import 'test_app.dart';

void main() {
  group('SignupScreen', () {
    testWidgets('shows required field errors on empty submit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows mismatch error when passwords differ', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'jane@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('navigates back to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Log in'));
      await tester.tap(find.widgetWithText(TextButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}
