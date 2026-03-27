import 'package:supabase_flutter/supabase_flutter.dart';

String getTimeSincePosted(DateTime postedAt) {
  Duration timeDiff = DateTime.now().difference(postedAt);
  if (timeDiff.inDays > 0) {
    return "${timeDiff.inDays}d ago";
  } else if (timeDiff.inHours > 0) {
    return "${timeDiff.inHours}h ago";
  }
  return "${timeDiff.inMinutes}m ago";
}

Future<int> fetchUserLikes(SupabaseClient supabase, String userId) async {
  final userPosts = await supabase
      .from('ForumPost')
      .select('id')
      .eq('author', userId);

  final postIds = (userPosts as List).map((p) => p['id']).toList();

  if (postIds.isEmpty) return 0;

  final votes = await supabase
      .from('PostVote')
      .select('id')
      .inFilter('post_id', postIds);

  return (votes as List).length;
}
