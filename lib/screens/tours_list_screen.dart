import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/tour_card_widget.dart';
import '../widgets/animated_search_background.dart';
import 'tour_details_screen.dart';

class ToursListScreen extends StatefulWidget {
  const ToursListScreen({super.key});

  @override
  State<ToursListScreen> createState() => _ToursListScreenState();
}

class _ToursListScreenState extends State<ToursListScreen> {
  final _service = FirestoreService();
  final _wishlistService = WishlistService();
  final _user = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _isGridView = true;
  bool _showFeaturedOnly = false;
  bool _showLikesOnly = false;
  bool _showTrendingOnly = false;
  bool _isSearchFocused = false;
  String _tourTypeFilter = 'All';

  RangeValues _priceRange = const RangeValues(0, 5000);
  final Set<String> _likedTours = {};

  final List<String> _tourTypes = [
    'All',
    'Safari',
    'Hiking',
    'Beach',
    'Cultural',
    'Adventure',
    'Photography',
    'Birding',
    'Helicopter',
  ];

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    if (_user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: _user!.uid)
          .where('itemType', isEqualTo: 'tour')
          .get();
      if (mounted) {
        setState(() {
          _likedTours
              .addAll(snapshot.docs.map((d) => d.data()['itemId'] as String));
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  // FILTER & SORT
  // ═══════════════════════════════════════════
  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> all) {
    var list = all.where((t) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (t['name'] ?? '').toString().toLowerCase().contains(search) ||
          (t['destinationName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(search);

      final matchFeatured = !_showFeaturedOnly || t['featured'] == true;
      final matchLikes = !_showLikesOnly || _likedTours.contains(t['id']);
      final matchTrending =
          !_showTrendingOnly || ((t['rating'] ?? 0) as num) >= 4.0;
      final matchType =
          _tourTypeFilter == 'All' || t['tourType'] == _tourTypeFilter;

      final price = (t['price'] ?? 0) as num;
      final matchPrice =
          price >= _priceRange.start && price <= _priceRange.end;

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchType &&
          matchPrice;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) =>
            ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num));
        break;
      case 'price_high':
        list.sort((a, b) =>
            ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num));
        break;
      case 'rating':
        list.sort((a, b) =>
            ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
    }

    list.sort((a, b) {
      if (a['featured'] == true && b['featured'] != true) return -1;
      if (a['featured'] != true && b['featured'] == true) return 1;
      return 0;
    });

    return list;
  }

  Future<void> _toggleLike(Map<String, dynamic> tour) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: tour['id'],
      itemType: 'tour',
      itemName: tour['name'] ?? '',
      itemImage: (tour['images'] as List?)?.isNotEmpty == true
          ? tour['images'][0]
          : '',
      price: (tour['price'] ?? 0).toDouble(),
      currency: tour['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedTours.add(tour['id']);
      } else {
        _likedTours.remove(tour['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${tour['name']}',
          'description': '${_user!.displayName ?? 'User'} liked this tour',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': tour['id'],
          'itemType': 'tour',
          'icon': '❤️',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasAdded ? '❤️ Liked!' : '💔 Removed'),
          backgroundColor: wasAdded ? Colors.red : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
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
          // 2. Dark Overlay
          Container(color: Colors.black.withOpacity(0.55)),

          // 3. CUSTOM SCROLL VIEW yenye SliverAppBar
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══════ SLIVER APP BAR (INAYOJIFICHA) ═══════
              SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  '🦁 Tours & Safaris',
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),

              // ═══════ SEARCH BAR (SLIVER) ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: height * 0.005, bottom: height * 0.005),
                  child: AnimatedSearchBackground(
                    isActive: _isSearchFocused || _searchQuery.isNotEmpty,
                    child: _buildSearchBar(width, height),
                  ),
                ),
              ),

