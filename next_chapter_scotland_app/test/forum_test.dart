import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/forum.dart';
import 'package:next_chapter_scotland_app/screens/login.dart';
import 'package:next_chapter_scotland_app/screens/post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SupabaseClient mockSupabase;
  late MockSupabaseHttpClient mockHttpClient;

  group('Forum tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
      mockSupabase.from('ForumPost').insert({
        'id': 1,
        'created_at': '2026-01-01 20:00:00.000000+00',
        'title': 'Test post',
        'body': 'Test body',
        'author': 1,
        'votes': 10,
        'pinned': false,
        'comment_count': 1,
        'author_name': 'Test author',
        'liked': false,
      });
      mockHttpClient.registerRpcFunction('get_filtered_posts', (
        params,
        tables,
      ) {
        return [
          {
            'id': 1,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'title': 'Test post',
            'body': 'Test body',
            'author': 1,
            'votes': 10,
            'pinned': false,
            'comment_count': 1,
            'author_name': 'Test author',
            'liked': false,
          },
        ];
      });
      mockHttpClient.registerRpcFunction('get_user_stats', (params, tables) {
        return {};
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    testWidgets('Forum page renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forum'), findsOneWidget);
      expect(find.widgetWithIcon(TextField, Icons.search), findsOneWidget);
      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.text('Filter by topic:'), findsOneWidget);
    });

    testWidgets('Sorting dropdown shows all options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Most Recent Post'));
      await tester.pump();

      expect(find.text('Most Replies'), findsOneWidget);
      expect(find.text('Most Recent Reply'), findsOneWidget);
    });

    testWidgets('Post container renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(' ago'), findsOneWidget);
      expect(find.text('Test post'), findsOneWidget);
      expect(find.text('Test body'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('Post author details are displayed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test author'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('Login prompt shows up for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          "You're browsing as a guest. Log in to post, like, or comment.",
        ),
        findsOneWidget,
      );
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('Login prompt does not show up for logged in users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: false, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You\u2019re browsing as a guest. Log in to post, like, or comment.',
        ),
        findsNothing,
      );
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('Login button redirects to login page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Add post button appears for logged in users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: false, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Add post button does not appear for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('Add post popup renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: false, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Choose a topic for your post'), findsOneWidget);
      expect(find.text('Body text'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
    });

    testWidgets('User can enter text into search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithIcon(TextField, Icons.search),
        'Test query',
      );

      expect(find.text('Test query'), findsOneWidget);
    });

    testWidgets('Tapping post container redirects to post screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test post'));
      await tester.pumpAndSettle();

      expect(find.byType(PostScreen), findsOneWidget);
    });

    testWidgets('Pin icon does not appear for non-admin users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: false, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsNothing);
      expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
    });

    testWidgets('Pin icon does not appear for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsNothing);
      expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
    });

    testWidgets('Pin icon appears for admin users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Forum(isGuest: false, isAdmin: true, supabase: mockSupabase),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin_outlined), findsAny);
    });

    testWidgets('Three dots menu does not appear for non-admin users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: false, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('Three dots menu does not appear for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('Three dots menu appears for admin users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Forum(isGuest: false, isAdmin: true, supabase: mockSupabase),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('Tapping three dots shows delete post option', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Forum(isGuest: false, isAdmin: true, supabase: mockSupabase),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Delete post'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete post shows confirmation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Forum(isGuest: false, isAdmin: true, supabase: mockSupabase),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Post'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this post?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Cancelling delete confirmation closes dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Forum(isGuest: false, isAdmin: true, supabase: mockSupabase),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to delete this post?'),
        findsNothing,
      );
      expect(find.text('Test post'), findsOneWidget);
    });
  });
}
