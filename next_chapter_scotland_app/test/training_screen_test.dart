import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/training_screen.dart';
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

  group('TrainingScreen tests', () {
    testWidgets('TrainingScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      expect(find.byType(TrainingScreen), findsOneWidget);
    });

    testWidgets('Shows correct app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Training'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Shows ready to start learning text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      expect(find.text('Ready to start learning?'), findsOneWidget);
    });

    testWidgets('Shows training portal button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      expect(find.text('Go to Training Portal on our website'), findsOneWidget);
    });

    testWidgets('Shows open in new icon', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingScreen()),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingScreen), findsNothing);
    });

    testWidgets('Background colour is correct', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF7F7F7));
    });
  });
}
