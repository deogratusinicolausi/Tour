import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/mountain_card_widget.dart';
import 'mountain_details_screen.dart';

class MountainsListScreen extends StatefulWidget {
  const MountainsListScreen({super.key});

  @override
  State<MountainsListScreen> createState() => _MountainsListScreenState();
}

class _MountainsListScreenState extends State<MountainsListScreen> {
  final _service = FirestoreService();
  final _wishlistService = WishlistService();
  final _user = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _isGridView = true;
  bool _showFeaturedOnly = false;
  bool _showLikesOnly = false;
  bool _showTrendingOnly = false;
  String _filterDifficulty = 'All';

  final Set<String> _likedMountains = {};

  final List<String> _difficulties = [
    'All',
    'Easy',
    'Moderate',
    'Hard',
    'Extreme',
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
          .where('itemType', isEqualTo: 'mountain')
          .get();
      setState(() {
        _likedMountains.addAll(
            snapshot.docs.map((d) => d.data()['itemId'] as String));
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> all) {
    var list = all.where((m) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (m['name'] ?? '').toString().toLowerCase().contains(search) ||
          (m['location'] ?? '').toString().toLowerCase().contains(search) ||
          (m['country'] ?? '').toString().toLowerCase().contains(search);

      final matchFeatured = !_showFeaturedOnly || m['featured'] == true;
      final matchLikes =
          !_showLikesOnly || _likedMountains.contains(m['id']);
      final matchTrending = !_showTrendingOnly ||
          ((m['rating'] ?? 0) as num) >= 4.0;

      final matchDifficulty = _filterDifficulty == 'All' ||
          m['difficulty'] == _filterDifficulty;

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchDifficulty;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) =>
            ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
      case 'height_low':
        list.sort((a, b) =>
            ((a['height'] ?? 0) as num).compareTo((b['height'] ?? 0) as num));
        break;
      case 'height_high':
        list.sort((a, b) =>
            ((b['height'] ?? 0) as num).compareTo((a['height'] ?? 0) as num));
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

  Future<void> _toggleLike(Map<String, dynamic> mountain) async {
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
      itemId: mountain['id'],
      itemType: 'mountain',
      itemName: mountain['name'] ?? '',
      itemImage: mountain['imageUrl'] ?? '',
      price: 0,
      currency: 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedMountains.add(mountain['id']);
      } else {
        _likedMountains.remove(mountain['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${mountain['name']}',
          'description':
          '${_user!.displayName ?? 'User'} liked this mountain',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': mountain['id'],
          'itemType': 'mountain',
          'icon': '❤️',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasAdded ? '❤️ Liked!' : '💔 Removed'),
        backgroundColor: wasAdded ? Colors.red : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⛰️ Mountains'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH + SORT
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search mountains...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: height * 0.015),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sortChip('recent', '🕐 Recent'),
                      _sortChip('rating', '⭐ Top Rated'),
                      _sortChip('height_high', '⛰️ Tallest'),
                      _sortChip('height_low', '🏔️ Shortest'),
                      _sortChip('name', '🔤 A-Z'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // QUICK CHIPS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip(
                    '⭐ Featured',
                    _showFeaturedOnly,
                        () => setState(() {
                      _showFeaturedOnly = !_showFeaturedOnly;
                      if (_showFeaturedOnly) {
                        _showLikesOnly = false;
                        _showTrendingOnly = false;
                      }
                    }),
                  ),
                  _quickChip(
                    '❤️ My Likes (${_likedMountains.length})',
                    _showLikesOnly,
                        () {
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
                    },
                  ),
                  _quickChip(
                    '🔥 Trending',
                    _showTrendingOnly,
                        () => setState(() {
                      _showTrendingOnly = !_showTrendingOnly;
                      if (_showTrendingOnly) {
                        _showFeaturedOnly = false;
                        _showLikesOnly = false;
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),

          // DIFFICULTY FILTER
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _difficulties.map((diff) {
                  final isSelected = _filterDifficulty == diff;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filterDifficulty = diff),
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
                        diff,
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

          // CONTENT
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getMountains(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final mountains = _filterAndSort(all);

                if (mountains.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.01),
                      child: Row(
                        children: [
                          Text(
                            '${mountains.length} mountain${mountains.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isGridView
                          ? GridView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: width * 0.03,
                          mainAxisSpacing: width * 0.03,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: mountains.length,
                        itemBuilder: (context, i) =>
                            MountainGridCard(
                              mountain: mountains[i],
                              isLiked: _likedMountains
                                  .contains(mountains[i]['id']),
                              onLike: () => _toggleLike(mountains[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MountainDetailsScreen(
                                            mountain: mountains[i]),
                                  ),
                                );
                              },
                            ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: mountains.length,
                        itemBuilder: (context, i) =>
                            MountainListCard(
                              mountain: mountains[i],
                              isLiked: _likedMountains
                                  .contains(mountains[i]['id']),
                              onLike: () => _toggleLike(mountains[i]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MountainDetailsScreen(
                                            mountain: mountains[i]),
                                  ),
                                );
                              },
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final isSelected = _sortBy == value;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.035, vertical: height * 0.008),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
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
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold.withOpacity(0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accentGold : Colors.grey.shade300,
            width: active ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentGold : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.028,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.terrain,
                size: width * 0.15, color: Colors.brown.shade700),
          ),
          SizedBox(height: height * 0.03),
          Text(
            _searchQuery.isEmpty
                ? 'No mountains available'
                : 'No results found',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            _searchQuery.isEmpty
                ? 'Mountains will appear here once admin adds them'
                : 'Try different filters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.035,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}