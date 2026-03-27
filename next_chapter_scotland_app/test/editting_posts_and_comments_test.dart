import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'comment_count': 1,
    'author_name': 'Test author',
    'is_edited': false,
  };

  group('Edit functionality tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co',
        'fakeAnonKey',
        httpClient: mockHttpClient,
      );
      mockHttpClient.registerRpcFunction('get_sorted_comments', (params, tables) {
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
            'is_edited': false,
            'author_name': '2nd Test author',
          },
        ];
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    // ── POST EDITED LABEL TESTS ──

    testWidgets('"edited" label does not appear on unedited post', (
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

      expect(find.text('edited'), findsNothing);
    });

    testWidgets('"edited" label appears on post when is_edited is true', (
      WidgetTester tester,
    ) async {
      final editedPost = Map<String, dynamic>.from(post);
      editedPost['is_edited'] = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: editedPost,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('edited'), findsOneWidget);
    });

    testWidgets('"edited" label on post is grey and small', (
      WidgetTester tester,
    ) async {
      final editedPost = Map<String, dynamic>.from(post);
      editedPost['is_edited'] = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: editedPost,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editedText = tester.widget<Text>(find.text('edited'));
      expect(editedText.style?.color, Colors.grey);
      expect(editedText.style?.fontSize, 11);
    });

    // ── COMMENT EDITED LABEL TESTS ──

    testWidgets('"edited" label does not appear on unedited comment', (
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

      expect(find.text('edited'), findsNothing);
    });

    testWidgets('"edited" label appears on comment when is_edited is true', (
      WidgetTester tester,
    ) async {
      // Re-register mock to return an edited comment
      mockHttpClient.registerRpcFunction('get_sorted_comments', (params, tables) {
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
            'is_edited': true,
            'author_name': '2nd Test author',
          },
        ];
      });

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

      expect(find.text('edited'), findsOneWidget);
    });

    // ── EDIT BUTTON VISIBILITY TESTS ──

    testWidgets('Edit button does not appear for guest users', (
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

      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('Edit comment button does not appear for guest users', (
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

      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('Edit comment button does not appear for non-author logged in users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: false,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // logged in user is not comment author (comment author id is 2, no real auth in mock)
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('Edit post option does not appear in menu for admin who is not the author', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: post,
            isPinned: false,
            isLiked: false,
            isGuest: false,
            isAdmin: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit post'), findsNothing);
      expect(find.text('Delete post'), findsOneWidget);
    });

    testWidgets('Both post and comment show edited label when both are edited', (
      WidgetTester tester,
    ) async {
      // Re-register mock to return an edited comment
      mockHttpClient.registerRpcFunction('get_sorted_comments', (params, tables) {
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
            'is_edited': true,
            'author_name': '2nd Test author',
          },
        ];
      });

      final editedPost = Map<String, dynamic>.from(post);
      editedPost['is_edited'] = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PostScreen(
            post: editedPost,
            isPinned: false,
            isLiked: false,
            isGuest: true,
            supabase: mockSupabase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('edited'), findsNWidgets(2));
    });
  });
}