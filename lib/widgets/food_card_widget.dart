import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ═══════════════════════════════════════════════════════════════
// ⭐️ HOVER FOOD CARD - 3D TILT + SHIMMER + GOLD GLOW
// ═══════════════════════════════════════════════════════════════
class HoverFoodCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverFoodCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverFoodCard> createState() => _HoverFoodCardState();
}

class _HoverFoodCardState extends State<HoverFoodCard>
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
                            painter: _FoodShimmerPainter(
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

class _FoodShimmerPainter extends CustomPainter {
  final double progress;
  _FoodShimmerPainter(this.progress);

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
  bool shouldRepaint(covariant _FoodShimmerPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ Helpers
// ═══════════════════════════════════════════════════════════════
Color getFoodCategoryColor(String category) {
  switch (category) {
    case 'Dish':
      return const Color(0xFFff5722);
    case 'Cuisine':
      return const Color(0xFFe91e63);
    case 'Restaurant':
      return const Color(0xFF9c27b0);
    case 'Drink':
      return const Color(0xFF2196f3);
    case 'Dessert':
      return const Color(0xFFff9800);
    case 'Street Food':
      return const Color(0xFF4caf50);
    default:
      return AppColors.primary;
  }
}

IconData getFoodCategoryIcon(String category) {
  switch (category) {
    case 'Dish':
      return Icons.restaurant;
    case 'Cuisine':
      return Icons.local_dining;
    case 'Restaurant':
      return Icons.store;
    case 'Drink':
      return Icons.local_bar;
    case 'Dessert':
      return Icons.cake;
    case 'Street Food':
      return Icons.fastfood;
    default:
      return Icons.restaurant_menu;
  }
}

Color getSpiceColor(String spice) {
  switch (spice) {
    case 'Mild':
      return Colors.green;
    case 'Medium':
      return Colors.amber;
    case 'Hot':
      return Colors.orange;
    case 'Very Hot':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// ═══════════════════════════════════════════════════════════════
// ⭐️ FOOD GRID CARD
// ═══════════════════════════════════════════════════════════════
class FoodGridCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const FoodGridCard({
    super.key,
    required this.food,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getFoodCategoryColor(food['category'] ?? '');
    final categoryIcon = getFoodCategoryIcon(food['category'] ?? '');
    final spiceColor = getSpiceColor(food['spiceLevel'] ?? 'Mild');

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
      child: HoverFoodCard(
        onTap: onTap,
        child: Container(
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
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 16 / 15,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'food_${food['id']}',
                        child: _buildImage(food['imageUrl'],
                            double.infinity, width, categoryIcon, categoryColor),
                      ),

                      // Category badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                (food['category'] ?? '')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Spice level
                      if ((food['spiceLevel'] ?? '').isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 32,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: spiceColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: spiceColor.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text('🌶️',
                                style: TextStyle(fontSize: 10)),
                          ),
                        ),

                      // Rating
                      if ((food['rating'] ?? 0) > 0)
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
                                  (food['rating'] as num).toStringAsFixed(1),
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

                      // Price
                      if ((food['price'] ?? 0) > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              '${food['currency'] ?? 'USD'} ${(food['price'] as num).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        food['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.032,
                          color: Colors.white, // ⭐ WHITE
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((food['location'] ?? '').toString().isNotEmpty ||
                              (food['restaurantName'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: width * 0.025,
                                    color: Colors.white70), // ⭐ WHITE70
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    food['restaurantName'] ??
                                        food['location'] ??
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
                          if ((food['dietary'] as List?)?.isNotEmpty ??
                              false) ...[
                            SizedBox(height: height * 0.003),
                            Text(
                              (food['dietary'] as List)
                                  .take(2)
                                  .join(' • '),
                              style: TextStyle(
                                fontSize: width * 0.02,
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildImage(dynamic url, double height, double width,
      IconData fallbackIcon, Color color) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.4), color.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: Icon(fallbackIcon, size: width * 0.1, color: Colors.white),
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
// ⭐️ FOOD LIST CARD - GLASS VERSION
// ═══════════════════════════════════════════════════════════════
class FoodListCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  final int animationIndex;

  const FoodListCard({
    super.key,
    required this.food,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getFoodCategoryColor(food['category'] ?? '');
    final categoryIcon = getFoodCategoryIcon(food['category'] ?? '');
    final spiceColor = getSpiceColor(food['spiceLevel'] ?? 'Mild');

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
      child: HoverFoodCard(
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
                      tag: 'food_${food['id']}',
                      child: SizedBox(
                        width: width * 0.32,
                        height: width * 0.32,
                        child: _buildImage(food['imageUrl'], width * 0.32,
                            width, categoryIcon, categoryColor),
                      ),
                    ),
                    if (food['featured'] == true)
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
                          color: spiceColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: spiceColor.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text('🌶️',
                            style: TextStyle(fontSize: 10)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food['name'] ?? 'Unnamed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                                color: Colors.white, // ⭐ WHITE
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((food['price'] ?? 0) > 0)
                            Text(
                              '${food['currency'] ?? 'USD'} ${(food['price'] as num).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.035,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: width * 0.03, color: categoryColor),
                          const SizedBox(width: 3),
                          Text(
                            food['category'] ?? '',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if ((food['location'] ?? '').toString().isNotEmpty ||
                          (food['restaurantName'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: width * 0.03,
                                color: Colors.white70), // ⭐ WHITE70
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                food['restaurantName'] ??
                                    '${food['location']}, ${food['region'] ?? ''}',
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
                      ],
                      if ((food['rating'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              (food['rating'] as num).toStringAsFixed(1),
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

  Widget _buildImage(dynamic url, double height, double width,
      IconData fallbackIcon, Color color) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.4), color.withOpacity(0.7)],
          ),
        ),
        child: Icon(fallbackIcon, size: width * 0.08, color: Colors.white),
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