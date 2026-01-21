import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/features/community/presentation/pages/create_post_page.dart';
import 'package:music_system/features/community/domain/entities/story_entity.dart';
import 'package:music_system/features/community/presentation/bloc/community_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/community_event.dart';
import 'package:music_system/features/community/presentation/bloc/community_state.dart';
import 'package:music_system/features/community/presentation/widgets/artist_avatar.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/auth/presentation/pages/login_page.dart';
import 'package:music_system/features/community/presentation/pages/story_player_page.dart';
import 'package:music_system/features/community/presentation/pages/create_story_page.dart';
import 'package:music_system/features/community/presentation/pages/conversations_page.dart';
import 'package:music_system/features/community/presentation/pages/activity_page.dart';
import 'package:music_system/features/community/domain/entities/notification_entity.dart';
import 'package:music_system/core/services/deezer_service.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_state.dart';
import 'package:music_system/features/community/presentation/widgets/artist_feed_card.dart';
import 'package:music_system/features/community/presentation/widgets/feed_shimmer.dart';
import 'package:music_system/features/live/presentation/pages/live_page.dart';
import 'package:music_system/features/client_menu/presentation/pages/client_menu_page.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/auth/domain/repositories/auth_repository.dart';

class ArtistNetworkPage extends StatefulWidget {
  const ArtistNetworkPage({super.key});

  @override
  State<ArtistNetworkPage> createState() => _ArtistNetworkPageState();
}

