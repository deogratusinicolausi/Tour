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
  String _sortBy = 'recent';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⭐ Reviews & Ratings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
      body: Column(
        children: [
          // STATS HEADER
          Container(
            padding: EdgeInsets.all(width * 0.05),
            color: AppColors.primary,
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
                        padding: EdgeInsets.symmetric(vertical: 2),
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

          // FILTER CHIPS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'all',
                  '5',
                  '4',
                  '3',
                  '2',
                  '1',
                ].map((r) {
                  final isSelected = _filterRating == r;
                  return GestureDetector(
                    onTap: () => setState(() => _filterRating = r),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.035,
                          vertical: height * 0.006),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r == 'all' ? 'All' : '$r ⭐',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: width * 0.026,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // REVIEWS
          Expanded(
            child: StreamBuilder<List<ReviewModel>>(
              stream: _reviewService.getItemReviews(widget.itemId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? [];
                var reviews = all.where((r) {
                  if (_filterRating == 'all') return true;
                  return r.rating.round().toString() == _filterRating;
                }).toList();

                if (reviews.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) => ReviewCard(
                    review: reviews[i],
                    currentUserId: _user?.uid,
                    onHelpfulTap: () async {
                      if (_user == null) return;
                      await _reviewService.markHelpful(
                        reviews[i].id,
                        _user!.uid,
                      );
                    },
                    onDelete: reviews[i].userId == _user?.uid
                        ? () => _confirmDelete(reviews[i])
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review,
              size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'Be the first to review!',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ReviewModel review) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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