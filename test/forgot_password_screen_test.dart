import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampul_app_v2/screens/forgot_password_screen.dart';

import 'test_app.dart';

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('shows required field error on empty submit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows invalid email error', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows screen copy', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));

      expect(find.text('Forgot password'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
    });
  });
}
