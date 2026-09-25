import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ⭐️ Hover Wrapper
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

class _HoverBeachCardState extends State<HoverBeachCard> {
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
                color: AppColors.accentGold.withOpacity(0.4),
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

// ⭐️ Beach Grid Card
class BeachGridCard extends StatelessWidget {
  final Map<String, dynamic> beach;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const BeachGridCard({
    super.key,
    required this.beach,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return HoverBeachCard(
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
            // Image
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  _buildImage(beach['imageUrl'], height * 0.18, width),

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
                              (beach['rating'] as num).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : Colors.white,
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
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.025, vertical: width * 0.015),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      beach['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: width * 0.035,
                                  color: Colors.white70),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  beach['location'] ??
                                      beach['country'] ??
                                      '',
                                  style: TextStyle(
                                    fontSize: width * 0.032,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if ((beach['activities'] as List?)
                              ?.isNotEmpty ??
                              false) ...[
                            Text(
                              (beach['activities'] as List)
                                  .take(2)
                                  .join(' • '),
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                    ),
                    )
                  ],
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
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade300,
            ],
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

// ⭐️ Beach List Card
class BeachListCard extends StatelessWidget {
  final Map<String, dynamic> beach;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const BeachListCard({
    super.key,
    required this.beach,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return HoverBeachCard(
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
                    child: _buildImage(beach['imageUrl'], width * 0.32, width),
                  ),
                  if (beach['featured'] == true)
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
                        fontSize: width * 0.05,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.035,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            beach['location'] ?? beach['country'] ?? '',
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.grey.shade500,
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
                          Icon(Icons.water,
                              size: width * 0.035,
                              color: Colors.blue.shade600),
                          const SizedBox(width: 3),
                          Text(
                            beach['waterType'],
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.blue.shade600,
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
                              color: AppColors.accentGold, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            (beach['rating'] as num).toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
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
            colors: [Colors.blue.shade100, Colors.blue.shade300],
          ),
        ),
        child: Icon(Icons.beach_access,
            size: width * 0.08, color: Colors.white),
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