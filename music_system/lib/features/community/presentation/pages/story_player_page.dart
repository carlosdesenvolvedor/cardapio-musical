import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/story_entity.dart';
import '../../../../core/presentation/widgets/app_network_image.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/story_repository.dart';
import 'package:music_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../../../../core/utils/cloudinary_sanitizer.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';
import '../widgets/story_comment_sheet.dart';

class StoryPlayerPage extends StatefulWidget {
  final List<StoryEntity> stories;
  final int initialIndex;
  final String? currentUserId;
  final List<String>? followingIds;

  const StoryPlayerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.currentUserId,
    this.followingIds,
  });

  @override
  State<StoryPlayerPage> createState() => _StoryPlayerPageState();
}

class _StoryPlayerPageState extends State<StoryPlayerPage> {
  late int _currentIndex;
  double _percent = 0.0;
  Timer? _timer;
  bool _isPaused = false;
  VideoPlayerController? _videoController;
  VideoPlayerController? _prefetchedController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadStory();
    _markAsViewed();
  }

  void _loadStory({bool useRawUrl = false}) {
    _timer?.cancel();
    _percent = 0.0;

    // Clean up current controller safely
    final oldController = _videoController;
    _videoController = null;
    oldController?.pause().then((_) => oldController.dispose());

    final story = widget.stories[_currentIndex];

    // Use pre-fetched controller if available and matching the current story
    if (_prefetchedController != null &&
        _prefetchedController!.dataSource
            .contains(story.mediaUrl.split('/').last.split('.').first)) {
      _videoController = _prefetchedController;
      _prefetchedController = null;

      if (_videoController!.value.isInitialized) {
        _onVideoInitialized();
      } else {
        _videoController!.initialize().then((_) => _onVideoInitialized());
      }
    } else {
      // Clean pre-fetched if not used
      _prefetchedController?.dispose();
      _prefetchedController = null;

      if (story.mediaType == 'video') {
        final mediaUrl = useRawUrl
            ? story.mediaUrl
            : CloudinarySanitizer.sanitize(
                story.mediaUrl,
                mediaType: story.mediaType,
                filterId: story.effects?.filterId,
                startOffset: story.effects?.startOffset,
                endOffset: story.effects?.endOffset,
              );

        final controller =
            VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
        _videoController = controller;

        controller.initialize().then((_) {
          if (_isDisposed || _videoController != controller) {
            controller.dispose();
            return;
          }
          _onVideoInitialized();
        }).catchError((error) {
          debugPrint('Error loading video: $error');
          if (!useRawUrl) {
            debugPrint('Attempting fallback to RAW URL...');
            _loadStory(useRawUrl: true);
          } else {
            _startTimer();
          }
        });
      } else {
        _startTimer();
      }
    }

    _prefetchNext();
  }

  void _onVideoInitialized() {
    if (_isDisposed || _videoController == null) return;
    setState(() {});
    _videoController!.play();
    _videoController!.setLooping(false);
    _startTimer();
  }

  void _prefetchNext() {
    if (_currentIndex + 1 < widget.stories.length) {
      final nextStory = widget.stories[_currentIndex + 1];
      if (nextStory.mediaType == 'video') {
        final nextUrl = CloudinarySanitizer.sanitize(nextStory.mediaUrl,
            mediaType: 'video');
        debugPrint('Prefetching next story: $nextUrl');
        _prefetchedController =
            VideoPlayerController.networkUrl(Uri.parse(nextUrl));
        _prefetchedController!.initialize().then((_) {
          return null;
        }).catchError((e) {
          return null;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (!_isPaused) {
        setState(() {
          if (_videoController != null &&
              _videoController!.value.isInitialized) {
            final duration = _videoController!.value.duration.inMilliseconds;
            final position = _videoController!.value.position.inMilliseconds;
            if (duration > 0) {
              _percent = position / duration;
            }

            if (_percent >= 1.0 ||
                (!_videoController!.value.isPlaying &&
                    _videoController!.value.position >=
                        _videoController!.value.duration)) {
              _timer?.cancel();
              _nextStory();
            }
          } else if (widget.stories[_currentIndex].mediaType == 'image') {
            if (_percent < 1) {
              _percent += 0.01; // 5s approx
            } else {
              _timer?.cancel();
              _nextStory();
            }
          }
        });
      }
    });
  }

  void _markAsViewed() {
    if (widget.currentUserId != null) {
      final story = widget.stories[_currentIndex];
      if (story.authorId != widget.currentUserId) {
        sl<StoryRepository>().markStoryAsViewed(
          story.id,
          widget.currentUserId!,
        );
        // Atualiza o estado local reativamente
        context.read<CommunityBloc>().add(MarkStoryAsViewedRequested(
              storyId: story.id,
              userId: widget.currentUserId!,
            ));
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory();
      _markAsViewed();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory();
      _markAsViewed();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    final c1 = _videoController;
    final c2 = _prefetchedController;
    _videoController = null;
    _prefetchedController = null;
    c1?.pause().then((_) => c1.dispose());
    c2?.dispose();
    super.dispose();
  }

  void _confirmDeletion(BuildContext context) {
    setState(() => _isPaused = true);
    _videoController?.pause();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Excluir Story?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isPaused = false);
              _videoController?.play();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final storyId = widget.stories[_currentIndex].id;
              await sl<StoryRepository>().deleteStory(storyId);
              if (mounted) {
                // Refresh feed
                // ignore: use_build_context_synchronously
                context.read<CommunityBloc>().add(
                    FetchStoriesStarted(followingIds: widget.followingIds));
                // ignore: use_build_context_synchronously
                Navigator.pop(context); // Close dialog
                // ignore: use_build_context_synchronously
                Navigator.pop(context); // Exit player
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final bool isOwner = widget.currentUserId == story.authorId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Media
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) {
              setState(() => _isPaused = true);
              _videoController?.pause();
            },
            onLongPressEnd: (_) {
              setState(() => _isPaused = false);
              _videoController?.play();
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 500) {
                  // Swipe right -> Previous
                  _previousStory();
                } else if (details.primaryVelocity! < -500) {
                  // Swipe left -> Next
                  _nextStory();
                }
              }
            },
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              final x = details.localPosition.dx;
              if (x < width / 3) {
                _previousStory();
              } else if (x > 2 * width / 3) {
                _nextStory();
              }
            },
            child: Center(
              child: story.mediaType == 'video'
                  ? (_videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator())
                  : AppNetworkImage(
                      imageUrl: story.mediaUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          // Top Bars (Progress)
          Positioned(
            top: 60,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Row(
                  children: widget.stories.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: LinearProgressIndicator(
                          value: index == _currentIndex
                              ? _percent
                              : (index < _currentIndex ? 1.0 : 0.0),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Author Info
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: story.authorPhotoUrl != null
                        ? NetworkImage(story.authorPhotoUrl!)
                        : null,
                    child: story.authorPhotoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    story.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: GestureDetector(
                    onTap: () async {
                      setState(() => _isPaused = true);
                      _videoController?.pause();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userId: story.authorId,
                            email: '',
                            showAppBar: true,
                          ),
                        ),
                      );
                      setState(() => _isPaused = false);
                      _videoController?.play();
                    },
                    child: Text(
                      'Ver perfil de ${story.authorName}',
                      style: const TextStyle(
                        color: Color(0xFFE5B80B),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.currentUserId != null &&
                          widget.currentUserId != story.authorId)
                        TextButton(
                          onPressed: () {
                            if (widget.followingIds?.contains(story.authorId) ??
                                false) {
                              context.read<AuthBloc>().add(
                                  UnfollowUserRequested(
                                      widget.currentUserId!, story.authorId));
                            } else {
                              context.read<AuthBloc>().add(FollowUserRequested(
                                  widget.currentUserId!, story.authorId));
                            }
                          },
                          child: Text(
                            (widget.followingIds?.contains(story.authorId) ??
                                    false)
                                ? 'Sou fã'
                                : 'Virar fã',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'report') {
                            _showReportDialog(context);
                          } else if (value == 'like') {
                            _showLikeInfo();
                          } else if (value == 'comment') {
                            _showCommentInfo();
                          } else if (value == 'unfollow') {
                            if (widget.currentUserId != null) {
                              context.read<AuthBloc>().add(
                                  UnfollowUserRequested(
                                      widget.currentUserId!, story.authorId));
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'like',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border,
                                    color: Colors.white70),
                                SizedBox(width: 10),
                                Text('Curtir',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'comment',
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    color: Colors.white70),
                                SizedBox(width: 10),
                                Text('Comentar',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report_problem_outlined,
                                    color: Colors.redAccent),
                                SizedBox(width: 10),
                                Text('Denunciar',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          if (widget.followingIds?.contains(story.authorId) ??
                              false)
                            const PopupMenuItem(
                              value: 'unfollow',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_outlined,
                                      color: Colors.white70),
                                  SizedBox(width: 10),
                                  Text('Deixar de ser fã',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                        ],
                        color: Colors.grey[900],
                      ),
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white70),
                          onPressed: () => _confirmDeletion(context),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Viewers list for owner
          if (isOwner)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  onTap: () => _showViewers(context, story.viewers),
                  child: Column(
                    children: [
                      const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${story.viewers.length} visualizações',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showViewers(BuildContext context, List<String> viewersIds) {
    setState(() => _isPaused = true);
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder(
          future: sl<AuthRepository>().getProfiles(viewersIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data;
            if (result == null || result.isLeft()) {
              return const Center(
                child: Text(
                  'Erro ao carregar visualizadores',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final profiles = result.getOrElse(() => []);

            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Visualizações',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: profiles.isEmpty
                      ? const Center(
                          child: Text(
                            'Ninguém viu ainda 😢',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: profiles.length,
                          itemBuilder: (context, index) {
                            final profile = profiles[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profile.photoUrl != null
                                    ? NetworkImage(profile.photoUrl!)
                                    : null,
                                child: profile.photoUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                profile.artisticName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isPaused = false);
        _videoController?.play();
      }
    });
  }

  void _showReportDialog(BuildContext context) {
    setState(() => _isPaused = true);
    _videoController?.pause();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Denunciar Story',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Deseja denunciar este conteúdo por violação das diretrizes?',
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
    ).then((_) {
      setState(() => _isPaused = false);
      _videoController?.play();
    });
  }

  void _showLikeInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Curtidas em stories estarão disponíveis em breve!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCommentInfo() {
    setState(() => _isPaused = true);
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryCommentSheet(
        story: widget.stories[_currentIndex],
        currentUserId: widget.currentUserId ?? '',
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isPaused = false);
        _videoController?.play();
      }
    });
  }
}
