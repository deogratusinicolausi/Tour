import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'dart:ui';

// ⭐️ Hover Wrapper
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

class _HoverMountainCardState extends State<HoverMountainCard> {
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

// ⭐️ Mountain Grid Card
class MountainGridCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const MountainGridCard({
    super.key,
    required this.mountain,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
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

    return HoverMountainCard(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                    bottom: Radius.circular(4),
                  ),
              child: Stack(
                children: [
                  _buildImage(mountain['imageUrl'], height * 0.11, width),

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
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : Colors.grey.shade700,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
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
                        fontSize: width * 0.035,
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
                                mountain['location'] ??
                                    mountain['country'] ??
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
                        if ((mountain['duration'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          SizedBox(height: height * 0.003),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: width * 0.022,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                mountain['duration'],
                                style: TextStyle(
                                  fontSize: width * 0.02,
                                  color: Colors.grey.shade500,
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
      )
    );
  }

  Widget _buildImage(dynamic url, double height, double width) {
    if (url == null || url.toString().isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.brown.shade200,
              Colors.brown.shade400,
            ],
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

// ⭐️ Mountain List Card
class MountainListCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const MountainListCard({
    super.key,
    required this.mountain,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
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

    return HoverMountainCard(
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
                        mountain['imageUrl'], width * 0.32, width),
                  ),
                  if (mountain['featured'] == true)
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
                        color: difficultyColor,
                        borderRadius: BorderRadius.circular(8),
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
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        Icon(Icons.height,
                            size: width * 0.03,
                            color: Colors.brown.shade700),
                        const SizedBox(width: 3),
                        Text(
                          '${(mountain['height'] ?? 0).toStringAsFixed(0)}m',
                          style: TextStyle(
                            fontSize: width * 0.028,
                            color: Colors.brown.shade700,
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
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            mountain['location'] ??
                                mountain['country'] ??
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
                    if ((mountain['duration'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: width * 0.03,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            mountain['duration'],
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.grey.shade500,
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
                            (mountain['rating'] as num).toStringAsFixed(1),
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