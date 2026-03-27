import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/signup.dart';
import 'package:next_chapter_scotland_app/screens/login.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignupPage Tests', () {
    testWidgets('SignupPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign Up to continue'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Email validation works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final emailField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.emailAddress,
      );

      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle &&
              widget.color == Colors.green,
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Password requirements displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Contains a number'), findsOneWidget);
      expect(
        find.text('Contains a special character (!, @, #, ...)'),
        findsOneWidget,
      );
    });

    testWidgets('Password validation updates', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final passwordField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Password',
      );

      await tester.enterText(passwordField, 'Test123!');
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle &&
              widget.color == Colors.green,
        ),
        findsAtLeastNWidgets(3),
      );
    });

    testWidgets('Sign Up button disabled when requirements not met', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      final button = tester.widget<ElevatedButton>(signUpButton);

      expect(button.onPressed, isNull);
    });

    testWidgets('Sign Up button enabled when requirements are met', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final emailField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.emailAddress,
      );
      final passwordField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Password',
      );

      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      await tester.enterText(passwordField, 'ValidPass123!');
      await tester.pump();

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      final button = tester.widget<ElevatedButton>(signUpButton);

      expect(button.onPressed, isNotNull);
    });

    testWidgets('Password visible toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final visibilityIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('Continue as guest button is there', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final guestButton = find.widgetWithText(
        ElevatedButton,
        'Continue as guest',
      );

      expect(guestButton, findsOneWidget);
    });

    testWidgets('Log in link is there and is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final loginLink = find.text('Log In');
      expect(loginLink, findsOneWidget);

      final gestureDetector = find.ancestor(
        of: loginLink,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsOneWidget);
    });

    testWidgets('Password with special characters validated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final passwordField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Password',
      );

      await tester.enterText(passwordField, 'Pass@1234');
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle &&
              widget.color == Colors.green,
        ),
        findsAtLeastNWidgets(3),
      );
    });

    testWidgets('Email shows green checkmark when valid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final emailField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.emailAddress,
      );

      await tester.enterText(emailField, 'valid@email.com');
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle &&
              widget.color == Colors.green,
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Empty email shows grey email icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.email &&
              widget.color == Colors.grey,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Partial password validation shows indicators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final passwordField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Password',
      );

      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.check_circle,
        ),
        findsAtLeastNWidgets(2),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon && widget.icon == Icons.radio_button_unchecked,
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Logo image is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final logoImage = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/next_chapter_logo.png',
      );

      expect(logoImage, findsOneWidget);
    });

    testWidgets('Back button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
    });

    testWidgets('Back button navigates to login page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupPage()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SignupPage), findsNothing);
    });
  });
}
