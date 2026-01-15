import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/story_entity.dart';
import '../../../../core/presentation/widgets/app_network_image.dart';

class StoryPlayerPage extends StatefulWidget {
  final List<StoryEntity> stories;
  final int initialIndex;

  const StoryPlayerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryPlayerPage> createState() => _StoryPlayerPageState();
}

class _StoryPlayerPageState extends State<StoryPlayerPage> {
  late int _currentIndex;
  double _percent = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _percent = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_percent < 1) {
          _percent += 0.01;
        } else {
          _timer?.cancel();
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _percent = 0;
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _percent = 0;
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Image
          GestureDetector(
            onTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3) {
                _previousStory();
              } else if (details.globalPosition.dx > 2 * width / 3) {
                _nextStory();
              }
            },
            child: Center(
              child: AppNetworkImage(
                imageUrl: story.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top Bars (Progress)
          Positioned(
            top: 60,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Row(
                  children: widget.stories.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: LinearProgressIndicator(
                          value: index == _currentIndex
                              ? _percent
                              : (index < _currentIndex ? 1.0 : 0.0),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Author Info
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: story.authorPhotoUrl != null
                        ? NetworkImage(story.authorPhotoUrl!)
                        : null,
                    child: story.authorPhotoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    story.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
