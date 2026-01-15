import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  // XFile? _image;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Compression at client level
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _publish() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem primeiro!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? url;

      // Intentar Cloudinary primeiro pela otimização automática de WebP
      try {
        url = await sl<CloudinaryService>().uploadImage(
          _imageBytes!,
          'story_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (e) {
        url = await sl<StorageService>().uploadImage(
          _imageBytes!,
          'stories/${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (url != null) {
        final story = StoryModel(
          id: '',
          authorId: widget.profile.id,
          authorName: widget.profile.artisticName,
          authorPhotoUrl: widget.profile.photoUrl,
          imageUrl: url,
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
          // Background - Click to pick if empty
          if (_imageBytes == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white24,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Selecionar Mídia'),
                  ),
                ],
              ),
            )
          else
            Positioned.fill(
              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
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
                if (_imageBytes != null)
                  TextButton(
                    onPressed: _isUploading ? null : _publish,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
}
