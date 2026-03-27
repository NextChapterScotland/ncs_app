import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/category_page.dart';
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

  group('CategoryPage tests', () {
    testWidgets('CategoryPage renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryPage(
            categoryName: 'Work',
            categoryUrl: 'https://www.nextchapterscotland.org.uk/work',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CategoryPage), findsOneWidget);
    });

    testWidgets('AppBar shows correct category name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryPage(
            categoryName: 'Work',
            categoryUrl: 'https://www.nextchapterscotland.org.uk/work',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Work')),
        findsOneWidget,
      );
    });

    testWidgets('Shows no topics found when no data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryPage(
            categoryName: 'Work',
            categoryUrl: 'https://www.nextchapterscotland.org.uk/work',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No topics found.'), findsOneWidget);
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryPage(
                    categoryName: 'Work',
                    categoryUrl: 'https://www.nextchapterscotland.org.uk/work',
                    color: Color(0xFFD7C7FF),
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

      expect(find.byType(CategoryPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPage), findsNothing);
    });

    testWidgets('Background colour is correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryPage(
            categoryName: 'Work',
            categoryUrl: 'https://www.nextchapterscotland.org.uk/work',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFD7C7FF));
    });
  });
}