              // ═══════ SORT ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.008),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _sortChip('recent', '🕐 Recent'),
                        _sortChip('price_low', '💰 Price ↑'),
                        _sortChip('price_high', '💎 Price ↓'),
                        _sortChip('rating', '⭐ Top'),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══════ QUICK CHIPS ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.005),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _quickChip('⭐ Featured', _showFeaturedOnly, () {
                          setState(() {
                            _showFeaturedOnly = !_showFeaturedOnly;
                            if (_showFeaturedOnly) {
                              _showLikesOnly = false;
                              _showTrendingOnly = false;
                            }
                          });
                        }),
                        _quickChip(
                            '❤️ My Likes (${_likedTours.length})',
                            _showLikesOnly, () {
                          if (_user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Please login to see your likes'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _showLikesOnly = !_showLikesOnly;
                            if (_showLikesOnly) {
                              _showFeaturedOnly = false;
                              _showTrendingOnly = false;
                            }
                          });
                        }),
                        _quickChip('🔥 Trending', _showTrendingOnly, () {
                          setState(() {
                            _showTrendingOnly = !_showTrendingOnly;
                            if (_showTrendingOnly) {
                              _showFeaturedOnly = false;
                              _showLikesOnly = false;
                            }
                          });
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══════ TOUR TYPE FILTER ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.005),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tourTypes.map((type) {
                        final isSelected = _tourTypeFilter == type;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _tourTypeFilter = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.only(right: width * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 0.035,
                                vertical: height * 0.006),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentGold
                                    : Colors.white.withOpacity(0.3),
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: AppColors.accentGold
                                      .withOpacity(0.5),
                                  blurRadius: 12,
                                ),
                              ]
                                  : [],
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white,
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
              ),

              // ═══════ CONTENT (STREAM) ═══════
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getTours(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: EdgeInsets.all(width * 0.04),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: width * 0.03,
                          mainAxisSpacing: width * 0.03,
                          mainAxisExtent: height * 0.32,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (_, __) => const TourShimmerCard(),
                          childCount: 4,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final tours = _filterAndSort(all);

                  if (tours.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(width, height),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: height * 0.01,
                                  bottom: height * 0.01),
                              child: Text(
                                '${tours.length} tour${tours.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.035,
                                ),
                              ),
                            ),
                          ),
                          _isGridView
                              ? GridView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: width * 0.03,
                              mainAxisSpacing: width * 0.03,
                              mainAxisExtent: height * 0.32,
                            ),
                            itemCount: tours.length,
                            itemBuilder: (context, i) => TourGridCard(
                              tour: tours[i],
                              animationIndex: i, // ⭐ STAGGERED
                              isLiked: _likedTours
                                  .contains(tours[i]['id']),
                              onLike: () => _toggleLike(tours[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TourDetailsScreen(
                                        tour: tours[i]),
                                  ),
                                );
                              },
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: tours.length,
                            itemBuilder: (context, i) => TourListCard(
                              tour: tours[i],
                              animationIndex: i, // ⭐ STAGGERED
                              isLiked: _likedTours
                                  .contains(tours[i]['id']),
                              onLike: () => _toggleLike(tours[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TourDetailsScreen(
                                        tour: tours[i]),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: height * 0.05),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SEARCH BAR (ANIMATED)
  // ═══════════════════════════════════════════
  Widget _buildSearchBar(double width, double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isSearchFocused ? 28 : 16),
        boxShadow: _isSearchFocused
            ? [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isSearchFocused ? 28 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSearchFocused
                    ? [
                  AppColors.accentGold.withOpacity(0.15),
                  Colors.white.withOpacity(0.1),
                ]
                    : [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_isSearchFocused ? 28 : 16),
              border: Border.all(
                color: _isSearchFocused
                    ? AppColors.accentGold.withOpacity(0.9)
                    : Colors.white.withOpacity(0.3),
                width: _isSearchFocused ? 1.8 : 1,
              ),
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() => _isSearchFocused = hasFocus);
              },
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search tours & safaris...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: width * 0.035,
                  ),
                  prefixIcon: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isSearchFocused ? 0.05 : 0,
                    child: Icon(
                      Icons.search,
                      color: _isSearchFocused
                          ? AppColors.accentGold
                          : Colors.white70,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: height * 0.018),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final isSelected = _sortBy == value;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.035, vertical: height * 0.008),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.5),
              blurRadius: 12,
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.026,
          ),
        ),
      ),
    );
  }

  Widget _quickChip(String label, bool active, VoidCallback onTap) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold.withOpacity(0.2)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.4),
              blurRadius: 15,
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentGold : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.028,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tour_outlined,
                size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _searchQuery.isEmpty ? 'No tours available' : 'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Tours will appear here once admin adds them'
                  : 'Try different filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: width * 0.035, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}