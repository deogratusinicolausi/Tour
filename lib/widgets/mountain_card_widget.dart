import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/colors.dart';

// ═══════════════════════════════════════════════════════════════
// ⭐️ HOVER MOUNTAIN CARD - 3D TILT + SHIMMER + GOLD GLOW
// ═══════════════════════════════════════════════════════════════
class HoverMountainCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverMountainCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverMountainCard> createState() => _HoverMountainCardState();
}

class _HoverMountainCardState extends State<HoverMountainCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  Offset _mousePosition = Offset.zero;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _mousePosition = Offset.zero;
      }),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final local = box.globalToLocal(event.position);
          final size = box.size;
          final dx = (local.dx / size.width - 0.5) * 2;
          final dy = (local.dy / size.height - 0.5) * 2;
          setState(() => _mousePosition = Offset(dx, dy));
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_isHovered ? -_mousePosition.dy * 0.08 : 0)
            ..rotateY(_isHovered ? _mousePosition.dx * 0.08 : 0)
            ..scale(_isHovered ? 1.04 : 1.0)
            ..translate(0.0, _isHovered ? -8.0 : 0.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.5),
                blurRadius: 35,
                spreadRadius: 2,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              widget.child,
              if (_isHovered)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _MountainShimmerPainter(
                              _shimmerController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MountainShimmerPainter extends CustomPainter {
  final double progress;
  _MountainShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment(-1 + progress * 2, -1),
      end: Alignment(1 + progress * 2, 1),
      colors: [
        Colors.transparent,
        AppColors.accentGold.withOpacity(0.15),
        Colors.white.withOpacity(0.25),
        AppColors.accentGold.withOpacity(0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _MountainShimmerPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ MOUNTAIN GRID CARD
// ═══════════════════════════════════════════════════════════════
class MountainGridCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const MountainGridCard({
    super.key,
    required this.mountain,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Hard':
        return Colors.orange;
      case 'Extreme':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final difficultyColor =
    _getDifficultyColor(mountain['difficulty'] ?? 'Moderate');

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (animationIndex * 80)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: HoverMountainCard(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // ⭐ GLASS
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 16 / 13, // Adjusted to prevent bottom overflow
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'mountain_${mountain['id']}',
                        child: _buildImage(
                            mountain['imageUrl'], double.infinity, width),
                      ),

                      // Height badge
                      if ((mountain['height'] ?? 0) > 0)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.height,
                                    color: Colors.white, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  '${(mountain['height'] as num).toStringAsFixed(0)}m',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Difficulty badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: difficultyColor.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            (mountain['difficulty'] ?? 'Moderate')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Featured
                      if (mountain['featured'] == true)
                        Positioned(
                          top: 8,
                          right: 32,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGold
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.star,
                                size: 10, color: Colors.black),
                          ),
                        ),

                      // Rating
                      if ((mountain['rating'] ?? 0) > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.accentGold, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  (mountain['rating'] as num)
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Like
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onLike,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isLiked
                                  ? Colors.red.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLiked
                                    ? Colors.red.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isLiked
                                      ? Colors.red.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: isLiked ? 12 : 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mountain['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.033,
                          color: Colors.white, // ⭐ WHITE
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: width * 0.025,
                                  color: Colors.white70), // ⭐ WHITE70
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  mountain['location'] ??
                                      mountain['country'] ??
                                      '',
                                  style: TextStyle(
                                    fontSize: width * 0.022,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if ((mountain['duration'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: width * 0.022,
                                    color: Colors.white70),
                                const SizedBox(width: 3),
                                Text(
                                  mountain['duration'],
                                  style: TextStyle(
                                    fontSize: width * 0.02,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(dynamic url, double height, double width) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown.shade200, Colors.brown.shade400],
          ),
        ),
        child: Center(
          child: Icon(Icons.terrain,
              size: width * 0.1, color: Colors.white),
        ),
      );
    }

    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black.withOpacity(0.2),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentGold,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade800,
        child: Icon(Icons.broken_image,
            size: width * 0.1, color: Colors.grey.shade400),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ MOUNTAIN LIST CARD - GLASS VERSION
// ═══════════════════════════════════════════════════════════════
class MountainListCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const MountainListCard({
    super.key,
    required this.mountain,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Hard':
        return Colors.orange;
      case 'Extreme':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final difficultyColor =
    _getDifficultyColor(mountain['difficulty'] ?? 'Moderate');

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (animationIndex * 80)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: HoverMountainCard(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: height * 0.015),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // ⭐ GLASS
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18)),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'mountain_${mountain['id']}',
                      child: SizedBox(
                        width: width * 0.38, // Increased from 0.32
                        height: width * 0.38, // Increased from 0.32
                        child: _buildImage(
                            mountain['imageUrl'], width * 0.38, width),
                      ),
                    ),
                    if (mountain['featured'] == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold
                                    .withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Text('⭐',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: difficultyColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: difficultyColor.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          (mountain['difficulty'] ?? 'Moderate')
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.035),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mountain['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.white, // ⭐ WHITE
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.height,
                              size: width * 0.03,
                              color: AppColors.accentGold),
                          const SizedBox(width: 3),
                          Text(
                            '${(mountain['height'] ?? 0).toStringAsFixed(0)}m',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: width * 0.03,
                              color: Colors.white70), // ⭐ WHITE70
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              mountain['location'] ??
                                  mountain['country'] ??
                                  '',
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((mountain['duration'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: width * 0.03,
                                color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              mountain['duration'],
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((mountain['rating'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              (mountain['rating'] as num)
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.03,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: width * 0.03),
                child: GestureDetector(
                  onTap: onLike,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? Colors.red.withOpacity(0.25)
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLiked
                            ? Colors.red.withOpacity(0.6)
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: width * 0.05,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(dynamic url, double height, double width) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown.shade200, Colors.brown.shade400],
          ),
        ),
        child: Icon(Icons.terrain, size: width * 0.08, color: Colors.white),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image,
            size: width * 0.08, color: Colors.grey.shade400),
      ),
    );
  }
}