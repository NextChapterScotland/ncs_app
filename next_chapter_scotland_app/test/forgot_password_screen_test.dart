import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://localhost:8000', anonKey: 'key');
    } catch (_) {}
  });

  group('ForgotPasswordPage tests', () {
    testWidgets('ForgotPasswordPage renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('Shows title and email text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.text('Enter your email to receive a reset code.'),
        findsOneWidget,
      );
    });

    testWidgets('Email text field is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    });

    testWidgets('Send code button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('Send Code'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Back button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Error message is not shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('Code input not shown initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('6-digit code'), findsNothing);
      expect(find.text('Verify Code'), findsNothing);
    });

    testWidgets('Can type into email field', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsNothing);
    });
    testWidgets('Verify Code button not shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('Verify Code'), findsNothing);
    });

    testWidgets('Resend code button not shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('Resend code'), findsNothing);
    });

    testWidgets('6-digit code field not shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.text('6-digit code'), findsNothing);
    });

    testWidgets('Only one text field shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Send Code button is enabled initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Email field is enabled initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      expect(emailField.enabled, isNotNull);
    });

    testWidgets('Subtitle shows correct initial text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordPage()));
      await tester.pump();

      expect(
        find.text('Enter your email to receive a reset code.'),
        findsOneWidget,
      );
    });
  });
}
