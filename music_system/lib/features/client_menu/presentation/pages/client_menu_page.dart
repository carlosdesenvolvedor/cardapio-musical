import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/core/services/deezer_service.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/features/client_menu/domain/entities/song.dart';
import '../bloc/repertoire_menu_bloc.dart';
import '../bloc/repertoire_menu_event.dart';
import '../bloc/repertoire_menu_state.dart';
import '../widgets/song_card.dart';
import '../../../live/presentation/pages/live_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../features/auth/data/models/user_profile_model.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class ClientMenuPage extends StatefulWidget {
  final String musicianId;

  const ClientMenuPage({super.key, this.musicianId = 'MVP_MUSICIAN_ID'});

  @override
  State<ClientMenuPage> createState() => _ClientMenuPageState();
}

class _ClientMenuPageState extends State<ClientMenuPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;
  late String _currentMusicianId;
  final DeezerService _deezerService = DeezerService();
  List<DeezerSong> _deezerSongs = [];
  bool _isSearchingDeezer = false;

  @override
  void initState() {
    super.initState();
    _currentMusicianId = widget.musicianId;

    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showTitleInAppBar) {
        setState(() => _showTitleInAppBar = true);
      } else if (_scrollController.offset <= 200 && _showTitleInAppBar) {
        setState(() => _showTitleInAppBar = false);
      }
    });

    if (!_isDemoId()) {
      _loadMusicianData();
    }
  }

  bool _isDemoId() {
    return _currentMusicianId == 'MVP_MUSICIAN_ID' ||
        _currentMusicianId.isEmpty;
  }

  void _loadMusicianData() {
    context.read<RepertoireMenuBloc>().add(
          FetchRepertoireMenu(_currentMusicianId),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchGlobal(String query) async {
    if (query.length < 3) {
      if (_deezerSongs.isNotEmpty) setState(() => _deezerSongs = []);
      return;
    }

    setState(() => _isSearchingDeezer = true);
    final results = await _deezerService.searchSongs(query);
    if (mounted) {
      setState(() {
        _deezerSongs = results;
        _isSearchingDeezer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDemoId()) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://music-system-421ee.web.app/assets/music_welcome_premium.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 100,
                          color: Color(0xFFE5B80B),
                        ).animate().scale(
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 32),
                        Text(
                          'MUSIC REQUEST',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        _FollowedArtistsWidget(
                          onArtistSelected: (id) {
                            setState(() => _currentMusicianId = id);
                            _loadMusicianData();
                          },
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 16),
                        Text(
                          'Escaneie o QR Code do artista para escolher sua trilha sonora.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 60),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TypeAheadField<UserProfile>(
                            builder: (context, controller, focusNode) =>
                                TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  setState(() => _currentMusicianId = value);
                                  _loadMusicianData();
                                }
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Buscar Músico (Nome)...',
                                hintStyle: TextStyle(color: Colors.white24),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                                suffixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFFE5B80B),
                                  size: 18,
                                ),
                              ),
                            ),
                            suggestionsCallback: (pattern) async {
                              if (pattern.length < 2) return [];

                              final query = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('artisticName',
                                      isGreaterThanOrEqualTo: pattern)
                                  .where('artisticName',
                                      isLessThanOrEqualTo: pattern + '\uf8ff')
                                  .limit(5)
                                  .get();

                              return query.docs.map((doc) {
                                final data = doc.data();
                                return UserProfile(
                                  id: doc.id,
                                  email: data['email'] ?? '',
                                  artisticName:
                                      data['artisticName'] ?? 'Sem Nome',
                                  pixKey: data['pixKey'] ?? '',
                                  photoUrl: data['photoUrl'],
                                  followersCount: data['followersCount'] ?? 0,
                                  followingCount: data['followingCount'] ?? 0,
                                  profileViewsCount:
                                      data['profileViewsCount'] ?? 0,
                                  isLive: data['isLive'] ?? false,
                                );
                              }).toList();
                            },
                            itemBuilder: (context, profile) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: profile.photoUrl != null &&
                                          profile.photoUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          profile.photoUrl!)
                                      : null,
                                  child: profile.photoUrl == null ||
                                          profile.photoUrl!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(profile.artisticName),
                                subtitle: const Text('Músico',
                                    style: TextStyle(fontSize: 10)),
                              );
                            },
                            onSelected: (profile) {
                              setState(() => _currentMusicianId = profile.id);
                              _loadMusicianData();
                            },
                            emptyBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Nenhum músico encontrado.'),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1600), Color(0xFF0C0C0C), Color(0xFF0C0C0C)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: _showTitleInAppBar
                  ? const Color(0xFF121212)
                  : Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              expandedHeight: 340.0,
              title: _showTitleInAppBar
                  ? StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_currentMusicianId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final profile = UserProfileModel.fromJson(
                              data, snapshot.data!.id);
                          return Text(
                            profile.artisticName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const Text(
                          'Músico',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentMusicianId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String name = 'Músico';
                    String? photoUrl;
                    String pix = '';
                    bool isLive = false;
                    String userId = _currentMusicianId;
                    bool isLoading =
                        snapshot.connectionState == ConnectionState.waiting;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final profile =
                          UserProfileModel.fromJson(data, snapshot.data!.id);
                      name = profile.artisticName;
                      photoUrl = profile.photoUrl;
                      pix = profile.pixKey;

                      // Lógica refinada para status Live
                      isLive = profile.isLive &&
                          (profile.liveUntil == null ||
                              profile.liveUntil!.isAfter(DateTime.now()));
                    } else if (!isLoading && !snapshot.hasData) {
                      name = 'Artista não encontrado';
                    } else if (isLoading) {
                      name = 'Carregando...';
                    }

                    return Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (photoUrl != null && photoUrl.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.black87,
                                    insetPadding: const EdgeInsets.all(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ),
                                          Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: CachedNetworkImage(
                                                  imageUrl: photoUrl!,
                                                  fit: BoxFit.contain,
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const Icon(
                                                    Icons.error,
                                                    size: 50,
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: isLive
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF833AB4),
                                              Color(0xFFFD1D1D),
                                              Color(0xFFFCAF45)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: !isLive
                                        ? const Color(0xFFE5B80B)
                                        : null,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.white10,
                                    backgroundImage:
                                        photoUrl != null && photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,
                                    onBackgroundImageError:
                                        photoUrl != null && photoUrl.isNotEmpty
                                            ? (_, __) {
                                                // Image failed to load
                                              }
                                            : null,
                                    child: photoUrl == null || photoUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.white24,
                                          )
                                        : null,
                                  ),
                                ),
                                if (isLive)
                                  Positioned(
                                    bottom: -2,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (userId.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LivePage(
                                                liveId: userId,
                                                isHost: false,
                                                userId:
                                                    'viewer_${DateTime.now().millisecondsSinceEpoch}',
                                                userName: 'Espectador',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFD1D1D),
                                              Color(0xFF833AB4)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.black, width: 2),
                                        ),
                                        child: const Text(
                                          'AO VIVO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn().slideX(),
                              const SizedBox(width: 8),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, authState) {
                                  UserEntity? currentUser;
                                  if (authState is Authenticated) {
                                    currentUser = authState.user;
                                  } else if (authState is ProfileLoaded) {
                                    currentUser = authState.currentUser;
                                  }

                                  if (currentUser != null &&
                                      currentUser.id != userId) {
                                    final isFollowing = currentUser.followingIds
                                        .contains(userId);
                                    return SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (isFollowing) {
                                            context.read<AuthBloc>().add(
                                                UnfollowUserRequested(
                                                    currentUser!.id, userId));
                                          } else {
                                            context.read<AuthBloc>().add(
                                                FollowUserRequested(
                                                    currentUser!.id, userId));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFollowing
                                              ? Colors.transparent
                                              : AppTheme.primaryColor,
                                          side: const BorderSide(
                                              color: AppTheme.primaryColor),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        child: Text(
                                          isFollowing ? 'Seguindo' : 'Seguir',
                                          style: TextStyle(
                                            color: isFollowing
                                                ? AppTheme.primaryColor
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.blueAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Artista Verificado',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              'PIX: $pix',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              final authState = context.read<AuthBloc>().state;
                              final musicianId = _currentMusicianId;
                              final musicianEmail = snapshot.data != null &&
                                      snapshot.data!.exists
                                  ? (snapshot.data!.data()
                                          as Map<String, dynamic>)['email'] ??
                                      ''
                                  : '';

                              if (authState is Authenticated ||
                                  (authState is ProfileLoaded &&
                                      authState.currentUser != null)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      userId: musicianId,
                                      email: musicianEmail,
                                      showAppBar: true,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(
                                      destination: ProfilePage(
                                        userId: musicianId,
                                        email: musicianEmail,
                                        showAppBar: true,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.people_outline,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                            label: const Text(
                              'Conheça nossa rede de artistas',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            BlocBuilder<RepertoireMenuBloc, RepertoireMenuState>(
              builder: (context, state) {
                if (state is RepertoireMenuLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is RepertoireMenuLoaded) {
                  final query = _searchController.text.toLowerCase();
                  final filteredSongs = state.songs
                      .where(
                        (song) =>
                            song.title.toLowerCase().contains(query) ||
                            song.artist.toLowerCase().contains(query),
                      )
                      .toList();

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {});
                              _searchGlobal(val);
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar no repertório...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFB3B3B3),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (query.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'NO REPERTÓRIO',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFE5B80B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentMusicianId)
                            .snapshots(),
                        builder: (context, profileSnapshot) {
                          final isLive = profileSnapshot.hasData &&
                                  profileSnapshot.data!.exists
                              ? (profileSnapshot.data!.data()
                                      as Map<String, dynamic>)['isLive'] ??
                                  false
                              : false;

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (filteredSongs.isEmpty && query.isNotEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Center(
                                      child: Text(
                                        'Nada encontrado...',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                  );
                                }
                                if (index >= filteredSongs.length) return null;
                                return SongCard(
                                  song: filteredSongs[index],
                                  isMusicianLive: isLive,
                                );
                              },
                              childCount:
                                  filteredSongs.isEmpty && query.isNotEmpty
                                      ? 1
                                      : filteredSongs.length,
                            ),
                          );
                        },
                      ),
                      if (_deezerSongs.isNotEmpty || _isSearchingDeezer) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.public,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BUSCA GLOBAL (DEEZER)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (_isSearchingDeezer)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_currentMusicianId)
                              .snapshots(),
                          builder: (context, profileSnapshot) {
                            final isLive = profileSnapshot.hasData &&
                                    profileSnapshot.data!.exists
                                ? (profileSnapshot.data!.data()
                                        as Map<String, dynamic>)['isLive'] ??
                                    false
                                : false;

                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index >= _deezerSongs.length) return null;
                                final dSong = _deezerSongs[index];
                                final song = Song(
                                  id: 'deezer_${dSong.id}',
                                  title: dSong.title,
                                  artist: dSong.artist,
                                  musicianId: _currentMusicianId,
                                  albumCoverUrl: dSong.albumCover,
                                  genre: 'Digital',
                                );
                                return SongCard(
                                  song: song,
                                  isMusicianLive: isLive,
                                );
                              }, childCount: _deezerSongs.length),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Pedir outra'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE5B80B),
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _FollowedArtistsWidget extends StatelessWidget {
  final Function(String) onArtistSelected;

  const _FollowedArtistsWidget({required this.onArtistSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        List<String> followingIds = [];
        if (state is Authenticated) {
          followingIds = state.user.followingIds;
        } else if (state is ProfileLoaded && state.currentUser != null) {
          followingIds = state.currentUser!.followingIds;
        }

        if (followingIds.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  'Meus Artistas',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE5B80B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120, // Altura suficiente para avatar + texto
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: followingIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return _ArtistAvatarItem(
                      artistId: followingIds[index],
                      onTap: onArtistSelected,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ArtistAvatarItem extends StatelessWidget {
  final String artistId;
  final Function(String) onTap;

  const _ArtistAvatarItem({required this.artistId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(artistId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final profile = UserProfileModel.fromJson(data, snapshot.data!.id);

        return GestureDetector(
          onTap: () => onTap(artistId),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: profile.isLive
                          ? Border.all(color: const Color(0xFFE5B80B), width: 2)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: profile.photoUrl != null &&
                              profile.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child:
                          profile.photoUrl == null || profile.photoUrl!.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                    ),
                  ),
                  if (profile.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: Text(
                  profile.artisticName,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
