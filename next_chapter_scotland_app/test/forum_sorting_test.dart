import 'package:flutter_test/flutter_test.dart';

// Copy just the _applySorting logic into a standalone function for testing
List<Map<String, dynamic>> applySorting(
  List<Map<String, dynamic>> posts,
  String filter,
) {
  final sortedPosts = List<Map<String, dynamic>>.from(posts);
  switch (filter) {
    case 'most_recent_post':
      sortedPosts.sort(
        (a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])),
      );
      break;
    case 'most_replies':
      sortedPosts.sort(
        (a, b) =>
            (b['comment_count'] as int).compareTo(a['comment_count'] as int),
      );
      break;
    case 'most_recent_reply':
      sortedPosts.sort((a, b) {
        if (a['last_reply_at'] == null && b['last_reply_at'] == null) return 0;
        if (a['last_reply_at'] == null) return 1;
        if (b['last_reply_at'] == null) return -1;
        return DateTime.parse(b['last_reply_at'].toString())
            .compareTo(DateTime.parse(a['last_reply_at'].toString()));
      });
      break;
  }
  sortedPosts.sort((a, b) => b['pinned'] ? 1 : 0);
  return sortedPosts;
}

void main() {
  final List<Map<String, dynamic>> mockPosts = [
    {
      'title': 'Old reply',
      'created_at': '2026-01-01T10:00:00.000Z',
      'comment_count': 1,
      'last_reply_at': '2026-01-01T11:00:00.000Z',
      'pinned': false,
    },
    {
      'title': 'Recent reply',
      'created_at': '2026-01-02T10:00:00.000Z',
      'comment_count': 3,
      'last_reply_at': '2026-03-15T11:00:00.000Z',
      'pinned': false,
    },
    {
      'title': 'No reply',
      'created_at': '2026-01-03T10:00:00.000Z',
      'comment_count': 0,
      'last_reply_at': null,
      'pinned': false,
    },
    {
      'title': 'Pinned post',
      'created_at': '2025-12-01T10:00:00.000Z',
      'comment_count': 0,
      'last_reply_at': null,
      'pinned': true,
    },
  ];

  group('applySorting - most_recent_reply', () {
    test('sorts by most recent last_reply_at descending', () {
      final result = applySorting(mockPosts, 'most_recent_reply');
      // Pinned always first
      expect(result[0]['title'], 'Pinned post');
      // Most recent reply next
      expect(result[1]['title'], 'Recent reply');
      // Older reply after
      expect(result[2]['title'], 'Old reply');
      // No reply goes to bottom
      expect(result[3]['title'], 'No reply');
    });

    test('posts with null last_reply_at go to the bottom', () {
      final result = applySorting(mockPosts, 'most_recent_reply');
      final nonPinned = result.where((p) => p['pinned'] == false).toList();
      expect(nonPinned.last['last_reply_at'], isNull);
    });
  });

  group('applySorting - most_replies', () {
    test('sorts by comment_count descending', () {
      final result = applySorting(mockPosts, 'most_replies');
      final nonPinned = result.where((p) => p['pinned'] == false).toList();
      expect(nonPinned[0]['comment_count'], 3);
      expect(nonPinned[1]['comment_count'], 1);
      expect(nonPinned[2]['comment_count'], 0);
    });
  });

  group('applySorting - pinned posts', () {
    test('pinned posts always appear first regardless of filter', () {
      for (final filter in ['most_recent_post', 'most_replies', 'most_recent_reply']) {
        final result = applySorting(mockPosts, filter);
        expect(result[0]['pinned'], true,
            reason: 'Pinned post should be first for filter: $filter');
      }
    });
  });

  group('applySorting - most_recent_post', () {
    test('sorts by created_at descending', () {
      final result = applySorting(mockPosts, 'most_recent_post');
      final nonPinned = result.where((p) => p['pinned'] == false).toList();
      expect(nonPinned[0]['title'], 'No reply'); // newest created_at
      expect(nonPinned[1]['title'], 'Recent reply');
      expect(nonPinned[2]['title'], 'Old reply');
    });
  });
}