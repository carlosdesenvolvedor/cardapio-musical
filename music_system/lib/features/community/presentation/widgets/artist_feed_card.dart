import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:music_system/features/community/domain/entities/post_entity.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/community/presentation/widgets/artist_avatar.dart';
import 'package:music_system/core/presentation/widgets/app_network_image.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/community/domain/repositories/post_repository.dart';
import 'package:music_system/features/community/presentation/bloc/community_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/community_event.dart';
import 'package:music_system/config/theme/app_theme.dart';

class ArtistFeedCard extends StatefulWidget {
  final PostEntity post;
  final String currentUserId;
  final bool isFollowing;

  const ArtistFeedCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isFollowing = false,
  });

  @override
  State<ArtistFeedCard> createState() => _ArtistFeedCardState();
}

class _ArtistFeedCardState extends State<ArtistFeedCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _paramsFromWidget();
  }

  @override
  void didUpdateWidget(covariant ArtistFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _paramsFromWidget();
    }
  }

  void _paramsFromWidget() {
    _isLiked = widget.post.likes.contains(widget.currentUserId);
    _likeCount = widget.post.likes.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          userId: widget.post.authorId,
                          email: '', // Not needed for viewing
                          showAppBar: true,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ArtistAvatar(
                        photoUrl: widget.post.authorPhotoUrl,
                        radius: 16,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                userId: widget.post.authorId,
                                email: '',
                                showAppBar: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Música & Arte',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.currentUserId != widget.post.authorId &&
                    widget.currentUserId.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      if (widget.isFollowing) {
                        context.read<AuthBloc>().add(UnfollowUserRequested(
                            widget.currentUserId, widget.post.authorId));
                      } else {
                        context.read<AuthBloc>().add(FollowUserRequested(
                            widget.currentUserId, widget.post.authorId));
                      }
                    },
                    child: Text(
                      widget.isFollowing ? 'Sou fã' : 'Virar fã',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          GestureDetector(
            onDoubleTap: () => _toggleLike(),
            child: AppNetworkImage(
              imageUrl: widget.post.imageUrl,
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),

          // Toolbar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showCommentsSheet(context),
                  child: const Icon(Icons.chat_bubble_outline, size: 24),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _confirmRepost(context),
                  child: const Icon(Icons.repeat, size: 28), // Repost icon
                ),
                const Spacer(),
                const Icon(Icons.bookmark_outline,
                    size: 26, color: Colors.white),
              ],
            ),
          ),

          // Likes & Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_likeCount curtidas',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${widget.post.authorName} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showCommentsSheet(context),
                  child: const Text(
                    'Ver todos os comentários',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _toggleLike() {
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Faça login para curtir!')));
      return;
    }

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });

    final authState = context.read<AuthBloc>().state;
    String? senderName;
    String? senderPhoto;
    if (authState is ProfileLoaded) {
      senderName = authState.profile.artisticName;
      senderPhoto = authState.profile.photoUrl;
    }

    context.read<CommunityBloc>().add(
          ToggleLikeRequested(
            postId: widget.post.id,
            userId: widget.currentUserId,
            senderName: senderName,
            senderPhoto: senderPhoto,
            postAuthorId: widget.post.authorId,
          ),
        );
  }

  void _confirmRepost(BuildContext context) {
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para repostar!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Repostar Publicação?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Essa publicação aparecerá no seu perfil.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performRepost();
            },
            child: const Text(
              'Repostar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _performRepost() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! ProfileLoaded) return;

    final newPost = PostEntity(
      id: const Uuid().v1(),
      authorId: widget.currentUserId,
      authorName: authState.profile.artisticName,
      authorPhotoUrl: authState.profile.photoUrl,
      imageUrl: widget.post.imageUrl, // Reuse image
      caption: '♻️ Repost de ${widget.post.authorName}: ${widget.post.caption}',
      likes: [],
      createdAt: DateTime.now(),
    );

    try {
      await sl<PostRepository>().createPost(newPost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação repostada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao repostar: $e')));
      }
    }
  }

  void _showCommentsSheet(BuildContext context) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Comentários',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: sl<PostRepository>().getComments(widget.post.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment =
                            comments[index].data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: comment['authorPhotoUrl'] != null
                                ? CachedNetworkImageProvider(
                                    comment['authorPhotoUrl'],
                                  )
                                : null,
                            child: comment['authorPhotoUrl'] == null
                                ? const Icon(Icons.person, size: 14)
                                : null,
                          ),
                          title: Text(
                            comment['authorName'] ?? 'Anônimo',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            comment['text'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
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
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Adicione um comentário...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (commentController.text.isNotEmpty &&
                          widget.currentUserId.isNotEmpty) {
                        // Get current user profile for naming the comment
                        final authState = context.read<AuthBloc>().state;
                        if (authState is ProfileLoaded) {
                          sl<PostRepository>().addComment(
                            postId: widget.post.id,
                            postAuthorId: widget.post.authorId,
                            comment: {
                              'authorId': widget.currentUserId,
                              'authorName': authState.profile.artisticName,
                              'authorPhotoUrl': authState.profile.photoUrl,
                              'text': commentController.text,
                              'createdAt': Timestamp.now(),
                            },
                          );
                          commentController.clear();
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
      ),
    );
  }
}
