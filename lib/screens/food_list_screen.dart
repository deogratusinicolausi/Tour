import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/food_card_widget.dart';
import 'food_details_screen.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
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
  String _filterSpice = 'All';

  final Set<String> _likedFood = {};

  final List<Map<String, String>> _categories = [
    {'value': 'All', 'label': '🍽️ All'},
    {'value': 'Dish', 'label': '🍛 Dishes'},
    {'value': 'Cuisine', 'label': '🥘 Cuisine'},
    {'value': 'Restaurant', 'label': '🏨 Restaurants'},
    {'value': 'Drink', 'label': '🍹 Drinks'},
    {'value': 'Dessert', 'label': '🎂 Desserts'},
    {'value': 'Street Food', 'label': '🍢 Street'},
  ];

  final List<Map<String, String>> _spiceLevels = [
    {'value': 'All', 'label': '🌶️ All'},
    {'value': 'Mild', 'label': '🟢 Mild'},
    {'value': 'Medium', 'label': '🟡 Medium'},
    {'value': 'Hot', 'label': '🟠 Hot'},
    {'value': 'Very Hot', 'label': '🔴 Very Hot'},
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
          .where('itemType', isEqualTo: 'food')
          .get();
      setState(() {
        _likedFood.addAll(
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
    var list = all.where((f) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (f['name'] ?? '').toString().toLowerCase().contains(search) ||
          (f['location'] ?? '').toString().toLowerCase().contains(search) ||
          (f['subCategory'] ?? '').toString().toLowerCase().contains(search) ||
          (f['restaurantName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(search);

      final matchFeatured = !_showFeaturedOnly || f['featured'] == true;
      final matchLikes = !_showLikesOnly || _likedFood.contains(f['id']);
      final matchTrending = !_showTrendingOnly ||
          ((f['rating'] ?? 0) as num) >= 4.0;

      final matchCategory =
          _filterCategory == 'All' || f['category'] == _filterCategory;
      final matchSpice =
          _filterSpice == 'All' || f['spiceLevel'] == _filterSpice;

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchTrending &&
          matchCategory &&
          matchSpice;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) =>
            ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
      case 'price_low':
        list.sort((a, b) =>
            ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num));
        break;
      case 'price_high':
        list.sort((a, b) =>
            ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num));
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

  Future<void> _toggleLike(Map<String, dynamic> food) async {
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
      itemId: food['id'],
      itemType: 'food',
      itemName: food['name'] ?? '',
      itemImage: food['imageUrl'] ?? '',
      price: (food['price'] ?? 0).toDouble(),
      currency: food['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedFood.add(food['id']);
      } else {
        _likedFood.remove(food['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${food['name']}',
          'description': '${_user!.displayName ?? 'User'} liked this food',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': food['id'],
          'itemType': 'food',
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
                        '🍛 Food & Cuisine',
                        style: TextStyle(
                          fontSize: width * 0.05,
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
                                      hintText: 'Search food, restaurants, cuisine...',
                                      hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
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
                                  _sortChip('price_low', '💰 Price ↑'),
                                  _sortChip('price_high', '💎 Price ↓'),
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
                              _quickChip('❤️ My Likes (${_likedFood.length})', _showLikesOnly, () {
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
                                onTap: () => setState(
                                        () => _filterCategory = cat['value']!),
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

                      // SPICE FILTER (Modified below)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04, vertical: height * 0.008),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _spiceLevels.map((spice) {
                              final isSelected = _filterSpice == spice['value'];
                              return GestureDetector(
                                onTap: () => setState(
                                        () => _filterSpice = spice['value']!),
                                child: Container(
                                  margin: EdgeInsets.only(right: width * 0.02),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.03,
                                      vertical: height * 0.005),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.orange.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.orange
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    spice['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: width * 0.024,
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
                          stream: _service.getFood(),
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
                            final food = _filterAndSort(all);

                            if (food.isEmpty) return _buildEmptyState(width, height);

                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.04,
                                      vertical: height * 0.01),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${food.length} item${food.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: Colors.white70,
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
                                    itemCount: food.length,
                                    itemBuilder: (context, i) => FoodGridCard(
                                      food: food[i],
                                      isLiked: _likedFood.contains(food[i]['id']),
                                      onLike: () => _toggleLike(food[i]),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FoodDetailsScreen(food: food[i]),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                      : ListView.builder(
                                    padding: EdgeInsets.all(width * 0.04),
                                    itemCount: food.length,
                                    itemBuilder: (context, i) => FoodListCard(
                                      food: food[i],
                                      isLiked: _likedFood.contains(food[i]['id']),
                                      onLike: () => _toggleLike(food[i]),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FoodDetailsScreen(food: food[i]),
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
            color: isSelected
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
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
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.02),
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
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
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
            Icon(Icons.restaurant_menu, size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _searchQuery.isEmpty ? 'No food available' : 'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Food will appear here once admin adds them'
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