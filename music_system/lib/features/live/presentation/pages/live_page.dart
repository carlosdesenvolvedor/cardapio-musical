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
  bool _isFullscreen = false;
  String? _error;
  EventsListener<RoomEvent>? _listener;
  final List<LiveChatMessage> _chatMessages = [];
  final TextEditingController _chatFieldController = TextEditingController();
  CameraPosition _cameraPosition = CameraPosition.front;

  // Fake data for UI alignment as per image
  final double _tipGoalProgress = 0.65;
  final List<Map<String, String>> _topSupporters = [
    {'name': 'Anranda', 'last': 'Llinta'},
    {'name': 'Joranna', 'last': 'Bompas'},
    {'name': 'Benzoa', 'last': 'Moria'},
    {'name': 'Aniver', 'last': 'Goia'},
    {'name': 'Eiron', 'last': 'Madro'},
    {'name': 'Brizaniha', 'last': 'Lilves'},
  ];

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

        final track =
            room.localParticipant?.videoTrackPublications.firstOrNull?.track;
        if (track is LocalVideoTrack) {
          _cameraPosition = CameraPosition.front;
        }

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
          _error = 'Ocorreu um erro de conexão. Toque para tentar novamente.';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    final room = _liveKitService.room;
    if (room == null || !widget.isHost) return;

    final track =
        room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is! LocalVideoTrack) return;

    try {
      final newPosition = _cameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;

      await track
          .restartTrack(CameraCaptureOptions(cameraPosition: newPosition));

      setState(() {
        _cameraPosition = newPosition;
      });
    } catch (e) {
      debugPrint('Error switching camera: $e');
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
      await room.localParticipant?.publishData(bytes);

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

  AuthBloc? _authBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    // Use cached bloc reference to avoid "unsafe ancestor lookup"
    if (widget.isHost && _authBloc != null) {
      _authBloc!.add(ToggleLiveStatus(widget.userId, false));
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
          child: CircularProgressIndicator(color: Color(0xFFE5B80B)),
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
              const Icon(Icons.wifi_off, color: Color(0xFFE5B80B), size: 64),
              const SizedBox(height: 24),
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initLiveKit();
                },
                child: const Text('Tentar Novamente'),
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
          // Background Video (When fullscreen) or black
          if (_isFullscreen)
            Positioned.fill(child: _buildVideoFrame(room, isFull: true)),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(room),
                Expanded(
                  child: Stack(
                    children: [
                      // Non-fullscreen view: Framed Video
                      if (!_isFullscreen)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Hero(
                              tag: 'live_video',
                              child: _buildVideoFrame(room, isFull: false),
                            ),
                          ),
                        ),

                      // Floating engagement panel
                      Positioned(
                        right: 16,
                        top: 16,
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: _buildSidePanel(room),
                      ),

                      // Fullscreen toggle button (Floating bottom right of video area)
                      Positioned(
                        left: 24,
                        bottom: 80,
                        child: _buildActionCircle(
                          icon: _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          onPressed: () =>
                              setState(() => _isFullscreen = !_isFullscreen),
                          color: const Color(0xFFE5B80B),
                        ),
                      ),

                      // Host controls
                      if (widget.isHost)
                        Positioned(
                          right: 24,
                          bottom: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionCircle(
                                icon: room.localParticipant
                                            ?.isMicrophoneEnabled() ??
                                        false
                                    ? Icons.mic
                                    : Icons.mic_off,
                                onPressed: () {
                                  final e = room.localParticipant
                                          ?.isMicrophoneEnabled() ??
                                      false;
                                  room.localParticipant
                                      ?.setMicrophoneEnabled(!e);
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildActionCircle(
                                icon: Icons.flip_camera_ios,
                                onPressed: _switchCamera,
                              ),
                              const SizedBox(height: 12),
                              _buildActionCircle(
                                icon:
                                    room.localParticipant?.isCameraEnabled() ??
                                            false
                                        ? Icons.videocam
                                        : Icons.videocam_off,
                                onPressed: () {
                                  final e = room.localParticipant
                                          ?.isCameraEnabled() ??
                                      false;
                                  room.localParticipant?.setCameraEnabled(!e);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Room room) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withAlpha(50),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => _confirmExit(),
          ),
          const SizedBox(width: 4),
          _buildUserAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: Colors.blueAccent, size: 16),
                  ],
                ),
                const Text('Ao vivo',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          _buildBadge('AO VIVO', isLive: true),
          const SizedBox(width: 8),
          _buildBadge(room.remoteParticipants.length + (widget.isHost ? 0 : 1),
              icon: Icons.person_outline),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Compartilhar Live',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Share logic here
              },
            ),
            ListTile(
              leading: Icon(
                  widget.isHost ? Icons.stop_circle : Icons.exit_to_app,
                  color: Colors.red),
              title: Text(
                  widget.isHost ? 'Encerrar Transmissão' : 'Sair da Live',
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmExit();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5B80B), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE5B80B).withAlpha(100), blurRadius: 8),
        ],
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String? photoUrl;
          if (state is ProfileLoaded) photoUrl = state.profile.photoUrl;
          return CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[900],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white54, size: 20)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBadge(dynamic content, {IconData? icon, bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFC00000).withAlpha(180) : Colors.black87,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isLive ? Colors.red : const Color(0xFFE5B80B), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFFE5B80B), size: 12),
            const SizedBox(width: 4)
          ],
          Text(
            content.toString(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFrame(Room room, {required bool isFull}) {
    final frame = Container(
      decoration: isFull
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5B80B), width: 4),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE5B80B).withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
      clipBehavior: Clip.antiAlias,
      child: widget.isHost ? _buildLocalVideo(room) : _buildRemoteVideo(room),
    );

    if (isFull) return frame;

    return AspectRatio(
      aspectRatio:
          9 / 12, // More vertical aspect ratio for larger presence on mobile
      child: frame,
    );
  }

  Widget _buildSidePanel(Room room) {
    if (_isFullscreen) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Tip Goal
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('META',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: _tipGoalProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFE5B80B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Top Supporters
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOP APOIADORES',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
              const SizedBox(height: 8),
              ..._topSupporters.take(4).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 10),
                        children: [
                          TextSpan(
                              text: s['name'],
                              style: const TextStyle(
                                  color: Color(0xFFE5B80B),
                                  fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' '),
                          TextSpan(
                              text: s['last'],
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black.withAlpha(80),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _chatFieldController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Comentar...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildActionCircle(
              icon: Icons.send,
              onPressed: _sendMessage,
              color: const Color(0xFFE5B80B),
              size: 44),
          const SizedBox(width: 8),
          _buildActionCircle(
              icon: Icons.music_note,
              color: const Color(0xFFE5B80B),
              onPressed: _showRepertoire,
              size: 44),
          const SizedBox(width: 8),
          // Large Tip Button
          GestureDetector(
            onTap: _showRepertoire,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE5B80B), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFE5B80B).withAlpha(150),
                          blurRadius: 12),
                    ],
                  ),
                  child: Center(
                      child: Text('\$',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFFE5B80B),
                              fontSize: 24,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 2),
                const Text('GORJETA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalVideo(Room room) {
    final track =
        room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null) return const Center(child: CircularProgressIndicator());
    return VideoTrackRenderer(track as VideoTrack, fit: VideoViewFit.cover);
  }

  Widget _buildRemoteVideo(Room room) {
    final remote = room.remoteParticipants.values
        .firstWhereOrNull((p) => p.videoTrackPublications.isNotEmpty);
    final track = remote?.videoTrackPublications.firstOrNull?.track;
    if (track == null)
      return const Center(
          child:
              Text('Aguardando...', style: TextStyle(color: Colors.white54)));
    return VideoTrackRenderer(track as VideoTrack, fit: VideoViewFit.cover);
  }

  Widget _buildActionCircle(
      {required IconData icon,
      Color color = Colors.white,
      required VoidCallback onPressed,
      double size = 42}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFE5B80B).withAlpha(150), width: 1.5),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(widget.isHost ? 'Encerrar Live?' : 'Sair da Live?',
            style: const TextStyle(color: Colors.white)),
        content: Text(widget.isHost ? 'A live será encerrada.' : 'Deseja sair?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Não')),
          TextButton(
              onPressed: () {
                if (widget.isHost)
                  context
                      .read<AuthBloc>()
                      .add(ToggleLiveStatus(widget.userId, false));
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Sim')),
        ],
      ),
    );
  }
}

extension IterableExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
