import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/story_repository.dart';
import '../../../../injection_container.dart';
import 'comment_tile.dart';

class StoryCommentSheet extends StatefulWidget {
  final StoryEntity story;
  final String currentUserId;

  const StoryCommentSheet({
    super.key,
    required this.story,
    required this.currentUserId,
  });

  @override
  State<StoryCommentSheet> createState() => _StoryCommentSheetState();
}

class _StoryCommentSheetState extends State<StoryCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = sl<StoryRepository>().getStoryComments(widget.story.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Comentários do Story',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum comentário ainda.\nSeja o primeiro!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final commentData =
                          commentDoc.data() as Map<String, dynamic>;
                      // We can reuse CommentTile, but we might need to handle the "postId" properly
                      // For stories, storyId acts as postId for the tile
                      return CommentTile(
                        key: ValueKey(commentDoc.id),
                        postId: widget.story.id,
                        commentId: commentDoc.id,
                        commentData: commentData,
                        isStory: true,
                        onReply: () {
                          // Stories might not support threaded replies yet to keep it simple
                          _commentController.text =
                              '@${commentData['authorName']} ';
                          FocusScope.of(context).requestFocus(FocusNode());
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Adicione um comentário...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_commentController.text.isNotEmpty &&
                        widget.currentUserId.isNotEmpty) {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is ProfileLoaded) {
                        final commentData = {
                          'authorId': widget.currentUserId,
                          'authorName': authState.profile.artisticName,
                          'authorPhotoUrl': authState.profile.photoUrl,
                          'text': _commentController.text,
                          'createdAt': Timestamp.now(),
                        };

                        await sl<StoryRepository>().addStoryComment(
                          storyId: widget.story.id,
                          storyAuthorId: widget.story.authorId,
                          comment: commentData,
                        );

                        if (mounted) {
                          _commentController.clear();
                          // Optional: Focus back or keep it
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Publicar',
                    style: TextStyle(
                      color: Color(0xFFE5B80B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
