// lib/widgets/animated_search_background.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AnimatedSearchBackground extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const AnimatedSearchBackground({
    super.key,
    required this.isActive,
    required this.child,
  });

  @override
  State<AnimatedSearchBackground> createState() =>
      _AnimatedSearchBackgroundState();
}

class _AnimatedSearchBackgroundState extends State<AnimatedSearchBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Create particles
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.5 + 0.3,
        opacity: _random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles
        for (var p in _particles) {
          p.y -= p.speed * 0.005;
          if (p.y < -0.1) {
            p.y = 1.1;
            p.x = _random.nextDouble();
          }
        }

        return Stack(
          children: [
            // Particles background
            if (widget.isActive)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(_particles, _controller.value),
                ),
              ),
            // Actual search bar
            widget.child,
          ],
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Pulsing opacity
      final pulse = (sin(progress * 2 * pi + p.x * 10) + 1) / 2;
      paint.color = AppColors.accentGold.withOpacity(p.opacity * pulse);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );

      // Glow
      paint.color = AppColors.accentGold.withOpacity(p.opacity * pulse * 0.3);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * 2.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}