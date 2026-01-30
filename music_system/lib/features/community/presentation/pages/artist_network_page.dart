import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/features/community/domain/entities/story_entity.dart';
import 'package:music_system/features/community/presentation/bloc/community_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/community_event.dart';
import 'package:music_system/features/community/presentation/bloc/community_state.dart';
import 'package:music_system/features/community/presentation/widgets/artist_avatar.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/community/presentation/pages/story_player_page.dart';
import 'package:music_system/features/community/presentation/pages/create_story_page.dart';
import 'package:music_system/features/community/presentation/pages/create_post_page.dart';
import 'package:music_system/features/community/presentation/pages/activity_page.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_state.dart';
import 'package:music_system/features/community/presentation/widgets/glass_nav_bar.dart';
import 'package:music_system/features/community/presentation/widgets/artist_feed_card.dart';
import 'package:music_system/features/community/presentation/widgets/feed_shimmer.dart';
import 'package:music_system/features/live/presentation/widgets/live_stream_viewer.dart';
import 'package:music_system/features/live/presentation/pages/live_page.dart';
import 'package:music_system/features/wallet/presentation/pages/wallet_page.dart';
import 'package:music_system/features/musician_dashboard/presentation/pages/manage_repertoire_page.dart';
import 'package:music_system/features/bands/presentation/pages/my_bands_page.dart';
import 'package:music_system/features/musician_dashboard/presentation/pages/artist_insights_page.dart';
import 'package:music_system/core/services/notification_service.dart';
import 'package:music_system/injection_container.dart';

import 'package:music_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:music_system/features/auth/domain/entities/user_entity.dart';
import 'package:music_system/features/community/presentation/bloc/story_upload_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/story_upload_state.dart';
import 'package:music_system/features/community/presentation/bloc/post_upload_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/post_upload_state.dart';
import 'package:music_system/main.dart'; // Import to use messengerKey

class ArtistNetworkPage extends StatefulWidget {
  const ArtistNetworkPage({super.key});

  @override
  State<ArtistNetworkPage> createState() => _ArtistNetworkPageState();
}

