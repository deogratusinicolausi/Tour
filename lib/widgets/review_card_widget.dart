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

// ⭐️ Review Card
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

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: width * 0.055,
                backgroundColor: AppColors.primary,
                backgroundImage: review.userPhoto.isNotEmpty
                    ? NetworkImage(review.userPhoto)
                    : null,
                child: review.userPhoto.isEmpty
                    ? Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
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
                              color: Colors.grey.shade900,
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
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.green.shade700,
                                    size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
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
                            color: Colors.grey.shade500,
                            fontSize: width * 0.026,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete (own review)
              if (widget.currentUserId == review.userId &&
                  widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.grey, size: 20),
                  onPressed: () => _showMenu(context, width),
                ),
            ],
          ),

          SizedBox(height: height * 0.015),

          // Title
          if (review.title.isNotEmpty) ...[
            Text(
              review.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.042,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: height * 0.005),
          ],

          // Comment
          Text(
            review.comment,
            style: TextStyle(
              fontSize: width * 0.035,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          // Photos
          if (review.photos.isNotEmpty) ...[
            SizedBox(height: height * 0.015),
            SizedBox(
              height: height * 0.1,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _showPhoto(context, review.photos[i]),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          review.photos[i],
                          width: height * 0.1,
                          height: height * 0.1,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: height * 0.1,
                            height: height * 0.1,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Admin Reply
          if (review.adminReply.isNotEmpty) ...[
            SizedBox(height: height * 0.015),
            Container(
              padding: EdgeInsets.all(width * 0.035),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: AppColors.primary, size: width * 0.04),
                      SizedBox(width: width * 0.02),
                      Text(
                        'TURIVA Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.03,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    review.adminReply,
                    style: TextStyle(
                      fontSize: width * 0.032,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Helpful button
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
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isHelpful
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
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
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                      SizedBox(width: width * 0.015),
                      Text(
                        'Helpful (${review.helpfulCount})',
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: _isHelpful
                              ? AppColors.primary
                              : Colors.grey.shade600,
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
    );
  }

  void _showMenu(BuildContext context, double width) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Review'),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}