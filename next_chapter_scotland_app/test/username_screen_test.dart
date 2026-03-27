import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/username_screen.dart';
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

  Widget buildScreen() => MaterialApp(
    home: UsernameScreen(userId: 'test-user-id', email: 'test@example.com'),
  );

  group('UsernameScreen tests', () {
    testWidgets('UsernameScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(UsernameScreen), findsOneWidget);
    });

    testWidgets('Shows title and subtitle text', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Choose a username'), findsOneWidget);
      expect(
        find.text("Keep it anonymous — don't use your real name."),
        findsOneWidget,
      );
    });

    testWidgets('Shows safety warning', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.text('For your safety, DO NOT use identifying information.'),
        findsOneWidget,
      );
    });

    testWidgets('Username text field is present', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    });

    testWidgets('Continue button is present', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Continue button is not available initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Back button is present', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Error message not shown initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('Can type into username field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('Shows error for username under 3 characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error for invalid characters in username', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'bad username!');
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Only letters, numbers, and underscores allowed'),
        findsOneWidget,
      );
    });

    testWidgets('Shows helper text for username rules', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.text('3–20 chars • letters, numbers, underscore\nKeep it respectful'),
        findsOneWidget,
      );
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UsernameScreen(
                    userId: 'test-id',
                    email: 'test@example.com',
                  ),
                ),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(UsernameScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(UsernameScreen), findsNothing);
    });
  });
}
