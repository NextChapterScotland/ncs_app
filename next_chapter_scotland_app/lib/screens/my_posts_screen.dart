import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  final String userId;
  final String username;

  const MyPostsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchMyPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchMyPosts() async {
    final List<Map<String, dynamic>> allPosts = await _supabase.rpc(
      'get_sorted_posts',
      params: {'max_limit': 1000},
    );

    return allPosts
        .where((p) => p['author'] == widget.userId)
        .map((p) => {...p, 'author_name': widget.username})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEDD33),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Posts',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("You haven't posted anything yet."),
            );
          }

          final posts = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Posts",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: posts
                        .map(
                          (p) => GestureDetector(
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(p['title'] ?? 'Untitled'),
                                subtitle: Text(
                                  p['body'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  DateTime.parse(
                                    p['created_at'],
                                  ).toLocal().toString().split(' ')[0],
                                  style: const TextStyle(fontSize: 10),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostScreen(
                                        post: {
                                          ...p,
                                          'author_name': widget.username,
                                        },
                                        isPinned: p['pinned'] ?? false,
                                        isLiked: false,
                                        isGuest: false,
                                        supabase: _supabase,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
