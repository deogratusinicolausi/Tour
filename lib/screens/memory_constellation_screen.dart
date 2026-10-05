import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class MemoryConstellationScreen extends StatefulWidget {
  const MemoryConstellationScreen({super.key});

  @override
  State<MemoryConstellationScreen> createState() =>
      _MemoryConstellationScreenState();
}

class _MemoryConstellationScreenState
    extends State<MemoryConstellationScreen>
    with SingleTickerProviderStateMixin {
  final _service = MemoryService();
  late AnimationController _controller;
  List<MemoryModel> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _load();
  }

  Future<void> _load() async {
    final memories = await _service.getUserMemories().first;
    // Sort chronologically
    final sorted = [...memories]
      ..sort((a, b) =>
          (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    if (mounted) {
      setState(() {
        _memories = sorted;
        _loading = false;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1F), // Deep night sky
      body: Stack(
        children: [
          // Star field background
          ..._buildRandomStars(width, height),

          // Constellation
          if (!_loading && _memories.isNotEmpty)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConstellationPainter(
                      memories: _memories,
                      progress: _controller.value,
                      width: width,
                      height: height,
                    ),
                  );
                },
              ),
            ),

          // Loading
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold),
            ),

          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌌 Your Constellation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Every memory is a star',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Empty
          if (!_loading && _memories.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome,
                      color: Colors.white.withOpacity(0.3),
                      size: width * 0.2),
                  const SizedBox(height: 20),
                  const Text(
                    'No stars yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create memories to build\nyour constellation',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Legend
          if (!_loading && _memories.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.accentGold.withOpacity(0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_memories.length} stars in your sky — tap the constellation to replay',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.reset();
                        _controller.forward();
                      },
                      child: const Icon(Icons.replay,
                          color: AppColors.accentGold, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRandomStars(double width, double height) {
    final random = math.Random(42); // Fixed seed for consistency
    return List.generate(
      100,
          (i) {
        final x = random.nextDouble() * width;
        final y = random.nextDouble() * height;
        final size = random.nextDouble() * 2 + 0.5;
        final opacity = random.nextDouble() * 0.5 + 0.2;
        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CONSTELLATION PAINTER
// ============================================================
class _ConstellationPainter extends CustomPainter {
  final List<MemoryModel> memories;
  final double progress;
  final double width;
  final double height;

  _ConstellationPainter({
    required this.memories,
    required this.progress,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (memories.isEmpty) return;

    // Compute positions for each memory
    final positions = <Offset>[];
    for (var i = 0; i < memories.length; i++) {
      final angle = (i / memories.length) * 2 * math.pi;
      // Use memory ID hash for slight randomness
      final hash = memories[i].id.hashCode;
      final radiusVariation = 0.3 + ((hash % 100) / 100) * 0.2;
      final radius = math.min(width, height) * radiusVariation;
      final cx = width / 2;
      final cy = height / 2;

      positions.add(Offset(
        cx + radius * math.cos(angle),
        cy + radius * math.sin(angle),
      ));
    }

    // Draw lines (animated progress)
    final linePaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final totalSegments = positions.length - 1;
    final visibleSegments = (totalSegments * progress).floor();
    final partial = (totalSegments * progress) - visibleSegments;

    for (var i = 0; i < visibleSegments; i++) {
      canvas.drawLine(positions[i], positions[i + 1], linePaint);
    }
    if (visibleSegments < totalSegments && visibleSegments >= 0) {
      final a = positions[visibleSegments];
      final b = positions[visibleSegments + 1];
      final interp = Offset(
        a.dx + (b.dx - a.dx) * partial,
        a.dy + (b.dy - a.dy) * partial,
      );
      canvas.drawLine(a, interp, linePaint);
    }

    // Draw stars (each appears at its time)
    for (var i = 0; i < positions.length; i++) {
      final starProgress = i / positions.length;
      if (starProgress > progress) continue;

      final m = memories[i];

      // Star glow
      final glowPaint = Paint()
        ..color = AppColors.accentGold
            .withOpacity(0.3 * (progress - starProgress) * 2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(positions[i], 20, glowPaint);

      // Star core
      final starPaint = Paint()
        ..color = m.favorite ? AppColors.accentGold : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(positions[i], 5, starPaint);

      // Inner shine
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(positions[i], 2, shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}