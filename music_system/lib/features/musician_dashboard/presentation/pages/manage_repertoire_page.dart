import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../client_menu/domain/entities/song.dart';
import '../bloc/repertoire_bloc.dart';
import 'package:music_system/injection_container.dart';
import '../../../../features/smart_lyrics/data/datasources/lyrics_remote_data_source.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:music_system/core/services/deezer_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageRepertoirePage extends StatefulWidget {
  const ManageRepertoirePage({super.key});

  @override
  State<ManageRepertoirePage> createState() => _ManageRepertoirePageState();
}

class _ManageRepertoirePageState extends State<ManageRepertoirePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final DeezerService _deezerService = DeezerService();
  String? _selectedAlbumCover;
  int _searchHelpTab = 0; // 0 for Cifra Club, 1 for Deezer

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) {
      userId = authState.user.id;
    } else if (authState is ProfileLoaded) {
      userId = authState.currentUser?.id;
    }

    if (userId != null) {
      context.read<RepertoireBloc>().add(
            LoadRepertoireEvent(userId),
          );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredSongs = _allSongs
          .where(
            (song) =>
                song.title.toLowerCase().contains(query.toLowerCase()) ||
                song.artist.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Repertório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _pickAndImport(context),
            tooltip: 'Importar Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: BlocConsumer<RepertoireBloc, RepertoireState>(
        listener: (context, state) {
          if (state is RepertoireOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            _loadSongs(); // Refresh list after success
          } else if (state is RepertoireError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is RepertoireLoading && _allSongs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RepertoireLoaded) {
            _allSongs = state.songs;
            _filteredSongs = _searchController.text.isEmpty
                ? _allSongs
                : _allSongs
                    .where(
                      (song) =>
                          song.title.toLowerCase().contains(
                                _searchController.text.toLowerCase(),
                              ) ||
                          song.artist.toLowerCase().contains(
                                _searchController.text.toLowerCase(),
                              ),
                    )
                    .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar música ou artista...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (state is RepertoireLoading && _allSongs.isNotEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadSongs();
                  },
                  child: _filteredSongs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.music_note),
                              ),
                              title: Text(song.title),
                              subtitle: Text('${song.artist} • ${song.genre}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showSongDialog(context, song: song),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, song),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSongDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Música'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma música encontrada',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickAndImport(context),
            icon: const Icon(Icons.file_upload),
            label: const Text('Importar do Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      if (!context.mounted) return;
      final bytes = result.files.single.bytes!;
      final authState = context.read<AuthBloc>().state;
      String? userId;

      if (authState is Authenticated) {
        userId = authState.user.id;
      } else if (authState is ProfileLoaded) {
        userId = authState.currentUser?.id;
      }

      if (userId != null) {
        context.read<RepertoireBloc>().add(
              StartImportEvent(bytes, userId),
            );
      }
    }
  }

  void _showSongDialog(BuildContext context, {Song? song}) {
    final bool isEditing = song != null;
    final titleController = TextEditingController(text: song?.title);
    final artistController = TextEditingController(text: song?.artist);
    final genreController = TextEditingController(text: song?.genre);
    _selectedAlbumCover = song?.albumCoverUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Música' : 'Adicionar Música'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEditing) ...[
                  Row(
                    children: [
                      _buildDialogTab('CIFRA CLUB', 0, setStateDialog),
                      const SizedBox(width: 8),
                      _buildDialogTab('DEEZER (CAPAS)', 1, setStateDialog),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_searchHelpTab == 0)
                    TypeAheadField<CifraClubSuggestion>(
                      builder: (context, controller, focusNode) {
                        if (controller.text != titleController.text &&
                            titleController.text.isNotEmpty &&
                            !focusNode.hasFocus) {
                          controller.text = titleController.text;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Título (Cifra Club)',
                            suffixIcon: Icon(Icons.search),
                            helperText: 'Busca inteligente de letras',
                          ),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (pattern.length < 3) return null;
                        final lyricsService = sl<LyricsRemoteDataSource>();
                        return await lyricsService.searchSuggestions(pattern);
                      },
                      loadingBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      emptyBuilder: (context) {
                        if (titleController.text.length < 3) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Digite pelo menos 3 letras...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhuma sugestão encontrada'),
                        );
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(suggestion.displayText),
                          subtitle: const Text('Toque para preencher'),
                        );
                      },
                      onSelected: (suggestion) {
                        final parts = suggestion.displayText.split(' - ');
                        if (parts.length >= 2) {
                          titleController.text = parts[0].trim();
                          artistController.text = parts[1].trim();
                        } else {
                          titleController.text = suggestion.displayText;
                        }
                        setStateDialog(() => _selectedAlbumCover = null);
                      },
                    )
                  else
                    TypeAheadField<DeezerSong>(
                      builder: (context, controller, focusNode) {
                        if (controller.text != titleController.text &&
                            titleController.text.isNotEmpty &&
                            !focusNode.hasFocus) {
                          controller.text = titleController.text;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Música (Deezer)',
                            suffixIcon: Icon(Icons.art_track),
                            helperText: 'Busca oficial com capa de ábum',
                          ),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (pattern.length < 3) return null;
                        return await _deezerService.searchSongs(pattern);
                      },
                      loadingBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      emptyBuilder: (context) {
                        if (titleController.text.length < 3) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Digite pelo menos 3 letras...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhuma música encontrada'),
                        );
                      },
                      itemBuilder: (context, song) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: song.albumCover,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                        );
                      },
                      onSelected: (song) {
                        titleController.text = song.title;
                        artistController.text = song.artist;
                        setStateDialog(
                          () => _selectedAlbumCover = song.albumCover,
                        );
                      },
                    ),
                ],
                if (isEditing) ...[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        if (_selectedAlbumCover != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _selectedAlbumCover!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white24,
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () => _showCoverPicker(
                            context,
                            titleController.text,
                            (url) {
                              setStateDialog(() => _selectedAlbumCover = url);
                            },
                          ),
                          icon: const Icon(
                            Icons.auto_fix_high,
                            size: 16,
                            color: Color(0xFFE5B80B),
                          ),
                          label: const Text(
                            'Buscar Capa no Deezer',
                            style: TextStyle(
                              color: Color(0xFFE5B80B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: 'Artista'),
                ),
                TextField(
                  controller: genreController,
                  decoration: const InputDecoration(
                    labelText: 'Gênero (opcional)',
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  artistController.text.isNotEmpty) {
                final authState = context.read<AuthBloc>().state;
                String? userId;

                if (authState is Authenticated) {
                  userId = authState.user.id;
                } else if (authState is ProfileLoaded) {
                  userId = authState.currentUser?.id;
                }

                if (userId != null) {
                  final newSong = Song(
                    id: isEditing ? song.id : const Uuid().v4(),
                    title: titleController.text,
                    artist: artistController.text,
                    genre: genreController.text.isNotEmpty
                        ? genreController.text
                        : 'Outros',
                    musicianId: userId,
                    albumCoverUrl: _selectedAlbumCover,
                  );

                  if (isEditing) {
                    context.read<RepertoireBloc>().add(
                          UpdateSongEvent(newSong),
                        );
                  } else {
                    context.read<RepertoireBloc>().add(AddSongEvent(newSong));
                  }
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showCoverPicker(
    BuildContext context,
    String query,
    Function(String) onCoverSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<DeezerSong>>(
          future: _deezerService.searchSongs(query),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Nenhuma capa encontrada',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ESCOLHA UMA CAPA',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final s = songs[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: s.albumCover,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(s.title),
                        subtitle: Text(s.artist),
                        onTap: () {
                          onCoverSelected(s.albumCover);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTab(String label, int index, StateSetter setStateDialog) {
    bool isSelected = _searchHelpTab == index;
    return GestureDetector(
      onTap: () {
        setStateDialog(() {
          _searchHelpTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5B80B) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
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

  void _confirmDelete(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Música'),
        content: Text('Tem certeza que deseja excluir "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<RepertoireBloc>().add(DeleteSongEvent(song.id));
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
