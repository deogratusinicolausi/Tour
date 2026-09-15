import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ⭐️ Hover Wrapper
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

class _HoverFoodCardState extends State<HoverFoodCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.03 : 1.0)
            ..translate(0.0, _isHovered ? -5.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ⭐️ Helpers
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

// ⭐️ Food Grid Card
class FoodGridCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const FoodGridCard({
    super.key,
    required this.food,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getFoodCategoryColor(food['category'] ?? '');
    final categoryIcon = getFoodCategoryIcon(food['category'] ?? '');
    final spiceColor = getSpiceColor(food['spiceLevel'] ?? 'Mild');

    return HoverFoodCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
              child: Stack(
                children: [
                  _buildImage(food['imageUrl'], height * 0.11, width,
                      categoryIcon, categoryColor),

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
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            (food['category'] ?? '').toString().toUpperCase(),
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
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onLike,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color:
                          isLiked ? Colors.red : Colors.grey.shade700,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
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
                        color: Colors.grey.shade900,
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
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  food['restaurantName'] ??
                                      food['location'] ??
                                      '',
                                  style: TextStyle(
                                    fontSize: width * 0.022,
                                    color: Colors.grey.shade500,
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
                              color: Colors.green.shade600,
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
    );
  }

  Widget _buildImage(dynamic url, double height, double width,
      IconData fallbackIcon, Color color) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.4),
              color.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Icon(fallbackIcon, size: width * 0.1, color: Colors.white),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image,
            size: width * 0.1, color: Colors.grey.shade400),
      ),
    );
  }
}

// ⭐️ Food List Card
class FoodListCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const FoodListCard({
    super.key,
    required this.food,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getFoodCategoryColor(food['category'] ?? '');
    final categoryIcon = getFoodCategoryIcon(food['category'] ?? '');
    final spiceColor = getSpiceColor(food['spiceLevel'] ?? 'Mild');

    return HoverFoodCard(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                    width: width * 0.32,
                    height: width * 0.32,
                    child: _buildImage(food['imageUrl'], width * 0.32, width,
                        categoryIcon, categoryColor),
                  ),
                  if (food['featured'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(8),
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
                              color: Colors.grey.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((food['price'] ?? 0) > 0)
                          Text(
                            '${food['currency'] ?? 'USD'} ${(food['price'] as num).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: categoryColor,
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
                            size: width * 0.03,
                            color: categoryColor),
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
                              color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              food['restaurantName'] ??
                                  '${food['location']}, ${food['region'] ?? ''}',
                              style: TextStyle(
                                fontSize: width * 0.028,
                                color: Colors.grey.shade500,
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
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey.shade400,
                  size: width * 0.06,
                ),
              ),
            ),
          ],
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