import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ⭐️ Hover Wrapper
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

class _HoverTourCardState extends State<HoverTourCard> {
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

// ⭐️ Tour Grid Card
class TourGridCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const TourGridCard({
    super.key,
    required this.tour,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = (tour['images'] as List?) ?? [];
    final firstImage = images.isNotEmpty ? images[0] : '';

    return HoverTourCard(
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
            // Image
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  _buildImage(firstImage, height * 0.11, width),

                  // Tour type badge
                  if ((tour['tourType'] ?? '').isNotEmpty)
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

                  // Featured
                  if (tour['featured'] == true)
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
                  if ((tour['rating'] ?? 0) > 0)
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
                          color: isLiked ? Colors.red : Colors.grey.shade700,
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
                      tour['name'] ?? 'Unnamed',
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
                                tour['destinationName'] ??
                                    tour['location'] ??
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
                        if ((tour['duration'] ?? '').isNotEmpty) ...[
                          SizedBox(height: height * 0.003),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: width * 0.025,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                tour['duration'],
                                style: TextStyle(
                                  fontSize: width * 0.022,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: height * 0.003),
                        if ((tour['price'] ?? 0) > 0)
                          Row(
                            children: [
                              Text(
                                '${tour['currency'] ?? 'USD'} ${(tour['price'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.032,
                                ),
                              ),
                              Text(
                                '/person',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: width * 0.022,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildImage(String url, double height, double width) {
    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
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

// ⭐️ Tour List Card
class TourListCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;

  const TourListCard({
    super.key,
    required this.tour,
    required this.onTap,
    required this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = (tour['images'] as List?) ?? [];
    final firstImage = images.isNotEmpty ? images[0] : '';

    return HoverTourCard(
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
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18)),
              child: SizedBox(
                width: width * 0.32,
                height: width * 0.32,
                child: Stack(
                  children: [
                    _buildImage(firstImage, width * 0.32, width),
                    if (tour['featured'] == true)
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
                            tour['destinationName'] ??
                                tour['location'] ??
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
                    if ((tour['duration'] ?? '').isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: width * 0.03,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            tour['duration'],
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.grey.shade500,
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
                          color: AppColors.primary,
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