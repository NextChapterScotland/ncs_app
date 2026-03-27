import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_view.dart';
import '../widgets/comment_widgets.dart';
import '../utilities/utility_functions.dart';
import '../screens/login.dart';

class PostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isPinned;
  final bool isLiked;
  final bool isGuest;
  final bool isAdmin;
  final SupabaseClient supabase;
  const PostScreen({
    super.key,
    required this.post,
    required this.isPinned,
    required this.isLiked,
    required this.isGuest,
    this.isAdmin = false,
    required this.supabase,
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final int commentsToFetch = 50;
  late bool _isPinnedState;
  late bool _isLikedState;
  bool _isAdmin = false;
  List<CommentNode> _commentTree = [];
  Set<int> _likedComments = {};
  Map<int, int> _commentVotes = {};
  bool _isLoadingComments = true;
  String? _commentError;

  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  Future<List<Map<String, dynamic>>> _fetchComments(int commentsToFetch) async {
    return await widget.supabase.rpc(
      'get_sorted_comments',
      params: {'post_id': widget.post['id'], 'max_limit': commentsToFetch},
    );
  }

  void _updatePinned(bool pinnedValue) async {
    await widget.supabase
        .from('ForumPost')
        .update({'pinned': pinnedValue})
        .eq('id', widget.post['id']);
  }

  Future<void> _loadComments(commentsToFetch) async {
    if (mounted) {
      setState(() {
        _isLoadingComments = true;
        _commentError = null;
      });
    }

    try {
      final rawCommentData = await _fetchComments(commentsToFetch);

      List<CommentNode> rootNodes = [];
      Map<int, CommentNode> nodeMap = {};
      Set<int> likedComments = {};
      Map<int, int> commentVotes = {};

      for (final comment in rawCommentData) {
        final int id = (comment['id'] as num).toInt();
        nodeMap[id] = CommentNode(data: comment);
      }

      for (final comment in rawCommentData) {
        final int id = (comment['id'] as num).toInt();
        if (comment['parent_comment'] == null) {
          rootNodes.add(nodeMap[id]!);
        } else {
          final int parentID = (comment['parent_comment'] as num).toInt();
          nodeMap[parentID]?.replies.add(nodeMap[id]!);
        }
        if (comment['liked'] ?? false) {
          likedComments.add(comment['id']);
        }
        commentVotes[comment['id']] = comment['votes'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _commentTree = rootNodes;
          _likedComments = likedComments;
          _commentVotes = commentVotes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentError = e.toString();
        });
      }
    } finally {
      _isLoadingComments = false;
    }
  }

  Future<void> _submitComment() async {
    final user = widget.supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in to comment')));
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (mounted) setState(() => _isPostingComment = true);

    try {
      await widget.supabase.from('ForumComment').insert({
        'post': widget.post['id'],
        'text': text,
        'author': user.id,
      });

      if (!mounted) return;

      _commentController.clear();

      if (mounted) {
        setState(() {
          final current = (widget.post['comment_count'] ?? 0);
          if (current is int) {
            widget.post['comment_count'] = current + 1;
          } else {
            widget.post['comment_count'] = 1;
          }
        });
      }

      await _loadComments(commentsToFetch);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _submitReply(int parentID, String text) async {
    await widget.supabase.from('ForumComment').insert({
      'post': widget.post['id'],
      'parent_comment': parentID,
      'text': text,
      'author': widget.supabase.auth.currentUser!.id,
    });

    await _loadComments(commentsToFetch);
  }

  @override
  void initState() {
    super.initState();
    _isPinnedState = widget.isPinned;
    _isLikedState = widget.isLiked;
    _isAdmin = widget.isAdmin;
    _loadComments(commentsToFetch);
    _checkIfAdmin();
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

  // Hard delete for admins — removes row entirely
  Future<void> _deleteComment(int commentId) async {
    try {
      await widget.supabase.from('ForumComment').delete().eq('id', commentId);

      if (mounted) {
        setState(() {
          final current = (widget.post['comment_count'] ?? 1);
          if (current is int && current > 0) {
            widget.post['comment_count'] = current - 1;
          }
        });
      }

      await _loadComments(commentsToFetch);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  // Soft delete for comment authors — marks as deleted, keeps row
  Future<void> _softDeleteComment(int commentId) async {
    try {
      print('=== Soft deleting comment $commentId');
      await widget.supabase
          .from('ForumComment')
          .update({'deleted': true})
          .eq('id', commentId);
      print('=== Soft delete done, reloading...');
      await _loadComments(commentsToFetch);
    } catch (e) {
      print('=== Soft delete error: $e'); // ADD THIS
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  Future<void> _deletePost() async {
    try {
      await widget.supabase
          .from('ForumComment')
          .delete()
          .eq('post', widget.post['id']);
      await widget.supabase
          .from('ForumPost')
          .delete()
          .eq('id', widget.post['id']);
      if (mounted) Navigator.pop(context, 'deleted');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  void _editPost(BuildContext context) {
    final titleController = TextEditingController(text: widget.post['title']);
    final bodyController = TextEditingController(text: widget.post['body']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newBody = bodyController.text.trim();
              if (newTitle.isNotEmpty && newBody.isNotEmpty) {
                await widget.supabase
                    .from('ForumPost')
                    .update({
                      'title': newTitle,
                      'body': newBody,
                      'is_edited': true,
                    })
                    .eq('id', widget.post['id']);
                if (mounted) {
                  setState(() {
                    widget.post['title'] = newTitle;
                    widget.post['body'] = newBody;
                    widget.post['is_edited'] = true;
                  });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

  void _updateLikedComment(int commentID, bool likedValue) async {
    if (likedValue) {
      await widget.supabase.from('CommentVote').delete().match({
        'comment_id': commentID,
        'user_id': widget.supabase.auth.currentUser!.id,
      });
    } else {
      await widget.supabase.from('CommentVote').insert({
        'comment_id': commentID,
        'user_id': widget.supabase.auth.currentUser!.id,
      });
    }
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

  void _toggleCommentLike(int commentID) {
    if (mounted) {
      setState(() {
        bool wasLiked = _likedComments.contains(commentID);
        if (wasLiked) {
          _likedComments.remove(commentID);
          _commentVotes[commentID] = (_commentVotes[commentID] ?? 1) - 1;
        } else {
          _likedComments.add(commentID);
          _commentVotes[commentID] = (_commentVotes[commentID] ?? 0) + 1;
        }
        _updateLikedComment(commentID, wasLiked);
      });
    }
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
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.supabase.auth.currentUser?.id;
    final isPostAuthor =
        currentUserId != null && currentUserId == widget.post['author'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5.0,
                horizontal: 5.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, {
                      'pinned': _isPinnedState,
                      'liked': _isLikedState,
                    }),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "View post",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Main post card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 15.0),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showUserProfileView(
                                context,
                                widget.post['author'],
                                widget.post['author_name'],
                              );
                            },
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _hexToColor(
                                    widget.post['profile_colour'],
                                  ),
                                  child: Text(
                                    widget.post['author_name'][0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.post['author_name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationStyle:
                                            TextDecorationStyle.dotted,
                                      ),
                                    ),
                                    Text(
                                      getTimeSincePosted(
                                        DateTime.parse(
                                          widget.post['created_at'],
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (_isAdmin) ...[
                                GestureDetector(
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        _isPinnedState = !_isPinnedState;
                                        _updatePinned(_isPinnedState);
                                      });
                                    }
                                  },
                                  child: Icon(
                                    _isPinnedState
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: _isPinnedState
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_horiz,
                                    color: Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') _editPost(context);
                                    if (value == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                            'Are you sure you want to delete this post and all its comments?',
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
                                                _deletePost();
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
                                    if (isPostAuthor)
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit post'),
                                          ],
                                        ),
                                      ),
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (widget.isPinned) ...[
                                const Icon(
                                  Icons.push_pin,
                                  color: Colors.black,
                                  size: 26,
                                ),
                              ] else if (isPostAuthor && !widget.isGuest) ...[
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_horiz,
                                    color: Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') _editPost(context);
                                    if (value == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                            'Are you sure you want to delete your post and all its comments?',
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
                                                _deletePost();
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
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit post'),
                                        ],
                                      ),
                                    ),
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text(
                      widget.post['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.post['body'],
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                    if (widget.post['is_edited'] == true)
                      const Text(
                        'edited',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.isGuest ||
                                widget.supabase.auth.currentUser == null) {
                              _showGuestLoginDialog("like posts");
                              return;
                            }
                            if (mounted) {
                              setState(() {
                                if (_isLikedState) {
                                  if (widget.post['votes'] > 0) {
                                    widget.post['votes']--;
                                  }
                                } else {
                                  widget.post['votes']++;
                                }
                                _updateLikedPost(
                                  widget.post['id'],
                                  _isLikedState,
                                );
                                _isLikedState = !_isLikedState;
                              });
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                _isLikedState
                                    ? Icons.thumb_up_alt
                                    : Icons.thumb_up_alt_outlined,
                                size: 22,
                                color: _isLikedState
                                    ? const Color(0xFFFEDD33)
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.post['votes']} likes",
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Replies (${widget.post['comment_count']})",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Replies
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _commentError != null
                  ? Center(child: Text('Error: $_commentError'))
                  : _commentTree.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : RefreshIndicator(
                      onRefresh: () => _loadComments(commentsToFetch),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        itemCount: _commentTree.length,
                        itemBuilder: (context, index) => CommentNodeWidget(
                          supabase: widget.supabase,
                          node: _commentTree[index],
                          likedComments: _likedComments,
                          commentVotes: _commentVotes,
                          depth: 0,
                          isGuest: widget.isGuest,
                          isAdmin: widget.isAdmin,
                          isLiked: _likedComments.contains(
                            _commentTree[index].data['id'],
                          ),
                          isRootComment: true,
                          onSubmitReply: _submitReply,
                          onDeleteComment: _deleteComment,
                          onSoftDeleteComment: _softDeleteComment,
                          onLike: _toggleCommentLike,
                          maxDepth: 4,
                        ),
                      ),
                    ),
            ),
            if (!widget.isGuest)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isPostingComment ? null : _submitComment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEDD33),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isPostingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
