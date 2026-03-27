import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/my_posts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://localhost:8000', anonKey: 'key');
    } catch (_) {}
  });

  group('MyPostsScreen Tests', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPostsScreen(userId: 'test-user-id', username: 'TestUser'),
        ),
      );
      await tester.pump();

      expect(find.byType(MyPostsScreen), findsOneWidget);
    });

    testWidgets('Displays My Posts title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPostsScreen(userId: 'test-user-id', username: 'TestUser'),
        ),
      );
      await tester.pump();

      expect(find.text('My Posts'), findsWidgets);
    });

    testWidgets('Has correct background colour', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPostsScreen(userId: 'test-user-id', username: 'TestUser'),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF7F7F7));
    });

    testWidgets('Has correct appBar colour', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPostsScreen(userId: 'test-user-id', username: 'TestUser'),
        ),
      );
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFFEDD33));
    });

    testWidgets('Displays back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyPostsScreen(
                      userId: 'test-user-id',
                      username: 'TestUser',
                    ),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
