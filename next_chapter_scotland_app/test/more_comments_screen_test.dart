import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/more_comments_screen.dart';
import 'package:next_chapter_scotland_app/screens/post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SupabaseClient mockSupabase;
  late MockSupabaseHttpClient mockHttpClient;
  Map<String, dynamic> post = {
    'id': 1,
    'created_at': '2026-01-01 20:00:00.000000+00',
    'title': 'Test post',
    'body': 'Test body',
    'author': 1,
    'votes': 10,
    'pinned': false,
    'comment_count': 5,
    'author_name': 'Test author',
  };

  group("Show more replies screen tests", () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
      mockHttpClient.registerRpcFunction('get_sorted_posts', (params, tables) {
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
          },
        ];
      });
      mockHttpClient.registerRpcFunction('get_sorted_comments', (
        params,
        tables,
      ) {
        return [
          {
            'id': 1,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test comment',
            'votes': 5,
            'post': 1,
            'parent_comment': null,
            'author': 2,
            'pinned': false,
            'author_name': '2nd Test author',
          },
          {
            'id': 2,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test reply',
            'votes': 4,
            'post': 1,
            'parent_comment': 1,
            'author': 3,
            'pinned': false,
            'author_name': '3rd Test author',
          },
          {
            'id': 3,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 2nd reply',
            'votes': 7,
            'post': 1,
            'parent_comment': 2,
            'author': 4,
            'pinned': false,
            'author_name': '4th Test author',
          },
          {
            'id': 4,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 3nd reply',
            'votes': 7,
            'post': 1,
            'parent_comment': 3,
            'author': 5,
            'pinned': false,
            'author_name': '4th Test author',
          },
          {
            'id': 5,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 4th reply',
            'votes': 8,
            'post': 1,
            'parent_comment': 4,
            'author': 6,
            'pinned': false,
            'author_name': '5th Test author',
          },
          {
            'id': 6,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 5th reply',
            'votes': 9,
            'post': 1,
            'parent_comment': 5,
            'author': 2,
            'pinned': false,
            'author_name': '6th Test author',
          },
        ];
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    testWidgets('Source comment renders properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.text('5th Test author'), findsOneWidget);
      expect(find.text('Test 4th reply'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // Vote count
      expect(find.textContaining(' ago'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('Parent comment of source comment is not displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.text('4th Test author'), findsNothing);
      expect(find.text('Test 3rd reply'), findsNothing);
      expect(find.text('7'), findsNothing); // Vote count
    });

    testWidgets('Reply to source comment renders properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.text('6th Test author'), findsOneWidget);
      expect(find.text('Test 5th reply'), findsOneWidget);
      expect(find.text('9'), findsOneWidget); // Vote count
    });

    testWidgets('Reply button does not show up for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.text('Reply'), findsNothing);
      expect(find.byIcon(Icons.reply_rounded), findsNothing);
    });

    testWidgets('Back button redirects to PostScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(PostScreen), findsOneWidget);
    });

    testWidgets('Three dots menu does not appear for guest users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });
  });

  group("Comment container nesting tests", () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
      mockHttpClient.registerRpcFunction('get_sorted_posts', (params, tables) {
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
          },
        ];
      });
      mockHttpClient.registerRpcFunction('get_sorted_comments', (
        params,
        tables,
      ) {
        return [
          {
            'id': 1,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test comment',
            'votes': 5,
            'post': 1,
            'parent_comment': null,
            'author': 2,
            'pinned': false,
            'author_name': '2nd Test author',
          },
          {
            'id': 2,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test reply',
            'votes': 4,
            'post': 1,
            'parent_comment': 1,
            'author': 3,
            'pinned': false,
            'author_name': '3rd Test author',
          },
          {
            'id': 3,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 2nd reply',
            'votes': 7,
            'post': 1,
            'parent_comment': 2,
            'author': 4,
            'pinned': false,
            'author_name': '4th Test author',
          },
          {
            'id': 4,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 3nd reply',
            'votes': 7,
            'post': 1,
            'parent_comment': 3,
            'author': 5,
            'pinned': false,
            'author_name': '4th Test author',
          },
          {
            'id': 5,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 4th reply',
            'votes': 8,
            'post': 1,
            'parent_comment': 4,
            'author': 6,
            'pinned': false,
            'author_name': '5th Test author',
          },
          {
            'id': 6,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 5th reply',
            'votes': 9,
            'post': 1,
            'parent_comment': 5,
            'author': 2,
            'pinned': false,
            'author_name': '6th Test author',
          },
          {
            'id': 7,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 6th reply',
            'votes': 10,
            'post': 1,
            'parent_comment': 6,
            'author': 2,
            'pinned': false,
            'author_name': '7th Test author',
          },
          {
            'id': 8,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 7th reply',
            'votes': 11,
            'post': 1,
            'parent_comment': 7,
            'author': 3,
            'pinned': false,
            'author_name': '8th Test author',
          },
          {
            'id': 9,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 8th reply',
            'votes': 12,
            'post': 1,
            'parent_comment': 8,
            'author': 4,
            'pinned': false,
            'author_name': '9th Test author',
          },
          {
            'id': 10,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 9th reply',
            'votes': 13,
            'post': 1,
            'parent_comment': 9,
            'author': 5,
            'pinned': false,
            'author_name': '10th Test author',
          },
          {
            'id': 11,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 10th reply',
            'votes': 14,
            'post': 1,
            'parent_comment': 10,
            'author': 6,
            'pinned': false,
            'author_name': '11th Test author',
          },
          {
            'id': 12,
            'created_at': '2026-01-01 20:00:00.000000+00',
            'text': 'Test 11th reply',
            'votes': 15,
            'post': 1,
            'parent_comment': 11,
            'author': 2,
            'pinned': false,
            'author_name': '12th Test author',
          },
        ];
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    testWidgets('Show more replies button correctly renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.text('Show more replies'), findsOneWidget);
    });

    testWidgets('Show more replies button correctly redirects to MoreCommentsScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();

      expect(find.byType(MoreCommentsScreen), findsOneWidget);
    });

    testWidgets('Back button redirects to PostScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text("Show more replies"), 500.0, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Show more replies"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(MoreCommentsScreen), findsOneWidget);
    });
  });
}