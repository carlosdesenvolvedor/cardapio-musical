import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lyrics_bloc.dart';

class LyricsViewPage extends StatefulWidget {
  final String songName;
  final String artist;

  const LyricsViewPage({
    super.key,
    required this.songName,
    required this.artist,
  });

  @override
  State<LyricsViewPage> createState() => _LyricsViewPageState();
}

class _LyricsViewPageState extends State<LyricsViewPage> {
  late ScrollController _scrollController;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 0.5;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<LyricsBloc>().add(
      FetchLyricsEvent(songName: widget.songName, artist: widget.artist),
    );
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    if (_isAutoScrolling) {
      _startScrolling();
    }
  }

  void _startScrolling() async {
    while (_isAutoScrolling) {
      if (!mounted) {
        _isAutoScrolling = false;
        break;
      }

      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted || !_isAutoScrolling) break;

      if (!_scrollController.hasClients) {
        // Controller lost clients (e.g., navigated away or view rebuilt), stop scrolling
        _isAutoScrolling = false;
        break;
      }

      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.offset;
      if (currentScroll < maxScroll) {
        _scrollController.jumpTo(currentScroll + _scrollSpeed);
      } else {
        setState(() {
          _isAutoScrolling = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.songName} - ${widget.artist}'),
        actions: [
          IconButton(
            icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoScroll,
          ),
        ],
      ),
      body: BlocBuilder<LyricsBloc, LyricsState>(
        builder: (context, state) {
          if (state is LyricsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LyricsLoaded) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.lyrics.content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 1.2,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 500), // Space for scrolling
                ],
              ),
            );
          } else if (state is LyricsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao buscar cifra: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LyricsBloc>().add(
                          FetchLyricsEvent(
                            songName: widget.songName,
                            artist: widget.artist,
                          ),
                        );
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Aguardando...'));
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Velocidade'),
            Slider(
              value: _scrollSpeed,
              min: 0.1,
              max: 2.0,
              onChanged: (val) {
                setState(() {
                  _scrollSpeed = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
