import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ═══════════════════════════════════════════════════════════════
// ⭐️ HOVER BEACH CARD - 3D TILT + SHIMMER + GOLD GLOW
// ═══════════════════════════════════════════════════════════════
class HoverBeachCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverBeachCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverBeachCard> createState() => _HoverBeachCardState();
}

class _HoverBeachCardState extends State<HoverBeachCard>
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
                            painter: _BeachShimmerPainter(
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

class _BeachShimmerPainter extends CustomPainter {
  final double progress;
  _BeachShimmerPainter(this.progress);

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
  bool shouldRepaint(covariant _BeachShimmerPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ BEACH GRID CARD
// ═══════════════════════════════════════════════════════════════
class BeachGridCard extends StatelessWidget {
  final Map<String, dynamic> beach;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const BeachGridCard({
    super.key,
    required this.beach,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
      child: HoverBeachCard(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
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
              // ⭐ IMAGE — fixed height (no AspectRatio)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: SizedBox(
                  height: height * 0.19,   // Increased from 0.13 to 0.18
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(beach['imageUrl'], double.infinity, width),

                      // Water type badge
                      if ((beach['waterType'] ?? '').isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🌊 ${beach['waterType']}'.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Featured
                      if (beach['featured'] == true)
                        Positioned(
                          top: 8,
                          right: 32,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.star,
                                size: 10, color: Colors.black),
                          ),
                        ),

                      // Rating
                      if ((beach['rating'] ?? 0) > 0)
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
                                const Icon(Icons.star,
                                    color: AppColors.accentGold, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  (beach['rating'] as num)
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
                            ),
                            child: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ⭐ INFO — compact with mainAxisSize.min
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.025,
                    vertical: width * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,   // ⭐ NO GAP
                  children: [
                    Text(
                      beach['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.035,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.028, color: Colors.white70),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            beach['location'] ?? beach['country'] ?? '',
                            style: TextStyle(
                              fontSize: width * 0.026,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if ((beach['activities'] as List?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 3),
                      Text(
                        (beach['activities'] as List).take(2).join(' • '),
                        style: TextStyle(
                          fontSize: width * 0.024,
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
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
            colors: [Colors.blue.shade100, Colors.blue.shade300],
          ),
        ),
        child: Center(
          child: Icon(Icons.beach_access,
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
// ⭐️ BEACH LIST CARD - GLASS VERSION
// ═══════════════════════════════════════════════════════════════
class BeachListCard extends StatelessWidget {
  final Map<String, dynamic> beach;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const BeachListCard({
    super.key,
    required this.beach,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
      child: HoverBeachCard(
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
                borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(18)),
                child: Stack(
                  children: [
                    SizedBox(
                      width: width * 0.40, // Increased from 0.32 to 0.40
                      height: width * 0.40, // Increased from 0.32 to 0.40
                      child: _buildImage(
                          beach['imageUrl'], width * 0.40, width),
                    ),
                    if (beach['featured'] == true)
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
                        beach['name'] ?? 'Unnamed',
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
                          Icon(Icons.location_on,
                              size: width * 0.03,
                              color: Colors.white70), // ⭐ WHITE70
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              beach['location'] ?? beach['country'] ?? '',
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
                      if ((beach['waterType'] ?? '').isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            const Icon(Icons.water,
                                size: 14,
                                color: AppColors.accentGold),
                            const SizedBox(width: 3),
                            Text(
                              beach['waterType'],
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((beach['rating'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              (beach['rating'] as num).toStringAsFixed(1),
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
          ),
        ),
        child: Center(
          child: Icon(Icons.beach_access,
              size: width * 0.08, color: Colors.white),
        ),
      );
    }
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image,
            size: width * 0.08, color: Colors.grey.shade400),
      ),
    );
  }
}