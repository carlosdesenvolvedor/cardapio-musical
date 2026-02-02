import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:music_system/config/theme/app_theme.dart';
import 'package:music_system/core/presentation/widgets/app_network_image.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/core/services/backend_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../injection_container.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_audio_player.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhoto;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhoto,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  late ChatBloc _chatBloc;

  bool _isRecording = false;

  // Nudge, Kiss & Jolt state
  bool _isNudging = false;
  bool _isKissing = false;
  bool _isJolting = false;
  bool _showActions = false;
  String? _lastInteractionId;
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    debugPrint(
        'DEBUG: ChatPage initState - Current: ${widget.currentUserId}, Target: ${widget.targetUserId}');
    _chatBloc = sl<ChatBloc>()
      ..add(
        ChatStarted(
          senderId: widget.currentUserId,
          receiverId: widget.targetUserId,
        ),
      );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _chatBloc.close();
    super.dispose();
  }

  void _triggerNudge() {
    if (_isNudging) return;
    setState(() => _isNudging = true);
    if (!kIsWeb) HapticFeedback.vibrate();
    Future.delayed(1500.ms, () {
      if (mounted) setState(() => _isNudging = false);
    });
  }

  void _triggerKiss() {
    if (_isKissing) return;
    setState(() => _isKissing = true);
    if (!kIsWeb) HapticFeedback.mediumImpact();
    Future.delayed(2000.ms, () {
      if (mounted) setState(() => _isKissing = false);
    });
  }

  void _triggerJolt() {
    if (_isJolting) return;
    setState(() => _isJolting = true);
    if (!kIsWeb) HapticFeedback.heavyImpact();
    Future.delayed(1000.ms, () {
      if (mounted) setState(() => _isJolting = false);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint('DEBUG: Image picked: ${image.name}');
      final cleanName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      final bytes = await image.readAsBytes();
      debugPrint('DEBUG: Uploading image to backend...');
      final storage = sl<BackendStorageService>();
      final uploadPath = await storage.uploadBytes(bytes, fileName, 'chats');

      // Construct full URL (ensuring slash and /media/ prefix)
      final url = uploadPath.startsWith('http')
          ? uploadPath
          : 'http://localhost/media/${uploadPath.startsWith('/') ? uploadPath.substring(1) : uploadPath}';

      debugPrint('DEBUG: Final Message URL: $url');

      debugPrint('DEBUG: Upload result: $url');
      if (mounted) {
        _sendMessage(context, type: 'image', mediaUrl: url);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final directory = await getTemporaryDirectory();
          path =
              '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        // On Web, path can be empty for default blob behavior or a mime type.
        await _audioRecorder.start(const RecordConfig(), path: path ?? '');
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && mounted) {
        debugPrint('DEBUG: Recording stopped, path: $path');
        Uint8List fileBytes;
        if (kIsWeb) {
          debugPrint('DEBUG: Fetching bytes from blob URL...');
          final response = await http.get(Uri.parse(path));
          fileBytes = response.bodyBytes;
        } else {
          final file = File(path);
          fileBytes = await file.readAsBytes();
        }

        debugPrint('DEBUG: File bytes length: ${fileBytes.length}');
        final cleanName =
            'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        debugPrint('DEBUG: Uploading audio to backend...');
        final storage = sl<BackendStorageService>();
        final uploadPath =
            await storage.uploadBytes(fileBytes, cleanName, 'chats');

        // Construct full URL (ensuring slash and /media/ prefix)
        final url = uploadPath.startsWith('http')
            ? uploadPath
            : 'http://localhost/media/${uploadPath.startsWith('/') ? uploadPath.substring(1) : uploadPath}';

        debugPrint('DEBUG: Final Message URL: $url');

        debugPrint('DEBUG: Upload result: $url');
        if (mounted) {
          _sendMessage(context, type: 'audio', mediaUrl: url);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: BlocListener<ChatBloc, ChatState>(
        listenWhen: (prev, curr) => curr.messages.isNotEmpty,
        listener: (context, state) {
          final lastMessage =
              state.messages.first; // Reverse list, so first is newest
          if (lastMessage.senderId != widget.currentUserId &&
              lastMessage.id != _lastInteractionId) {
            if (lastMessage.type == 'nudge') {
              _lastInteractionId = lastMessage.id;
              _triggerNudge();
            } else if (lastMessage.type == 'kiss') {
              _lastInteractionId = lastMessage.id;
              _triggerKiss();
            } else if (lastMessage.type == 'jolt') {
              _lastInteractionId = lastMessage.id;
              _triggerJolt();
            }
          }
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 1,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.targetUserPhoto != null &&
                              widget.targetUserPhoto!.isNotEmpty
                          ? AppNetworkImage.provider(widget.targetUserPhoto!)
                          : null,
                      child: (widget.targetUserPhoto == null ||
                              widget.targetUserPhoto!.isEmpty)
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.targetUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state.status == ChatStatus.loading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final messages = state.messages;

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe =
                                message.senderId == widget.currentUserId;

                            return _buildMessageBubble(
                              message.text,
                              isMe,
                              message.createdAt,
                              type: message.type,
                              mediaUrl: message.mediaUrl,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
            )
                .animate(target: _isJolting ? 1 : 0)
                .shake(duration: 600.ms, hz: 20, offset: const Offset(15, 15)),
            if (_isNudging)
              IgnorePointer(
                child: Center(
                  child: const Icon(
                    Icons.pan_tool,
                    color: Colors.blueAccent,
                    size: 400,
                  )
                      .animate()
                      .scale(
                          duration: 300.ms,
                          begin: const Offset(0.01, 0.01),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack)
                      .fadeIn(duration: 100.ms)
                      .then()
                      .shake(
                          duration: 150.ms,
                          hz: 20,
                          offset: const Offset(15, 15)) // Toque 1
                      .then(delay: 100.ms)
                      .shake(
                          duration: 150.ms,
                          hz: 20,
                          offset: const Offset(15, 15)) // Toque 2
                      .then(delay: 100.ms)
                      .shake(
                          duration: 150.ms,
                          hz: 20,
                          offset: const Offset(15, 15)) // Toque 3
                      .fadeOut(delay: 800.ms, duration: 400.ms),
                ),
              ),
            if (_isKissing)
              IgnorePointer(
                child: Center(
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 400,
                  )
                      .animate()
                      .scale(
                          duration: 800.ms,
                          begin: const Offset(0.1, 0.1),
                          end: const Offset(1.5, 1.5),
                          curve: Curves.elasticOut)
                      .fadeIn(duration: 200.ms)
                      .then()
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1000.ms)
                      .fadeOut(delay: 1500.ms, duration: 500.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, DateTime createdAt,
      {String type = 'text', String? mediaUrl}) {
    final timeStr = DateFormat('HH:mm').format(createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE5B80B) : Colors.grey[850],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'text')
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 15,
                ),
              )
            else if (type == 'image' && mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  imageUrl: mediaUrl,
                  borderRadius: 12,
                ),
              )
            else if (type == 'audio' && mediaUrl != null)
              ChatAudioPlayer(
                mediaUrl: mediaUrl,
                isMe: isMe,
                audioPlayer: _audioPlayer,
                isPlayingCurrent: _currentPlayingUrl == mediaUrl,
                onPlay: () {
                  setState(() => _currentPlayingUrl = mediaUrl);
                },
              )
            else if (type == 'nudge')
              Column(
                children: [
                  const Icon(
                    Icons.pan_tool,
                    color: Colors.blueAccent,
                    size: 30,
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .shake(
                          duration: 500.ms, hz: 10, offset: const Offset(4, 4)),
                  const SizedBox(height: 4),
                  Text(
                    isMe ? 'Você enviou um Knock!' : 'ENVIARAM UM KNOCK!',
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else if (type == 'kiss')
              Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 30,
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          duration: 600.ms,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    isMe
                        ? 'Você enviou um Beijo!'
                        : 'VOCÊ RECEBEU UM BEIJO! 💋',
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else if (type == 'jolt')
              Column(
                children: [
                  Icon(
                    Icons.bolt,
                    color: isMe ? Colors.black : AppTheme.primaryColor,
                    size: 30,
                  )
                      .animate(onPlay: (controller) {
                        if (!isMe) {
                          HapticFeedback.vibrate();
                          Future.delayed(
                              100.ms, () => HapticFeedback.vibrate());
                          Future.delayed(
                              200.ms, () => HapticFeedback.vibrate());
                        }
                      })
                      .shimmer(duration: 1.seconds)
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    isMe
                        ? 'Você chamou a atenção!'
                        : 'ESTÃO CHAMANDO SUA ATENÇÃO!',
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe ? Colors.black54 : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showActions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Foto',
                        color: Colors.white70,
                        onPressed: _pickImage,
                      ),
                      _buildActionButton(
                        icon: Icons.mic,
                        label: 'Áudio',
                        color: Colors.white70,
                        onPressed: _startRecording,
                      ),
                      _buildActionButton(
                        icon: Icons.sports_mma,
                        label: 'Knock',
                        color: Colors.blueAccent,
                        onPressed: () => _sendMessage(context, type: 'nudge'),
                      ),
                      _buildActionButton(
                        icon: Icons.bolt,
                        label: 'Atenção',
                        color: Colors.amber,
                        onPressed: () {
                          if (!kIsWeb) HapticFeedback.mediumImpact();
                          _sendMessage(context, type: 'jolt');
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.favorite,
                        label: 'Beijo',
                        color: Colors.redAccent,
                        onPressed: () => _sendMessage(context, type: 'kiss'),
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showActions
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: const Color(0xFFE5B80B),
                    ),
                    onPressed: () =>
                        setState(() => _showActions = !_showActions),
                  ),
                  if (_isRecording)
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.red),
                      onPressed: _stopRecording,
                    ),
                  if (_isRecording)
                    Expanded(
                      child: const Text(
                        'Gravando...',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeOut(duration: 500.ms),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) => _sendMessage(context),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFE5B80B)),
                    onPressed: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _sendMessage(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context,
      {String type = 'text', String? mediaUrl}) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty || mediaUrl != null || type != 'text') {
      debugPrint(
          'DEBUG: _sendMessage called - type: $type, mediaUrl: $mediaUrl');
      if (type == 'nudge') _triggerNudge();
      if (type == 'kiss') _triggerKiss();
      if (type == 'jolt') _triggerJolt();

      final authState = context.read<AuthBloc>().state;
      String? senderName;
      String? senderPhoto;
      if (authState is ProfileLoaded) {
        senderName = authState.profile.artisticName;
        senderPhoto = authState.profile.photoUrl;
      }

      _chatBloc.add(
        MessageSentRequested(
          text,
          type: type,
          mediaUrl: mediaUrl,
          senderName: senderName,
          senderPhoto: senderPhoto,
        ),
      );
      _messageController.clear();
    }
  }
}
