import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/change_password_screen.dart';
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

  group('ChangePasswordScreen tests', () {
    testWidgets('ChangePasswordScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('Shows info box with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(
        find.text('Choose a strong password with at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Shows New Password and Confirm New Password labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('Two text fields are present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('New password field has correct hint text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(
        find.widgetWithText(TextField, 'Enter new password'),
        findsOneWidget,
      );
    });

    testWidgets('Confirm password field has correct hint text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(
        find.widgetWithText(TextField, 'Confirm new password'),
        findsOneWidget,
      );
    });

    testWidgets('Change Password button is present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.text('Change Password'), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Change Password button is enabled initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Back button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsNothing);
    });

    testWidgets('Password fields are obscured by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in fields) {
        expect(field.obscureText, isTrue);
      }
    });

    testWidgets('Visibility toggle icons are present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets(
      'Tapping visibility icon on new password field toggles obscure',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ChangePasswordScreen()),
        );
        await tester.pump();

        final visibilityIcons = find.byIcon(Icons.visibility);
        await tester.tap(visibilityIcons.first);
        await tester.pump();

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping visibility icon on confirm password field toggles obscure',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ChangePasswordScreen()),
        );
        await tester.pump();

        final visibilityIcons = find.byIcon(Icons.visibility);
        await tester.tap(visibilityIcons.last);
        await tester.pump();

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      },
    );

    testWidgets('Can type into new password field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter new password'),
        'mypassword123',
      );
      await tester.pump();

      expect(find.text('mypassword123'), findsOneWidget);
    });

    testWidgets('Can type into confirm password field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm new password'),
        'mypassword123',
      );
      await tester.pump();

      expect(find.text('mypassword123'), findsOneWidget);
    });

    testWidgets('Shows snackbar when submitting with empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter a new password'), findsOneWidget);
    });

    testWidgets('Shows snackbar when password is too short', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter new password'),
        'abc',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Shows snackbar when passwords do not match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter new password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm new password'),
        'differentpassword',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Info box icon is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
