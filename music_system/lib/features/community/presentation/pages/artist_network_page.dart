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
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:music_system/features/auth/domain/entities/user_entity.dart';

class ArtistNetworkPage extends StatefulWidget {
  const ArtistNetworkPage({super.key});

  @override
  State<ArtistNetworkPage> createState() => _ArtistNetworkPageState();
}

class _ArtistNetworkPageState extends State<ArtistNetworkPage> {
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
    context.read<AuthBloc>().add(ProfileRequested(userId));
    final followingResult = await sl<AuthRepository>().getFollowedUsers(userId);
    List<String> loadedFollowingIds = [];
    followingResult.fold(
      (failure) =>
          debugPrint('Error fetching followed users: ${failure.message}'),
      (ids) => loadedFollowingIds = ids,
    );
    final feedIds = List<String>.from(loadedFollowingIds)..add(userId);
    if (mounted) {
      _localFollowingIds = loadedFollowingIds;
      context
          .read<CommunityBloc>()
          .add(FetchFeedStarted(followingIds: feedIds));
      context
          .read<CommunityBloc>()
          .add(FetchStoriesStarted(followingIds: feedIds));
      setState(() => _isLoadingData = false);
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
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(currentUserProfile, currentUserEntity),
            body: _currentIndex == 0
                ? _buildFeedSection(currentUserId, currentUserProfile)
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
                                child: Text('Faça login para ver seu perfil')))
                        : const Center(child: Text('Em breve')),
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
              : Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_rede.png',
                      height: 28,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'MUSICG',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'Outfit',
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
      actions: [
        if (_currentIndex == 0) ...[
          IconButton(
            icon: const Icon(Icons.dashboard_customize,
                color: AppTheme.primaryColor, size: 28),
            tooltip: 'Meu Painel',
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () => setState(() => _currentIndex = 1),
          ),
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.add_box_outlined,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostPage(profile: profile),
                ),
              ),
            ),
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state.notifications.any((n) => !n.isRead);
              return IconButton(
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

  Widget _buildFeedSection(
      String? currentUserId, UserProfile? currentUserProfile) {
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
          if (state.status == CommunityStatus.initial ||
              (state.status == CommunityStatus.loading &&
                  state.posts.isEmpty)) {
            return const FeedShimmer();
          }
          final posts = state.posts;
          final List<String> followingIds = List.from(_localFollowingIds);
          if (currentUserId != null) followingIds.add(currentUserId);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              final allUsers = snapshot.data?.docs ?? [];
              final groupedStories = <String, List<StoryEntity>>{};
              for (var s in state.stories) {
                groupedStories.putIfAbsent(s.authorId, () => []).add(s);
              }

              final Map<String, DocumentSnapshot> userDocsMap = {
                for (var doc in allUsers) doc.id: doc
              };
              DocumentSnapshot? me;
              try {
                me = allUsers.firstWhere((u) => u.id == currentUserId);
              } catch (_) {}

              final Set<String> idsToShow = Set.from(_localFollowingIds);
              if (currentUserId != null) idsToShow.remove(currentUserId);
              for (var story in state.stories) {
                if (story.authorId != currentUserId) {
                  idsToShow.add(story.authorId);
                }
              }

              final List<String> sortedIds = idsToShow.toList();
              sortedIds.sort((a, b) {
                final aStories = groupedStories[a] ?? [];
                final bStories = groupedStories[b] ?? [];

                if (aStories.isEmpty && bStories.isEmpty) return 0;
                if (aStories.isEmpty) return 1;
                if (bStories.isEmpty) return -1;

                final aAllViewed =
                    aStories.every((s) => s.viewers.contains(currentUserId));
                final bAllViewed =
                    bStories.every((s) => s.viewers.contains(currentUserId));

                if (aAllViewed != bAllViewed) {
                  return aAllViewed ? 1 : -1;
                }

                final aLatest = aStories
                    .map((s) => s.createdAt)
                    .reduce((v, e) => v.isAfter(e) ? v : e);
                final bLatest = bStories
                    .map((s) => s.createdAt)
                    .reduce((v, e) => v.isAfter(e) ? v : e);
                return bLatest.compareTo(aLatest);
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
                              if (me != null)
                                _buildStoryItem(
                                  'Você',
                                  (me.data()
                                      as Map<String, dynamic>)['photoUrl'],
                                  isMe: true,
                                  hasStories:
                                      groupedStories.containsKey(currentUserId),
                                  allStoriesViewed: currentUserId != null &&
                                      groupedStories
                                          .containsKey(currentUserId) &&
                                      groupedStories[currentUserId]!.every(
                                          (s) => s.viewers
                                              .contains(currentUserId)),
                                  onTap: () {
                                    if (groupedStories
                                        .containsKey(currentUserId)) {
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
                                                          _localFollowingIds)));
                                    } else if (currentUserProfile != null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateStoryPage(
                                                      profile:
                                                          currentUserProfile)));
                                    }
                                  },
                                ),
                              ...sortedIds.map((userId) {
                                final userDoc = userDocsMap[userId];
                                final stories = groupedStories[userId] ?? [];
                                if (userDoc == null && stories.isEmpty)
                                  return const SizedBox();
                                final name = userDoc != null
                                    ? (userDoc.data() as Map<String, dynamic>)[
                                            'artisticName'] ??
                                        'Artista'
                                    : (stories.isNotEmpty
                                        ? stories.first.authorName
                                        : 'Artista');
                                final photoUrl = userDoc != null
                                    ? (userDoc.data()
                                        as Map<String, dynamic>)['photoUrl']
                                    : (stories.isNotEmpty
                                        ? stories.first.authorPhotoUrl
                                        : null);
                                final isLive = userDoc != null
                                    ? (userDoc.data() as Map<String, dynamic>)[
                                            'isLive'] ??
                                        false
                                    : false;
                                return _buildStoryItem(
                                  name,
                                  photoUrl,
                                  hasStories: stories.isNotEmpty,
                                  allStoriesViewed: currentUserId != null &&
                                      stories.isNotEmpty &&
                                      stories.every((s) =>
                                          s.viewers.contains(currentUserId)),
                                  isLive: isLive,
                                  onTap: () {
                                    if (stories.isNotEmpty) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  StoryPlayerPage(
                                                      stories: stories,
                                                      currentUserId:
                                                          currentUserId,
                                                      followingIds:
                                                          _localFollowingIds)));
                                    } else {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ProfilePage(
                                                  userId: userId,
                                                  email: '',
                                                  showAppBar: true)));
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: Divider(color: Colors.white10, height: 1)),
                  if (posts.isEmpty && state.status == CommunityStatus.success)
                    const SliverFillRemaining(
                        child: Center(
                            child: Text('Nenhuma publicação encontrada.')))
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
                        childCount: state.hasReachedMax
                            ? posts.length
                            : posts.length + 1,
                      ),
                    ),
                ],
              );
            },
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
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('artisticName', isGreaterThanOrEqualTo: _searchQuery)
                .where('artisticName',
                    isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                .snapshots(),
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

  Widget _buildBottomBar(UserProfile? currentUser, List<String> followingIds,
      String? currentUserId) {
    return GlassmorphismNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 2) {
          if (currentUser != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CreateStoryPage(profile: currentUser))).then((_) {
              if (currentUserId != null) _loadData(currentUserId);
            });
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
    );
  }
}
