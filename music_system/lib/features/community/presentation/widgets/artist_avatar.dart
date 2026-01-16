import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_network_image.dart';

class ArtistAvatar extends StatelessWidget {
  final String? photoUrl;
  final bool isMe;
  final bool isLive;
  final bool hasStories;
  final double radius;
  final VoidCallback? onTap;

  const ArtistAvatar({
    super.key,
    this.photoUrl,
    this.isMe = false,
    this.isLive = false,
    this.hasStories = false,
    this.radius = 30,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anel Dourado Pulsante (se estiver Live/Tocando)
          if (isLive) _PulsingRing(radius: radius + 4),

          // Anel de Stories (se tiver stories e não estiver live)
          if (!isLive && hasStories)
            Container(
              width: (radius + 4) * 2,
              height: (radius + 4) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Colors.orange, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

          // Container do Avatar
          Container(
            padding: EdgeInsets.all((isLive || hasStories) ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isLive || hasStories) ? Colors.black : Colors.transparent,
            ),
            child: photoUrl != null
                ? AppNetworkImage(
                    imageUrl: photoUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    borderRadius: radius,
                    memCacheWidth: (radius * 4).toInt(),
                  )
                : CircleAvatar(
                    radius: radius,
                    backgroundColor: Colors.white10,
                    child: Icon(
                      Icons.person,
                      color: Colors.white24,
                      size: radius,
                    ),
                  ),
          ),

          // Ícone de Adicionar Story (se for o Próprio Usuário e não tiver stories ativos)
          if (isMe && !hasStories)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 16),
              ),
            ),

          // Badge "AO VIVO"
          if (isLive)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Text(
                  'TOCANDO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final double radius;

  const _PulsingRing({required this.radius});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.radius * 2 * _animation.value,
          height: widget.radius * 2 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(
                0.5 * (2 - _animation.value),
              ),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
