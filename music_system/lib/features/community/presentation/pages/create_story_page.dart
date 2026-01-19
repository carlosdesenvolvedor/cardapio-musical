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

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
        setState(() {
          _pickedFile = media;
          _mediaType = isVideo ? 'video' : 'image';
          _mediaBytes = null;
          _initError = null;
        });

        if (isVideo) {
          _videoController?.dispose();
          // Usando .network para maior compatibilidade com Flutter Web em versões específicas
          _videoController = VideoPlayerController.network(media.path)
            ..setVolume(0);

          _videoController!
              .initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _showUploadOnly = false;
                  });
                  _videoController?.play();
                  _videoController?.setLooping(true);
                }
              })
              .catchError((e) {
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
          // For images, we still read bytes for preview because it's safer and small
          final bytes = await media.readAsBytes();
          setState(() => _mediaBytes = bytes);
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
      final bytes = await _pickedFile!.readAsBytes();
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
          print('Cloudinary Video Error, falling back to Firebase: $e');
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
        if (url.contains('cloudinary.com') && url.contains('/upload/')) {
          // vc_h264: Força o codec H.264, o mais compatível com iPhone/Safari
          // f_auto,q_auto: Escolhe o melhor formato/qualidade
          url = url.replaceFirst('/upload/', '/upload/f_auto,q_auto,vc_h264/');

          // Garante que o container seja .mp4 para o iPhone reconhecer como vídeo
          if (!url.toLowerCase().endsWith('.mp4')) {
            url = '$url.mp4';
          }
        }

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
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ))),
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
                      backgroundColor: Colors.white,
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
              ],
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
