import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:music_system/config/theme/app_theme.dart';

class ChatAudioPlayer extends StatefulWidget {
  final String mediaUrl;
  final bool isMe;
  final AudioPlayer audioPlayer;
  final bool
      isPlayingCurrent; // If this specific widget is the one currently playing in the shared player
  final VoidCallback onPlay;

  const ChatAudioPlayer({
    super.key,
    required this.mediaUrl,
    required this.isMe,
    required this.audioPlayer,
    required this.isPlayingCurrent,
    required this.onPlay,
  });

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _playbackRate = 1.0;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _playerStateSubscription =
        widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (widget.isPlayingCurrent && mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _durationSubscription =
        widget.audioPlayer.onDurationChanged.listen((newDuration) {
      if (widget.isPlayingCurrent && mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _positionSubscription =
        widget.audioPlayer.onPositionChanged.listen((newPosition) {
      if (widget.isPlayingCurrent && mounted) {
        setState(() => _position = newPosition);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPlayingCurrent) {
      // Reset state if we are no longer the active player
      if (_isPlaying) setState(() => _isPlaying = false);
      // Optional: keep last known position or reset? Resetting is cleaner for now.
      if (_position != Duration.zero) setState(() => _position = Duration.zero);
    } else if (oldWidget.isPlayingCurrent != widget.isPlayingCurrent) {
      // We just became active, maybe sync state?
      // The streams will handle it mostly.
      _isPlaying = widget.audioPlayer.state == PlayerState.playing;
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlay() async {
    if (widget.isPlayingCurrent && _isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      widget.onPlay(); // Notify parent to set us as active
      await widget.audioPlayer.setSourceUrl(widget.mediaUrl);
      await widget.audioPlayer.setPlaybackRate(_playbackRate);
      await widget.audioPlayer.resume();
    }
  }

  void _changeSpeed() {
    setState(() {
      if (_playbackRate == 1.0) {
        _playbackRate = 1.5;
      } else if (_playbackRate == 1.5) {
        _playbackRate = 2.0;
      } else {
        _playbackRate = 1.0;
      }
    });
    if (widget.isPlayingCurrent) {
      widget.audioPlayer.setPlaybackRate(_playbackRate);
    }
  }

  void _seek(double value) {
    if (widget.isPlayingCurrent) {
      final position = Duration(milliseconds: value.toInt());
      widget.audioPlayer.seek(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.black : Colors.white;
    final trackColor = widget.isMe ? Colors.black38 : Colors.white38;
    final activeColor = widget.isMe ? Colors.black : AppTheme.primaryColor;

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: color,
                ),
                onPressed: _togglePlay,
              ),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        thumbColor: activeColor,
                        activeTrackColor: activeColor,
                        inactiveTrackColor: trackColor,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds
                            .toDouble()
                            .clamp(0, _duration.inMilliseconds.toDouble()),
                        min: 0,
                        max: _duration.inMilliseconds.toDouble() > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 0, // Avoid division by zero issues or invalid max
                        onChanged: (value) {
                          if (widget.isPlayingCurrent) {
                            // Just update UI immediately for smoothness
                            setState(() {
                              _position = Duration(milliseconds: value.toInt());
                            });
                          }
                        },
                        onChangeEnd: _seek,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _changeSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: trackColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_playbackRate}x',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
