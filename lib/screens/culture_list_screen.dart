import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/culture_card_widget.dart';
import 'culture_details_screen.dart';

class CultureListScreen extends StatefulWidget {
  const CultureListScreen({super.key});

  @override
  State<CultureListScreen> createState() => _CultureListScreenState();
}

class _CultureListScreenState extends State<CultureListScreen> {
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
  String _filterCategory = 'All';

  final Set<String> _likedCulture = {};

  final List<Map<String, String>> _categories = [
    {'value': 'All', 'label': '🌍 All'},
    {'value': 'Tribe', 'label': '👥 Tribes'},
    {'value': 'Festival', 'label': '🎉 Festivals'},
    {'value': 'Art', 'label': '🎨 Arts'},
    {'value': 'Music', 'label': '🎵 Music'},
    {'value': 'Dance', 'label': '💃 Dance'},
    {'value': 'Historical', 'label': '🏛️ History'},
    {'value': 'Village', 'label': '🏠 Villages'},
    {'value': 'Craft', 'label': '🧵 Crafts'},
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
          .where('itemType', isEqualTo: 'culture')
          .get();
      setState(() {
        _likedCulture.addAll(
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
    var list = all.where((c) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (c['name'] ?? '').toString().toLowerCase().contains(search) ||
          (c['location'] ?? '').toString().toLowerCase().contains(search) ||
          (c['subCategory'] ?? '').toString().toLowerCase().contains(search);

      final matchFeatured = !_showFeaturedOnly || c['featured'] == true;
      final matchLikes =
          !_showLikesOnly || _likedCulture.contains(c['id']);
      final matchTrending = !_showTrendingOnly ||
          ((c['rating'] ?? 0) as num) >= 4.0;

      final matchCategory = _filterCategory == 'All' ||
          c['category'] == _filterCategory;

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchCategory;
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

  Future<void> _toggleLike(Map<String, dynamic> culture) async {
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
      itemId: culture['id'],
      itemType: 'culture',
      itemName: culture['name'] ?? '',
      itemImage: culture['imageUrl'] ?? '',
      price: (culture['entryFee'] ?? 0).toDouble(),
      currency: culture['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedCulture.add(culture['id']);
      } else {
        _likedCulture.remove(culture['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${culture['name']}',
          'description':
          '${_user!.displayName ?? 'User'} liked this culture',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': culture['id'],
          'itemType': 'culture',
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
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM TOP HEADER ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '🎭 Culture',
                        style: TextStyle(
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                ),

                // --- REST OF YOUR CONTENT ---
                Expanded(
                  child: Column(
                    children: [
                      // SEARCH + SORT (Modified below)
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        child: Column(
                          children: [
                            // GLASS SEARCH BAR
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      hintText: 'Search culture...',
                                      hintStyle:
                                      TextStyle(color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: const Icon(Icons.search,
                                          color: Colors.white70),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: height * 0.015),
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
                            SizedBox(height: height * 0.015),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _sortChip('recent', '🕐 Recent'),
                                  _sortChip('rating', '⭐ Top Rated'),
                                  _sortChip('name', '🔤 A-Z'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // QUICK CHIPS (Modified below)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04, vertical: height * 0.01),
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
                              _quickChip('❤️ My Likes (${_likedCulture.length})', _showLikesOnly, () {
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

                      // CATEGORY FILTER (Modified below)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04, vertical: height * 0.01),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = _filterCategory == cat['value'];
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _filterCategory = cat['value']!),
                                child: Container(
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
                                  ),
                                  child: Text(
                                    cat['label']!,
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

                      // CONTENT (StreamBuilder)
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _service.getCulture(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.white)));
                            }

                            final all = snapshot.data ?? [];
                            final culture = _filterAndSort(all);

                            if (culture.isEmpty) return _buildEmptyState(width, height);

                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.04,
                                      vertical: height * 0.01),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${culture.length} item${culture.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: Colors.white70, // WHITE70
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
                                    itemCount: culture.length,
                                    itemBuilder: (context, i) => CultureGridCard(
                                      culture: culture[i],
                                      isLiked: _likedCulture.contains(culture[i]['id']),
                                      onLike: () => _toggleLike(culture[i]),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CultureDetailsScreen(culture: culture[i]),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                      : ListView.builder(
                                    padding: EdgeInsets.all(width * 0.04),
                                    itemCount: culture.length,
                                    itemBuilder: (context, i) => CultureListCard(
                                      culture: culture[i],
                                      isLiked: _likedCulture.contains(culture[i]['id']),
                                      onLike: () => _toggleLike(culture[i]),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CultureDetailsScreen(culture: culture[i]),
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
                ),
              ],
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
          color: isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.3),
          ),
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
        padding:
            EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold.withOpacity(0.2)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accentGold : Colors.white.withOpacity(0.3),
            width: active ? 2 : 1,
          ),
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
            Icon(Icons.museum, size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _searchQuery.isEmpty ? 'No culture available' : 'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Culture will appear here once admin adds them'
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