class _ArtistNetworkPageState extends State<ArtistNetworkPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> _localFollowingIds = [];
  bool _isLoadingData = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
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
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadData(String userId) async {
    if (mounted) setState(() => _isLoadingData = true);

    try {
      // Firing profile and following requests in parallel
      context.read<AuthBloc>().add(ProfileRequested(userId));
      final followingFuture = sl<AuthRepository>().getFollowedUsers(userId);

      final results = await Future.wait([
        followingFuture,
      ]).timeout(const Duration(seconds: 15));

      final followingResult = results[0];

      List<String> loadedFollowingIds = [];
      followingResult.fold(
        (failure) =>
            debugPrint('Error fetching followed users: ${failure.message}'),
        (ids) => loadedFollowingIds = ids,
      );

      if (mounted) {
        _localFollowingIds = loadedFollowingIds;
        final feedIds = List<String>.from(loadedFollowingIds)..add(userId);

        // Parallelize feed and stories fetches
        context
            .read<CommunityBloc>()
            .add(FetchFeedStarted(followingIds: feedIds));
        context
            .read<CommunityBloc>()
            .add(FetchStoriesStarted(followingIds: feedIds));
      }
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      if (mounted) {
        // Ensure the Bloc knows about the failure so the UI updates
        context.read<CommunityBloc>().add(FetchFeedStarted(
            followingIds: const [])); // Or a specific failure event if available, but this might trigger error state if empty
        // Better yet, we can't easily force an error state from here without a specific event.
        // Let's rely on the finally block to stop the spinner, and the UI checking _isLoadingData
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<CommunityBloc>().state;
      if (state.status == CommunityStatus.success && !state.hasReachedMax) {
        context.read<CommunityBloc>().add(LoadMorePostsRequested(
            followingIds: List.from(_localFollowingIds)
              ..add(context.read<AuthBloc>().state is Authenticated
                  ? (context.read<AuthBloc>().state as Authenticated).user.id
                  : '')));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        UserProfile? currentUserProfile;
        UserEntity? currentUserEntity;
        String? currentUserId;
        if (authState is Authenticated) {
          currentUserEntity = authState.user;
          currentUserId = authState.user.id;
        } else if (authState is ProfileLoaded) {
          currentUserProfile = authState.profile;
          currentUserEntity = authState.currentUser;
          currentUserId = authState.profile.id;
        }
        return MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
            BlocListener<PostUploadBloc, PostUploadState>(
              listener: (context, state) {
                if (state.status == PostUploadStatus.success) {
                  if (currentUserId != null) {
                    _loadData(currentUserId);
                  }
                }
              },
            ),
          ],
          child: Scaffold(
            key: _scaffoldKey, // Add a key
            backgroundColor: Colors.black,
            drawer: _buildDrawer(context, authState),
            appBar:
                _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 4
                    ? _buildAppBar(currentUserProfile, currentUserEntity)
                    : null,
            body: Column(
              children: [
                _buildUploadProgressBar(),
                _buildPostUploadProgressBar(),
                Expanded(
                  child: _currentIndex == 0
                      ? _buildFeed(currentUserId, currentUserProfile)
                      : _currentIndex == 1
                          ? _buildSearchPage()
                          : _currentIndex == 4
                              ? (currentUserId != null
                                  ? ProfilePage(
                                      userId: currentUserId,
                                      email: currentUserProfile?.email ??
                                          currentUserEntity?.email ??
                                          '',
                                      showAppBar: false)
                                  : const Center(
                                      child: Text(
                                          'Faça login para ver seu perfil')))
                              : const Center(child: Text('Em breve')),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(
                currentUserProfile, _localFollowingIds, currentUserId),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(UserProfile? profile, UserEntity? entity) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.black,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.primaryColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      centerTitle: false,
      title: _currentIndex == 1
          ? const Text('BUSCAR',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: 'Outfit'))
          : _currentIndex == 4
              ? const Text('MEU PERFIL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'Outfit'))
              : const Text(
                  'MixArt',
                  style: TextStyle(
                    color: Color(0xFFE5B80B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Outfit',
                    fontSize: 26,
                  ),
                ),
      actions: [
        if (_currentIndex == 0) ...[
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state.notifications.any((n) => !n.isRead);
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.music_note,
                        color: AppTheme.primaryColor),
                    tooltip: 'Meus Pedidos',
                    onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.bolt, color: Colors.white, size: 28),
                        if (hasUnread)
                          Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle))),
                      ],
                    ),
                    onPressed: () {
                      if (profile != null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ActivityPage(userId: profile.id)));
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
        if (_currentIndex == 4 && profile != null)
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sair da Rede'),
                    content: const Text('Deseja realmente deslogar da rede?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(SignOutRequested());
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        child: const Text('Sair',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              }),
      ],
    );
  }

  Widget _buildUploadProgressBar() {
    return BlocConsumer<StoryUploadBloc, StoryUploadState>(
      listener: (context, state) {
        if (state.status == StoryUploadStatus.success) {
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Story publicado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh stories after success
          context
              .read<CommunityBloc>()
              .add(FetchStoriesStarted(followingIds: _localFollowingIds));
        } else if (state.status == StoryUploadStatus.failure) {
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Erro ao publicar: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == StoryUploadStatus.uploading) {
          return Container(
            color: Colors.white10,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  minHeight: 3,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Compartilhando story... ${(state.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFeed(String? currentUserId, UserProfile? currentUserProfile) {
    if (_isLoadingData)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    return RefreshIndicator(
      onRefresh: () async {
        if (currentUserId != null) await _loadData(currentUserId);
      },
      color: AppTheme.primaryColor,
      child: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          // If we are locally loading OR the bloc is loading with empty posts, show shimmer
          if (_isLoadingData ||
              (state.status == CommunityStatus.loading &&
                  state.posts.isEmpty)) {
            return const FeedShimmer();
          }

          // If we are NOT loading anymore, but status is failure OR initial (which means it didn't start properly), show error
          if (state.status == CommunityStatus.failure ||
              state.status == CommunityStatus.initial) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          state.status == CommunityStatus.initial
                              ? 'Não foi possível carregar os dados.'
                              : 'Erro ao carregar o feed:',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (state.errorMessage != null)
                          SelectableText(
                            state.errorMessage!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            if (currentUserId != null) _loadData(currentUserId);
                          },
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final posts = state.posts;
          final List<String> followingIds = List.from(_localFollowingIds);
          if (currentUserId != null) followingIds.add(currentUserId);

          final groupedStories = <String, List<StoryEntity>>{};
          for (var s in state.stories) {
            groupedStories.putIfAbsent(s.authorId, () => []).add(s);
          }

          final Set<String> idsToShow = Set.from(_localFollowingIds);
          if (currentUserId != null) idsToShow.remove(currentUserId);
          for (var story in state.stories) {
            if (story.authorId != currentUserId) {
              idsToShow.add(story.authorId);
            }
          }

          // Optimization: Pre-calculate sorting metadata to avoid O(N^2)
          final Map<String, ({bool allViewed, DateTime latestStory})>
              sortingMeta = {};

          for (var id in idsToShow) {
            final stories = groupedStories[id] ?? [];
            if (stories.isEmpty) {
              sortingMeta[id] = (
                allViewed: true,
                latestStory: DateTime(2000),
              );
              continue;
            }

            final allViewed =
                stories.every((s) => s.viewers.contains(currentUserId));
            final latest = stories
                .map((s) => s.createdAt)
                .reduce((v, e) => v.isAfter(e) ? v : e);

            sortingMeta[id] = (
              allViewed: allViewed,
              latestStory: latest,
            );
          }

          final List<String> sortedIds = idsToShow.toList();
          sortedIds.sort((a, b) {
            final metaA = sortingMeta[a]!;
            final metaB = sortingMeta[b]!;

            if (metaA.allViewed != metaB.allViewed) {
              return metaA.allViewed ? 1 : -1;
            }

            return metaB.latestStory.compareTo(metaA.latestStory);
          });

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 8),
                      child: Text('Studio Riffs',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    Container(
                      height: 160,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        children: [
                          _buildStoryItem(
                            'Você',
                            currentUserProfile?.photoUrl,
                            isMe: true,
                            hasStories:
                                groupedStories.containsKey(currentUserId),
                            allStoriesViewed: currentUserId != null &&
                                groupedStories.containsKey(currentUserId) &&
                                groupedStories[currentUserId]!.every(
                                    (s) => s.viewers.contains(currentUserId)),
                            onTap: () {
                              if (currentUserId != null &&
                                  groupedStories.containsKey(currentUserId)) {
                                final stories = List<StoryEntity>.from(
                                    groupedStories[currentUserId]!)
                                  ..sort((a, b) =>
                                      a.createdAt.compareTo(b.createdAt));

                                final firstUnviewedIndex = stories.indexWhere(
                                    (s) => !s.viewers.contains(currentUserId));

                                final initialIndex = firstUnviewedIndex != -1
                                    ? firstUnviewedIndex
                                    : 0;

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => StoryPlayerPage(
                                            stories: stories,
                                            initialIndex: initialIndex,
                                            currentUserId: currentUserId,
                                            followingIds: _localFollowingIds)));
                              } else if (currentUserProfile != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CreateStoryPage(
                                            profile: currentUserProfile)));
                              }
                            },
                          ),
                          // --- LIVE TEST ITEM (MOCKED) ---
                          _buildStoryItem('Live Test', null, isLive: true,
                              onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Scaffold(
                                        backgroundColor: Colors.black,
                                        body: Center(
                                            child: LiveStreamViewer(
                                          streamUrl:
                                              "https://136.248.64.90.nip.io:8888/live/mystream/index.m3u8",
                                          isLive: true,
                                        )))));
                          }),
                          // -------------------------------
                          ...sortedIds.map((userId) {
                            final stories = groupedStories[userId] ?? [];
                            if (stories.isEmpty) return const SizedBox();

                            final sortedStories = List<StoryEntity>.from(
                                stories)
                              ..sort(
                                  (a, b) => a.createdAt.compareTo(b.createdAt));

                            final firstUnviewedIndex = sortedStories.indexWhere(
                                (s) =>
                                    currentUserId != null &&
                                    !s.viewers.contains(currentUserId));

                            final initialIndex = firstUnviewedIndex != -1
                                ? firstUnviewedIndex
                                : 0;

                            return _buildStoryItem(
                              sortedStories.first.authorName,
                              sortedStories.first.authorPhotoUrl,
                              hasStories: true,
                              allStoriesViewed: currentUserId != null &&
                                  sortedStories.every(
                                      (s) => s.viewers.contains(currentUserId)),
                              isLive: false,
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => StoryPlayerPage(
                                            stories: sortedStories,
                                            initialIndex: initialIndex,
                                            currentUserId: currentUserId,
                                            followingIds: _localFollowingIds)));
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_localFollowingIds.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎨 DESCOBERTA',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Explore novos talentos na rede MixArt',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                  child: Divider(color: Colors.white10, height: 1)),
              if (state.status == CommunityStatus.failure)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Erro ao carregar o feed:',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            state.errorMessage ?? 'Erro desconhecido',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              if (currentUserId != null)
                                _loadData(currentUserId);
                            },
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (posts.isEmpty && state.status == CommunityStatus.success)
                const SliverFillRemaining(
                    child:
                        Center(child: Text('Nenhuma publicação encontrada.')))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= posts.length)
                        return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor)));
                      return ArtistFeedCard(
                          post: posts[index],
                          currentUserId: currentUserId ?? '',
                          isFollowing: _localFollowingIds
                              .contains(posts[index].authorId));
                    },
                    childCount:
                        state.hasReachedMax ? posts.length : posts.length + 1,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pesquisar artistas ou músicas...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.primaryColor),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: () {
              final query = _searchQuery.trim();
              if (query.isEmpty) {
                return FirebaseFirestore.instance
                    .collection('users')
                    .limit(20)
                    .snapshots();
              }

              if (query.startsWith('@')) {
                final nick = query.substring(1).toLowerCase().trim();
                if (nick.isEmpty) {
                  return FirebaseFirestore.instance
                      .collection('users')
                      .where('nickname', isNull: false)
                      .limit(20)
                      .snapshots();
                }
                return FirebaseFirestore.instance
                    .collection('users')
                    .where('nickname', isGreaterThanOrEqualTo: nick)
                    .where('nickname', isLessThanOrEqualTo: '$nick\uf8ff')
                    .snapshots();
              }

              final searchName = query.toLowerCase();
              return FirebaseFirestore.instance
                  .collection('users')
                  .where('searchName', isGreaterThanOrEqualTo: searchName)
                  .where('searchName', isLessThanOrEqualTo: '$searchName\uf8ff')
                  .snapshots();
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty)
                return const Center(
                    child: Text('Nenhum resultado encontrado.'));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundImage: data['photoUrl'] != null
                            ? CachedNetworkImageProvider(data['photoUrl'])
                            : null),
                    title: Text(data['artisticName'] ?? 'Artista',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(data['bio'] ?? '',
                        style: const TextStyle(color: Colors.white54)),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(
                                userId: docs[index].id,
                                email: data['email'] ?? '',
                                showAppBar: true))),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryItem(String name, String? photoUrl,
      {required VoidCallback onTap,
      bool isMe = false,
      bool isLive = false,
      bool hasStories = false,
      bool allStoriesViewed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ArtistAvatar(
          photoUrl: photoUrl,
          isMe: isMe,
          isLive: isLive,
          hasStories: hasStories,
          allStoriesViewed: allStoriesViewed,
          onTap: onTap,
          isSquare: true,
          label: name),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthState state) {
    UserEntity? user;
    if (state is Authenticated) user = state.user;
    if (state is ProfileLoaded) user = state.currentUser;

    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE5B80B)),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoUrl != null
                  ? CachedNetworkImageProvider(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.black)
                  : null,
            ),
            accountName: Text(
              user?.displayName ?? 'Artista',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.nickname != null ? '@${user!.nickname}' : user?.email ?? '',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFFE5B80B)),
            title: const Text('Início / Feed'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFFE5B80B)),
            title: const Text('Insights & Estatísticas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArtistInsightsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFFE5B80B)),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context);
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      userId: user!.id,
                      email: user.email,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFFE5B80B)),
            title: const Text('Minha Carteira'),
            onTap: () {
              Navigator.pop(context);
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalletPage(userId: user!.id),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.library_music,
              color: Color(0xFFE5B80B),
            ),
            title: const Text('Gerenciar Repertório'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRepertoirePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Color(0xFFE5B80B)),
            title: const Text('Minhas Bandas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBandsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.live_tv, color: Colors.redAccent),
            title: const Text('Iniciar Transmissão'),
            onTap: () {
              Navigator.pop(context);
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LivePage(
                      liveId: user!.id,
                      isHost: true,
                      userId: user.id,
                      userName: user.displayName,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_active,
              color: Color(0xFFE5B80B),
            ),
            title: const Text('Ativar Notificações'),
            onTap: () async {
              Navigator.pop(context);
              await sl<PushNotificationService>().initialize();
              if (mounted) {
                messengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tentando ativar notificações... Verifique o pop-up do navegador.',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFFE5B80B)),
            title: const Text('Painel de Pedidos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title:
                const Text('Sair', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              context.read<AuthBloc>().add(SignOutRequested());
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateOptions(
      BuildContext context, UserProfile profile, String? currentUserId) {
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
            const Text(
              'O QUE DESEJA CRIAR?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCreateOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Story',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateStoryPage(profile: profile),
                      ),
                    ).then((_) {
                      if (currentUserId != null) _loadData(currentUserId);
                    });
                  },
                ),
                _buildCreateOption(
                  context,
                  icon: Icons.grid_on,
                  label: 'Publicação',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostPage(profile: profile),
                      ),
                    ).then((_) {
                      if (currentUserId != null) _loadData(currentUserId);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(UserProfile? currentUser, List<String> followingIds,
      String? currentUserId) {
    return GlassmorphismNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 2) {
          if (currentUser != null) {
            _showCreateOptions(context, currentUser, currentUserId);
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
    );
  }

  Widget _buildPostUploadProgressBar() {
    return BlocConsumer<PostUploadBloc, PostUploadState>(
      listener: (context, state) {
        if (state.status == PostUploadStatus.success) {
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Sua publicação está no ar! 🚀'),
              backgroundColor: Colors.green,
            ),
          );
          // Recarregar feed
          final authState = context.read<AuthBloc>().state;
          String? currentUserId;
          if (authState is Authenticated) currentUserId = authState.user.id;
          if (authState is ProfileLoaded) currentUserId = authState.profile.id;
          if (currentUserId != null) _loadData(currentUserId);
        } else if (state.status == PostUploadStatus.failure) {
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Falha na publicação: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == PostUploadStatus.uploading) {
          return Container(
            color: const Color(0xFFE5B80B).withOpacity(0.05),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFE5B80B),
                  ),
                  minHeight: 4,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload,
                          size: 14, color: Color(0xFFE5B80B)),
                      const SizedBox(width: 8),
                      Text(
                        'Publicando mídia... ${(state.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFE5B80B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
