import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/features/community/presentation/bloc/story_upload_bloc.dart';
import 'package:music_system/features/community/presentation/bloc/story_upload_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:music_system/features/community/presentation/widgets/video_filter_selector.dart';

class StoryLayer {
  final String id;
  Uint8List? imageBytes;
  final XFile? videoFile;
  final String type; // 'image' or 'video'
  Offset position;
  double scale;
  double rotation;
  String? filterId;

  StoryLayer({
    required this.id,
    this.imageBytes,
    this.videoFile,
    required this.type,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.filterId,
  });
}

class CreateStoryPage extends StatefulWidget {
  final UserProfile profile;

  const CreateStoryPage({super.key, required this.profile});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final ImagePicker _picker = ImagePicker();
  final List<StoryLayer> _layers = [];
  int? _activeLayerIndex;

  bool _isUploading = false;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final _captionController = TextEditingController();
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _captionController.dispose();
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
        final id = DateTime.now().millisecondsSinceEpoch.toString();

        // Calcular posição central se for a primeira camada, ou offset se houver outras
        final size = MediaQuery.of(context).size;
        final initialPos = _layers.isEmpty
            ? Offset((size.width - 250) / 2, (size.height - 400) / 2)
            : Offset(20.0 * _layers.length, 20.0 * _layers.length);

        if (isVideo) {
          final layer = StoryLayer(
            id: id,
            videoFile: media,
            type: 'video',
            position: initialPos,
          );

          final controller =
              VideoPlayerController.networkUrl(Uri.parse(media.path));
          await controller.initialize();
          controller.play();
          controller.setLooping(true);

          setState(() {
            _videoControllers[id] = controller;
            _layers.add(layer);
            _activeLayerIndex = _layers.length - 1;
          });
        } else {
          final bytes = await media.readAsBytes();
          final layer = StoryLayer(
            id: id,
            imageBytes: bytes,
            type: 'image',
            position: initialPos,
          );
          setState(() {
            _layers.add(layer);
            _activeLayerIndex = _layers.length - 1;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _removeActiveLayer() {
    if (_activeLayerIndex == null) return;

    setState(() {
      final layer = _layers.removeAt(_activeLayerIndex!);
      if (layer.type == 'video') {
        _videoControllers[layer.id]?.dispose();
        _videoControllers.remove(layer.id);
      }
      _activeLayerIndex = _layers.isEmpty ? null : _layers.length - 1;
    });
  }

  Future<void> _publish() async {
    if (_layers.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      // Sempre capturamos o RepaintBoundary pois agora temos multicamadas e transformações
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final finalBytes = byteData.buffer.asUint8List();
          if (mounted) {
            context.read<StoryUploadBloc>().add(
                  StartStoryUploadRequested(
                    mediaBytes: finalBytes,
                    mediaType:
                        'image', // Resultado final é sempre uma imagem composta (collage)
                    profile: widget.profile,
                    caption: _captionController.text.isNotEmpty
                        ? _captionController.text
                        : null,
                  ),
                );
            Navigator.pop(context);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error publishing story: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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

  Future<void> _openEditor(int index) async {
    final layer = _layers[index];
    if (layer.imageBytes == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          layer.imageBytes!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async {
              setState(() {
                layer.imageBytes = bytes;
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
            filterEditor: const FilterEditorConfigs(enabled: true),
            blurEditor: const BlurEditorConfigs(enabled: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background/Preview
          if (_layers.isEmpty)
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
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Canvas de fundo preto
                    GestureDetector(
                      onTap: () => setState(() => _activeLayerIndex = null),
                      child: Container(color: Colors.black),
                    ),
                    // Camadas
                    ..._layers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final layer = entry.value;
                      return _buildLayerWidget(index, layer);
                    }).toList(),
                  ],
                ),
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
                if (_layers.isNotEmpty)
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
                if (_layers.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.add_a_photo,
                        color: Colors.white, size: 28),
                    onPressed: () => _pickMedia(false),
                  ),
                if (_layers.isNotEmpty && _activeLayerIndex != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 28),
                    onPressed: _removeActiveLayer,
                  ),
                if (_layers.isNotEmpty &&
                    _activeLayerIndex != null &&
                    _layers[_activeLayerIndex!].type == 'image')
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high,
                        color: AppTheme.primaryColor, size: 28),
                    onPressed: () => _openEditor(_activeLayerIndex!),
                  ),
              ],
            ),
          ),

          // Zoom Slider (Lateral) - Atua na camada ativa
          if (_layers.isNotEmpty && _activeLayerIndex != null && !_isUploading)
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height * 0.25,
              bottom: MediaQuery.of(context).size.height * 0.25,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryColor,
                  ),
                  child: Slider(
                    value: _layers[_activeLayerIndex!].scale.clamp(0.1, 5.0),
                    min: 0.1,
                    max: 5.0,
                    onChanged: (val) {
                      setState(() {
                        _layers[_activeLayerIndex!].scale = val;
                      });
                    },
                  ),
                ),
              ),
            ),

          // Caption Field
          if (_layers.isNotEmpty && !_isUploading)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Adicionar legenda...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

          // Video Filter Selector (Bottom)
          if (_layers.isNotEmpty &&
              _activeLayerIndex != null &&
              _layers[_activeLayerIndex!].type == 'video' &&
              !_isUploading)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: VideoFilterSelector(
                selectedFilterId: _layers[_activeLayerIndex!].filterId,
                onFilterSelected: (id) {
                  setState(() {
                    _layers[_activeLayerIndex!].filterId = id;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerWidget(int index, StoryLayer layer) {
    return Positioned(
      left: layer.position.dx,
      top: layer.position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          setState(() {
            _activeLayerIndex = index;
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            // Arraste (Posicionamento)
            layer.position += details.focalPointDelta;

            // Escala (Zoom)
            if (details.scale != 1.0) {
              layer.scale *= details.scale;
            }

            // Rotação
            if (details.rotation != 0.0) {
              layer.rotation += details.rotation;
            }
          });
        },
        onTap: () {
          setState(() {
            _activeLayerIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: _activeLayerIndex == index
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Transform.rotate(
            angle: layer.rotation,
            child: Transform.scale(
              scale: layer.scale,
              child: _buildLayerContent(layer),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerContent(StoryLayer layer) {
    Widget content;
    if (layer.type == 'image') {
      content = Image.memory(
        layer.imageBytes!,
        fit: BoxFit.contain,
        width: 250, // Tamanho base inicial
      );
    } else {
      final controller = _videoControllers[layer.id];
      if (controller != null && controller.value.isInitialized) {
        content = SizedBox(
          width: 250,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      } else {
        content = const SizedBox(
          width: 250,
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        );
      }
    }

    // Aplicar filtros se houver (para vídeos ou imagens filtradas via seletor rápido)
    if (layer.filterId != null) {
      final filter = _getFilterMatrix(layer.filterId);
      if (filter != null) {
        return ColorFiltered(
          colorFilter: filter,
          child: content,
        );
      }
    }

    return content;
  }

  Widget _buildPickButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 40),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
