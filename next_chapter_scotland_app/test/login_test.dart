import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/login.dart';
import 'package:next_chapter_scotland_app/screens/signup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage Tests', () {
    testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Log In to continue'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Log In button disabled when requirements not met', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      final button = tester.widget<ElevatedButton>(loginButton);

      expect(button.onPressed, isNull);
    });

    testWidgets('Password visible toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

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
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      final guestButton = find.widgetWithText(
        ElevatedButton,
        'Continue as guest',
      );

      expect(guestButton, findsOneWidget);
    });

    testWidgets('Sign Up link is there and is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      final loginLink = find.text('Sign Up');
      expect(loginLink, findsOneWidget);

      final gestureDetector = find.ancestor(
        of: loginLink,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsOneWidget);
    });

    testWidgets('Logo image is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

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
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
    });

    testWidgets('Back button navigates to signup page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SignupPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  });
}
