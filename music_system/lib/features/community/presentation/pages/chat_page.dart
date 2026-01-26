import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_system/core/presentation/widgets/app_network_image.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../injection_container.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

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

  bool _isRecording = false;
  String? _recordingPath;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final storage = sl<StorageService>();
      final fileName =
          'chats/${widget.currentUserId}_${widget.targetUserId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final url = await storage.uploadImage(bytes, fileName);
      if (url != null && mounted) {
        _sendMessage(context, type: 'image', mediaUrl: url);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
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
        final file = File(path);
        final bytes = await file.readAsBytes();
        final storage = sl<StorageService>();
        final fileName =
            'chats/${widget.currentUserId}_${widget.targetUserId}/${DateTime.now().millisecondsSinceEpoch}.m4a';

        final url = await storage.uploadFile(
          fileBytes: bytes,
          fileName: fileName,
          contentType: 'audio/m4a',
        );

        if (url != null && mounted) {
          _sendMessage(context, type: 'audio', mediaUrl: url);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ChatBloc>()
        ..add(
          ChatStarted(
            senderId: widget.currentUserId,
            receiverId: widget.targetUserId,
          ),
        ),
      child: Scaffold(
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = state.messages;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUserId;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: isMe ? Colors.black : Colors.white,
                    ),
                    onPressed: () async {
                      await _audioPlayer.play(UrlSource(mediaUrl));
                    },
                  ),
                  const Text('Mensagem de voz', style: TextStyle(fontSize: 12)),
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Color(0xFFE5B80B)),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                    color: const Color(0xFFE5B80B)),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              Expanded(
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
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFE5B80B)),
                onPressed: () => _sendMessage(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context,
      {String type = 'text', String? mediaUrl}) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty || mediaUrl != null) {
      final authState = context.read<AuthBloc>().state;
      String? senderName;
      String? senderPhoto;
      if (authState is ProfileLoaded) {
        senderName = authState.profile.artisticName;
        senderPhoto = authState.profile.photoUrl;
      }

      context.read<ChatBloc>().add(
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
