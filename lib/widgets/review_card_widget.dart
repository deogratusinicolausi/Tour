import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../utils/colors.dart';

// ⭐️ Star Rating Widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.accentGold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, color: color, size: size);
        } else if (i < rating && rating - i >= 0.5) {
          return Icon(Icons.star_half, color: color, size: size);
        }
        return Icon(Icons.star_border, color: color, size: size);
      }),
    );
  }
}

// ⭐️ Interactive Star Picker
class StarPicker extends StatelessWidget {
  final double rating;
  final Function(double) onChanged;
  final double size;

  const StarPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 45,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged((i + 1).toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star : Icons.star_border,
              color: AppColors.accentGold,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

// ⭐️ Review Card (GLASS)
class ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final String? currentUserId;
  final VoidCallback? onHelpfulTap;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.currentUserId,
    this.onHelpfulTap,
    this.onDelete,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isHelpful = false;

  @override
  void initState() {
    super.initState();
    _isHelpful = widget.review.helpfulBy
        .contains(widget.currentUserId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final review = widget.review;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          margin: EdgeInsets.only(bottom: height * 0.015),
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: width * 0.055,
                    backgroundColor: AppColors.accentGold,
                    backgroundImage: review.userPhoto.isNotEmpty
                        ? NetworkImage(review.userPhoto)
                        : null,
                    child: review.userPhoto.isEmpty
                        ? Text(
                      review.userName.isNotEmpty
                          ? review.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                      ),
                    )
                        : null,
                  ),
                  SizedBox(width: width * 0.03),

                  // Name + Verified
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.038,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (review.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green
                                        .withOpacity(0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.verified,
                                        color: Colors.green, size: 10),
                                    SizedBox(width: 3),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: height * 0.003),
                        Row(
                          children: [
                            StarRating(rating: review.rating, size: 14),
                            SizedBox(width: width * 0.02),
                            Text(
                              review.timeAgo,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.026,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete menu
                  if (widget.currentUserId == review.userId &&
                      widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white70, size: 20),
                      onPressed: () => _showMenu(context, width),
                    ),
                ],
              ),

              SizedBox(height: height * 0.015),

              // ===== TITLE =====
              if (review.title.isNotEmpty) ...[
                Text(
                  review.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.042,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: height * 0.005),
              ],

              // ===== COMMENT =====
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),

              // ===== PHOTOS =====
              if (review.photos.isNotEmpty) ...[
                SizedBox(height: height * 0.015),
                SizedBox(
                  height: height * 0.1,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.photos.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () =>
                            _showPhoto(context, review.photos[i]),
                        child: Container(
                          margin: EdgeInsets.only(right: width * 0.02),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.network(
                                  review.photos[i],
                                  width: height * 0.1,
                                  height: height * 0.1,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: height * 0.1,
                                    height: height * 0.1,
                                    color: Colors.white
                                        .withOpacity(0.1),
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white54),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // ===== ADMIN REPLY =====
              if (review.adminReply.isNotEmpty) ...[
                SizedBox(height: height * 0.015),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.all(width * 0.035),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accentGold.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: AppColors.accentGold,
                                size: 16,
                              ),
                              SizedBox(width: width * 0.02),
                              Text(
                                'TURIVA Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.03,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            review.adminReply,
                            style: TextStyle(
                              fontSize: width * 0.032,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ===== HELPFUL BUTTON =====
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onHelpfulTap != null) {
                        widget.onHelpfulTap!();
                        setState(() => _isHelpful = !_isHelpful);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isHelpful
                            ? AppColors.accentGold.withOpacity(0.25)
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isHelpful
                              ? AppColors.accentGold
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isHelpful
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14,
                            color: _isHelpful
                                ? AppColors.accentGold
                                : Colors.white70,
                          ),
                          SizedBox(width: width * 0.015),
                          Text(
                            'Helpful (${review.helpfulCount})',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: _isHelpful
                                  ? AppColors.accentGold
                                  : Colors.white70,
                              fontWeight: _isHelpful
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS DELETE MENU
  // ============================================================
  void _showMenu(BuildContext context, double width) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.25)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: width * 0.04),
                ListTile(
                  leading:
                  const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text(
                    'Delete Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete!();
                  },
                ),
                SizedBox(height: width * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FULL SCREEN PHOTO VIEWER
  // ============================================================
  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                  const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}