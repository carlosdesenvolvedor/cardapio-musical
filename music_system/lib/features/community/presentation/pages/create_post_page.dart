import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_system/core/services/cloudinary_service.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/community/data/services/community_service.dart';
import 'package:music_system/features/community/data/models/post_model.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';

class CreatePostPage extends StatefulWidget {
  final UserProfile profile;

  const CreatePostPage({super.key, required this.profile});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _image = image;
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

      try {
        url = await sl<CloudinaryService>().uploadImage(
          _imageBytes!,
          _image!.name,
        );
        if (url == null) throw Exception('Cloudinary failed');
      } catch (e) {
        debugPrint('Falha no Cloudinary, tentando Firebase: $e');
        url = await sl<StorageService>().uploadImage(
          _imageBytes!,
          _image!.name,
        );
      }

      if (url != null) {
        final post = Post(
          id: '',
          authorId: widget.profile.id,
          authorName: widget.profile.artisticName,
          authorPhotoUrl: widget.profile.photoUrl,
          imageUrl: url,
          caption: _captionController.text,
          likes: const [],
          createdAt: DateTime.now(),
        );

        await sl<CommunityService>().createPost(post);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicado com sucesso!')),
          );
        }
      } else {
        throw Exception(
          'Servidores de imagem ocupados. Tente novamente em instantes.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Publicação'),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _publish,
                  child: const Text(
                    'Compartilhar',
                    style: TextStyle(
                      color: Color(0xFFE5B80B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBytes == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escreva uma legenda...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
