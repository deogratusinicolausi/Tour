import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/beach_card_widget.dart';
import '../widgets/animated_search_background.dart';
import 'beach_details_screen.dart';

class BeachesListScreen extends StatefulWidget {
  const BeachesListScreen({super.key});

  @override
  State<BeachesListScreen> createState() => _BeachesListScreenState();
}

class _BeachesListScreenState extends State<BeachesListScreen> {
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
  String _filterWaterType = 'All';

  RangeValues _priceRange = const RangeValues(0, 5000);
  final Set<String> _likedBeaches = {};

  final List<String> _waterTypes = [
    'All',
    'Ocean',
    'Sea',
    'Lake',
    'River',
    'Lagoon',
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
          .where('itemType', isEqualTo: 'beach')
          .get();
      if (mounted) {
        setState(() {
          _likedBeaches.addAll(
              snapshot.docs.map((d) => d.data()['itemId'] as String));
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

  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> all) {
    var list = all.where((b) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (b['name'] ?? '').toString().toLowerCase().contains(search) ||
          (b['location'] ?? '').toString().toLowerCase().contains(search) ||
          (b['country'] ?? '').toString().toLowerCase().contains(search);

      final matchFeatured = !_showFeaturedOnly || b['featured'] == true;
      final matchLikes = !_showLikesOnly || _likedBeaches.contains(b['id']);
      final matchTrending = !_showTrendingOnly ||
          ((b['rating'] ?? 0) as num) >= 4.0 ||
          ((b['views'] ?? 0) as num) > 50;

      final matchWaterType = _filterWaterType == 'All' ||
          b['waterType'] == _filterWaterType;

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchWaterType;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) =>
            ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
      case 'name':
        list.sort((a, b) => ((a['name'] ?? '') as String)
            .compareTo((b['name'] ?? '') as String));
        break;
    }

    list.sort((a, b) {
      if (a['featured'] == true && b['featured'] != true) return -1;
      if (a['featured'] != true && b['featured'] == true) return 1;
      return 0;
    });

    return list;
  }

  Future<void> _toggleLike(Map<String, dynamic> beach) async {
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
      itemId: beach['id'],
      itemType: 'beach',
      itemName: beach['name'] ?? '',
      itemImage: beach['imageUrl'] ?? '',
      price: 0,
      currency: 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedBeaches.add(beach['id']);
      } else {
        _likedBeaches.remove(beach['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${beach['name']}',
          'description': '${_user!.displayName ?? 'User'} liked this beach',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': beach['id'],
          'itemType': 'beach',
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

          // 3. CUSTOM SCROLL VIEW
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══════ SLIVER APP BAR ═══════
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
                  '🏖️ Beaches',
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

              // ═══════ SEARCH BAR ═══════
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
                        _sortChip('rating', '⭐ Top Rated'),
                        _sortChip('name', '🔤 A-Z'),
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
                            '❤️ My Likes (${_likedBeaches.length})',
                            _showLikesOnly, () {
                          if (_user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login'),
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

              // ═══════ WATER TYPE FILTER ═══════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.005),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _waterTypes.map((type) {
                        final isSelected = _filterWaterType == type;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filterWaterType = type),
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

              // ═══════ CONTENT ═══════
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getBeaches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: EdgeInsets.all(width * 0.04),
                      sliver: SliverGrid(
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: width * 0.03,
                          mainAxisSpacing: width * 0.03,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (_, __) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
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
                  final beaches = _filterAndSort(all);

                  if (beaches.isEmpty) {
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
                                '${beaches.length} beach${beaches.length > 1 ? 'es' : ''}',
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
                              childAspectRatio: 0.75,
                            ),
                            itemCount: beaches.length,
                            itemBuilder: (context, i) => BeachGridCard(
                              beach: beaches[i],
                              animationIndex: i,
                              isLiked: _likedBeaches
                                  .contains(beaches[i]['id']),
                              onLike: () => _toggleLike(beaches[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BeachDetailsScreen(
                                        beach: beaches[i]),
                                  ),
                                );
                              },
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: beaches.length,
                            itemBuilder: (context, i) => BeachListCard(
                              beach: beaches[i],
                              animationIndex: i,
                              isLiked: _likedBeaches
                                  .contains(beaches[i]['id']),
                              onLike: () => _toggleLike(beaches[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BeachDetailsScreen(
                                        beach: beaches[i]),
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
                  hintText: 'Search beaches...',
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
            Icon(Icons.beach_access,
                size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _searchQuery.isEmpty
                  ? 'No beaches available'
                  : 'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Beaches will appear here once admin adds them'
                  : 'Try different filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: width * 0.035, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}