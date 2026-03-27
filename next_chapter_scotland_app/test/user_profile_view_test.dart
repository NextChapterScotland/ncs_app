import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/user_profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://localhost:8000', anonKey: 'key');
    } catch (_) {}
  });

  group('UserProfileView Tests', () {
    testWidgets('Renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(UserProfileView), findsOneWidget);
    });

    testWidgets('Displays username', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('Displays correct initial letter in avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('Displays CircleAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('Displays Member since text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Member since'), findsOneWidget);
    });

    testWidgets('Avatar background colour is correct', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pump();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, const Color(0xFFFEDD33));
    });

    testWidgets('Does not display admin post list for non admin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileView(userId: 'test-id', username: 'TestUser'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User Posts'), findsNothing);
    });
  });
}
