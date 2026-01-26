import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:music_system/core/presentation/widgets/app_network_image.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/post_repository.dart';

class CommentTile extends StatefulWidget {
  final String postId;
  final String commentId;
  final Map<String, dynamic> commentData;
  final VoidCallback onReply;

  final bool isStory;

  const CommentTile({
    super.key,
    required this.postId,
    required this.commentId,
    required this.commentData,
    required this.onReply,
    this.isStory = false,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late Stream<QuerySnapshot> _repliesStream;
  bool _showAllReplies = false;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commentId != widget.commentId ||
        oldWidget.postId != widget.postId) {
      _initStream();
    }
  }

  void _initStream() {
    if (widget.isStory) {
      // Stories might not have sub-threaded replies yet, or we can use the same pattern
      // For now, let's keep it compatible or return empty stream
      _repliesStream = const Stream.empty();
    } else {
      _repliesStream =
          sl<PostRepository>().getReplies(widget.postId, widget.commentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundImage: widget.commentData['authorPhotoUrl'] != null
                ? AppNetworkImage.provider(
                    widget.commentData['authorPhotoUrl'],
                  )
                : null,
            child: widget.commentData['authorPhotoUrl'] == null
                ? const Icon(Icons.person, size: 14)
                : null,
          ),
          title: Row(
            children: [
              Text(
                widget.commentData['authorName'] ?? 'Anônimo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onReply,
                child: const Text(
                  'Responder',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          subtitle: Text(
            widget.commentData['text'] ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
        // Replies list
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: StreamBuilder<QuerySnapshot>(
            stream: _repliesStream,
            builder: (context, replySnapshot) {
              if (replySnapshot.hasError) {
                return Text(
                  'Erro ao carregar respostas: ${replySnapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                );
              }

              if (replySnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 20,
                  width: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!replySnapshot.hasData || replySnapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              final allReplies = replySnapshot.data!.docs;
              final repliesToShow =
                  _showAllReplies ? allReplies : allReplies.take(3).toList();
              final hasMore = allReplies.length > 3 && !_showAllReplies;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...repliesToShow.map((replyDoc) {
                    final reply = replyDoc.data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundImage: reply['authorPhotoUrl'] != null
                            ? AppNetworkImage.provider(
                                reply['authorPhotoUrl'],
                              )
                            : null,
                        child: reply['authorPhotoUrl'] == null
                            ? const Icon(Icons.person, size: 10)
                            : null,
                      ),
                      title: Text(
                        reply['authorName'] ?? 'Anônimo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        reply['text'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  if (hasMore)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setState(() => _showAllReplies = true),
                      child: Text(
                        '--- Ver mais ${allReplies.length - 3} respostas',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
