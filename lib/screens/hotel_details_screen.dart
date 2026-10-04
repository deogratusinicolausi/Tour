import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wishlist_service.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import 'booking_screen.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/review_card_widget.dart';
import 'reviews_list_screen.dart';
import 'map_screen.dart';


class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({super.key, required this.hotel, required Map<String, dynamic> hotelData});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  final _wishlistService = WishlistService();
  final _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLiked = false;
  int _currentImageIndex = 0;
  // ⭐ Facilities selection
  final Set<String> _selectedFacilities = {};

  @override
  void initState() {
    super.initState();
    _checkLiked();
    _logView();
    _loadFacilitySelections(); // ⭐ NEW
  }

  Future<void> _logView() async {
    try {
      await _firestore.collection('activities').add({
        'type': 'view',
        'action': 'viewed',
        'title': 'Viewed: ${widget.hotel['name']}',
        'description': '${_user?.displayName ?? 'Guest'} viewed this hotel',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.hotel['id'],
        'itemType': 'hotel',
        'icon': '👁️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error: $e');
    }
  }

  // ===== Facilities: load saved picks =====
  Future<void> _loadFacilitySelections() async {
    if (_user == null) return;
    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(_user!.uid)
          .collection('hotel_facilities')
          .doc(widget.hotel['id'])
          .get();
      if (doc.exists) {
        final saved = (doc.data()?['facilities'] as List?) ?? [];
        if (mounted) {
          setState(() {
            _selectedFacilities
              ..clear()
              ..addAll(saved.map((e) => e.toString()));
          });
        }
      }
    } catch (e) {
      debugPrint('🔥 load facilities: $e');
    }
  }

  // ===== Facilities: save picks =====
  Future<void> _saveFacilitySelections() async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('user_preferences')
          .doc(_user!.uid)
          .collection('hotel_facilities')
          .doc(widget.hotel['id'])
          .set({
        'facilities': _selectedFacilities.toList(),
        'hotelName': widget.hotel['name'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('🔥 save facilities: $e');
    }
  }

  // ===== Facilities: toggle =====
  void _toggleFacility(String label) {
    setState(() {
      if (_selectedFacilities.contains(label)) {
        _selectedFacilities.remove(label);
      } else {
        _selectedFacilities.add(label);
      }
    });
    _saveFacilitySelections();
  }

  // ===== Facilities: clear all =====
  void _clearFacilities() {
    setState(() => _selectedFacilities.clear());
    _saveFacilitySelections();
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.05,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // ⭐ Open TURIVA Street Map (OpenStreetMap)
  void _openStreetMap() {
    final lat = (widget.hotel['latitude'] as num?)?.toDouble();
    final lng = (widget.hotel['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location not available for this hotel'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: widget.hotel['name'] ?? 'Hotel',
        ),
      ),
    );
  }

  Future<void> _checkLiked() async {
    if (_user == null) return;
    final liked = await _wishlistService.isLiked(
      _user!.uid,
      widget.hotel['id'],
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_user == null) return;
    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: widget.hotel['id'],
      itemType: 'hotel',
      itemName: widget.hotel['name'] ?? '',
      itemImage: widget.hotel['imageUrl'] ?? '',
      price: (widget.hotel['priceFrom'] ?? 0).toDouble(),
      currency: widget.hotel['currency'] ?? 'USD',
    );

    if (wasAdded) {
      await _firestore.collection('activities').add({
        'type': 'wishlist',
        'action': 'liked',
        'title': 'Liked: ${widget.hotel['name']}',
        'description': '${_user!.displayName ?? 'User'} liked this hotel',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.hotel['id'],
        'itemType': 'hotel',
        'icon': '❤️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() => _isLiked = wasAdded);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasAdded ? '❤️ Added to wishlist' : '💔 Removed'),
          backgroundColor: wasAdded ? Colors.red : Colors.grey,
        ),
      );
    }
  }

  // ⭐️ Images zote kutoka admin
  List<String> get _allImages {
    final images = <String>[];
    if ((widget.hotel['imageUrl'] ?? '').toString().isNotEmpty) {
      images.add(widget.hotel['imageUrl']);
    }
    final gallery = widget.hotel['gallery'] as List?;
    if (gallery != null) {
      for (var img in gallery) {
        if (img.toString().isNotEmpty) images.add(img.toString());
      }
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = _allImages;
    final facilities = (widget.hotel['facilities'] as List?) ?? [];

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
                  _buildMainImage(images, height, width),
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
                          widget.hotel['name'] ?? '',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if ((widget.hotel['rating'] ?? 0) > 0)
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
                                (widget.hotel['rating'] as num)
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
                  SizedBox(height: height * 0.01),

                  // LOCATION
                  if ((widget.hotel['location'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: AppColors.primary, size: width * 0.05),
                        SizedBox(width: width * 0.02),
                        Expanded(
                          child: Text(
                            widget.hotel['location'],
                            style: TextStyle(
                                fontSize: width * 0.038,
                                color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: height * 0.015),

                  // ⭐ GLASS MAP PREVIEW CARD
                  GestureDetector(
                    onTap: _openStreetMap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accentGold.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon circle
                              Container(
                                padding: EdgeInsets.all(width * 0.03),
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentGold.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.map,
                                  color: Colors.black,
                                  size: width * 0.06,
                                ),
                              ),
                              SizedBox(width: width * 0.035),

                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View on TURIVA Map',
                                      style: TextStyle(
                                        fontSize: width * 0.038,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: height * 0.003),
                                    Text(
                                      'Distance, nearby hotels & directions',
                                      style: TextStyle(
                                        fontSize: width * 0.028,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.accentGold,
                                size: width * 0.04,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.02),

                  // PRICE
                  if ((widget.hotel['priceFrom'] ?? 0) > 0)
                    Container(
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRICE FROM',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.026,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${widget.hotel['currency'] ?? 'USD'} ${(widget.hotel['priceFrom'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'per night',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.028,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.hotel, color: AppColors.accentGold, size: width * 0.12),
                        ],
                      ),
                    ),

                  SizedBox(height: height * 0.025),

                  // DESCRIPTION
                  if ((widget.hotel['description'] ?? '').isNotEmpty) ...[
                    _sectionTitle('About', width),
                    SizedBox(height: height * 0.01),
                    Text(
                      widget.hotel['description'],
                      style: TextStyle(
                        fontSize: width * 0.037,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // FACILITIES (SELECTABLE)
                  if (facilities.isNotEmpty) ...[
                    Row(
                      children: [
                        _sectionTitle('Facilities', width),
                        const Spacer(),
                        if (_selectedFacilities.isNotEmpty)
                          GestureDetector(
                            onTap: _clearFacilities,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.close, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Clear (${_selectedFacilities.length})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: facilities.map((f) {
                        final label = f.toString();
                        final selected = _selectedFacilities.contains(label);
                        return GestureDetector(
                          onTap: () => _toggleFacility(label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? Colors.blue : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? Colors.blue.shade700
                                    : Colors.white.withOpacity(0.3),
                                width: selected ? 1.5 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.45),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[
                                  const Icon(Icons.check_circle,
                                      color: Colors.white, size: 15),
                                  const SizedBox(width: 6),
                                ] else ...[
                                  const Icon(Icons.star_border,
                                      color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    color: selected ? Colors.white : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // GALLERY
                  if (images.length > 1) ...[
                    _sectionTitle('Gallery', width),
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
                                        child: const Icon(Icons.broken_image),
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

                  // CONTACT
                  if ((widget.hotel['contactPhone'] ?? '').isNotEmpty ||
                      (widget.hotel['website'] ?? '').isNotEmpty) ...[
                    _sectionTitle('Contact', width),
                    SizedBox(height: height * 0.01),
                    Row(
                      children: [
                        if ((widget.hotel['contactPhone'] ?? '')
                            .isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(
                                    'tel:${widget.hotel['contactPhone']}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if ((widget.hotel['contactPhone'] ?? '')
                            .isNotEmpty &&
                            (widget.hotel['website'] ?? '').isNotEmpty)
                          SizedBox(width: width * 0.03),
                        if ((widget.hotel['website'] ?? '').isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri =
                                Uri.parse(widget.hotel['website']);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.language, size: 18),
                              label: const Text('Website'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // REVIEWS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: ReviewService().getItemRatingStats(widget.hotel['id']),
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
                                itemId: widget.hotel['id'],
                                itemType: 'hotel',
                                itemName: widget.hotel['name'] ?? '',
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
                    stream: ReviewService().getItemReviews(widget.hotel['id']),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1), // GLASS
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.rate_review, color: Colors.white70, size: 32),
                              SizedBox(height: height * 0.01),
                              const Text('No reviews yet', style: TextStyle(color: Colors.white70)),
                            ],
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

                  SizedBox(height: height * 0.03),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? Colors.red.withOpacity(0.2)
                                : Colors.white.withOpacity(0.15), // GLASS
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLiked
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isLiked
                                ? Colors.red
                                : Colors.white, // WHITE when idle
                            size: width * 0.07,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      GestureDetector(
                        onTap: () async {
                          if (_user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please login first')),
                            );
                            return;
                          }
                          final cartService = CartService();
                          final added = await cartService.addToCart(_user!.uid, CartItem(
                            itemId: widget.hotel['id'],
                            itemType: 'hotel',
                            itemName: widget.hotel['name'] ?? '',
                            itemImage: widget.hotel['imageUrl'] ?? '',
                            price: (widget.hotel['priceFrom'] ?? 0).toDouble(),
                            currency: widget.hotel['currency'] ?? 'USD',
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
                              color: Colors.white, size: width * 0.07), // WHITE
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(
                                  itemType: 'hotel',
                                  itemId: widget.hotel['id'],
                                  itemName: widget.hotel['name'] ?? '',
                                  itemImage: widget.hotel['imageUrl'] ?? '',
                                  price: (widget.hotel['priceFrom'] ?? 0)
                                      .toDouble(),
                                  currency:
                                  widget.hotel['currency'] ?? 'USD',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.022),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold, // GOLD button
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
                                  color: Colors.black, // BLACK text on gold
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
        ],
      ),
    );
  }

  Widget _buildMainImage(List<String> images, double height, double width) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.primary.withOpacity(0.1),
        child: Center(
          child: Icon(Icons.hotel_outlined,
              size: width * 0.2, color: AppColors.primary),
        ),
      );
    }

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (i) => setState(() => _currentImageIndex = i),
      itemBuilder: (context, i) => Image.network(
        images[i],
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image,
              size: width * 0.2, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}