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
    context.read<AuthBloc>().add(ProfileRequested(_currentMusicianId));
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
              child: Padding(
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
                          child: TextField(
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() => _currentMusicianId = value);
                                _loadMusicianData();
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Digite o ID do Músico...',
                              hintStyle: TextStyle(color: Colors.white24),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: InputBorder.none,
                              suffixIcon: Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFE5B80B),
                                size: 18,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Músico não encontrado.'),
              backgroundColor: Colors.redAccent,
              action: SnackBarAction(
                label: 'Tentar Novamente',
                textColor: Colors.white,
                onPressed: () =>
                    setState(() => _currentMusicianId = 'MVP_MUSICIAN_ID'),
              ),
            ),
          );
        }
      },
      child: Scaffold(
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
                expandedHeight: 300.0,
                title: _showTitleInAppBar
                    ? BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return Text(
                            state is ProfileLoaded
                                ? state.profile.artisticName
                                : 'Músico',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String name = 'Carregando...';
                      String? photoUrl;
                      String pix = '...';
                      if (state is ProfileLoaded) {
                        name = state.profile.artisticName;
                        photoUrl = state.profile.photoUrl;
                        pix = state.profile.pixKey;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5B80B),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white10,
                                backgroundImage:
                                    photoUrl != null && photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                                child: photoUrl == null || photoUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.white24,
                                      )
                                    : null,
                              ),
                            ).animate().scale(duration: 400.ms),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn().slideX(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Artista Verificado',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PIX: $pix',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
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
                        SliverList(
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
                              return SongCard(song: filteredSongs[index]);
                            },
                            childCount:
                                filteredSongs.isEmpty && query.isNotEmpty
                                ? 1
                                : filteredSongs.length,
                          ),
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
                          SliverList(
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
                              return SongCard(song: song);
                            }, childCount: _deezerSongs.length),
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
      ),
    );
  }
}
