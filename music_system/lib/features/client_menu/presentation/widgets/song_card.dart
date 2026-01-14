import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/song.dart';
import '../../../song_requests/domain/entities/song_request.dart';
import '../../../song_requests/presentation/bloc/song_request_bloc.dart';
import '../../../song_requests/presentation/bloc/song_request_event.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(4),
          ),
          child: song.albumCoverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.albumCoverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Icon(Icons.music_note, color: Colors.white54),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note, color: Colors.white54),
                  ),
                )
              : const Icon(Icons.music_note, color: Colors.white54),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFB3B3B3)),
          onPressed: () {
            _showRequestModal(context);
          },
        ),
        onTap: () => _showRequestModal(context),
      ),
    );
  }

  void _showRequestModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestModal(song: song),
    );
  }
}

class _RequestModal extends StatefulWidget {
  final Song song;

  const _RequestModal({required this.song});

  @override
  State<_RequestModal> createState() => _RequestModalState();
}

class _RequestModalState extends State<_RequestModal> {
  double _tipAmount = 0;
  bool _isSuccess = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Color(0xFF181818),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Color(0xFFE5B80B),
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 600.ms),
                  const SizedBox(height: 24),
                  const Text(
                    'Pedido enviado!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  const Text(
                    'O músico recebeu sua solicitação.',
                    style: TextStyle(color: Colors.white70),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Entendido'),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pedir Música',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.song.title} - ${widget.song.artist}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          const Text(
            'Oferecer uma gorjeta? (Opcional)',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TipButton(
                amount: 5,
                isSelected: _tipAmount == 5,
                onSelected: () => setState(() => _tipAmount = 5),
              ),
              _TipButton(
                amount: 10,
                isSelected: _tipAmount == 10,
                onSelected: () => setState(() => _tipAmount = 10),
              ),
              _TipButton(
                amount: 20,
                isSelected: _tipAmount == 20,
                onSelected: () => setState(() => _tipAmount = 20),
              ),
            ],
          ),
          if (_tipAmount > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'PIX Copia e Cola:',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String pixKey = 'PIX_NAO_CONFIGURADO';
                      if (state is ProfileLoaded) {
                        pixKey = state.profile.pixKey;
                      }
                      return SelectableText(
                        pixKey,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Clipboard simulation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código PIX copiado!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar código'),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              final request = SongRequest(
                id: const Uuid().v4(),
                songName: widget.song.title,
                artistName: widget.song.artist,
                musicianId: widget.song.musicianId,
                tipAmount: _tipAmount,
                createdAt: DateTime.now(),
              );

              context.read<SongRequestBloc>().add(CreateSongRequest(request));

              setState(() {
                _isSuccess = true;
              });
              _confettiController.play();
            },
            child: const Text('Confirmar Pedido'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TipButton extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final VoidCallback onSelected;

  const _TipButton({
    required this.amount,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onSelected,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFE5B80B).withOpacity(0.2)
            : null,
        side: BorderSide(
          color: isSelected ? const Color(0xFFE5B80B) : Colors.white24,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        'R\$ ${amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: isSelected ? const Color(0xFFE5B80B) : Colors.white,
        ),
      ),
    );
  }
}
