import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utilities/utility_functions.dart';
import 'post_screen.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _supabase = Supabase.instance.client;
  bool _isAdmin = false;
  bool _loading = true;
  int _postCount = 0;
  int _totalLikes = 0;
  DateTime? _joinedAt;
  String? _profileColour;
  String? _bio;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUserId)
        .maybeSingle();

    if (profile != null && profile['role'] == 'admin' && mounted) {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserPosts() async {
    if (!_isAdmin) return [];

    final List<Map<String, dynamic>> allPosts = await _supabase.rpc(
      'get_sorted_posts',
      params: {'max_limit': 1000},
    );

    return allPosts
        .where((p) => p['author'] == widget.userId)
        .map(
          (p) => {
            ...p,
            'author_name': widget.username,
            'profile_colour': p['profile_colour'],
          },
        )
        .toList();
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _supabase.rpc(
        'get_user_stats',
        params: {'user_id': widget.userId},
      );

      final row = (stats as List).first;

      final profile = await _supabase
          .from('profiles')
          .select('created_at, profile_colour, bio')
          .eq('id', widget.userId)
          .maybeSingle();

      _totalLikes = await fetchUserLikes(_supabase, widget.userId);

      if (mounted) {
        setState(() {
          _postCount = row['post_count'] as int;
          if (profile != null && profile['created_at'] != null) {
            _joinedAt = DateTime.parse(profile['created_at']);
          }
          _profileColour = profile?['profile_colour'];
          _bio = profile?['bio'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _initialFromUsername(String username) {
    final u = username.trim();
    if (u.isEmpty) return '?';
    return u[0].toUpperCase();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return const Color(0xFFFEDD33);
    }

    final cleanedHex = hex
        .trim()
        .replaceAll('#', '')
        .replaceAll("'", '')
        .replaceAll('"', '');

    try {
      return Color(int.parse('FF$cleanedHex', radix: 16));
    } catch (_) {
      return const Color(0xFFFEDD33);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _isAdmin ? 0.4 : 0.35,
      maxChildSize: _isAdmin ? 0.9 : 0.35,
      minChildSize: _isAdmin ? 0.35 : 0.3,
      snap: true,
      snapSizes: _isAdmin ? [0.9] : [],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: scrollController,
                      children: [
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _loading
                                  ? Center(
                                      child: const SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                  )
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundColor: _hexToColor(_profileColour),
                                      child: Text(
                                        _initialFromUsername(widget.username),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.username,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _joinedAt == null
                                          ? 'Member since -'
                                          : 'Member since ${_joinedAt!.day}/${_joinedAt!.month}/${_joinedAt!.year}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (!_loading &&
                                    _bio != null &&
                                    _bio!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Bio',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bio!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator()),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(label: "Posts", value: _postCount.toString()),
                                Container(width: 1, height: 40, color: Colors.grey[300]),
                                _StatItem(
                                  label: "Post Likes",
                                  value: _totalLikes.toString(),
                                ),
                              ],
                            ),
                          ),
                            if (_isAdmin)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchUserPosts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: CircularProgressIndicator()
                                    ),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text("This user has no posts."),
                                );
                              }
                              final posts = snapshot.data!; 
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "User Posts",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                      ...posts.map((p) => GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PostScreen(
                                                post: {
                                                  ...p,
                                                  'author_name': widget.username,
                                                  'profile_colour': p['profile_colour'],
                                                },
                                                isPinned: p['pinned'] ?? false,
                                                isLiked: false,
                                                isGuest: false,
                                                supabase: _supabase,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(p['title'] ?? "Untitled"),
                                            subtitle: Text(
                                              p['body'] ?? "",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Text(
                                              DateTime.parse(
                                                p['created_at'],
                                              ).toLocal().toString().split(' ')[0],
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                      )
                                    )
                                  ],
                                )
                              );
                            },
                          ),
                        const SizedBox(height: 32),
                      ]
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: double.infinity,
                          height: 40,
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

void showUserProfileView(BuildContext context, String userId, String username) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => UserProfileView(userId: userId, username: username),
  );
}
