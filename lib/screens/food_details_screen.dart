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
import '../widgets/food_card_widget.dart';
import 'booking_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> food;

  const FoodDetailsScreen({super.key, required this.food});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final _wishlistService = WishlistService();
  final _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLiked = false;
  int _currentImageIndex = 0;

  Future<void> _openInGoogleMaps() async {
    final lat = widget.food['latitude'];
    final lng = widget.food['longitude'];

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
        'title': 'Viewed: ${widget.food['name']}',
        'description':
        '${_user?.displayName ?? 'Guest'} viewed this food',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.food['id'],
        'itemType': 'food',
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
      widget.food['id'],
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_user == null) return;
    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: widget.food['id'],
      itemType: 'food',
      itemName: widget.food['name'] ?? '',
      itemImage: widget.food['imageUrl'] ?? '',
      price: (widget.food['price'] ?? 0).toDouble(),
      currency: widget.food['currency'] ?? 'USD',
    );

    if (wasAdded) {
      await _firestore.collection('activities').add({
        'type': 'wishlist',
        'action': 'liked',
        'title': 'Liked: ${widget.food['name']}',
        'description': '${_user!.displayName ?? 'User'} liked this food',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.food['id'],
        'itemType': 'food',
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

  List<String> get _allImages {
    final images = <String>[];
    if ((widget.food['imageUrl'] ?? '').toString().isNotEmpty) {
      images.add(widget.food['imageUrl']);
    }
    final gallery = widget.food['gallery'] as List?;
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
    final ingredients = (widget.food['ingredients'] as List?) ?? [];
    final preparation = (widget.food['preparation'] as List?) ?? [];
    final dietary = (widget.food['dietary'] as List?) ?? [];
    final pairings = (widget.food['bestPairings'] as List?) ?? [];
    final category = widget.food['category'] ?? '';
    final categoryColor = getFoodCategoryColor(category);
    final categoryIcon = getFoodCategoryIcon(category);
    final spiceColor = getSpiceColor(widget.food['spiceLevel'] ?? 'Mild');

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
                    color: categoryColor.withOpacity(0.5),
                    child: Icon(categoryIcon,
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
                  // CATEGORY BADGE
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              category.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((widget.food['spiceLevel'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        SizedBox(width: width * 0.02),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: spiceColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: spiceColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌶️',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                widget.food['spiceLevel'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: spiceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: height * 0.015),

                  // NAME
                  Text(
                    widget.food['name'] ?? '',
                    style: TextStyle(
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // CHANGED
                    ),
                  ),

                  if ((widget.food['subCategory'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    SizedBox(height: height * 0.005),
                    Text(
                      widget.food['subCategory'],
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  SizedBox(height: height * 0.01),

                  // LOCATION / RESTAURANT
                  if ((widget.food['restaurantName'] ?? '')
                      .toString()
                      .isNotEmpty ||
                      (widget.food['location'] ?? '').toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.white70, // CHANGED
                            size: width * 0.05),
                        SizedBox(width: width * 0.02),
                        Expanded(
                          child: Text(
                            widget.food['restaurantName'] ??
                                '${widget.food['location']}, ${widget.food['region'] ?? ''}',
                            style: TextStyle(
                              fontSize: width * 0.038,
                              color: Colors.white70, // CHANGED
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (widget.food['latitude'] != null && widget.food['longitude'] != null) ...[
                    SizedBox(height: height * 0.01),
                    InkWell(
                      onTap: _openInGoogleMaps,
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            'View on Maps',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: height * 0.02),

                  // FEATURED + RATING + PRICE + SERVING TIME
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.food['featured'] == true)
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
                      if ((widget.food['rating'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.accentGold, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                (widget.food['rating'] as num)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((widget.food['price'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: categoryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money,
                                  color: categoryColor, size: 16),
                              Text(
                                '${widget.food['currency'] ?? 'USD'} ${(widget.food['price'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((widget.food['servingTime'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border:
                            Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.blue.shade700, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.food['servingTime'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  // DESCRIPTION
                  if ((widget.food['description'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    _sectionTitle('📖 About', width),
                    SizedBox(height: height * 0.01),
                    Text(
                      widget.food['description'],
                      style: TextStyle(
                        fontSize: width * 0.037,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // DIETARY
                  if (dietary.isNotEmpty) ...[
                    _sectionTitle('🥗 Dietary', width),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dietary.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco,
                                  color: Colors.green.shade700, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                d.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // INGREDIENTS
                  if (ingredients.isNotEmpty) ...[
                    _sectionTitle('🥘 Ingredients', width),
                    SizedBox(height: height * 0.01),
                    Container(
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: ingredients.map((ing) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: width * 0.01),
                            child: Row(
                              children: [
                                Container(
                                  width: width * 0.02,
                                  height: width * 0.02,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: width * 0.03),
                                Expanded(
                                  child: Text(
                                    ing.toString(),
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // PREPARATION
                  if (preparation.isNotEmpty) ...[
                    _sectionTitle('👨‍🍳 Preparation Steps', width),
                    SizedBox(height: height * 0.01),
                    ...preparation.asMap().entries.map((e) {
                      return Container(
                        margin: EdgeInsets.only(bottom: height * 0.01),
                        padding: EdgeInsets.all(width * 0.035),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: categoryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: width * 0.08,
                              height: width * 0.08,
                              decoration: BoxDecoration(
                                gradient: AppColors.mainGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: height * 0.025),
                  ],

                  // BEST PAIRINGS
                  if (pairings.isNotEmpty) ...[
                    _sectionTitle('🍷 Best Pairings', width),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pairings.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_dining,
                                  color: Colors.purple.shade700,
                                  size: 14),
                              const SizedBox(width: 5),
                              Text(
                                p.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

                  // CONTACT
                  if ((widget.food['contactInfo'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    _sectionTitle('📞 Contact', width),
                    SizedBox(height: height * 0.01),
                    Container(
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        widget.food['contactInfo'],
                        style: TextStyle(
                          fontSize: width * 0.035,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

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
                                itemId: widget.food['id'],
                                itemType: 'food',
                                itemName: widget.food['name'] ?? '',
                                itemImage: widget.food['imageUrl'] ?? '',
                                price:
                                    (widget.food['price'] ?? 0).toDouble(),
                                currency: widget.food['currency'] ?? 'USD',
                              ));
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 2),
                          ),
                          child: Icon(Icons.shopping_cart_outlined,
                              color: AppColors.primary, size: width * 0.07),
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
                                  itemType: 'food',
                                  itemId: widget.food['id'],
                                  itemName: widget.food['name'] ?? '',
                                  itemImage:
                                  widget.food['imageUrl'] ?? '',
                                  price: (widget.food['price'] ?? 0)
                                      .toDouble(),
                                  currency:
                                  widget.food['currency'] ?? 'USD',
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

                  SizedBox(height: height * 0.03),

                  // REVIEWS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: ReviewService().getItemRatingStats(widget.food['id']),
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
                                itemId: widget.food['id'],
                                itemType: 'food',
                                itemName: widget.food['name'] ?? '',
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
                    stream: ReviewService().getItemReviews(widget.food['id']),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.rate_review, color: Colors.grey.shade400, size: 32),
                                SizedBox(height: height * 0.01),
                                Text('No reviews yet',
                                    style: TextStyle(color: Colors.grey.shade500)),
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

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),

        ]));
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.05,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
    );
  }
}