class _ArtistNetworkPageState extends State<ArtistNetworkPage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _searchTab = 0; // 0 for Artists, 1 for Musics
  final DeezerService _deezerService = DeezerService();
  List<DeezerSong> _deezerMusicResults = [];
  bool _isSearchingMusic = false;

  // Local state to hold following IDs fetched explicitly
  List<String> _localFollowingIds = [];
  bool _isLoadingData = true; // New state to track loading

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final authState = context.read<AuthBloc>().state;

    String? currentUserId;

    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    } else if (authState is ProfileLoaded && authState.currentUser != null) {
      currentUserId = authState.currentUser!.id;
    }

    if (currentUserId != null) {
      _loadData(currentUserId);
    } else {
      // If we don't have user yet, we wait for AuthState listener or just show empty/loading
      _isLoadingData = false;
    }
  }

  Future<void> _loadData(String userId) async {
    if (mounted) setState(() => _isLoadingData = true);

    context.read<AuthBloc>().add(ProfileRequested(userId));

    // Fetch followed users explicitly since UserEntity/Profile doesn't guarantee it
    final followingResult = await sl<AuthRepository>().getFollowedUsers(userId);

    List<String> loadedFollowingIds = [];
    followingResult.fold(
      (failure) =>
          debugPrint('Error fetching followed users: ${failure.message}'),
      (ids) => loadedFollowingIds = ids,
    );

    // If we failed to load (or list is empty), we might fallback to authState if available,
    // but usually if this call fails, we rely on what we have.
    // Ensure we include ourselves in the feed
    final feedIds = List<String>.from(loadedFollowingIds)..add(userId);

    if (mounted) {
      // Update local state AND trigger Bloc BEFORE setting loading to false
      _localFollowingIds = loadedFollowingIds; // Update this before setState

      context
          .read<CommunityBloc>()
          .add(FetchFeedStarted(followingIds: feedIds));
      context
          .read<CommunityBloc>()
          .add(FetchStoriesStarted(followingIds: loadedFollowingIds));

      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final authState = context.read<AuthBloc>().state;
      List<String> followingIds = [];
      if (authState is Authenticated) {
        followingIds = authState.user.followingIds;
      } else if (authState is ProfileLoaded && authState.currentUser != null) {
        followingIds = authState.currentUser!.followingIds;
      }
      context
          .read<CommunityBloc>()
          .add(LoadMorePostsRequested(followingIds: followingIds));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user profile from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    UserProfile? currentUserProfile;
    List<String> followingIds = [];
    String? currentUserId;

    if (authState is ProfileLoaded) {
      currentUserProfile = authState.profile;
      currentUserId = authState.currentUser?.id;
      // Prioritize local IDs if AuthBloc's list is empty but we fetched something
      if ((authState.currentUser?.followingIds.isEmpty ?? true) &&
          _localFollowingIds.isNotEmpty) {
        followingIds = _localFollowingIds;
      } else {
        followingIds =
            List<String>.from(authState.currentUser?.followingIds ?? []);
      }
    } else if (authState is Authenticated) {
      currentUserId = authState.user.id;
      if (authState.user.followingIds.isEmpty &&
          _localFollowingIds.isNotEmpty) {
        followingIds = _localFollowingIds;
      } else {
        followingIds = List<String>.from(authState.user.followingIds);
      }
      // We need a dummy profile here if it's null, or logic further down might break if it relies on currentUserProfile
      currentUserProfile ??= UserProfile(
        id: authState.user.id,
        email: authState.user.email,
        artisticName: authState.user.displayName,
        pixKey: '',
        photoUrl: authState.user.photoUrl,
        followersCount: 0,
        followingCount: 0,
        profileViewsCount: 0,
        isLive: false,
      );
    }

    // Sempre inclui o próprio usuário para ver seus posts
    if (currentUserId != null && !followingIds.contains(currentUserId)) {
      followingIds.add(currentUserId);
    }

    if (authState is AuthLoading || _isLoadingData) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text(
          _currentIndex == 4
              ? 'MEU PERFIL'
              : (_currentIndex == 1 ? 'BUSCAR' : 'ARTIST NETWORK'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'Outfit',
            fontSize: 20,
          ),
        ),
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.white),
              onPressed: () {
                if (currentUserProfile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreatePostPage(profile: currentUserProfile!),
                    ),
                  ).then((_) {
                    final authState = context.read<AuthBloc>().state;
                    List<String> currentFollowing = [];
                    String? myId;
                    if (authState is Authenticated) {
                      currentFollowing =
                          List<String>.from(authState.user.followingIds);
                      myId = authState.user.id;
                    } else if (authState is ProfileLoaded) {
                      currentFollowing = List<String>.from(
                          authState.currentUser?.followingIds ?? []);
                      myId = authState.currentUser?.id;
                    }
                    if (myId != null && !currentFollowing.contains(myId)) {
                      currentFollowing.add(myId);
                    }
                    context
                        .read<CommunityBloc>()
                        .add(FetchFeedStarted(followingIds: currentFollowing));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Faça login para publicar!')),
                  );
                }
              },
            ),
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final notifications = state.notifications;
                final hasUnread = notifications.any((n) => !n.isRead);
                final hasInvitations = notifications.any(
                  (n) => !n.isRead && n.type == NotificationType.band_invite,
                );
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      if (hasUnread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      if (hasInvitations)
                        Positioned(
                          left: -4,
                          top: -4,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    if (currentUserProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityPage(userId: currentUserProfile!.id),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Faça login para ver atividades!'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                if (currentUserProfile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConversationsPage(userId: currentUserProfile!.id),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Faça login para conversar!')),
                  );
                }
              },
            ),
          ],
          if (_currentIndex == 4 && currentUserProfile != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                context.read<AuthBloc>().add(SignOutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            final ids =
                List<String>.from(state.currentUser?.followingIds ?? []);
            if (state.currentUser?.id != null) {
              ids.add(state.currentUser!.id);
            }
            context
                .read<CommunityBloc>()
                .add(FetchFeedStarted(followingIds: ids));
          } else if (state is Authenticated) {
            final ids = List<String>.from(state.user.followingIds);
            ids.add(state.user.id);
            context
                .read<CommunityBloc>()
                .add(FetchFeedStarted(followingIds: ids));
          }
        },
        child: _currentIndex == 4
            ? (currentUserProfile != null
                ? ProfilePage(
                    userId: currentUserProfile.id,
                    email: '',
                    showAppBar: false,
                  )
                : const Center(child: Text('Faça login para ver seu perfil')))
            : _currentIndex == 1
                ? _buildSearchPage()
                : BlocBuilder<CommunityBloc, CommunityState>(
                    builder: (context, state) {
                      if (state.status == CommunityStatus.loading &&
                          state.posts.isEmpty) {
                        return const FeedShimmer();
                      }

                      final posts = state.posts;

                      return RefreshIndicator(
                        onRefresh: () async {
                          final ids = List<String>.from(followingIds);
                          if (currentUserId != null) ids.add(currentUserId);
                          context.read<CommunityBloc>().add(
                                FetchFeedStarted(
                                    followingIds: ids, isRefresh: true),
                              );
                        },
                        color: AppTheme.primaryColor,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // Stories section (Artists)
                            SliverToBoxAdapter(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .snapshots(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData)
                                    return const SizedBox();

                                  final allUsers = userSnapshot.data!.docs;

                                  final Map<String, List<StoryEntity>>
                                      groupedStories = {};
                                  for (var story in state.stories) {
                                    groupedStories
                                        .putIfAbsent(story.authorId, () => [])
                                        .add(story);
                                  }

                                  // Filtro rígido: Apenas quem eu sigo ou eu mesmo
                                  final Map<String, DocumentSnapshot>
                                      userDocsMap = {
                                    for (var doc in allUsers) doc.id: doc
                                  };

                                  DocumentSnapshot? me;
                                  try {
                                    me = allUsers.firstWhere(
                                      (u) => u.id == currentUserId,
                                    );
                                  } catch (_) {}

                                  // DEBUG: Log filtering logic
                                  debugPrint('--- BUILD STORIES DEBUG ---');
                                  debugPrint('Current User ID: $currentUserId');
                                  debugPrint('Following IDs: $followingIds');
                                  debugPrint(
                                      'Total Stories: ${state.stories.length}');

                                  // Coletamos todos os IDs que devem aparecer (seguidos)
                                  // Removemos o próprio ID para não duplicar com o item "Você"
                                  final Set<String> idsToShow =
                                      Set.from(followingIds);
                                  if (currentUserId != null) {
                                    idsToShow.remove(currentUserId);
                                  }

                                  // Adicionamos autores de stories ativos que eu sigo
                                  for (var story in state.stories) {
                                    // DEBUG: Check each story
                                    // debugPrint('Checking story from: ${story.authorName} (${story.authorId})');

                                    if (followingIds.contains(story.authorId) &&
                                        story.authorId != currentUserId) {
                                      idsToShow.add(story.authorId);
                                    } else {
                                      // debugPrint('Excluded story from ${story.authorName}: Followed? ${followingIds.contains(story.authorId)}');
                                    }
                                  }
                                  debugPrint('Final IDs to Show: $idsToShow');

                                  final bool myStoriesAllViewed =
                                      currentUserId != null &&
                                          groupedStories
                                              .containsKey(currentUserId) &&
                                          groupedStories[currentUserId]!.every(
                                            (s) => s.viewers
                                                .contains(currentUserId),
                                          );

                                  return Container(
                                    height: 125,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        if (me != null)
                                          _buildStoryItem(
                                            'Você',
                                            (me.data() as Map<String, dynamic>)[
                                                'photoUrl'],
                                            isMe: true,
                                            isLive: (me.data() as Map<String,
                                                    dynamic>)['isLive'] ??
                                                false,
                                            isStreaming:
                                                false, // Dono do perfil no story bar geralmente não mostra streaming ali
                                            hasStories:
                                                groupedStories.containsKey(
                                              currentUserId,
                                            ),
                                            allStoriesViewed:
                                                myStoriesAllViewed,
                                            onTap: () {
                                              if (groupedStories.containsKey(
                                                currentUserId,
                                              )) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StoryPlayerPage(
                                                      stories: groupedStories[
                                                          currentUserId]!,
                                                      currentUserId:
                                                          currentUserId,
                                                      followingIds:
                                                          followingIds,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  // Refresh when returning from player
                                                  if (context.mounted) {
                                                    context
                                                        .read<CommunityBloc>()
                                                        .add(FetchStoriesStarted(
                                                            followingIds:
                                                                followingIds));
                                                  }
                                                });
                                              } else {
                                                final authState = context
                                                    .read<AuthBloc>()
                                                    .state;
                                                if (authState
                                                    is ProfileLoaded) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CreateStoryPage(
                                                        profile:
                                                            authState.profile,
                                                      ),
                                                    ),
                                                  ).then((_) {
                                                    // Refresh after creating a story
                                                    context
                                                        .read<CommunityBloc>()
                                                        .add(FetchStoriesStarted(
                                                            followingIds:
                                                                followingIds));
                                                  });
                                                }
                                              }
                                            },
                                          )
                                        else
                                          _buildStoryItem(
                                            'Entrar',
                                            null,
                                            isGuest: true,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginPage(),
                                              ),
                                            ),
                                          ),

                                        // Apresenta usuários seguidos (que estão live ou possuem stories ou simplesmente seguimos)
                                        ...idsToShow.map((userId) {
                                          final userDoc = userDocsMap[userId];
                                          final stories =
                                              groupedStories[userId] ?? [];
                                          final hasStories = stories.isNotEmpty;

                                          String name = 'Artista';
                                          String? photoUrl;
                                          bool isPerforming = false;
                                          bool isStreaming = false;

                                          if (userDoc != null) {
                                            final userData = userDoc.data()
                                                as Map<String, dynamic>;
                                            name = userData['artisticName'] ??
                                                'Artista';
                                            photoUrl = userData['photoUrl'];

                                            final bool isLive =
                                                userData['isLive'] ?? false;
                                            isPerforming = isLive &&
                                                userData['liveUntil'] != null;
                                            isStreaming = isLive &&
                                                userData['liveUntil'] == null;
                                          } else if (hasStories) {
                                            // Fallback para info do story se o doc do usuário não carregou
                                            name = stories.first.authorName;
                                            photoUrl =
                                                stories.first.authorPhotoUrl;
                                          } else {
                                            // Se não temos doc nem stories, não mostramos nada para este ID (evita círculos vazios indesejados)
                                            return const SizedBox();
                                          }

                                          final bool allViewed =
                                              currentUserId != null &&
                                                  hasStories &&
                                                  stories.every(
                                                    (s) => s.viewers.contains(
                                                        currentUserId),
                                                  );

                                          return _buildStoryItem(
                                            name,
                                            photoUrl,
                                            hasStories: hasStories,
                                            allStoriesViewed: allViewed,
                                            isLive: isPerforming,
                                            isStreaming: isStreaming,
                                            onTap: () {
                                              if (isStreaming) {
                                                // 1. Live Streaming
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LivePage(
                                                      liveId: userId,
                                                      isHost: false,
                                                      userId: currentUserId ??
                                                          'viewer_${DateTime.now().millisecondsSinceEpoch}',
                                                      userName: currentUserProfile
                                                              ?.artisticName ??
                                                          'Espectador',
                                                    ),
                                                  ),
                                                );
                                              } else if (hasStories) {
                                                // 2. Stories
                                                // 2. Stories
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StoryPlayerPage(
                                                      stories: stories,
                                                      currentUserId:
                                                          currentUserId,
                                                      followingIds:
                                                          followingIds,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  // Refresh stories to update "viewed" ring status
                                                  if (context.mounted &&
                                                      currentUserId != null) {
                                                    _loadData(currentUserId);
                                                  }
                                                });
                                              } else if (isPerforming) {
                                                // 3. Peça sua música (Menu)
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ClientMenuPage(
                                                            musicianId: userId),
                                                  ),
                                                );
                                              } else {
                                                // 4. Perfil
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProfilePage(
                                                      userId: userId,
                                                      email: (userDoc?.data()
                                                                  as Map<String,
                                                                      dynamic>?)?[
                                                              'email'] ??
                                                          '',
                                                      showAppBar: true,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  // Refresh feed/stories in case user followed/unfollowed
                                                  if (context.mounted &&
                                                      currentUserId != null) {
                                                    _loadData(currentUserId);
                                                  }
                                                });
                                              }
                                            },
                                          );
                                        }),

                                        // Ícone de "Descobrir" ao final
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _currentIndex = 1),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white24,
                                                        width: 2),
                                                  ),
                                                  child: const Icon(
                                                      Icons.explore_outlined,
                                                      color: Colors.white54,
                                                      size: 28),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text('Explorar',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white54)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: Divider(color: Colors.white10, height: 1),
                            ),

                            // Feed section (Posts)
                            if (posts.isEmpty &&
                                state.status == CommunityStatus.success)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.people_outline,
                                          size: 64, color: Colors.white24),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Seu feed está vazio.',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Vire fã de músicos para ver suas postagens.',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () =>
                                            setState(() => _currentIndex = 1),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                        ),
                                        child:
                                            const Text('Virar fã de músicos'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index >= posts.length) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 32),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.primaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    final post = posts[index];
                                    return ArtistFeedCard(
                                      post: post,
                                      currentUserId: currentUserId ?? '',
                                      isFollowing:
                                          followingIds.contains(post.authorId),
                                    );
                                  },
                                  childCount: state.hasReachedMax
                                      ? posts.length
                                      : posts.length + 1,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: _buildBottomBar(
        currentUserProfile,
        followingIds,
        currentUserId,
      ),
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _searchTab == 0
                      ? 'Procurar artistas...'
                      : 'Procurar músicas...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _deezerMusicResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                  if (_searchTab == 1) {
                    _performMusicSearch(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSearchTypeTab('ARTISTAS', 0),
                  const SizedBox(width: 8),
                  _buildSearchTypeTab('MÚSICAS (DEEZER)', 1),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchTab == 0
              ? _buildArtistSearchResults()
              : _buildMusicSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchTypeTab(String label, int index) {
    bool isSelected = _searchTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchTab = index;
          if (_searchTab == 1 && _searchQuery.isNotEmpty) {
            _performMusicSearch(_searchQuery);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  void _performMusicSearch(String query) async {
    if (query.length < 3) {
      setState(() => _deezerMusicResults = []);
      return;
    }
    setState(() => _isSearchingMusic = true);
    final results = await _deezerService.searchSongs(query);
    if (mounted) {
      setState(() {
        _deezerMusicResults = results;
        _isSearchingMusic = false;
      });
    }
  }

  Widget _buildMusicSearchResults() {
    if (_isSearchingMusic) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_deezerMusicResults.isEmpty && _searchQuery.length >= 3) {
      return const Center(
        child: Text(
          'Nenhuma música encontrada',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      itemCount: _deezerMusicResults.length,
      itemBuilder: (context, index) {
        final song = _deezerMusicResults[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: CachedNetworkImageProvider(song.albumCover),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            song.artist,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(
            Icons.music_note_outlined,
            color: Colors.white24,
          ),
        );
      },
    );
  }

  Widget _buildArtistSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredUsers = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['artisticName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum artista encontrado',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            final userId = filteredUsers[index].id;
            final isLive = userData['isLive'] ?? false;
            final liveUntil = userData['liveUntil'] != null
                ? (userData['liveUntil'] as Timestamp).toDate()
                : null;
            final scheduledShow = userData['scheduledShow'] != null
                ? (userData['scheduledShow'] as Timestamp).toDate()
                : null;

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: userData['photoUrl'] != null
                    ? CachedNetworkImageProvider(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                userData['artisticName'] ?? 'Artista',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Artista',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  if (isLive)
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5B80B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            liveUntil != null
                                ? 'TOCANDO AGORA (até ${DateFormat('HH:mm').format(liveUntil)})'
                                : 'TOCANDO AGORA',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (scheduledShow != null &&
                      scheduledShow.isAfter(DateTime.now()))
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFE5B80B).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'PRÓXIMO SHOW: ${DateFormat("dd/MM 'às' HH:mm").format(scheduledShow)}',
                            style: const TextStyle(
                              color: Color(0xFFE5B80B),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      userId: userId,
                      email: '',
                      showAppBar: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStoryItem(
    String name,
    String? photoUrl, {
    required VoidCallback onTap,
    bool isMe = false,
    bool isGuest = false,
    bool isLive = false,
    bool isStreaming = false,
    bool hasStories = false,
    bool allStoriesViewed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          ArtistAvatar(
            photoUrl: photoUrl,
            isMe: isMe,
            isLive: isLive,
            isStreaming: isStreaming,
            hasStories: hasStories,
            allStoriesViewed: allStoriesViewed,
            onTap: onTap,
            radius: 30,
          ),
          const SizedBox(height: 4),
          Text(
            name.split(' ')[0],
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    UserProfile? currentUser,
    List<String> followingIds,
    String? currentUserId,
  ) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 2) {
          if (currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateStoryPage(profile: currentUser),
              ),
            ).then((_) {
              final authState = context.read<AuthBloc>().state;
              List<String> currentFollowing = [];
              String? myId;
              if (authState is Authenticated) {
                currentFollowing =
                    List<String>.from(authState.user.followingIds);
                myId = authState.user.id;
              } else if (authState is ProfileLoaded) {
                currentFollowing = List<String>.from(
                    authState.currentUser?.followingIds ?? []);
                myId = authState.currentUser?.id;
              }
              if (myId != null && !currentFollowing.contains(myId)) {
                currentFollowing.add(myId);
              }
              context
                  .read<CommunityBloc>()
                  .add(FetchFeedStarted(followingIds: currentFollowing));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Faça login para criar stories!')),
            );
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
