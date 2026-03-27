import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/forum.dart';
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
    'liked': false,
  };

  group('Standard post screen tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
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
        ];
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    testWidgets('Post screen renders without errors', (
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

      expect(find.text('View post'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Post body renders correctly', (WidgetTester tester) async {
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

      expect(find.textContaining(' ago'), findsAtLeastNWidgets(1));
      expect(find.text('Test post'), findsOneWidget);
      expect(find.text('Test body'), findsOneWidget);
      expect(find.text('10 likes'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsAtLeastNWidgets(1));
      expect(find.textContaining('Replies '), findsOneWidget);
    });

    testWidgets('Post author details are displayed correctly', (
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

      expect(find.text('Test author'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('Comment container renders correctly', (
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

      expect(find.text('2nd Test author'), findsOneWidget);
      expect(find.textContaining(' ago'), findsAtLeastNWidgets(1));
      expect(find.text('Test comment'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'Show more replies button does not appear if there are not enough nested replies',
      (WidgetTester tester) async {
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

        expect(find.text('Show more replies'), findsNothing);
      },
    );

    testWidgets('Back arrow redirects to forum page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Forum(isGuest: true, supabase: mockSupabase)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test post'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(Forum), findsOneWidget);
    });

    testWidgets('Comment bar shows up for logged in users', (
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

      expect(find.text('Write a reply...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Comment bar does not show up for guest users', (
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

      expect(find.text('Write a reply...'), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
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

      expect(find.text('Reply'), findsNothing);
      expect(find.byIcon(Icons.reply_rounded), findsNothing);
    });

    testWidgets('Reply popup renders correctly', (WidgetTester tester) async {
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
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      expect(find.text('Reply'), findsNWidgets(2));
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
    });

    testWidgets('Parent comment in reply popup renders correctly', (
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
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      expect(find.text('Test comment'), findsNWidgets(2));
      expect(find.textContaining(' ago'), findsNWidgets(3));
      expect(find.text('2nd Test author'), findsNWidgets(2));
    });

    testWidgets(
      'Pin post icon does not appear for non-admin users if post not pinned',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsNothing);
        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
      },
    );

    testWidgets(
      'Pin post icon appears for non-admin users if post is pinned, but cannot be clicked',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PostScreen(
              post: post,
              isPinned: true,
              isLiked: false,
              isGuest: false,
              supabase: mockSupabase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin), findsOne);
        await tester.tap(find.byIcon(Icons.push_pin));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
        expect(find.byIcon(Icons.push_pin), findsOne);
      },
    );

    testWidgets(
      'Pin post icon does not appear for guest users if post not pinned',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsNothing);
        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
      },
    );

    testWidgets(
      'Pin post icon appears for guest users if post is pinned, but cannot be clicked',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PostScreen(
              post: post,
              isPinned: true,
              isLiked: false,
              isGuest: true,
              supabase: mockSupabase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin), findsOne);
        await tester.tap(find.byIcon(Icons.push_pin));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
        expect(find.byIcon(Icons.push_pin), findsOne);
      },
    );

    testWidgets('Pin post icon appears for admin users', (
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

      expect(find.byIcon(Icons.push_pin_outlined), findsAny);
    });

    testWidgets('Three dots menu does not appear on post for non-admin users', (
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

      expect(find.byIcon(Icons.more_horiz), findsNothing);
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

      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('Three dots menu appears on post and comment for admin users', (
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

      expect(find.byIcon(Icons.more_horiz), findsAtLeastNWidgets(2));
    });

    testWidgets('Tapping three dots on post shows delete post option', (
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

      expect(find.text('Delete post'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete post shows confirmation dialog', (
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

      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Post'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this post and all its comments?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Cancelling delete post confirmation closes the dialog', (
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

      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to delete this post and all its comments?',
        ),
        findsNothing,
      );
      expect(find.text('Test post'), findsOneWidget);
    });

    testWidgets('Tapping three dots on comment shows delete comment option', (
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

      await tester.tap(find.byIcon(Icons.more_horiz).last);
      await tester.pumpAndSettle();

      expect(find.text('Delete comment'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete comment shows confirmation dialog', (
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

      await tester.tap(find.byIcon(Icons.more_horiz).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete comment'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Comment'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this comment?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Cancelling delete comment confirmation closes dialog', (
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

      await tester.tap(find.byIcon(Icons.more_horiz).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete comment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to delete this comment?'),
        findsNothing,
      );
      expect(find.text('Test comment'), findsOneWidget);
    });

    testWidgets(
      'Pin comment icon does not appear for guest users if comment not pinned',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsNothing);
        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
      },
    );

    testWidgets(
      'Pin comment icon does not appear for non-admin users if comment is not pinned',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsNothing);
        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
      },
    );
  });

  group('Tests with a pinned comment', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
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
            'pinned': true,
            'author_name': '2nd Test author',
          },
        ];
      });
    });

    tearDownAll(() async {
      mockHttpClient.close();
    });

    testWidgets(
      'Pin comment icon appears for non-admin users if comment is pinned, but cannot be clicked',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsOne);
        await tester.tap(find.byIcon(Icons.push_pin));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
        expect(find.byIcon(Icons.push_pin), findsOne);
      },
    );

    testWidgets(
      'Pin comment icon appears for guest users if comment is pinned, but cannot be clicked',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.push_pin), findsOne);
        await tester.tap(find.byIcon(Icons.push_pin));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
        expect(find.byIcon(Icons.push_pin), findsOne);
      },
    );

    testWidgets('Pin post icon appears for admin users', (
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

      expect(find.byIcon(Icons.push_pin), findsAny);
    });
  });

  group("Reply nesting tests", () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co', // Does not matter what URL you pass here as long as it's a valid URL
        'fakeAnonKey', // Does not matter what string you pass here
        httpClient: mockHttpClient,
      );
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

    testWidgets('First nested reply container renders correctly', (
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

      expect(find.text('3rd Test author'), findsOneWidget);
      expect(find.text('Test reply'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // Vote count
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('4th nested reply container still renders', (
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

      expect(find.text('5th Test author'), findsOneWidget);
      expect(find.text('Test 4th reply'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // Vote count
      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('5th nested reply container no longer renders', (
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

      expect(find.text("Show more replies"), findsOneWidget);
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

      expect(find.text('Show more replies'), findsOneWidget);
    });

    testWidgets(
      'Show more replies button correctly redirects to MoreCommentsScreen',
      (WidgetTester tester) async {
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
        await tester.scrollUntilVisible(
          find.text("Show more replies"),
          500.0,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text("Show more replies"));
        await tester.pumpAndSettle();

        expect(find.byType(MoreCommentsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Pin comment icon only appears on comment replying directly to post',
      (WidgetTester tester) async {
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

        expect(
          find.byIcon(Icons.push_pin_outlined),
          findsNWidgets(2),
        ); // One icon is at top of screen for pinning post and one on first comment card
      },
    );
  });
}
