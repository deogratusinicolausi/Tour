import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ⭐️ Hover Wrapper
class HoverCultureCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverCultureCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverCultureCard> createState() => _HoverCultureCardState();
}

class _HoverCultureCardState extends State<HoverCultureCard> {
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

// ⭐️ Helper functions
Color getCategoryColor(String category) {
  switch (category) {
    case 'Tribe':
      return const Color(0xFFe91e63);
    case 'Festival':
      return const Color(0xFFff9800);
    case 'Art':
      return const Color(0xFF9c27b0);
    case 'Music':
      return const Color(0xFF3f51b5);
    case 'Dance':
      return const Color(0xFFf44336);
    case 'Food':
      return const Color(0xFF4caf50);
    case 'Historical':
      return const Color(0xFF795548);
    case 'Village':
      return const Color(0xFF009688);
    case 'Craft':
      return const Color(0xFFff5722);
    default:
      return AppColors.primary;
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Tribe':
      return Icons.people;
    case 'Festival':
      return Icons.celebration;
    case 'Art':
      return Icons.palette;
    case 'Music':
      return Icons.music_note;
    case 'Dance':
      return Icons.music_video;
    case 'Food':
      return Icons.restaurant;
    case 'Historical':
      return Icons.account_balance;
    case 'Village':
      return Icons.home;
    case 'Craft':
      return Icons.handyman;
    default:
      return Icons.museum;
  }
}

// ⭐️ Culture Grid Card
class CultureGridCard extends StatelessWidget {
  final Map<String, dynamic> culture;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const CultureGridCard({
    super.key,
    required this.culture,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getCategoryColor(culture['category'] ?? '');
    final categoryIcon = getCategoryIcon(culture['category'] ?? '');

    return HoverCultureCard(
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
                  _buildImage(culture['imageUrl'], height * 0.11, width,
                      categoryIcon),

                  // Category badge
                  if ((culture['category'] ?? '').isNotEmpty)
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
                              (culture['category'] ?? '').toString().toUpperCase(),
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

                  // Featured
                  if (culture['featured'] == true)
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
                  if ((culture['rating'] ?? 0) > 0)
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
                              (culture['rating'] as num).toStringAsFixed(1),
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

                  // Entry fee
                  if ((culture['entryFee'] ?? 0) > 0)
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
                        child: Text(
                          '${culture['currency'] ?? 'USD'} ${(culture['entryFee'] as num).toStringAsFixed(0)}',
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
                      culture['name'] ?? 'Unnamed',
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
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: width * 0.025,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                culture['location'] ??
                                    culture['country'] ??
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
                        if ((culture['languages'] as List?)
                            ?.isNotEmpty ??
                            false) ...[
                          SizedBox(height: height * 0.003),
                          Text(
                            (culture['languages'] as List)
                                .take(2)
                                .join(' • '),
                            style: TextStyle(
                              fontSize: width * 0.02,
                              color: Colors.purple.shade600,
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
      IconData fallbackIcon) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              getCategoryColor(culture['category'] ?? '').withOpacity(0.4),
              getCategoryColor(culture['category'] ?? '').withOpacity(0.7),
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

// ⭐️ Culture List Card
class CultureListCard extends StatelessWidget {
  final Map<String, dynamic> culture;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const CultureListCard({
    super.key,
    required this.culture,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final categoryColor = getCategoryColor(culture['category'] ?? '');
    final categoryIcon = getCategoryIcon(culture['category'] ?? '');

    return HoverCultureCard(
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
                    child: _buildImage(
                        culture['imageUrl'], width * 0.32, width,
                        categoryIcon),
                  ),
                  if (culture['featured'] == true)
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
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(categoryIcon,
                          size: 12, color: Colors.white),
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
                      culture['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.03,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            culture['location'] ??
                                culture['country'] ??
                                '',
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
                    if ((culture['category'] ?? '').isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Text(
                        culture['category'],
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if ((culture['rating'] ?? 0) > 0) ...[
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            (culture['rating'] as num).toStringAsFixed(1),
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
      IconData fallbackIcon) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              getCategoryColor(culture['category'] ?? '').withOpacity(0.4),
              getCategoryColor(culture['category'] ?? '').withOpacity(0.7),
            ],
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