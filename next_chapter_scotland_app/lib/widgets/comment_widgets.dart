import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:next_chapter_scotland_app/screens/more_comments_screen.dart';
import '../utilities/utility_functions.dart';
import '../screens/login.dart';

class CommentNode {
  final Map<String, dynamic> data;
  final List<CommentNode> replies;

  CommentNode({required this.data, List<CommentNode>? replies})
    : replies = replies ?? [];
}

class CommentNodeWidget extends StatelessWidget {
  final SupabaseClient supabase;
  final CommentNode node;
  final Set<int> likedComments;
  final Map<int, int> commentVotes;
  final int depth;
  final bool isGuest;
  final bool isAdmin;
  final bool isLiked;
  final bool isRootComment;
  final Function(int parentID, String text) onSubmitReply;
  final Function(int commentID) onDeleteComment;
  final Function(int commentID) onSoftDeleteComment;
  final Function(int commentID) onLike;
  final int maxDepth;

  const CommentNodeWidget({
    super.key,
    required this.supabase,
    required this.node,
    required this.likedComments,
    required this.commentVotes,
    required this.depth,
    required this.isGuest,
    required this.isLiked,
    this.isRootComment = false,
    this.isAdmin = false,
    required this.onSubmitReply,
    required this.onDeleteComment,
    required this.onSoftDeleteComment,
    required this.onLike,
    required this.maxDepth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentCard(
            comment: node.data,
            likedComments: likedComments,
            commentVotes: commentVotes[node.data['id']] ?? 0,
            isGuest: isGuest,
            isAdmin: isAdmin,
            isPinned: node.data['pinned'],
            isLiked: isLiked,
            isRootComment: isRootComment,
            supabase: supabase,
            onSubmitReply: onSubmitReply,
            onDeleteComment: onDeleteComment,
            onSoftDeleteComment: onSoftDeleteComment,
            onLike: onLike,
          ),
          depth < maxDepth
              ? Column(
                  children: [
                    ...node.replies.map(
                      (reply) => CommentNodeWidget(
                        supabase: supabase,
                        node: reply,
                        likedComments: likedComments,
                        commentVotes: commentVotes,
                        depth: depth + 1,
                        isGuest: isGuest,
                        isAdmin: isAdmin,
                        isLiked: likedComments.contains(reply.data['id']),
                        onSubmitReply: onSubmitReply,
                        onDeleteComment: onDeleteComment,
                        onSoftDeleteComment: onSoftDeleteComment,
                        onLike: onLike,
                        maxDepth: maxDepth,
                      ),
                    ),
                  ],
                )
              : node.replies.isNotEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MoreCommentsScreen(
                              supabase: supabase,
                              sourceNode: node,
                              likedComments: likedComments,
                              commentVotes: commentVotes,
                              sourceIsLiked: likedComments.contains(
                                node.data['id'],
                              ),
                              isGuest: isGuest,
                              onSubmitReply: onSubmitReply,
                              onLike: onLike,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEDD33),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text("Show more replies"),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> comment;
  final Set<int> likedComments;
  final int commentVotes;
  final bool isGuest;
  final bool isAdmin;
  final bool isRootComment;
  final SupabaseClient supabase;
  final bool isPinned;
  final bool isLiked;
  final Function(int parentID, String text) onSubmitReply;
  final Function(int commentID) onDeleteComment;
  final Function(int commentID) onSoftDeleteComment;
  final Function(int commentID) onLike;

  const CommentCard({
    super.key,
    required this.comment,
    required this.likedComments,
    required this.commentVotes,
    required this.isGuest,
    this.isAdmin = false,
    this.isPinned = false,
    this.isRootComment = false,
    required this.isLiked,
    required this.supabase,
    required this.onSubmitReply,
    required this.onDeleteComment,
    required this.onSoftDeleteComment,
    required this.onLike,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late bool _isPinned = widget.isPinned;
  late bool _isLiked = widget.isLiked;
  late int _voteCount = widget.commentVotes;

  void _updatePinnedComment(int commentID, bool pinnedValue) async {
    await widget.supabase
        .from('ForumComment')
        .update({'pinned': pinnedValue})
        .eq('id', commentID);
  }

  void _editComment(BuildContext context) {
    final controller = TextEditingController(text: widget.comment['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await widget.supabase
                    .from('ForumComment')
                    .update({'text': newText, 'is_edited': true})
                    .eq('id', widget.comment['id']);
                if (mounted) {
                  setState(() {
                    widget.comment['text'] = newText;
                    widget.comment['is_edited'] = true;
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
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.supabase.auth.currentUser?.id;
    final isAuthor =
        currentUserId != null && currentUserId == widget.comment['author'];
    final isDeleted = widget.comment['deleted'] == true;

    // If soft deleted — show placeholder, no author, no actions
    if (isDeleted) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              const Icon(
                Icons.remove_circle_outline,
                color: Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'This comment has been deleted',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.comment['author_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        getTimeSincePosted(
                          DateTime.parse(widget.comment['created_at']),
                        ),
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isAdmin) ...[
                  if (widget.isRootComment) ...[
                    GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _isPinned = !_isPinned;
                          });
                        }
                        _updatePinnedComment(widget.comment['id'], _isPinned);
                      },
                      child: Icon(
                        _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: _isPinned ? Colors.black : Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Comment'),
                            content: const Text(
                              'Are you sure you want to delete this comment?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDeleteComment(widget.comment['id']);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
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
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Delete comment',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (isAuthor && !widget.isGuest) ...[
                  // Author can soft-delete their own comment
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Comment'),
                            content: const Text(
                              'Your comment will be replaced with "This comment has been deleted". Replies will remain.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onSoftDeleteComment(
                                    widget.comment['id'],
                                  );
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
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
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Delete comment',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (widget.isPinned)
                  const Icon(Icons.push_pin, color: Colors.black, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.comment['text'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            if (widget.comment['is_edited'] == true)
              const Text(
                'edited',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            const SizedBox(height: 5),
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
                        _isLiked ? _voteCount-- : _voteCount++;
                        _isLiked = !_isLiked;
                      });
                    }
                    widget.onLike(widget.comment['id']);
                  },
                  child: Row(
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 22,
                        color: _isLiked ? const Color(0xFFFEDD33) : Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "$_voteCount",
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                ),
                if (!widget.isGuest) ...[
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => openReplyPopup(
                      context,
                      widget.onSubmitReply,
                      widget.comment,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Reply",
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthor) ...[
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => _editComment(context),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.grey, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReplyPopup extends StatefulWidget {
  final Function(String text) onSubmit;

  const ReplyPopup({super.key, required this.onSubmit});

  @override
  State<ReplyPopup> createState() => ReplyPopupState();
}

class ReplyPopupState extends State<ReplyPopup> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
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
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                minLines: 6,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: "Reply",
                  hintText: "Enter your reply here...",
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
                    if (_textController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reply')),
                      );
                      return;
                    }
                    widget.onSubmit(_textController.text.trim());
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

void openReplyPopup(
  BuildContext context,
  Function(int parentID, String text) submitPost,
  Map<String, dynamic> comment,
) {
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
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 10.0,
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  comment['deleted'] == true
                                      ? 'Deleted'
                                      : comment['author_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  getTimeSincePosted(
                                    DateTime.parse(comment['created_at']),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          comment['deleted'] == true
                              ? 'This comment has been deleted'
                              : comment['text'],
                          style: TextStyle(
                            fontSize: 16,
                            color: comment['deleted'] == true
                                ? Colors.grey.shade500
                                : Colors.black.withValues(alpha: 0.6),
                            fontStyle: comment['deleted'] == true
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
                ReplyPopup(
                  onSubmit: (text) {
                    Navigator.pop(context);
                    submitPost(comment['id'], text);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
