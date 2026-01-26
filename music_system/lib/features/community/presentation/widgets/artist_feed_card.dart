import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:music_system/features/community/domain/entities/post_entity.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/community/presentation/widgets/artist_avatar.dart';
import 'comment_tile.dart';
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
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isSaved = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _paramsFromWidget();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    if (widget.currentUserId.isEmpty) return;
    final result = await sl<PostRepository>().isPostSaved(
      widget.currentUserId,
      widget.post.id,
    );
    result.fold(
      (l) => null,
      (saved) {
        if (mounted) {
          setState(() => _isSaved = saved);
        }
      },
    );
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

    // Se tiver postType explícito, usamos ele (posts novos v2.5)
    // Se não tiver, tentamos detectar pela URL (retrocompatibilidade)
    final type = widget.post.postType;
    final url = widget.post.imageUrl.toLowerCase();

    _isVideo = type == 'video' ||
        (type == 'image' &&
            (url.contains('/video/upload/') ||
                url.endsWith('.mp4') ||
                url.contains('.mp4?')));

    if (_isVideo) {
      _initVideo();
    } else {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  void _initVideo() {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.imageUrl),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.setVolume(1.0);
          _videoController?.play();
        }
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
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
                            (widget.post.authorName == 'Artista Sem Nome' ||
                                    widget.post.authorName.isEmpty)
                                ? 'MixArter'
                                : widget.post.authorName,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog(context);
                    } else if (value == 'unfollow') {
                      context.read<AuthBloc>().add(UnfollowUserRequested(
                          widget.currentUserId, widget.post.authorId));
                    } else if (value == 'like') {
                      _toggleLike();
                    } else if (value == 'comment') {
                      _showCommentsSheet(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'like',
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border,
                              color: Colors.white70, size: 20),
                          SizedBox(width: 10),
                          Text('Curtir'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'comment',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              color: Colors.white70, size: 20),
                          SizedBox(width: 10),
                          Text('Comentar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem_outlined,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Denunciar'),
                        ],
                      ),
                    ),
                    if (widget.isFollowing)
                      const PopupMenuItem(
                        value: 'unfollow',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove_outlined,
                                color: Colors.white70, size: 20),
                            SizedBox(width: 10),
                            Text('Deixar de ser fã'),
                          ],
                        ),
                      ),
                  ],
                  color: Colors.grey[900],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content (Imagem Única, Vídeo ou Carrossel)
          Column(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.width,
                ),
                width: double.infinity,
                child: _isVideo
                    ? GestureDetector(
                        onDoubleTap: () => _toggleLike(),
                        child: (_videoController != null &&
                                _videoController!.value.isInitialized
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : Container(
                                height: MediaQuery.of(context).size.width,
                                color: Colors.black,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              )),
                      )
                    : widget.post.postType == 'carousel'
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              if (widget.post.mediaUrls.isEmpty) ...[
                                const Center(
                                    child: Text('Erro ao carregar mídia')),
                              ],
                              ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                }),
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: widget.post.mediaUrls.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                  },
                                  itemBuilder: (context, index) =>
                                      GestureDetector(
                                    onDoubleTap: () => _toggleLike(),
                                    onTapUp: (details) {
                                      final double screenWidth =
                                          MediaQuery.of(context).size.width;
                                      final double tapPosition =
                                          details.localPosition.dx;
                                      if (tapPosition < screenWidth * 0.3) {
                                        if (_currentPage > 0) {
                                          _pageController.previousPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      } else if (tapPosition >
                                          screenWidth * 0.7) {
                                        if (_currentPage <
                                            widget.post.mediaUrls.length - 1) {
                                          _pageController.nextPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      }
                                    },
                                    child: AppNetworkImage(
                                      imageUrl: widget.post.mediaUrls[index],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // Setas de navegação (Visíveis se mais de 1 item)
                              if (widget.post.mediaUrls.length > 1) ...[
                                if (_currentPage > 0)
                                  Positioned(
                                    left: 10,
                                    child: _buildNavButton(
                                      icon: Icons.chevron_left,
                                      onPressed: () {
                                        _pageController.previousPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    ),
                                  ),
                                if (_currentPage <
                                    widget.post.mediaUrls.length - 1)
                                  Positioned(
                                    right: 10,
                                    child: _buildNavButton(
                                      icon: Icons.chevron_right,
                                      onPressed: () {
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                              // Contador superior
                              if (widget.post.mediaUrls.length > 1)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentPage + 1}/${widget.post.mediaUrls.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : GestureDetector(
                            onDoubleTap: () => _toggleLike(),
                            child: AppNetworkImage(
                              imageUrl: widget.post.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
              ),
              if (widget.post.postType == 'carousel' &&
                  widget.post.mediaUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.post.mediaUrls.length > 10
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1} de ${widget.post.mediaUrls.length}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.post.mediaUrls.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _currentPage == index ? 12 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: _currentPage == index
                                    ? AppTheme.primaryColor
                                    : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                ),
            ],
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
                GestureDetector(
                  onTap: () => _showSaveOptions(context),
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    size: 26,
                    color: _isSaved ? AppTheme.primaryColor : Colors.white,
                  ),
                ),
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
                        text:
                            '${(widget.post.authorName == 'Artista Sem Nome' || widget.post.authorName.isEmpty) ? "MixArter" : widget.post.authorName} ',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentSheetContent(
        post: widget.post,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _showSaveOptions(BuildContext context) {
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para salvar!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Download no dispositivo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final url = widget.post.imageUrl;
                // Para Web, o melhor é url_launcher
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Não foi possível baixar.')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                _isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                _isSaved ? 'Remover dos salvos' : 'Salvar para ver depois',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleSave();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSave() async {
    final repo = sl<PostRepository>();
    if (_isSaved) {
      final result =
          await repo.unsavePost(widget.currentUserId, widget.post.id);
      result.fold(
        (l) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover: ${l.message}'))),
        (r) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removido dos salvos.')));
        },
      );
    } else {
      final result = await repo.savePost(widget.currentUserId, widget.post.id);
      result.fold(
        (l) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${l.message}'))),
        (r) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salvo para ver depois!')));
        },
      );
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Denunciar Publicação',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Deseja denunciar esta publicação por violação das diretrizes?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Denúncia enviada para análise.')),
              );
            },
            child: const Text('Denunciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}

class CommentSheetContent extends StatefulWidget {
  final PostEntity post;
  final String currentUserId;

  const CommentSheetContent({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<CommentSheetContent> createState() => _CommentSheetContentState();
}

class _CommentSheetContentState extends State<CommentSheetContent> {
  final TextEditingController _commentController = TextEditingController();
  late Stream<QuerySnapshot> _commentsStream;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  String? _replyingToAuthorId;

  @override
  void initState() {
    super.initState();
    _commentsStream = sl<PostRepository>().getComments(widget.post.id);
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
        child: Column(
          children: [
            const Text(
              'Comentários',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final commentData =
                          commentDoc.data() as Map<String, dynamic>;
                      return CommentTile(
                        key: ValueKey(commentDoc.id),
                        postId: widget.post.id,
                        commentId: commentDoc.id,
                        commentData: commentData,
                        onReply: () {
                          setState(() {
                            _replyingToCommentId = commentDoc.id;
                            _replyingToAuthorName = commentData['authorName'];
                            _replyingToAuthorId = commentData['authorId'];
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10),
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.white12,
                child: Row(
                  children: [
                    Text(
                      'Respondendo a $_replyingToAuthorName',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToAuthorName = null;
                          _replyingToAuthorId = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
                        final userData = {
                          'authorId': widget.currentUserId,
                          'authorName': authState.profile.artisticName,
                          'authorPhotoUrl': authState.profile.photoUrl,
                          'text': _commentController.text,
                          'createdAt': Timestamp.now(),
                        };

                        final repo = sl<PostRepository>();
                        if (_replyingToCommentId == null) {
                          await repo.addComment(
                            postId: widget.post.id,
                            postAuthorId: widget.post.authorId,
                            comment: userData,
                          );
                        } else {
                          await repo.addReply(
                            postId: widget.post.id,
                            commentId: _replyingToCommentId!,
                            commentAuthorId: _replyingToAuthorId!,
                            reply: userData,
                          );
                        }

                        if (mounted) {
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToAuthorName = null;
                            _replyingToAuthorId = null;
                          });
                          _commentController.clear();
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
