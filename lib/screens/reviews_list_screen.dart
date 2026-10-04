import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../utils/colors.dart';
import '../widgets/review_card_widget.dart';
import 'write_review_screen.dart';

class ReviewsListScreen extends StatefulWidget {
  final String itemId;
  final String itemType;
  final String itemName;

  const ReviewsListScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemName,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  final _reviewService = ReviewService();
  final _user = FirebaseAuth.instance.currentUser;

  String _filterRating = 'all';
  final String _sortBy = 'recent';
  bool _hasReviewed = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkUserReviewed();
  }

  Future<void> _loadStats() async {
    final stats = await _reviewService.getItemRatingStats(widget.itemId);
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _checkUserReviewed() async {
    if (_user == null) return;
    final reviewed = await _reviewService.hasUserReviewed(
      _user!.uid,
      widget.itemId,
    );
    if (mounted) setState(() => _hasReviewed = reviewed);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ===== DARK OVERLAY =====
          Container(color: Colors.black.withOpacity(0.7)),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                // ===== GLASS APP BAR =====
                _buildGlassAppBar(context, width),

                // ===== CONTENT SCROLL =====
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // GLASS STATS CARD
                      _buildGlassStatsCard(width, height),

                      // GLASS FILTER CHIPS
                      _buildGlassFilterChips(width, height),

                      // REVIEWS
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: height * 0.01),
                        child: StreamBuilder<List<ReviewModel>>(
                          stream: _reviewService
                              .getItemReviews(widget.itemId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accentGold,
                                  ),
                                ),
                              );
                            }

                            final all = snapshot.data ?? [];
                            final reviews = all.where((r) {
                              if (_filterRating == 'all') return true;
                              return r.rating.round().toString() ==
                                  _filterRating;
                            }).toList();

                            if (reviews.isEmpty) {
                              return _buildEmptyState(width, height);
                            }

                            return Column(
                              children: reviews
                                  .map((r) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: width * 0.03),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12),
                                    child: ReviewCard(
                                      review: r,
                                      currentUserId: _user?.uid,
                                      onHelpfulTap: () async {
                                        if (_user == null) return;
                                        await _reviewService
                                            .markHelpful(
                                          r.id,
                                          _user!.uid,
                                        );
                                      },
                                      onDelete:
                                      r.userId == _user?.uid
                                          ? () =>
                                          _confirmDelete(r)
                                          : null,
                                    ),
                                  ),
                                ),
                              ))
                                  .toList(),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: height * 0.08),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !_hasReviewed && _user != null
          ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteReviewScreen(
                itemId: widget.itemId,
                itemType: widget.itemType,
                itemName: widget.itemName,
              ),
            ),
          );
          if (result == true) {
            _loadStats();
            _checkUserReviewed();
          }
        },
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.rate_review, color: Colors.black),
        label: const Text(
          'Write Review',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
    );
  }

  // ============================================================
  // GLASS APP BAR
  // ============================================================
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.02,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
              vertical: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                const Expanded(
                  child: Text(
                    '⭐ Reviews & Ratings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS STATS CARD (average + breakdown)
  // ============================================================
  Widget _buildGlassStatsCard(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.008,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Average
                Column(
                  children: [
                    Text(
                      (_stats['average'] ?? 0.0).toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StarRating(
                      rating: (_stats['average'] ?? 0.0).toDouble(),
                      size: 18,
                    ),
                    SizedBox(height: height * 0.005),
                    Text(
                      '${_stats['total'] ?? 0} reviews',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: width * 0.03,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: width * 0.05),
                // Breakdown
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = _stats['$star'] ?? 0;
                      final total = _stats['total'] ?? 1;
                      final percent =
                      total > 0 ? (count / total) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$star',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 12),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor:
                                  Colors.white.withOpacity(0.2),
                                  color: AppColors.accentGold,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS FILTER CHIPS
  // ============================================================
  Widget _buildGlassFilterChips(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['all', '5', '4', '3', '2', '1'].map((r) {
            final isSelected = _filterRating == r;
            return GestureDetector(
              onTap: () => setState(() => _filterRating = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: width * 0.02),
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.045,
                    vertical: height * 0.01),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentGold
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: AppColors.accentGold
                          .withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ]
                      : [],
                ),
                child: Text(
                  r == 'all' ? 'All' : '$r ⭐',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.028,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.06),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.08),
          padding: EdgeInsets.all(width * 0.08),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.06),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.rate_review,
                    size: width * 0.12, color: Colors.black),
              ),
              SizedBox(height: height * 0.025),
              Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: width * 0.048,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: height * 0.01),
              Text(
                'Be the first to review!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: width * 0.032,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE DIALOG
  // ============================================================
  void _confirmDelete(ReviewModel review) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reviewService.deleteReview(review.id);
              _loadStats();
              _checkUserReviewed();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Review deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}