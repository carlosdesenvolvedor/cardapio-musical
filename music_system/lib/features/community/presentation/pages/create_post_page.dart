import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/community/presentation/widgets/user_selector_dialog.dart';
import 'package:music_system/features/community/presentation/widgets/music_selector_sheet.dart';
import 'package:music_system/features/community/presentation/bloc/post_upload_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/post_upload_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/config/theme/app_theme.dart';

class CreatePostPage extends StatefulWidget {
  final UserProfile profile;

  const CreatePostPage({super.key, required this.profile});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  final _artisticNameController = TextEditingController(); // Novo controller
  final ImagePicker _picker = ImagePicker();

  bool get _isDefaultName =>
      widget.profile.artisticName == 'Artista Sem Nome' ||
      widget.profile.artisticName.isEmpty;

  // Suporte multimídia
  List<XFile> _selectedFiles = [];
  List<Uint8List> _filesBytes = [];
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _artisticNameController.text = widget.profile.artisticName;
  }

  bool _isUploading = false;
  List<UserProfile> _taggedUsers = [];
  List<UserProfile> _collaborators = [];
  Map<String, dynamic>? _selectedMusic;

  Future<void> _pickMedia() async {
    try {
      final source = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppTheme.surfaceColor,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Fotos (Carrossel)',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'images'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppTheme.primaryColor),
              title: const Text('Vídeo (Único)',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      );

      if (source == 'images') {
        final List<XFile> images =
            await _picker.pickMultiImage(imageQuality: 70);
        if (images.isNotEmpty) {
          final List<Uint8List> bytesList = [];
          for (var img in images) {
            bytesList.add(await img.readAsBytes());
          }
          setState(() {
            _selectedFiles = images;
            _filesBytes = bytesList;
            _isVideo = false;
          });
        }
      } else if (source == 'video') {
        final XFile? video =
            await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          final bytes = await video.readAsBytes();
          setState(() {
            _selectedFiles = [video];
            _filesBytes = [bytes];
            _isVideo = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  Future<void> _selectTags() async {
    final result = await showDialog<List<UserProfile>>(
      context: context,
      builder: (context) => const UserSelectorDialog(title: 'Marcar Artistas'),
    );
    if (result != null) {
      setState(() => _taggedUsers = result);
    }
  }

  Future<void> _selectCollaborators() async {
    final result = await showDialog<List<UserProfile>>(
      context: context,
      builder: (context) =>
          const UserSelectorDialog(title: 'Postagem em Conjunto'),
    );
    if (result != null) {
      setState(() => _collaborators = result);
    }
  }

  Future<void> _selectMusic() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicSelectorSheet(),
    );
    if (result != null) {
      setState(() => _selectedMusic = result);
    }
  }

  Future<void> _publish() async {
    if (_filesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma mídia primeiro!')),
      );
      return;
    }

    final String finalName = _artisticNameController.text.trim();
    if (finalName.isEmpty || finalName == 'Artista Sem Nome') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, defina seu Nome Artístico!')),
      );
      return;
    }

    // Disparar upload em segundo plano
    context.read<PostUploadBloc>().add(
          StartPostUploadRequested(
            filesBytes: _filesBytes,
            fileNames: _selectedFiles.map((f) => f.name).toList(),
            isVideo: _isVideo,
            profile: widget.profile,
            caption: _captionController.text,
            customArtisticName:
                finalName != widget.profile.artisticName ? finalName : null,
            taggedUserIds: _taggedUsers.map((u) => u.id).toList(),
            collaboratorIds: _collaborators.map((u) => u.id).toList(),
            musicData: _selectedMusic,
          ),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sua publicação está sendo preparada...'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Nova Publicação',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: _publish,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Compartilhar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isDefaultName) ...[
              const Text(
                'Identidade MixArt',
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Como você quer ser chamado na rede?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor, width: 0.5),
                ),
                child: TextField(
                  controller: _artisticNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Seu Nome Artístico',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
            ],
            InkWell(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _filesBytes.isEmpty
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: _filesBytes.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_to_photos_outlined,
                            size: 60,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Toque para selecionar Fotos ou Vídeo',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _isVideo
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.videocam,
                                            size: 48,
                                            color: AppTheme.primaryColor),
                                        const SizedBox(height: 8),
                                        Text(_selectedFiles.first.name,
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _filesBytes.length,
                                    itemBuilder: (context, index) => Container(
                                      width: 300,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.memory(_filesBytes[index],
                                              fit: BoxFit.cover),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedFiles
                                                      .removeAt(index);
                                                  _filesBytes.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close,
                                                    size: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          // Contador de Fotos
                          if (!_isVideo && _filesBytes.isNotEmpty)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppTheme.primaryColor, width: 1),
                                ),
                                child: Text(
                                  '${_filesBytes.length} ${_filesBytes.length > 1 ? "fotos selecionadas" : "foto selecionada"}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _captionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Escreva uma legenda...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Marcar Pessoas',
              count: _taggedUsers.length,
              onTap: _selectTags,
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              icon: Icons.group_add_outlined,
              title: 'Postagem em Conjunto (Collab)',
              count: _collaborators.length,
              onTap: _selectCollaborators,
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              icon: Icons.music_note_outlined,
              title: 'Adicionar Música',
              trailingText:
                  _selectedMusic != null ? _selectedMusic!['title'] : 'Nenhuma',
              onTap: _selectMusic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    int? count,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null && count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (trailingText != null)
              Text(
                trailingText,
                style:
                    const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
