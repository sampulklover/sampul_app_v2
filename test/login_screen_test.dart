import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/screens/login_screen.dart';
import 'package:sampul_app_v2/screens/signup_screen.dart';

import 'test_app.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows required field errors on empty submit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows format errors for invalid credentials input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'not-an-email',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('navigates to signup screen', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign up'));
      await tester.tap(find.widgetWithText(TextButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
    });
  });
}
