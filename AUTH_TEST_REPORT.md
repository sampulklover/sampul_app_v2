# Test Coverage Report

## Purpose

This file gives a simple snapshot of the Flutter tests currently in the project.

Most of the current tests focus on:

- business logic that does not need live backend access
- form validation on important screens
- model parsing and helper methods
- flow rules that are easy to break during future changes

## Current test coverage

### Auth and account screens

- `test/login_screen_test.dart`
  - empty login form shows validation errors
  - invalid email and short password show validation errors
  - login screen can navigate to sign up

- `test/signup_screen_test.dart`
  - empty sign-up form shows validation errors
  - mismatched passwords show validation errors
  - sign-up screen can navigate back to login

- `test/forgot_password_screen_test.dart`
  - empty email shows validation error
  - invalid email shows validation error
  - screen text renders correctly

### Hibah and payment logic

- `test/hibah_model_test.dart`
  - hibah status mapping
  - `Hibah.fromJson`
  - `Hibah.toJson`

- `test/hibah_payment_test.dart`
  - payment success / failed / pending helpers
  - `HibahPayment.fromJson`

- `test/hibah_payment_service_test.dart`
  - registration fee tiers
  - amendment fee calculation
  - execution fee calculation
  - combined payment breakdown

### Will logic

- `test/will_model_and_service_test.dart`
  - will completeness and status
  - `Will.fromJson`
  - `Will.toJson`
  - `WillService.validateWill`
  - `WillService.generateWillDocument`

### Trust, executor, and profile helpers

- `test/trust_and_executor_model_test.dart`
  - trust status mapping
  - trust payment totals and progress
  - trust payment status helpers
  - executor status mapping
  - executor serialization

- `test/user_profile_test.dart`
  - display name fallback
  - religion helper
  - date formatting in `toJson`

### Supporting logic

- `test/onboarding_goal_test.dart`
  - onboarding step rules
  - required vs optional step rules

- `test/relationship_test.dart`
  - relationship lookup
  - legacy relationship checks
  - suggested modern replacements
  - equality behavior

- `test/verification_test.dart`
  - verification parsing
  - `copyWith`
  - completed / expired / active helpers

- `test/extra_wishes_test.dart`
  - mixed input normalization
  - serialization with database field names

- `test/widget_test.dart`
  - basic widget smoke test harness

## Why these tests are useful

These tests help catch common regressions early, for example:

- a validation message disappears
- a payment formula changes by mistake
- a model stops parsing backend data correctly
- a rule-based journey changes unexpectedly
- a generated will document loses important content

They are fast to run and suitable for local development and CI.

## What is still not covered

Some important flows still need either dependency injection, fakes, or integration testing:

- successful email login
- failed email login with real Supabase errors
- successful sign-up flow and verification dialog behavior
- real forgot-password submission
- Google sign-in
- Apple sign-in
- auth state routing in `AuthWrapper`
- end-to-end creation flows for will, trust, hibah, and assets

## Recommended next step

The next high-value improvement is to make backend-driven screens easier to fake in tests.

For auth, that means replacing direct singleton usage like:

- `AuthController.instance.signInWithEmail(...)`
- `AuthController.instance.signUp(...)`
- `AuthController.instance.resetPassword(...)`

with an injectable interface, for example:

- `AuthGateway.signInWithEmail(...)`
- `AuthGateway.signUp(...)`
- `AuthGateway.resetPassword(...)`

That would make it much easier to test:

- loading states
- success navigation
- snackbar error messages
- verification dialog behavior

## Current status

- `flutter test` passes
- coverage now includes auth forms, payment rules, will logic, trust/executor helpers, onboarding rules, and several supporting models
- deeper backend-driven flows will be easier to test after dependency injection or higher-level integration tests
