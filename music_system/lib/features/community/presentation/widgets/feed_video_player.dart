import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:music_system/config/theme/app_theme.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final VoidCallback? onDoubleTap;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.onDoubleTap,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(false);
          if (widget.autoPlay) {
            _controller.play();
          }
          // Briefly show controls on start
          setState(() => _showControls = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _controller.value.isPlaying) {
              setState(() => _showControls = false);
            }
          });
        }
      });

    _controller.addListener(() {
      if (mounted) {
        // Force show controls if paused
        if (!_controller.value.isPlaying && !_showControls) {
          setState(() => _showControls = true);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showControls = true;
      } else {
        _controller.play();
        _showControls = true;
        // Hide after delay if it successfully started playing
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _controller.value.isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          // Play/Pause Overlay Icon
          IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
          // Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppTheme.primaryColor,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Pause Indicator (if controls hidden but paused)
          if (!_controller.value.isPlaying && !_showControls)
            const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white54,
                size: 60,
              ),
            ),
        ],
      ),
    );
  }
}
