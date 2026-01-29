import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LiveStreamViewer extends StatefulWidget {
  final String
      streamUrl; // e.g., http://localhost:8888/live/mystream/index.m3u8
  final bool isLive;

  const LiveStreamViewer({
    super.key,
    required this.streamUrl,
    this.isLive = true,
  });

  @override
  State<LiveStreamViewer> createState() => _LiveStreamViewerState();
}

class _LiveStreamViewerState extends State<LiveStreamViewer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller.initialize();
      await _controller.play();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error initializing HLS player: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Erro ao carregar transmissão.',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE5B80B)));
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          _buildControls(),
          if (widget.isLive)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('AO VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return VideoProgressIndicator(
      _controller,
      allowScrubbing: false,
      colors: const VideoProgressColors(
        playedColor: Color(0xFFE5B80B),
        bufferedColor: Colors.white24,
        backgroundColor: Colors.grey,
      ),
    );
  }
}
