import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:music_system/core/services/cloudinary_service.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/community/data/models/story_model.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/community/domain/repositories/story_repository.dart';
import 'package:music_system/core/utils/cloudinary_sanitizer.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/features/community/domain/entities/story_effects.dart';
import 'package:music_system/features/community/presentation/widgets/video_filter_selector.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class CreateStoryPage extends StatefulWidget {
  final UserProfile profile;

  const CreateStoryPage({super.key, required this.profile});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  Uint8List? _mediaBytes; // For images only
  String _mediaType = 'image';
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  String? _initError;
  bool _showUploadOnly = false;
  String? _selectedFilterId;

  ColorFilter? _getFilterMatrix(String? id) {
    if (id == null) return null;

    switch (id) {
      case 'grayscale':
        return const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'sepia':
        return const ColorFilter.matrix([
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix([
          0.9,
          0,
          0,
          0,
          0,
          0,
          0.8,
          0,
          0,
          0,
          0,
          0,
          0.5,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'warm':
        return const ColorFilter.matrix([
          1.2,
          0,
          0,
          0,
          10,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          0.8,
          0,
          -10,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'cool':
        return const ColorFilter.matrix([
          0.8,
          0,
          0,
          0,
          -10,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          1.2,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _openEditor() async {
    if (_mediaBytes == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          _mediaBytes!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async {
              setState(() {
                _mediaBytes = bytes;
              });
              Navigator.pop(context);
            },
          ),
          configs: ProImageEditorConfigs(
            designMode: ImageEditorDesignMode.material,
            mainEditor: const MainEditorConfigs(
              style: MainEditorStyle(
                background: Colors.black,
              ),
            ),
            textEditor: const TextEditorConfigs(),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(bool isVideo) async {
    try {
      final XFile? media = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );

      if (media != null) {
        if (isVideo) {
          setState(() {
            _pickedFile = media;
            _mediaType = 'video';
            _mediaBytes = null;
            _initError = null;
          });
          _videoController?.dispose();
          _videoController =
              VideoPlayerController.networkUrl(Uri.parse(media.path))
                ..setVolume(0);

          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {
                _showUploadOnly = false;
              });
              _videoController?.play();
              _videoController?.setLooping(true);
            }
          }).catchError((e) {
            debugPrint('Video Init Error: $e');
            if (mounted) {
              setState(() {
                _showUploadOnly = true;
                _initError =
                    'Prévia indisponível, mas você ainda pode compartilhar!';
              });
            }
          });
        } else {
          final bytes = await media.readAsBytes();
          setState(() {
            _pickedFile = media;
            _mediaType = 'image';
            _mediaBytes = bytes;
            _initError = null;
          });
          // Automatically open editor for images
          _openEditor();
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  Future<void> _publish() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma mídia primeiro!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Use edited bytes if available (for images) or read from file (for videos)
      final bytes = _mediaType == 'image' && _mediaBytes != null
          ? _mediaBytes!
          : await _pickedFile!.readAsBytes();
      String? url;

      if (_mediaType == 'image') {
        try {
          url = await sl<CloudinaryService>().uploadImage(
            bytes,
            'story_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}',
          );
        } catch (e) {
          url = await sl<StorageService>().uploadImage(
            bytes,
            'stories/${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      } else {
        // Try Cloudinary for video first, then fallback to Firebase Storage
        try {
          url = await sl<CloudinaryService>().uploadVideo(
            bytes,
            'story_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}',
          );
        } catch (e) {
          debugPrint('Cloudinary Video Error, falling back to Firebase: $e');
          url = await sl<StorageService>().uploadFile(
            fileBytes: bytes,
            fileName:
                'stories/${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.mp4',
            contentType: 'video/mp4',
          );
        }
      }

      if (url != null) {
        // Otimizar URL do Cloudinary para compatibilidade máxima entre dispositivos
        url = CloudinarySanitizer.sanitize(
          url,
          mediaType: _mediaType,
          filterId: _selectedFilterId,
        );

        final story = StoryModel(
          id: '',
          authorId: widget.profile.id,
          authorName: widget.profile.artisticName,
          authorPhotoUrl: widget.profile.photoUrl,
          mediaUrl: url,
          mediaType: _mediaType,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          viewers: const [],
          effects: _selectedFilterId != null
              ? StoryEffects(filterId: _selectedFilterId)
              : null,
        );

        await sl<StoryRepository>().createStory(story);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Story publicado!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background/Preview
          if (_pickedFile == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white24,
                    size: 80,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPickButton(
                        Icons.image,
                        'Imagem',
                        () => _pickMedia(false),
                      ),
                      const SizedBox(width: 20),
                      _buildPickButton(
                        Icons.videocam,
                        'Vídeo',
                        () => _pickMedia(true),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: _getFilterMatrix(_selectedFilterId) ??
                    const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: _mediaType == 'image'
                    ? (_mediaBytes != null
                        ? Image.memory(_mediaBytes!, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator()))
                    : (_showUploadOnly
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.video_file,
                                  color: Color(0xFFE5B80B),
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _initError ?? 'Vídeo selecionado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Toque em "Compartilhar" para publicar.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          )
                        : (_videoController != null &&
                                _videoController!.value.isInitialized
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : _initError != null
                                ? Center(
                                    child: Text(
                                      _initError!,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ))),
              ),
            ),

          // Top Actions
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                if (_pickedFile != null)
                  TextButton(
                    onPressed: _isUploading ? null : _publish,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Compartilhar',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                if (_pickedFile != null && _mediaType == 'image')
                  IconButton(
                    icon: const Icon(Icons.text_fields,
                        color: Colors.white, size: 28),
                    onPressed: _openEditor,
                  ),
              ],
            ),
          ),

          // Filter Selector (Only for videos, as images have editor filters)
          if (_pickedFile != null && !_isUploading && _mediaType == 'video')
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: VideoFilterSelector(
                selectedFilterId: _selectedFilterId,
                onFilterSelected: (id) {
                  setState(() => _selectedFilterId = id);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
