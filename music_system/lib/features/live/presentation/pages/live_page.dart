import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:music_system/core/services/livekit_service.dart';
import 'package:music_system/injection_container.dart';
import 'package:music_system/features/client_menu/presentation/pages/client_menu_page.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveChatMessage {
  final String senderName;
  final String text;
  final DateTime timestamp;

  LiveChatMessage({
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
}

class LivePage extends StatefulWidget {
  final String liveId;
  final bool isHost;
  final String userId;
  final String userName;

  const LivePage({
    super.key,
    required this.liveId,
    required this.isHost,
    required this.userId,
    required this.userName,
  });

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _liveKitService = sl<LiveKitService>();
  bool _isLoading = true;
  String? _error;
  EventsListener<RoomEvent>? _listener;
  final List<LiveChatMessage> _chatMessages = [];
  final TextEditingController _chatFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLiveKit();
  }

  Future<void> _initLiveKit() async {
    try {
      final tokenData =
          await _liveKitService.getToken(widget.liveId, widget.userName);

      final room = await _liveKitService.connect(
          tokenData['serverUrl']!, tokenData['token']!);

      _listener = room.createListener();
      _listener!.on<TrackSubscribedEvent>((event) {
        if (mounted) setState(() {});
      });
      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (mounted) setState(() {});
      });
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted) setState(() {});
      });
      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (mounted) setState(() {});
      });

      // Handle Data Received (Chat)
      _listener!.on<DataReceivedEvent>((event) {
        final String rawData = utf8.decode(event.data);
        try {
          final Map<String, dynamic> messageData = jsonDecode(rawData);
          if (messageData['type'] == 'chat') {
            final newMessage = LiveChatMessage(
              senderName: messageData['senderName'] ?? 'Anon',
              text: messageData['text'] ?? '',
              timestamp: DateTime.now(),
            );
            if (mounted) {
              setState(() {
                _chatMessages.add(newMessage);
                if (_chatMessages.length > 50) _chatMessages.removeAt(0);
              });
            }
          }
        } catch (e) {
          debugPrint('Error decoding chat data: $e');
        }
      });

      if (widget.isHost) {
        await room.localParticipant?.setCameraEnabled(true);
        await room.localParticipant?.setMicrophoneEnabled(true);
        if (mounted) {
          context.read<AuthBloc>().add(ToggleLiveStatus(widget.userId, true));
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in LivePage init: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Falha ao iniciar live: $e';
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _chatFieldController.text.trim();
    if (text.isEmpty) return;

    final room = _liveKitService.room;
    if (room == null) return;

    final messageData = {
      'type': 'chat',
      'senderName': widget.userName,
      'text': text,
    };

    final bytes = utf8.encode(jsonEncode(messageData));

    try {
      await room.localParticipant?.publishData(
        bytes,
      );

      // Add local message to list
      if (mounted) {
        setState(() {
          _chatMessages.add(LiveChatMessage(
            senderName: widget.userName,
            text: text,
            timestamp: DateTime.now(),
          ));
          _chatFieldController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    if (widget.isHost) {
      context.read<AuthBloc>().add(ToggleLiveStatus(widget.userId, false));
    }
    _listener?.dispose();
    _liveKitService.disconnect();
    _chatFieldController.dispose();
    super.dispose();
  }

  void _showRepertoire() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF0C0C0C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClientMenuPage(musicianId: widget.liveId),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE5B80B)),
              SizedBox(height: 16),
              Text('Conectando ao LiveKit...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final room = _liveKitService.room;
    if (room == null)
      return const Scaffold(body: Center(child: Text('Erro de conexão')));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.isHost
                ? _buildLocalVideo(room)
                : _buildRemoteVideo(room),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 50,
            left: 16,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                  onPressed: () => _confirmExit(),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildArtistAvatar(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.userName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  color: Colors.blueAccent, size: 14),
                            ],
                          ),
                          const Text(
                            'Ao vivo agora',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFD1D1D), Color(0xFF833AB4)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AO VIVO',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${room.remoteParticipants.length + (widget.isHost ? 0 : 1)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showOptionsMenu,
                ),
              ],
            ),
          ),

          // Chat Messages Overlay
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              height: 200,
              child: ListView.builder(
                reverse: true,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[_chatMessages.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${msg.senderName}: ',
                          style: const TextStyle(
                              color: Color(0xFFE5B80B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            msg.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Bar (Input)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _chatFieldController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Enviar um comentário...',
                        hintStyle:
                            TextStyle(color: Colors.white60, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionCircle(
                  icon: Icons.send,
                  onPressed: _sendMessage,
                ),
                const SizedBox(width: 12),
                _buildActionCircle(
                  icon: Icons.music_note,
                  color: const Color(0xFFE5B80B),
                  onPressed: _showRepertoire,
                ),
                const SizedBox(width: 12),
                _buildActionCircle(
                  icon: Icons.monetization_on,
                  color: Colors.greenAccent,
                  onPressed: _showRepertoire,
                ),
              ],
            ),
          ),

          if (widget.isHost)
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                children: [
                  _buildActionCircle(
                    icon: room.localParticipant?.isMicrophoneEnabled() ?? false
                        ? Icons.mic
                        : Icons.mic_off,
                    onPressed: () async {
                      final enabled =
                          room.localParticipant?.isMicrophoneEnabled() ?? false;
                      await room.localParticipant
                          ?.setMicrophoneEnabled(!enabled);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCircle(
                    icon: room.localParticipant?.isCameraEnabled() ?? false
                        ? Icons.videocam
                        : Icons.videocam_off,
                    onPressed: () async {
                      final enabled =
                          room.localParticipant?.isCameraEnabled() ?? false;
                      await room.localParticipant?.setCameraEnabled(!enabled);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.black,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String? photoUrl;
            if (state is ProfileLoaded) photoUrl = state.profile.photoUrl;
            return photoUrl != null
                ? CircleAvatar(
                    radius: 17, backgroundImage: NetworkImage(photoUrl))
                : const Icon(Icons.person, size: 20, color: Colors.white);
          },
        ),
      ),
    );
  }

  Widget _buildActionCircle(
      {required IconData icon,
      Color color = Colors.white,
      required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report, color: Colors.white),
            title: const Text('Denunciar Live',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Compartilhar Transmissão',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.redAccent),
            title: const Text('Sair da Live',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _confirmExit();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocalVideo(Room room) {
    final track =
        room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null)
      return const Center(
          child: Text('Iniciando câmera...',
              style: TextStyle(color: Colors.white)));
    return VideoTrackRenderer(track as VideoTrack, fit: VideoViewFit.cover);
  }

  Widget _buildRemoteVideo(Room room) {
    final remote = room.remoteParticipants.values
        .firstWhereOrNull((p) => p.videoTrackPublications.isNotEmpty);
    final track = remote?.videoTrackPublications.firstOrNull?.track;
    if (track == null)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, color: Colors.white54, size: 64),
        const SizedBox(height: 16),
        Text('Aguardando início da transmissão...',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16))
      ]));
    return VideoTrackRenderer(track as VideoTrack, fit: VideoViewFit.cover);
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(widget.isHost ? 'Encerrar Live?' : 'Sair da Live?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
            widget.isHost
                ? 'Isso irá encerrar a transmissão para todos os espectadores.'
                : 'Tem certeza que deseja sair agora?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(widget.isHost ? 'Encerrar' : 'Sair',
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
