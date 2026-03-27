import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/comment_widgets.dart';

class MoreCommentsScreen extends StatefulWidget {
  final SupabaseClient supabase;
  final CommentNode sourceNode;
  final Set<int> likedComments;
  final Map<int, int> commentVotes;
  final bool sourceIsLiked;
  final bool isGuest;
  final Function(int parentID, String text) onSubmitReply;
  final Function(int commentID) onLike;

  const MoreCommentsScreen({
    super.key,
    required this.supabase,
    required this.sourceNode,
    required this.likedComments,
    required this.commentVotes,
    required this.sourceIsLiked,
    required this.isGuest,
    required this.onSubmitReply,
    required this.onLike,
  });

  @override
  State<MoreCommentsScreen> createState() => _MoreCommentsScreenState();
}

class _MoreCommentsScreenState extends State<MoreCommentsScreen> {
  final int repliesToFetch = 50;
  List<CommentNode> _replyTree = [];
  bool _isLoadingReplies = true;
  String? _replyError;
  bool _isAdmin = false;

  Future<void> _loadReplies(int repliesToFetch) async {
    if (mounted) {
      setState(() {
        _isLoadingReplies = true;
        _replyError = null;
      });
    }

    try {
      final rawReplyData = await widget.supabase.rpc(
        'get_sorted_comments',
        params: {
          'post_id': widget.sourceNode.data['post'],
          'max_limit': repliesToFetch,
        },
      );

      List<CommentNode> rootNodes = [];
      Map<int, CommentNode> nodeMap = {};

      for (final comment in rawReplyData) {
        final int id = (comment['id'] as num).toInt();
        nodeMap[id] = CommentNode(data: comment);
      }

      for (final comment in rawReplyData) {
        final int id = (comment['id'] as num).toInt();
        if (comment['parent_comment'] != null &&
            comment['parent_comment'] == widget.sourceNode.data['id']) {
          rootNodes.add(nodeMap[id]!);
        } else if (comment['parent_comment'] != null) {
          final int parentID = (comment['parent_comment'] as num).toInt();
          nodeMap[parentID]?.replies.add(nodeMap[id]!);
        }
      }
      if (mounted) {
        setState(() {
          _replyTree = rootNodes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _replyError = e.toString();
        });
      }
    } finally {
      _isLoadingReplies = false;
    }
  }

  // Hard delete for admins
  Future<void> _deleteComment(int commentId) async {
    try {
      await widget.supabase.from('ForumComment').delete().eq('id', commentId);
      await _loadReplies(repliesToFetch);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  // Soft delete for comment authors
  Future<void> _softDeleteComment(int commentId) async {
    try {
      await widget.supabase
          .from('ForumComment')
          .update({'deleted': true})
          .eq('id', commentId);
      await _loadReplies(repliesToFetch);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
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

  @override
  void initState() {
    super.initState();
    _loadReplies(repliesToFetch);
    _checkIfAdmin();
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "More comments",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Source comment card
            CommentCard(
              comment: widget.sourceNode.data,
              likedComments: widget.likedComments,
              commentVotes:
                  widget.commentVotes[widget.sourceNode.data['id']] ?? 0,
              isGuest: widget.isGuest,
              isLiked: widget.sourceIsLiked,
              supabase: widget.supabase,
              onSubmitReply: widget.onSubmitReply,
              onDeleteComment: _deleteComment,
              onSoftDeleteComment: _softDeleteComment,
              onLike: widget.onLike,
            ),
            // Replies
            Expanded(
              child: _isLoadingReplies
                  ? const Center(child: CircularProgressIndicator())
                  : _replyError != null
                  ? Center(child: Text('Error: $_replyError'))
                  : _replyTree.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : RefreshIndicator(
                      onRefresh: () => _loadReplies(repliesToFetch),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        itemCount: _replyTree.length,
                        itemBuilder: (context, index) => CommentNodeWidget(
                          supabase: widget.supabase,
                          node: _replyTree[index],
                          likedComments: widget.likedComments,
                          commentVotes: widget.commentVotes,
                          depth: 1,
                          isGuest: widget.isGuest,
                          isAdmin: _isAdmin,
                          isLiked: widget.likedComments
                              .contains(_replyTree[index].data['id']),
                          onSubmitReply: (parentID, text) {
                            widget.onSubmitReply(parentID, text);
                            _loadReplies(repliesToFetch);
                          },
                          onDeleteComment: _deleteComment,
                          onSoftDeleteComment: _softDeleteComment,
                          onLike: widget.onLike,
                          maxDepth: 4,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}