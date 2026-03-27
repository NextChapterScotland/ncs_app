import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
// import 'package:next_chapter_scotland_app/utilities/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_screen.dart';
import 'user_profile_view.dart';
import 'login.dart';

class Forum extends StatefulWidget {
  final bool isGuest;
  final bool isAdmin;
  final SupabaseClient supabase;
  const Forum({
    super.key,
    this.isGuest = false,
    this.isAdmin = false,
    required this.supabase,
  });

  @override
  State<Forum> createState() => _ForumState();
}

class _ForumState extends State<Forum> {
  static const int _pageSize = 10;
  final List<Map<String, dynamic>> _posts = [];
  bool _isFetchingMore = false;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  String _selectedFilter = 'most_recent_post';
  String? _selectedTopicId;
  final Set<int> _likedPosts = {};
  final Set<int> _pinnedPosts = {};
  bool _isAdmin = false;

  void _showGuestLoginDialog(String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login required"),
        content: Text("Log in to $action."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEDD33),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text("Log In"),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _topics = [
    {
      'id': '1',
      'name': 'Work',
      'icon': Icons.work,
      'color': const Color.fromARGB(255, 105, 178, 237),
    },
    {
      'id': '2',
      'name': 'Health',
      'icon': Icons.favorite,
      'color': const Color.fromARGB(255, 217, 164, 238),
    },
    {
      'id': '3',
      'name': 'Housing',
      'icon': Icons.home,
      'color': const Color.fromARGB(255, 112, 235, 144),
    },
    {
      'id': '4',
      'name': 'Family & Society',
      'icon': Icons.family_restroom,
      'color': const Color.fromARGB(255, 234, 236, 151),
    },
    {
      'id': '5',
      'name': 'Money Matters',
      'icon': Icons.attach_money,
      'color': const Color.fromARGB(255, 102, 232, 246),
    },
    {
      'id': '6',
      'name': 'Living Life',
      'icon': Icons.self_improvement,
      'color': const Color.fromARGB(255, 155, 218, 238),
    },
    {
      'id': '7',
      'name': 'Criminal Justice System',
      'icon': Icons.gavel,
      'color': const Color.fromARGB(255, 238, 212, 155),
    },
    {
      'id': '8',
      'name': 'Defending Your Rights',
      'icon': Icons.security,
      'color': const Color.fromARGB(255, 252, 172, 247),
    },
  ];

  final List<Map<String, String>> _filterOptions = [
    {'value': 'most_recent_post', 'label': 'Most Recent Post'},
    {'value': 'most_replies', 'label': 'Most Replies'},
    {'value': 'most_recent_reply', 'label': 'Most Recent Reply'},
  ];

  Future<void> _loadPosts({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _posts.clear();
          _hasMore = true;
          _isLoading = true;
        });
      }
    } else {
      if (_isFetchingMore || !_hasMore) return;
      if (mounted) setState(() => _isFetchingMore = true);
    }

    try {
      final newPosts = List<Map<String, dynamic>>.from(
        await widget.supabase.rpc(
          'get_filtered_posts',
          params: {
            'sort_by': _selectedFilter,
            'topic_filter': _selectedTopicId,
            'search_query': _searchQuery.isEmpty ? null : _searchQuery,
            'page_size': _pageSize,
            'page_offset': reset ? 0 : _posts.length,
          },
        ),
      );

      Set<int> likedPosts = {};
      Set<int> pinnedPosts = {};

      for (var newPost in newPosts) {
        if (newPost['liked']) {
          likedPosts.add(newPost['id']); 
        }
        if (newPost['pinned']) {
          pinnedPosts.add(newPost['id']);
        }
      }

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _likedPosts.addAll(likedPosts);
          _pinnedPosts.addAll(pinnedPosts);
          _hasMore = newPosts.length == _pageSize;
          _isLoading = false;
          _isFetchingMore = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients &&
            _scrollController.position.maxScrollExtent == 0 &&
            _hasMore) {
          _loadPosts();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  void _resetAndReload() => _loadPosts(reset: true);

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _resetAndReload();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _loadPosts();
    }
  }

  void _submitPost(
    String title,
    String body,
    String userID,
    String topicId,
  ) async {
    await widget.supabase.from('ForumPost').insert({
      'title': title,
      'body': body,
      'author': userID,
      'topic': topicId,
    });
    _resetAndReload();
  }

  void _updatePinnedPost(int postID, bool pinnedValue) async {
    await widget.supabase
        .from('ForumPost')
        .update({'pinned': pinnedValue})
        .eq('id', postID);
  }

  void _updateLikedPost(int postID, bool likedValue) async {
    if (likedValue) {
      await widget.supabase.from('PostVote').delete().match({
        'post_id': postID,
        'user_id': widget.supabase.auth.currentUser!.id,
      });
    } else {
      await widget.supabase.from('PostVote').insert({
        'post_id': postID,
        'user_id': widget.supabase.auth.currentUser!.id,
      });
    }
  }

  String _getTimeSincePosted(DateTime postedAt) {
    Duration timeDiff = DateTime.now().difference(postedAt);
    if (timeDiff.inDays > 0) return "${timeDiff.inDays}d ago";
    if (timeDiff.inHours > 0) return "${timeDiff.inHours}h ago";
    return "${timeDiff.inMinutes}m ago";
  }

  String _getTimeSinceLastReply(String? lastReplyAt) {
    if (lastReplyAt == null) return 'No replies';
    try {
      DateTime replyTime = DateTime.parse(lastReplyAt);
      Duration timeDiff = DateTime.now().difference(replyTime);
      if (timeDiff.inDays > 0) return "Last reply ${timeDiff.inDays}d ago";
      if (timeDiff.inHours > 0) return "Last reply ${timeDiff.inHours}h ago";
      if (timeDiff.inMinutes > 0) {
        return "Last reply ${timeDiff.inMinutes}m ago";
      }
      return "Just now";
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFFFEDD33);
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

  Color _getTopicColor(String? topicId) {
    if (topicId == null) return Colors.grey;
    final topic = _topics.firstWhere(
      (t) => t['id'] == topicId,
      orElse: () => {'color': Colors.grey},
    );
    return topic['color'] as Color;
  }

  IconData _getTopicIcon(String? topicId) {
    if (topicId == null) return Icons.label;
    final topic = _topics.firstWhere(
      (t) => t['id'] == topicId,
      orElse: () => {'icon': Icons.label},
    );
    return topic['icon'] as IconData;
  }

  String _getTopicName(String? topicId) {
    if (topicId == null) return 'Unknown';
    final topic = _topics.firstWhere(
      (t) => t['id'] == topicId,
      orElse: () => {'name': 'Unknown'},
    );
    return topic['name'] as String;
  }

  Widget _buildTopicChip(
    String? topicId,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedTopicId == topicId;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (mounted) {
          setState(() {
            _selectedTopicId = selected ? topicId : null;
          });
        }
        _resetAndReload();
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      ),
    );
  }

  void _openCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _CreatePostPopup(
                  topics: _topics,
                  onSubmit: (title, body, topicId) {
                    Navigator.pop(context);
                    _submitPost(
                      title,
                      body,
                      widget.supabase.auth.currentUser!.id,
                      topicId,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _isAdmin = widget.isAdmin;
    _checkIfAdmin();
    _loadPosts(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkIfAdmin() async {
    if (widget.isGuest) return;
    final currentUserId = widget.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    final profile = await widget.supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUserId)
        .maybeSingle();
    if (profile != null && profile['role'] == 'admin') {
      if (mounted) setState(() => _isAdmin = true);
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      await widget.supabase.from('ForumComment').delete().eq('post', postId);
      await widget.supabase.from('ForumPost').delete().eq('id', postId);
      _resetAndReload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFEDD33),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Forum',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.exit_to_app, color: Color(0xFFCC3300)),
              tooltip: 'Quick Exit',
              onPressed: () => exit(0),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isGuest)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6CC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFEDD33)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "You're browsing as a guest. Log in to post, like, or comment.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDD33),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text("Log In"),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              child: Center(
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search questions, topics, or authors...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          // Sort Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEDD33).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sort by:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _filterOptions.map((option) {
                        return DropdownMenuItem(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          if (mounted) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          }
                          _resetAndReload();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Topic Filter Horizontal Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEDD33).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Filter by topic:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTopicChip(
                        null,
                        'All',
                        Icons.all_inclusive,
                        Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      ..._topics.map(
                        (topic) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildTopicChip(
                            topic['id'],
                            topic['name'],
                            topic['icon'],
                            topic['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Posts List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPosts(reset: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                  ? const Center(child: Text('No posts found'))
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _posts.length + (_isFetchingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final p = _posts[index];
                        final isLiked = _likedPosts.contains(p['id']);
                        final isPinned = _pinnedPosts.contains(p['id']);
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<dynamic>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostScreen(
                                  post: p,
                                  isPinned: isPinned,
                                  isLiked: isLiked,
                                  isGuest: widget.isGuest,
                                  isAdmin: _isAdmin,
                                  supabase: widget.supabase,
                                ),
                              ),
                            );
                            // Always reload when returning from a post so
                            // last_reply_at and comment_count stay up to date
                            _loadPosts(reset: true);
                            if (result != null && result != 'deleted') {
                              if (mounted) {
                                setState(() {
                                  result['liked'] ? _likedPosts.add(p['id']) : _likedPosts.remove(p['id']);
                                  result['pinned'] ? _pinnedPosts.add(p['id']) : _pinnedPosts.remove(p['id']);
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                  color: Colors.black.withValues(alpha: 0.05),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFEDD33,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getTimeSincePosted(
                                          DateTime.parse(p['created_at']),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (p['topic'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTopicColor(
                                            p['topic']?.toString(),
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _getTopicColor(
                                              p['topic']?.toString(),
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getTopicIcon(
                                                p['topic']?.toString(),
                                              ),
                                              size: 12,
                                              color: _getTopicColor(
                                                p['topic']?.toString(),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getTopicName(
                                                p['topic']?.toString(),
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getTopicColor(
                                                  p['topic']?.toString(),
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const Spacer(),
                                    if (_selectedFilter ==
                                            'most_recent_reply' &&
                                        p['last_reply_at'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            _getTimeSinceLastReply(
                                              p['last_reply_at']?.toString(),
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_isAdmin) ...[
                                      GestureDetector(
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              isPinned ? _pinnedPosts.remove(p['id']) : _pinnedPosts.add(p['id']);
                                            });
                                          }
                                          _updatePinnedPost(
                                            p['id'],
                                            _pinnedPosts.contains(p['id']),
                                          );
                                        },
                                        child: Icon(
                                          isPinned
                                              ? Icons.push_pin
                                              : Icons.push_pin_outlined,
                                          color: isPinned
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 0,
                                          minHeight: 0,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                  'Delete Post',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this post?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _deletePost(p['id']);
                                                    },
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete post',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: Icon(
                                          Icons.more_horiz,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ] else if (isPinned) ...[
                                      const Icon(
                                        Icons.push_pin,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  p['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  p['body'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showUserProfileView(
                                          context,
                                          p['author'],
                                          p['author_name'],
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: _hexToColor(
                                              p['profile_colour'],
                                            ),
                                            child: Text(
                                              p['author_name'][0],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            p['author_name'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationStyle:
                                                  TextDecorationStyle.dotted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (widget.isGuest || widget.supabase.auth.currentUser == null) {
                                              _showGuestLoginDialog(
                                                "like posts",
                                              );
                                              return;
                                            }
                                            if (mounted) {
                                              setState(() {
                                                if (isLiked) {
                                                  if (p['votes'] > 0) {
                                                    p['votes']--;
                                                  }
                                                  _likedPosts.remove(p['id']);
                                                } else {
                                                  p['votes']++;
                                                  _likedPosts.add(p['id']);
                                                }
                                              });
                                            }
                                            _updateLikedPost(p['id'], isLiked);
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLiked
                                                    ? Icons.thumb_up_alt
                                                    : Icons
                                                          .thumb_up_alt_outlined,
                                                size: 16,
                                                color: isLiked
                                                    ? const Color(0xFFFEDD33)
                                                    : Colors.black,
                                              ),
                                              const SizedBox(width: 4),
                                              Text('${p['votes']}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 16,
                                              color:
                                                  _selectedFilter ==
                                                      'most_replies'
                                                  ? const Color(0xFFFEDD33)
                                                  : Colors.black,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${p['comment_count']}',
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedFilter ==
                                                        'most_replies'
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    _selectedFilter ==
                                                        'most_replies'
                                                    ? const Color(0xFFFEDD33)
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFFFEDD33),
              onPressed: _openCreatePostSheet,
              child: const Icon(Icons.add, color: Colors.black),
            ),
    );
  }
}

class _CreatePostPopup extends StatefulWidget {
  final Function(String title, String body, String topicId) onSubmit;
  final List<Map<String, dynamic>> topics;

  const _CreatePostPopup({required this.onSubmit, required this.topics});

  @override
  State<_CreatePostPopup> createState() => _CreatePostPopupState();
}

class _CreatePostPopupState extends State<_CreatePostPopup> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedTopicId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "What's your question or topic?",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),

              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please choose the topic you think fits best with your post',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedTopicId,
                  decoration: const InputDecoration(
                    labelText: "Select Topic",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(Icons.topic),
                  ),
                  hint: const Text('Choose a topic for your post'),
                  isExpanded: true,
                  items: widget.topics.map((topic) {
                    return DropdownMenuItem<String>(
                      value: topic['id'] as String,
                      child: Row(
                        children: [
                          Icon(topic['icon'], size: 18, color: topic['color']),
                          const SizedBox(width: 8),
                          Text(
                            topic['name'],
                            style: TextStyle(
                              color: topic['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _selectedTopicId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a topic';
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Body text",
                  hintText: "Provide more details about your post...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEDD33),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    if (_selectedTopicId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a topic')),
                      );
                      return;
                    }
                    if (_bodyController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter body text')),
                      );
                      return;
                    }
                    widget.onSubmit(
                      _titleController.text.trim(),
                      _bodyController.text.trim(),
                      _selectedTopicId!,
                    );
                  },
                  child: const Text(
                    "Post",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
