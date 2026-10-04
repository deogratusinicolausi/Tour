import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ═══════════════════════════════════════════════════════════════
// ⭐️ HOVER TOUR CARD - 3D TILT + SHIMMER + GOLD GLOW
// ═══════════════════════════════════════════════════════════════
class HoverTourCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverTourCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverTourCard> createState() => _HoverTourCardState();
}

class _HoverTourCardState extends State<HoverTourCard>
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
                            painter: _TourShimmerPainter(
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

class _TourShimmerPainter extends CustomPainter {
  final double progress;
  _TourShimmerPainter(this.progress);

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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TourShimmerPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ TOUR GRID CARD - With Staggered Animation
// ═══════════════════════════════════════════════════════════════
class TourGridCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const TourGridCard({
    super.key,
    required this.tour,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = (tour['images'] as List?) ?? [];
    final firstImage = images.isNotEmpty ? images[0] : '';

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
      child: HoverTourCard(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // GLASS
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
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: width * 0.32,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'tour_${tour['id']}',
                        child: _buildImage(firstImage, double.infinity, width),
                      ),

                      // Tour type badge
                      if ((tour['tourType'] ?? '').isNotEmpty)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              tour['tourType'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // Featured badge
                      if (tour['featured'] == true)
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
                                  color: AppColors.accentGold.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 10, color: Colors.black),
                                SizedBox(width: 3),
                                Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Rating badge
                      if ((tour['rating'] ?? 0) > 0)
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
                                  (tour['rating'] as num).toStringAsFixed(1),
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

                      // Like button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: AnimatedTourLikeButton(
                          isLiked: isLiked,
                          onTap: onLike,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info
              Padding(
                padding: EdgeInsets.all(width * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.032,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.025, color: Colors.white70),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            tour['destinationName'] ??
                                tour['location'] ??
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
                    if ((tour['duration'] ?? '').isNotEmpty) ...[
                      SizedBox(height: height * 0.002),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: width * 0.025, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text(
                            tour['duration'],
                            style: TextStyle(
                              fontSize: width * 0.022,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: height * 0.005),
                    if ((tour['price'] ?? 0) > 0)
                      Row(
                        children: [
                          Text(
                            '${tour['currency'] ?? 'USD'} ${(tour['price'] as num).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.032,
                            ),
                          ),
                          Text(
                            '/person',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.022,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url, double height, double width) {
    if (url.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.25),
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.tour_outlined,
              size: width * 0.1, color: AppColors.primary),
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
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade800,
        child: Icon(Icons.broken_image,
            size: width * 0.1, color: Colors.grey.shade400),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ TOUR LIST CARD - GLASS VERSION (HAKUNA WHITE BACKGROUND)
// ═══════════════════════════════════════════════════════════════
class TourListCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const TourListCard({
    super.key,
    required this.tour,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = (tour['images'] as List?) ?? [];
    final firstImage = images.isNotEmpty ? images[0] : '';

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
      child: HoverTourCard(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: height * 0.015),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // ⭐ GLASS - HAKUNA WHITE
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
                child: SizedBox(
                  width: width * 0.32,
                  height: width * 0.32,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'tour_${tour['id']}',
                        child: _buildImage(firstImage, width * 0.32, width),
                      ),
                      if (tour['featured'] == true)
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    size: 10, color: Colors.black),
                                SizedBox(width: 3),
                                Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.035),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.white, // ⭐ WHITE TEXT
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
                              tour['destinationName'] ??
                                  tour['location'] ??
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
                      if ((tour['duration'] ?? '').isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: width * 0.03,
                                color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              tour['duration'],
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((tour['rating'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              (tour['rating'] as num).toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.03,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((tour['price'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.008),
                        Text(
                          '${tour['currency'] ?? 'USD'} ${(tour['price'] as num).toStringAsFixed(0)}/person',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.035,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: width * 0.03),
                child: AnimatedTourLikeButton(
                  isLiked: isLiked,
                  onTap: onLike,
                  size: width * 0.06,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url, double height, double width) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.primary.withOpacity(0.1),
        child: Icon(Icons.tour_outlined,
            size: width * 0.08, color: AppColors.primary),
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

// ═══════════════════════════════════════════════════════════════
// ⭐️ ANIMATED LIKE BUTTON (Heart bounce effect)
// ═══════════════════════════════════════════════════════════════
class AnimatedTourLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double? size;

  const AnimatedTourLikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size,
  });

  @override
  State<AnimatedTourLikeButton> createState() =>
      _AnimatedTourLikeButtonState();
}

class _AnimatedTourLikeButtonState extends State<AnimatedTourLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(covariant AnimatedTourLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? 16.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(widget.size != null ? 4 : 6),
        decoration: BoxDecoration(
          color: widget.isLiked
              ? Colors.red.withOpacity(0.25)
              : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isLiked
                ? Colors.red.withOpacity(0.6)
                : Colors.white.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isLiked
                  ? Colors.red.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: widget.isLiked ? 12 : 8,
            ),
          ],
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(widget.isLiked),
              color: widget.isLiked ? Colors.red : Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ TOUR SHIMMER LOADING CARD
// ═══════════════════════════════════════════════════════════════
class TourShimmerCard extends StatefulWidget {
  const TourShimmerCard({super.key});

  @override
  State<TourShimmerCard> createState() => _TourShimmerCardState();
}

class _TourShimmerCardState extends State<TourShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                height: height * 0.11,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                    stops: [
                      (_controller.value - 0.3).clamp(0.0, 1.0),
                      _controller.value.clamp(0.0, 1.0),
                      (_controller.value + 0.3).clamp(0.0, 1.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 14, width: double.infinity),
                      const SizedBox(height: 6),
                      _shimmerBox(height: 10, width: 100),
                      const Spacer(),
                      _shimmerBox(height: 12, width: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value.clamp(0.0, 1.0),
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}