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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadStory();
    _markAsViewed();
  }

  void _loadStory() {
    _timer?.cancel();
    _percent = 0.0;
    _videoController?.dispose();
    _videoController = null;

    final story = widget.stories[_currentIndex];
    final mediaUrl = CloudinarySanitizer.sanitize(
      story.mediaUrl,
      mediaType: story.mediaType,
    );

    if (story.mediaType == 'video') {
      _videoController = VideoPlayerController.network(mediaUrl)
        ..setVolume(
          0,
        ) // Crucial para Autoplay em navegadores mobile (Safari/iOS)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _startTimer();
          }
        }).catchError((error) {
          debugPrint('Erro ao carregar vídeo: $error');
          // Se falhar o vídeo, pula para o próximo ou mostra erro
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aguardando carregamento do vídeo...'),
                duration: Duration(seconds: 4),
              ),
            );
            _startTimer(); // Inicia o timer mesmo assim para não travar o player
          }
        });
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isPaused) {
        setState(() {
          if (_videoController != null &&
              _videoController!.value.isInitialized) {
            // Sync with video progress
            final duration = _videoController!.value.duration.inMilliseconds;
            final position = _videoController!.value.position.inMilliseconds;
            _percent = position / duration;

            if (_percent >= 1.0) {
              _timer?.cancel();
              _nextStory();
            }
          } else {
            // Default 5s for images
            if (_percent < 1) {
              _percent += 0.01; // 50ms * 100 = 5000ms = 5s
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
      Navigator.pop(context);
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
    _timer?.cancel();
    _videoController?.dispose();
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
            onLongPressStart: (_) {
              setState(() => _isPaused = true);
              _videoController?.pause();
            },
            onLongPressEnd: (_) {
              setState(() => _isPaused = false);
              _videoController?.play();
            },
            onTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3) {
                _previousStory();
              } else if (details.globalPosition.dx > 2 * width / 3) {
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
      setState(() => _isPaused = false);
      _videoController?.play();
    });
  }
}
