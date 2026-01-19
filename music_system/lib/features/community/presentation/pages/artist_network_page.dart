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
import 'package:music_system/core/services/deezer_service.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/notifications_state.dart';
import 'package:music_system/features/community/presentation/widgets/artist_feed_card.dart';
import 'package:music_system/features/community/presentation/widgets/feed_shimmer.dart';
import 'package:music_system/features/live/presentation/pages/live_page.dart';

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

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<AuthBloc>().add(ProfileRequested(authState.user.id));
      // Inicializa o feed
      context.read<CommunityBloc>().add(const FetchFeedStarted());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CommunityBloc>().add(const LoadMorePostsRequested());
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
    UserProfile? currentUser;

    if (authState is ProfileLoaded) {
      currentUser = authState.profile;
    } else if (authState is Authenticated || authState is AuthLoading) {
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
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreatePostPage(profile: currentUser!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Faça login para publicar!')),
                  );
                }
              },
            ),
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final hasUnread = state.notifications.any((n) => !n.isRead);
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.favorite_border, color: Colors.white),
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
                    ],
                  ),
                  onPressed: () {
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityPage(userId: currentUser!.id),
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
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConversationsPage(userId: currentUser!.id),
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
          if (_currentIndex == 4 && currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                context.read<AuthBloc>().add(SignOutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
      body: _currentIndex == 4
          ? (currentUser != null
              ? ProfilePage(
                  userId: currentUser.id,
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
                        context.read<CommunityBloc>().add(
                              const FetchFeedStarted(isRefresh: true),
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
                                final currentUserId = currentUser?.id;

                                // Group state.stories by authorId
                                final Map<String, List<StoryEntity>>
                                    groupedStories = {};
                                for (var story in state.stories) {
                                  groupedStories
                                      .putIfAbsent(story.authorId, () => [])
                                      .add(story);
                                }

                                // Identify users with stories
                                final usersWithStories = allUsers
                                    .where(
                                        (u) => groupedStories.containsKey(u.id))
                                    .toList();
                                final usersWithoutStories = allUsers
                                    .where(
                                      (u) =>
                                          !groupedStories.containsKey(u.id) &&
                                          u.id != currentUserId,
                                    )
                                    .toList();

                                DocumentSnapshot? me;
                                try {
                                  me = allUsers.firstWhere(
                                    (u) => u.id == currentUserId,
                                  );
                                } catch (_) {}

                                final bool myStoriesAllViewed = currentUserId !=
                                        null &&
                                    groupedStories.containsKey(currentUserId) &&
                                    groupedStories[currentUserId]!.every(
                                      (s) => s.viewers.contains(currentUserId),
                                    );

                                return Container(
                                  height: 125,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      // 1. Me Logged or Guest
                                      if (me != null)
                                        _buildStoryItem(
                                          'Você',
                                          (me.data() as Map<String, dynamic>)[
                                              'photoUrl'],
                                          isMe: true,
                                          isLive: (me.data() as Map<String,
                                                  dynamic>)['isLive'] ??
                                              false,
                                          hasStories:
                                              groupedStories.containsKey(
                                            currentUserId,
                                          ),
                                          allStoriesViewed: myStoriesAllViewed,
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
                                                  ),
                                                ),
                                              );
                                            } else {
                                              final authState = context
                                                  .read<AuthBloc>()
                                                  .state;
                                              if (authState is ProfileLoaded) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CreateStoryPage(
                                                      profile:
                                                          authState.profile,
                                                    ),
                                                  ),
                                                );
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

                                      // 2. Artists with Stories
                                      ...usersWithStories.map((user) {
                                        final userData =
                                            user.data() as Map<String, dynamic>;
                                        final bool allViewed =
                                            currentUserId != null &&
                                                groupedStories
                                                    .containsKey(user.id) &&
                                                groupedStories[user.id]!.every(
                                                  (s) => s.viewers
                                                      .contains(currentUserId),
                                                );
                                        return _buildStoryItem(
                                          userData['artisticName'] ?? 'Artista',
                                          userData['photoUrl'],
                                          hasStories: true,
                                          allStoriesViewed: allViewed,
                                          isLive: userData['isLive'] ?? false,
                                          onTap: () {
                                            if (userData['isLive'] == true) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      LivePage(
                                                    liveId: user.id,
                                                    isHost: false,
                                                    userId: currentUserId ??
                                                        'viewer_${DateTime.now().millisecondsSinceEpoch}',
                                                    userName: currentUser
                                                            ?.artisticName ??
                                                        'Espectador',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      StoryPlayerPage(
                                                    stories: groupedStories[
                                                        user.id]!,
                                                    currentUserId:
                                                        currentUserId,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }),

                                      // 3. Other artists (discovery)
                                      ...usersWithoutStories.map((user) {
                                        final userData =
                                            user.data() as Map<String, dynamic>;
                                        return _buildStoryItem(
                                          userData['artisticName'] ?? 'Artista',
                                          userData['photoUrl'],
                                          isLive:
                                              (userData['isLive'] ?? false) ==
                                                  true,
                                          onTap: () {
                                            if (userData['isLive'] == true) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      LivePage(
                                                    liveId: user.id,
                                                    isHost: false,
                                                    userId: currentUserId ??
                                                        'viewer_${DateTime.now().millisecondsSinceEpoch}',
                                                    userName: currentUser
                                                            ?.artisticName ??
                                                        'Espectador',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfilePage(
                                                    userId: user.id,
                                                    email: '',
                                                    showAppBar: true,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }),
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
                            const SliverFillRemaining(
                              child: Center(
                                child:
                                    Text('Nenhuma publicação na rede ainda.'),
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
                                  return ArtistFeedCard(
                                    post: posts[index],
                                    currentUserId: currentUser?.id ?? '',
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
      bottomNavigationBar: _buildBottomBar(currentUser),
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

  Widget _buildBottomBar(UserProfile? currentUser) {
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
            );
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
