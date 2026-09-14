import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import 'booking_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.hotel,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.hotel['name'] ?? '',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
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

                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: AppColors.primary, size: width * 0.05),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          widget.hotel['location'] ?? '',
                          style: TextStyle(
                            fontSize: width * 0.038,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),

                  if ((widget.hotel['priceFrom'] ?? 0) > 0)
                    Container(
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        borderRadius: BorderRadius.circular(14),
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
                                  color: Colors.white,
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
                          Icon(Icons.hotel, color: Colors.white, size: width * 0.12),
                        ],
                      ),
                    ),

                  SizedBox(height: height * 0.025),

                  if ((widget.hotel['description'] ?? '').isNotEmpty) ...[
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      widget.hotel['description'],
                      style: TextStyle(
                        fontSize: width * 0.037,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  if ((widget.hotel['facilities'] as List?)?.isNotEmpty ?? false) ...[
                    Text(
                      'Facilities',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.hotel['facilities'] as List).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text('✨ $f',
                              style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  if ((widget.hotel['contactPhone'] ?? '').isNotEmpty ||
                      (widget.hotel['website'] ?? '').isNotEmpty) ...[
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                                foregroundColor: Colors.green,
                                side:
                                const BorderSide(color: Colors.green),
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
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  SizedBox(height: height * 0.03),

                  // Map Background Placeholder
                  Container(
                    height: height * 0.15,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.map,
                        size: width * 0.15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),

                  // Action buttons
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? Colors.red.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLiked
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isLiked
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: width * 0.07,
                          ),
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
                              gradient: AppColors.mainGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'BOOK NOW',
                                style: TextStyle(
                                  color: Colors.white,
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
}