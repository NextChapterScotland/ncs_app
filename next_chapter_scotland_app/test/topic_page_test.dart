import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/topic_page.dart';
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

  group('TopicPage tests', () {
    testWidgets('TopicPage renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopicPage(
            topicName: 'PVG Scheme',
            topicUrl:
                'https://www.nextchapterscotland.org.uk/topic/pvg-scheme-2025',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TopicPage), findsOneWidget);
    });

    testWidgets('AppBar shows correct topic name', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopicPage(
            topicName: 'PVG Scheme',
            topicUrl:
                'https://www.nextchapterscotland.org.uk/topic/pvg-scheme-2025',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('PVG Scheme'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Shows loading indicator while fetching', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopicPage(
            topicName: 'PVG Scheme',
            topicUrl:
                'https://www.nextchapterscotland.org.uk/topic/pvg-scheme-2025',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No content found.'), findsOneWidget);
    });

    testWidgets('Back button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TopicPage(
                    topicName: 'PVG Scheme',
                    topicUrl:
                        'https://www.nextchapterscotland.org.uk/topic/pvg-scheme-2025',
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

      expect(find.byType(TopicPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(TopicPage), findsNothing);
    });

    testWidgets('Background colour is correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopicPage(
            topicName: 'PVG Scheme',
            topicUrl:
                'https://www.nextchapterscotland.org.uk/topic/pvg-scheme-2025',
            color: Color(0xFFD7C7FF),
          ),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF7F7F7));
    });
  });
}
