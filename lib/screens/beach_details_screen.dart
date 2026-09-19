import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wishlist_service.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/review_card_widget.dart';
import 'reviews_list_screen.dart';
import 'booking_screen.dart';

class BeachDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> beach;

  const BeachDetailsScreen({super.key, required this.beach});

  @override
  State<BeachDetailsScreen> createState() => _BeachDetailsScreenState();
}

class _BeachDetailsScreenState extends State<BeachDetailsScreen> {
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
        'title': 'Viewed: ${widget.beach['name']}',
        'description':
        '${_user?.displayName ?? 'Guest'} viewed this beach',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.beach['id'],
        'itemType': 'beach',
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
      widget.beach['id'],
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_user == null) return;
    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: widget.beach['id'],
      itemType: 'beach',
      itemName: widget.beach['name'] ?? '',
      itemImage: widget.beach['imageUrl'] ?? '',
      price: 0,
      currency: 'USD',
    );

    if (wasAdded) {
      await _firestore.collection('activities').add({
        'type': 'wishlist',
        'action': 'liked',
        'title': 'Liked: ${widget.beach['name']}',
        'description': '${_user!.displayName ?? 'User'} liked this beach',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.beach['id'],
        'itemType': 'beach',
        'icon': '❤️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() => _isLiked = wasAdded);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              wasAdded ? '❤️ Added to wishlist' : '💔 Removed'),
          backgroundColor: wasAdded ? Colors.red : Colors.grey,
        ),
      );
    }
  }

  List<String> get _allImages {
    final images = <String>[];
    if ((widget.beach['imageUrl'] ?? '').toString().isNotEmpty) {
      images.add(widget.beach['imageUrl']);
    }
    final gallery = widget.beach['gallery'] as List?;
    if (gallery != null) {
      for (var img in gallery) {
        if (img.toString().isNotEmpty) images.add(img.toString());
      }
    }
    return images;
  }

  Future<void> _openMap() async {
    final lat = widget.beach['latitude'];
    final lng = widget.beach['longitude'];

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
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = _allImages;
    final activities = (widget.beach['activities'] as List?) ?? [];

     return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.55),
          ),
          // 3. Your Existing CustomScrollView
          CustomScrollView(
            slivers: [
              // IMAGE HEADER
              SliverAppBar(
                expandedHeight: height * 0.4,
                pinned: true,
                backgroundColor: Colors.transparent, // CHANGED
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
                    color: Colors.blue.shade100,
                    child: const Icon(Icons.beach_access,
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
                          widget.beach['name'] ?? '',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // CHANGED
                          ),
                        ),
                      ),
                      if ((widget.beach['rating'] ?? 0) > 0)
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
                                (widget.beach['rating'] as num)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white, // WHITE
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),

                  // LOCATION
                  if ((widget.beach['location'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.white70,
                            size: width * 0.05),
                        SizedBox(width: width * 0.02),
                        Expanded(
                          child: Text(
                            '${widget.beach['location']}, ${widget.beach['country'] ?? ''}',
                            style: TextStyle(
                              fontSize: width * 0.038,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: height * 0.015),

                  // FEATURED BADGE + WATER TYPE
                  Row(
                    children: [
                      if (widget.beach['featured'] == true)
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
                      if (widget.beach['featured'] == true &&
                          (widget.beach['waterType'] ?? '').isNotEmpty)
                        SizedBox(width: width * 0.02),
                      if ((widget.beach['waterType'] ?? '').isNotEmpty)
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
                              Icon(Icons.water, size: 16, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                widget.beach['waterType'],
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
                  if ((widget.beach['description'] ?? '').isNotEmpty) ...[
                    _sectionTitle('About', width),
                    SizedBox(height: height * 0.01),
                    Text(
                      widget.beach['description'],
                      style: TextStyle(
                        fontSize: width * 0.037,
                        color: Colors.white70, // CHANGED
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // INFO CARDS
                  Row(
                    children: [
                      _infoCard(
                          Icons.calendar_today,
                          'Best Time',
                          widget.beach['bestTime'] ?? 'All Year',
                          Colors.blue,
                          width,
                      ),
                      SizedBox(width: width * 0.03),
                      _infoCard(
                          Icons.map_outlined,
                          'Map',
                          'Open GPS',
                          Colors.green,
                          width,
                          onTap: _openMap,
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  // ACTIVITIES
                  if (activities.isNotEmpty) ...[
                    _sectionTitle('🎯 Activities', width),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            a.toString(),
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
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

                  // MAP
                  if ((widget.beach['latitude'] ?? 0) != 0 &&
                      (widget.beach['longitude'] ?? 0) != 0) ...[
                    _sectionTitle('📍 Location', width),
                    SizedBox(height: height * 0.01),
                    GestureDetector(
                      onTap: _openMap,
                      child: Container(
                        padding: EdgeInsets.all(width * 0.05),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15), // GLASS
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map, color: Colors.white70, size: width * 0.08),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'View on Map',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.04,
                                      color: Colors.white, // WHITE
                                    ),
                                  ),
                                  Text(
                                    'Tap to open in Google Maps',
                                    style: TextStyle(
                                      color: Colors.white70, // WHITE70
                                      fontSize: width * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: width * 0.035,
                                color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // REVIEWS SECTION
                  // REVIEWS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: ReviewService().getItemRatingStats(widget.beach['id']),
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
                                itemId: widget.beach['id'],
                                itemType: 'beach',
                                itemName: widget.beach['name'] ?? '',
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
                    stream: ReviewService().getItemReviews(widget.beach['id']),
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
                              const SnackBar(content: Text('Please login first')),
                            );
                            return;
                          }
                          final cartService = CartService();
                          final added = await cartService.addToCart(
                              _user!.uid,
                              CartItem(
                                itemId: widget.beach['id'],
                                itemType: 'beach',
                                itemName: widget.beach['name'] ?? '',
                                itemImage: widget.beach['imageUrl'] ?? '',
                                price: (widget.beach['priceFrom'] ?? 0).toDouble(),
                                currency: widget.beach['currency'] ?? 'USD',
                              ));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(added ? '🛒 Added to cart!' : '❌ Failed'),
                                backgroundColor: added ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
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
                                  itemType: 'beach',
                                  itemId: widget.beach['id'],
                                  itemName: widget.beach['name'] ?? '',
                                  itemImage:
                                  widget.beach['imageUrl'] ?? '',
                                  price: 0,
                                  currency: 'USD',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: height * 0.022),
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
       ]
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

  Widget _infoCard(IconData icon, String label, String value, Color color,
      double width, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // GLASS
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3), // Slightly stronger for icon
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: width * 0.05),
              ),
              SizedBox(width: width * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: Colors.white70, // WHITE70
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: width * 0.032,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // WHITE
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}