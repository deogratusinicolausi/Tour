import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/wishlist_service.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'booking_screen.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailsScreen({super.key, required this.destination});

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  final _wishlistService = WishlistService();
  final _firestoreService = FirestoreService();
  final _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLiked = false;
  int _currentImageIndex = 0;
  bool _isLoading = true;
  int _viewCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLiked();
    _logView();
    _incrementViewCount();
  }

  // ⭐️ Log view activity for admin
  Future<void> _logView() async {
    try {
      await _firestore.collection('activities').add({
        'type': 'view',
        'action': 'viewed',
        'title': 'Viewed: ${widget.destination['name']}',
        'description': '${_user?.displayName ?? 'Guest'} viewed this destination',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.destination['id'],
        'itemType': 'destination',
        'icon': '👁️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error logging view: $e');
    }
  }

  // ⭐️ Increment view count on destination
  Future<void> _incrementViewCount() async {
    try {
      final doc = await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .get();
      final data = doc.data() ?? {};
      final currentViews = data['views'] ?? 0;
      setState(() => _viewCount = currentViews + 1);

      await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .update({
        'views': currentViews + 1,
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error incrementing views: $e');
    }
  }

  Future<void> _checkLiked() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final liked = await _wishlistService.isLiked(
      _user!.uid,
      widget.destination['id'],
    );
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: widget.destination['id'],
      itemType: 'destination',
      itemName: widget.destination['name'] ?? '',
      itemImage: widget.destination['imageUrl'] ?? '',
      price: 0,
      currency: 'USD',
    );

    // ⭐️ Log like activity for admin
    if (wasAdded) {
      await _firestore.collection('activities').add({
        'type': 'wishlist',
        'action': 'liked',
        'title': 'Liked: ${widget.destination['name']}',
        'description': '${_user!.displayName ?? 'User'} liked this destination',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.destination['id'],
        'itemType': 'destination',
        'icon': '❤️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() => _isLiked = wasAdded);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasAdded
              ? '❤️ Added to wishlist'
              : '💔 Removed from wishlist'),
          backgroundColor: wasAdded ? Colors.red : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ⭐️ Share activity
  Future<void> _shareDestination() async {
    try {
      final url = Uri.parse(
          'https://turiva.app/destination/${widget.destination['id']}');
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // Log share
      await _firestore.collection('activities').add({
        'type': 'share',
        'action': 'shared',
        'title': 'Shared: ${widget.destination['name']}',
        'description': '${_user?.displayName ?? 'Guest'} shared this',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.destination['id'],
        'itemType': 'destination',
        'icon': '📤',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error sharing: $e');
    }
  }

  // ⭐️ Open Map activity
  Future<void> _openMap() async {
    final lat = widget.destination['latitude'] ?? 0;
    final lng = widget.destination['longitude'] ?? 0;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // Log map open
      await _firestore.collection('activities').add({
        'type': 'map',
        'action': 'opened',
        'title': 'Opened map: ${widget.destination['name']}',
        'description': '${_user?.displayName ?? 'Guest'} opened map',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': widget.destination['id'],
        'itemType': 'destination',
        'icon': '📍',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  List<String> get _allImages {
    final images = <String>[];
    if ((widget.destination['imageUrl'] ?? '').toString().isNotEmpty) {
      images.add(widget.destination['imageUrl']);
    }
    final gallery = widget.destination['gallery'] as List?;
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
          // ===== IMAGE HEADER =====
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
              // Like
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
              // Share
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share,
                      color: Colors.white, size: 20),
                ),
                onPressed: _shareDestination,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isEmpty
                      ? Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image,
                        size: 80, color: Colors.white),
                  )
                      : PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, i) {
                      return Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image,
                              size: 80, color: Colors.white),
                        ),
                      );
                    },
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
                  // Image counter
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
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  // View count
                  Positioned(
                    top: 80,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_viewCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== CONTENT =====
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + RATING
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.destination['name'] ?? 'Unnamed',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      if (widget.destination['rating'] != null &&
                          (widget.destination['rating'] as num) > 0)
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
                                (widget.destination['rating'] as num)
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

                  // LOCATION
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: AppColors.primary, size: width * 0.05),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          '${widget.destination['location'] ?? ''}, ${widget.destination['country'] ?? ''}',
                          style: TextStyle(
                            fontSize: width * 0.038,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),

                  // FEATURED BADGE
                  if (widget.destination['featured'] == true)
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
                          Icon(Icons.star, size: 16, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            'FEATURED DESTINATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: height * 0.025),

                  // DESCRIPTION
                  _sectionTitle('📖 About', width),
                  SizedBox(height: height * 0.01),
                  Text(
                    widget.destination['description'] ??
                        'No description available.',
                    style: TextStyle(
                      fontSize: width * 0.037,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // INFO CARDS
                  Row(
                    children: [
                      _infoCard(Icons.calendar_today, 'Best Time', 'All Year',
                          Colors.blue, width),
                      SizedBox(width: width * 0.03),
                      _infoCard(Icons.people, 'Type', 'Adventure',
                          Colors.orange, width),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  // HIGHLIGHTS
                  _sectionTitle('✨ Highlights', width),
                  SizedBox(height: height * 0.01),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '🦁 Wildlife',
                      '📸 Photography',
                      '🚶 Walking',
                      '🏕️ Camping',
                      '🧗 Adventure',
                      '🍽️ Local Cuisine',
                    ].map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: height * 0.025),

                  // GALLERY
                  if (images.length > 1) ...[
                    _sectionTitle('📸 Gallery', width),
                    SizedBox(height: height * 0.01),
                    SizedBox(
                      height: height * 0.12,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _currentImageIndex = i),
                            child: Container(
                              margin:
                              EdgeInsets.only(right: width * 0.03),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      images[i],
                                      width: height * 0.12,
                                      height: height * 0.12,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.broken_image),
                                          ),
                                    ),
                                    if (i == _currentImageIndex)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.primary,
                                              width: 3,
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(12),
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
                    SizedBox(height: height * 0.025),
                  ],

                  // MAP
                  _sectionTitle('📍 Location', width),
                  SizedBox(height: height * 0.01),
                  GestureDetector(
                    onTap: _openMap,
                    child: Container(
                      height: height * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800'),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Open in Maps',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // REVIEWS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('⭐ Reviews (4.8)', width),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  _reviewCard(
                    'Sarah M.',
                    'Amazing experience! The wildlife was breathtaking. Highly recommend!',
                    5.0,
                    '2 days ago',
                    width,
                  ),
                  _reviewCard(
                    'John K.',
                    'Well organized tour. Our guide was very knowledgeable.',
                    4.5,
                    '1 week ago',
                    width,
                  ),

                  SizedBox(height: height * 0.025),

                  // SIMILAR DESTINATIONS
                  _sectionTitle('🎯 Similar Destinations', width),
                  SizedBox(height: height * 0.01),
                  SizedBox(
                    height: height * 0.2,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getDestinations(),
                      builder: (context, snapshot) {
                        final all = snapshot.data ?? [];
                        final similar = all
                            .where((d) =>
                        d['id'] != widget.destination['id'])
                            .take(5)
                            .toList();

                        if (similar.isEmpty) {
                          return Center(
                            child: Text(
                              'No similar destinations',
                              style:
                              TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similar.length,
                          itemBuilder: (context, i) {
                            final dest = similar[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DestinationDetailsScreen(
                                        destination: dest),
                                  ),
                                );
                              },
                              child: Container(
                                width: width * 0.4,
                                margin: EdgeInsets.only(
                                    right: width * 0.03),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        dest['imageUrl'] ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        width * 0.03),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dest['name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          dest['country'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
                                  itemType: 'destination',
                                  itemId: widget.destination['id'],
                                  itemName:
                                  widget.destination['name'] ?? '',
                                  itemImage: widget.destination['imageUrl'] ??
                                      '',
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
                              gradient: AppColors.mainGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  AppColors.primary.withOpacity(0.4),
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

  Widget _infoCard(IconData icon, String label, String value, Color color,
      double width) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: width * 0.05),
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: width * 0.032,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(
      String name, String comment, double rating, String time, double width) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: width * 0.045,
                backgroundColor: AppColors.primary,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.accentGold,
                            size: 14,
                          );
                        }),
                        SizedBox(width: width * 0.02),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}