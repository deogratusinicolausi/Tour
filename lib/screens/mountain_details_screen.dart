import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/review_card_widget.dart';
import 'reviews_list_screen.dart';
import 'booking_screen.dart';

class MountainDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> mountain;

  const MountainDetailsScreen({super.key, required this.mountain});

  @override
  State<MountainDetailsScreen> createState() =>
      _MountainDetailsScreenState();
}

class _MountainDetailsScreenState extends State<MountainDetailsScreen> {
  final _wishlistService = WishlistService();
  final _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLiked = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLiked();
    _logView();
  }

  Future<void> _logView() async {
    try {
      await _firestore.collection('activities').add({
        'type': 'view',
        'action': 'viewed',
        'title': 'Viewed: ${widget.mountain['name']}',
        'description':
        '${_user?.displayName ?? 'Guest'} viewed this mountain',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.mountain['id'],
        'itemType': 'mountain',
        'icon': '👁️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _checkLiked() async {
    if (_user == null) return;
    final liked = await _wishlistService.isLiked(
      _user!.uid,
      widget.mountain['id'],
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_user == null) return;
    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: widget.mountain['id'],
      itemType: 'mountain',
      itemName: widget.mountain['name'] ?? '',
      itemImage: widget.mountain['imageUrl'] ?? '',
      price: 0,
      currency: 'USD',
    );

    if (wasAdded) {
      await _firestore.collection('activities').add({
        'type': 'wishlist',
        'action': 'liked',
        'title': 'Liked: ${widget.mountain['name']}',
        'description':
        '${_user!.displayName ?? 'User'} liked this mountain',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.mountain['id'],
        'itemType': 'mountain',
        'icon': '❤️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() => _isLiked = wasAdded);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(wasAdded ? '❤️ Added to wishlist' : '💔 Removed'),
          backgroundColor: wasAdded ? Colors.red : Colors.grey,
        ),
      );
    }
  }

  Future<void> _openInGoogleMaps() async {
    final lat = widget.mountain['latitude'];
    final lng = widget.mountain['longitude'];

    if (lat == null || lng == null || lat == 0 || lng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  List<String> get _allImages {
    final images = <String>[];
    if ((widget.mountain['imageUrl'] ?? '').toString().isNotEmpty) {
      images.add(widget.mountain['imageUrl']);
    }
    final gallery = widget.mountain['gallery'] as List?;
    if (gallery != null) {
      for (var img in gallery) {
        if (img.toString().isNotEmpty) images.add(img.toString());
      }
    }
    return images;
  }

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
    final images = _allImages;
    final routes = (widget.mountain['routes'] as List?) ?? [];
    final highlights = (widget.mountain['highlights'] as List?) ?? [];
    final included = (widget.mountain['included'] as List?) ?? [];
    final excluded = (widget.mountain['excluded'] as List?) ?? [];
    final difficultyColor =
    _getDifficultyColor(widget.mountain['difficulty'] ?? 'Moderate');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // IMAGE HEADER
          SliverAppBar(
            expandedHeight: height * 0.4,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: _toggleLike,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isEmpty
                      ? Container(
                    color: Colors.brown.shade200,
                    child: const Icon(Icons.terrain,
                        size: 80, color: Colors.white),
                  )
                      : PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image,
                            size: 80, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME + RATING
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mountain['name'] ?? '',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      if ((widget.mountain['rating'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.accentGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                (widget.mountain['rating'] as num)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: height * 0.015),

                  // QUICK STATS
                  Row(
                    children: [
                      _quickStat(
                        Icons.height,
                        '${(widget.mountain['height'] ?? 0).toStringAsFixed(0)}m',
                        'Height',
                        Colors.brown.shade700,
                        width,
                      ),
                      SizedBox(width: width * 0.02),
                      _quickStat(
                        Icons.speed,
                        widget.mountain['difficulty'] ?? 'Moderate',
                        'Difficulty',
                        difficultyColor,
                        width,
                      ),
                      SizedBox(width: width * 0.02),
                      _quickStat(
                        Icons.access_time,
                        widget.mountain['duration'] ?? 'N/A',
                        'Duration',
                        Colors.blue,
                        width,
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),

                  // LOCATION
                  if ((widget.mountain['location'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: AppColors.primary,
                            size: width * 0.05),
                        SizedBox(width: width * 0.02),
                        Expanded(
                          child: Text(
                            '${widget.mountain['location']}, ${widget.mountain['country'] ?? ''}',
                            style: TextStyle(
                              fontSize: width * 0.038,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: height * 0.015),

                  // GOOGLE MAPS BUTTON
                  InkWell(
                    onTap: _openInGoogleMaps,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View on Google Maps',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: width * 0.035),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // FEATURED + BEST TIME
                  Wrap(
                    spacing: 8,
                    children: [
                      if (widget.mountain['featured'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star,
                                  size: 16, color: Colors.black),
                              SizedBox(width: 5),
                              Text(
                                'FEATURED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((widget.mountain['bestTime'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                widget.mountain['bestTime'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  // DESCRIPTION
                  if ((widget.mountain['description'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    _sectionTitle('About', width),
                    SizedBox(height: height * 0.01),
                    Text(
                      widget.mountain['description'],
                      style: TextStyle(
                        fontSize: width * 0.037,
                        color: Colors.white70, // CHANGED
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // HIGHLIGHTS
                  if (highlights.isNotEmpty) ...[
                    _sectionTitle('✨ Highlights', width),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: highlights.map((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.accentGold, size: 14),
                              const SizedBox(width: 5),
                              Text(h.toString(),
                                  style: const TextStyle(fontSize: 13, color: Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // ROUTES
                  if (routes.isNotEmpty) ...[
                    _sectionTitle('🗺️ Routes', width),
                    SizedBox(height: height * 0.01),
                    ...routes.asMap().entries.map((e) {
                      return Container(
                        margin: EdgeInsets.only(bottom: height * 0.01),
                        padding: EdgeInsets.all(width * 0.035),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15), // GLASS
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: width * 0.08,
                              height: width * 0.08,
                              decoration: BoxDecoration(
                                color: AppColors.accentGold, // GOLD
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.black, // BLACK on gold
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: Text(
                                e.value.toString(),
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.white, // WHITE
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: height * 0.025),
                  ],

                  // INCLUDED
                  if (included.isNotEmpty) ...[
                    _sectionTitle('✅ What\'s Included', width),
                    SizedBox(height: height * 0.01),
                    ...included.map((e) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: width * 0.01),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Text(
                                e.toString(),
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.white70, // WHITE70
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: height * 0.025),
                  ],

                  // EXCLUDED
                  if (excluded.isNotEmpty) ...[
                    _sectionTitle('❌ Not Included', width),
                    SizedBox(height: height * 0.01),
                    ...excluded.map((e) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: width * 0.01),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel,
                                color: Colors.red, size: 20),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Text(
                                e.toString(),
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.white70, // WHITE70
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: height * 0.025),
                  ],

                  // GALLERY
                  if (images.length > 1) ...[
                    _sectionTitle('📸 Gallery', width),
                    SizedBox(height: height * 0.01),
                    SizedBox(
                      height: height * 0.1,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _currentImageIndex = i),
                            child: Container(
                              margin:
                              EdgeInsets.only(right: width * 0.02),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  images[i],
                                  width: height * 0.1,
                                  height: height * 0.1,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                            Icons.broken_image),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // REVIEWS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: ReviewService().getItemRatingStats(widget.mountain['id']),
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? {};
                          final avg = (stats['average'] ?? 0.0).toStringAsFixed(1);
                          final total = stats['total'] ?? 0;
                          return Row(
                            children: [
                              _sectionTitle('⭐ Reviews', width),
                              SizedBox(width: width * 0.02),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: AppColors.accentGold, size: 14),
                                    SizedBox(width: width * 0.01),
                                    Text(
                                      '$avg ($total)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsListScreen(
                                itemId: widget.mountain['id'],
                                itemType: 'mountain',
                                itemName: widget.mountain['name'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  StreamBuilder<List<ReviewModel>>(
                    stream: ReviewService().getItemReviews(widget.mountain['id']),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1), // GLASS
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.rate_review, color: Colors.white70, size: 32),
                                SizedBox(height: height * 0.01),
                                Text('No reviews yet', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: reviews.take(2).map((r) {
                          return ReviewCard(
                            review: r,
                            currentUserId: _user?.uid,
                            onHelpfulTap: () async {
                              if (_user == null) return;
                              await ReviewService().markHelpful(r.id, _user!.uid);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: height * 0.025),

                  SizedBox(height: height * 0.03),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      // LIKE BUTTON
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? Colors.red.withOpacity(0.2)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLiked
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.white,
                            size: width * 0.07,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.03),

                      // CART BUTTON
                      GestureDetector(
                        onTap: () async {
                          if (_user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please login first')),
                            );
                            return;
                          }
                          final cartService = CartService();
                          final added = await cartService.addToCart(
                            _user!.uid,
                            CartItem(
                              itemId: widget.mountain['id'],
                              itemType: 'mountain',
                              itemName: widget.mountain['name'] ?? '',
                              itemImage: widget.mountain['imageUrl'] ?? '',
                              price: (widget.mountain['price'] ?? 0).toDouble(),
                              currency: widget.mountain['currency'] ?? 'USD',
                            ),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    added ? '🛒 Added to cart!' : '❌ Failed'),
                                backgroundColor:
                                    added ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: width * 0.07),
                        ),
                      ),
                      SizedBox(width: width * 0.03),

                      // BOOK NOW BUTTON
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(
                                  itemType: 'mountain',
                                  itemId: widget.mountain['id'],
                                  itemName: widget.mountain['name'] ?? '',
                                  itemImage: widget.mountain['imageUrl'] ?? '',
                                  price: 0,
                                  currency: 'USD',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.022),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold, // GOLD
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGold.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'BOOK NOW',
                                style: TextStyle(
                                  color: Colors.black, // BLACK on gold
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.05,
        fontWeight: FontWeight.bold,
        color: Colors.white, // CHANGED
      ),
    );
  }

  Widget _quickStat(IconData icon, String value, String label, Color color,
      double width) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: width * 0.03, horizontal: width * 0.02),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // GLASS
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: width * 0.06),
            SizedBox(height: width * 0.015),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.032,
                color: Colors.white, // WHITE
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: width * 0.024,
                color: Colors.white70, // WHITE70
              ),
            ),
          ],
        ),
      ),
    );
  }
}