import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/hotel_card_widget.dart';
import '../widgets/animated_search_background.dart'; // ⭐ IMPORT MPYA
import 'hotel_details_screen.dart';

class HotelsListScreen extends StatefulWidget {
  const HotelsListScreen({super.key});

  @override
  State<HotelsListScreen> createState() => _HotelsListScreenState();
}

class _HotelsListScreenState extends State<HotelsListScreen> {
  final _service = FirestoreService();
  final _wishlistService = WishlistService();
  final _user = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _isGridView = true;
  bool _showFeaturedOnly = false;
  bool _showCompare = false;
  bool _showLikesOnly = false;
  bool _showTrendingOnly = false;
  bool _isSearchFocused = false; // ⭐ Kwa animation

  RangeValues _priceRange = const RangeValues(0, 5000);
  List<String> _selectedAmenities = [];
  int _minRating = 0;

  final List<String> _compareItems = [];
  final Set<String> _likedHotels = {};

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
          .where('itemType', isEqualTo: 'hotel')
          .get();
      if (mounted) {
        setState(() {
          _likedHotels
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
    var list = all.where((h) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (h['name'] ?? '').toString().toLowerCase().contains(search) ||
          (h['location'] ?? '').toString().toLowerCase().contains(search) ||
          (h['destinationName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(search);

      final matchFeatured = !_showFeaturedOnly || h['featured'] == true;
      final matchLikes =
          !_showLikesOnly || _likedHotels.contains(h['id']);
      final matchTrending = !_showTrendingOnly ||
          ((h['rating'] ?? 0) as num) >= 4.0 ||
          ((h['views'] ?? 0) as num) > 50;

      final price = (h['priceFrom'] ?? 0) as num;
      final matchPrice =
          price >= _priceRange.start && price <= _priceRange.end;

      final rating = (h['rating'] ?? 0) as num;
      final matchRating = rating >= _minRating;

      final facilities = (h['facilities'] as List?) ?? [];
      final matchAmenities = _selectedAmenities.isEmpty ||
          _selectedAmenities.every((a) => facilities.contains(a));

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchPrice &&
          matchRating &&
          matchAmenities;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => ((a['priceFrom'] ?? 0) as num)
            .compareTo((b['priceFrom'] ?? 0) as num));
        break;
      case 'price_high':
        list.sort((a, b) => ((b['priceFrom'] ?? 0) as num)
            .compareTo((a['priceFrom'] ?? 0) as num));
        break;
      case 'rating':
        list.sort((a, b) => ((b['rating'] ?? 0) as num)
            .compareTo((a['rating'] ?? 0) as num));
        break;
    }

    list.sort((a, b) {
      if (a['featured'] == true && b['featured'] != true) return -1;
      if (a['featured'] != true && b['featured'] == true) return 1;
      return 0;
    });

    return list;
  }

  Future<void> _toggleLike(Map<String, dynamic> hotel) async {
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
      itemId: hotel['id'],
      itemType: 'hotel',
      itemName: hotel['name'] ?? '',
      itemImage: hotel['imageUrl'] ?? '',
      price: (hotel['priceFrom'] ?? 0).toDouble(),
      currency: hotel['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedHotels.add(hotel['id']);
      } else {
        _likedHotels.remove(hotel['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${hotel['name']}',
          'description': '${_user!.displayName ?? 'User'} liked this hotel',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': hotel['id'],
          'itemType': 'hotel',
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

  void _toggleCompare(String hotelId) {
    setState(() {
      if (_compareItems.contains(hotelId)) {
        _compareItems.remove(hotelId);
      } else if (_compareItems.length < 2) {
        _compareItems.add(hotelId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Can only compare 2 hotels'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFilterSheet(),
    );
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
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

          // 3. ⭐ CUSTOM SCROLL VIEW (SliverAppBar inayojificha)
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
                  '🏨 Hotels & Lodges',
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
                      _showCompare
                          ? Icons.compare_arrows
                          : Icons.compare_arrows_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _showCompare = !_showCompare),
                  ),
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

              // ═══════ SORT + FILTER ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.008),
                  child: Row(
                    children: [
                      Expanded(
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
                      GestureDetector(
                        onTap: _openFilters,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.tune,
                              color: Colors.black, size: 20),
                        ),
                      ),
                    ],
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
                        _quickChip('❤️ My Likes (${_likedHotels.length})',
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

              // ═══════ CONTENT (STREAM) ═══════
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getHotels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: EdgeInsets.all(width * 0.04),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: width * 0.03,
                          mainAxisSpacing: width * 0.03,
                          mainAxisExtent: height * 0.34,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (_, __) => const ShimmerCard(),
                          childCount: 4,
                        ),
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final hotels = _filterAndSort(all);

                  if (hotels.isEmpty) {
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
                          // Count
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: height * 0.01,
                                  bottom: height * 0.01),
                              child: Text(
                                '${hotels.length} hotel${hotels.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.035,
                                ),
                              ),
                            ),
                          ),
                          // Grid or List
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
                              mainAxisExtent: height * 0.34,
                            ),
                            itemCount: hotels.length,
                            itemBuilder: (context, i) => HotelGridCard(
                              hotel: hotels[i],
                              animationIndex: i, // ⭐ STAGGERED
                              isLiked: _likedHotels
                                  .contains(hotels[i]['id']),
                              showCompare: _showCompare,
                              isSelectedForCompare: _compareItems
                                  .contains(hotels[i]['id']),
                              onCompareTap: () =>
                                  _toggleCompare(hotels[i]['id']),
                              onLike: () => _toggleLike(hotels[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HotelDetailsScreen(
                                      hotel: hotels[i],
                                      hotelData: {},
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: hotels.length,
                            itemBuilder: (context, i) => HotelListCard(
                              hotel: hotels[i],
                              animationIndex: i, // ⭐ STAGGERED
                              isLiked: _likedHotels
                                  .contains(hotels[i]['id']),
                              onLike: () => _toggleLike(hotels[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HotelDetailsScreen(
                                      hotel: hotels[i],
                                      hotelData: {},
                                    ),
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

          // Compare FAB
          if (_compareItems.length == 2)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {},
                backgroundColor: AppColors.accentGold,
                icon: const Icon(Icons.compare, color: Colors.black),
                label: Text(
                  'Compare ${_compareItems.length}',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ANIMATED SEARCH BAR
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
                  hintText: 'Search hotels worldwide...',
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
                    icon: const Icon(Icons.clear, color: Colors.white70),
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

  // ═══════════════════════════════════════════
  // SORT CHIP
  // ═══════════════════════════════════════════
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

  // ═══════════════════════════════════════════
  // QUICK CHIP
  // ═══════════════════════════════════════════
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

  // ═══════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════
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
            Icon(Icons.hotel_outlined,
                size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _searchQuery.isEmpty ? 'No hotels available' : 'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Hotels will appear here once admin adds them'
                  : 'Try different filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: width * 0.035, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // FILTER SHEET
  // ═══════════════════════════════════════════
  Widget _buildFilterSheet() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final amenities = [
      'WiFi',
      'Pool',
      'Spa',
      'Gym',
      'Restaurant',
      'Bar',
      'Parking',
      'AC',
      'Pet Friendly'
    ];

    return StatefulBuilder(
      builder: (_, setSheetState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              padding: EdgeInsets.all(width * 0.05),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Row(
                      children: [
                        const Icon(Icons.tune, color: AppColors.accentGold),
                        const SizedBox(width: 10),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: width * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _priceRange = const RangeValues(0, 5000);
                              _selectedAmenities = [];
                              _minRating = 0;
                            });
                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.accentGold),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    Text('💰 Price Range',
                        style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: height * 0.01),
                    Row(
                      children: [
                        Text('\$${_priceRange.start.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            activeColor: AppColors.accentGold,
                            labels: RangeLabels(
                              '\$${_priceRange.start.toInt()}',
                              '\$${_priceRange.end.toInt()}',
                            ),
                            onChanged: (v) {
                              setSheetState(() => _priceRange = v);
                              setState(() {});
                            },
                          ),
                        ),
                        Text('\$${_priceRange.end.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    Text('⭐ Minimum Rating',
                        style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: height * 0.01),
                    Row(
                      children: [1, 2, 3, 4, 5].map((r) {
                        final isSelected = _minRating == r;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _minRating = r);
                            setState(() {});
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: width * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 0.03, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star,
                                    color: isSelected
                                        ? Colors.black
                                        : AppColors.accentGold,
                                    size: 14),
                                const SizedBox(width: 3),
                                Text('$r',
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.02),
                    Text('✨ Amenities',
                        style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities.map((a) {
                        final isSelected = _selectedAmenities.contains(a);
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                _selectedAmenities.remove(a);
                              } else {
                                _selectedAmenities.add(a);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
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
                            ),
                            child: Text(
                              a,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: height * 0.03),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'APPLY FILTERS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}