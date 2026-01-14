import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:music_system/features/community/presentation/pages/create_post_page.dart';
import 'package:music_system/features/community/data/models/post_model.dart';
import 'package:music_system/features/community/data/services/community_service.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/auth/presentation/pages/profile_page.dart';
import 'package:music_system/features/community/presentation/pages/chat_page.dart';
import 'package:music_system/features/auth/presentation/pages/login_page.dart';
import 'package:music_system/core/services/deezer_service.dart';

class ArtistNetworkPage extends StatefulWidget {
  const ArtistNetworkPage({super.key});

  @override
  State<ArtistNetworkPage> createState() => _ArtistNetworkPageState();
}

class _ArtistNetworkPageState extends State<ArtistNetworkPage> {
  int _currentIndex = 0;
  final CommunityService _communityService = sl<CommunityService>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _searchTab = 0; // 0 for Artists, 1 for Musics
  final DeezerService _deezerService = DeezerService();
  List<DeezerSong> _deezerMusicResults = [];
  bool _isSearchingMusic = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      context.read<AuthBloc>().add(ProfileRequested(state.user.id));
    }
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
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                if (currentUser != null) {
                  _showUserChatPicker(context, currentUser.id);
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
          : StreamBuilder<List<Post>>(
              stream: _communityService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                return CustomScrollView(
                  slivers: [
                    // Stories section (Artists)
                    SliverToBoxAdapter(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) return const SizedBox();

                          final allUsers = userSnapshot.data!.docs;
                          // Separate current user (me) from others
                          List<DocumentSnapshot> otherUsers = [];
                          DocumentSnapshot? me;
                          final currentUserId = currentUser?.id;

                          for (var doc in allUsers) {
                            if (currentUserId != null &&
                                doc.id == currentUserId) {
                              me = doc;
                            } else {
                              otherUsers.add(doc);
                            }
                          }

                          // The first item is RESERVED for the user (Logged or Guest)
                          final int itemCount = otherUsers.length + 1;

                          return Container(
                            height: 110,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: itemCount,
                              itemBuilder: (context, index) {
                                // Index 0 is always the RESERVED slot
                                if (index == 0) {
                                  if (me != null) {
                                    // Me Logged In
                                    final userData =
                                        me.data() as Map<String, dynamic>;
                                    return _buildStoryItem(
                                      'Você',
                                      userData['photoUrl'],
                                      isMe: true,
                                      onTap: () =>
                                          setState(() => _currentIndex = 4),
                                    );
                                  } else {
                                    // Guest Mode
                                    return _buildStoryItem(
                                      'Entrar',
                                      null,
                                      isMe: false,
                                      isGuest: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }

                                // Other artists
                                final otherIndex = index - 1;
                                final userData =
                                    otherUsers[otherIndex].data()
                                        as Map<String, dynamic>;
                                final artisticName =
                                    userData['artisticName'] ?? 'Artista';
                                final photoUrl = userData['photoUrl'];
                                final targetUserId = otherUsers[otherIndex].id;

                                return _buildStoryItem(
                                  artisticName,
                                  photoUrl,
                                  isMe: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(
                                          userId: targetUserId,
                                          email: '',
                                          showAppBar: true,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(color: Colors.white10, height: 1),
                    ),

                    // Feed section (Posts)
                    if (posts.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('Nenhuma publicação na rede ainda.'),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return ArtistFeedCard(
                            post: posts[index],
                            currentUserId: currentUser?.id ?? '',
                          );
                        }, childCount: posts.length),
                      ),
                  ],
                );
              },
            ),
      bottomNavigationBar: _buildBottomBar(),
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
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userData['photoUrl'] != null
                    ? CachedNetworkImageProvider(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                userData['artisticName'] ?? 'Artista',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Artista',
                style: TextStyle(color: Colors.white54, fontSize: 12),
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

  void _showUserChatPicker(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Conversar com...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      if (userId == currentUserId) return const SizedBox();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userData['photoUrl'] != null
                              ? CachedNetworkImageProvider(userData['photoUrl'])
                              : null,
                          child: userData['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(userData['artisticName'] ?? 'Artista'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                currentUserId: currentUserId,
                                targetUserId: userId,
                                targetUserName:
                                    userData['artisticName'] ?? 'Artista',
                                targetUserPhoto: userData['photoUrl'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(
    String name,
    String? photoUrl, {
    required VoidCallback onTap,
    bool isMe = false,
    bool isGuest = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (isMe || isGuest)
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          Colors.orange,
                          AppTheme.primaryColor.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isMe
                    ? Colors.greenAccent
                    : (isGuest ? Colors.white24 : null),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(
                          isGuest ? Icons.add : Icons.person,
                          color: Colors.white24,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name.split(' ')[0],
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library_outlined),
          label: 'Reels',
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

class ArtistFeedCard extends StatefulWidget {
  final Post post;
  final String currentUserId;

  const ArtistFeedCard({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<ArtistFeedCard> createState() => _ArtistFeedCardState();
}

class _ArtistFeedCardState extends State<ArtistFeedCard> {
  bool get _isLiked => widget.post.likes.contains(widget.currentUserId);

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
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: widget.post.authorPhotoUrl != null
                            ? CachedNetworkImageProvider(
                                widget.post.authorPhotoUrl!,
                              )
                            : null,
                        child: widget.post.authorPhotoUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
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
                    onPressed: () => sl<CommunityService>().toggleFollow(
                      widget.currentUserId,
                      widget.post.authorId,
                    ),
                    child: const Text(
                      'Seguir',
                      style: TextStyle(
                        color: Color(0xFFE5B80B),
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
            child: CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10),
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
                const Icon(Icons.send_outlined, size: 24),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 28),
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
                  '${widget.post.likes.length} curtidas',
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
    sl<CommunityService>().toggleLike(widget.post.id, widget.currentUserId);
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
                  stream: sl<CommunityService>().getComments(widget.post.id),
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
                          sl<CommunityService>().addComment(widget.post.id, {
                            'authorId': widget.currentUserId,
                            'authorName': authState.profile.artisticName,
                            'authorPhotoUrl': authState.profile.photoUrl,
                            'text': commentController.text,
                            'createdAt': Timestamp.now(),
                          });
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
