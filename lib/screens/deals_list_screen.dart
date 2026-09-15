import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/deal_card_widget.dart';
import 'deal_details_screen.dart';

class DealsListScreen extends StatefulWidget {
  const DealsListScreen({super.key});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  final _service = FirestoreService();
  final _wishlistService = WishlistService();
  final _user = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _isGridView = true;
  bool _showFeaturedOnly = false;
  bool _showLikesOnly = false;
  bool _showExpiringSoon = false;
  String _filterDiscount = 'All';

  final Set<String> _likedDeals = {};

  final List<Map<String, String>> _discountFilters = [
    {'value': 'All', 'label': '🎁 All'},
    {'value': '10', 'label': '💰 10%+'},
    {'value': '25', 'label': '💰 25%+'},
    {'value': '50', 'label': '💎 50%+'},
    {'value': '70', 'label': '🔥 70%+'},
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
          .where('itemType', isEqualTo: 'deal')
          .get();
      setState(() {
        _likedDeals.addAll(
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
    var list = all.where((d) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          (d['title'] ?? '').toString().toLowerCase().contains(search) ||
          (d['itemName'] ?? '').toString().toLowerCase().contains(search);

      final matchFeatured = !_showFeaturedOnly || d['featured'] == true;
      final matchLikes = !_showLikesOnly || _likedDeals.contains(d['id']);

      // Expiring soon (within 3 days)
      final endDate = d['endDate'] != null
          ? (d['endDate'] as dynamic).toDate() as DateTime
          : null;
      final matchExpiring = !_showExpiringSoon ||
          (endDate != null &&
              endDate.difference(DateTime.now()).inDays <= 3 &&
              endDate.isAfter(DateTime.now()));

      // Discount filter
      final discount = (d['discount'] ?? 0) as num;
      final matchDiscount = _filterDiscount == 'All' ||
          discount >= int.parse(_filterDiscount);

      return matchSearch &&
          matchFeatured &&
          matchLikes &&
          matchExpiring &&
          matchDiscount;
    }).toList();

    switch (_sortBy) {
      case 'discount':
        list.sort((a, b) =>
            ((b['discount'] ?? 0) as num).compareTo((a['discount'] ?? 0) as num));
        break;
      case 'price_low':
        list.sort((a, b) =>
            ((a['salePrice'] ?? 0) as num)
                .compareTo((b['salePrice'] ?? 0) as num));
        break;
      case 'price_high':
        list.sort((a, b) =>
            ((b['salePrice'] ?? 0) as num)
                .compareTo((a['salePrice'] ?? 0) as num));
        break;
    }

    list.sort((a, b) {
      if (a['featured'] == true && b['featured'] != true) return -1;
      if (a['featured'] != true && b['featured'] == true) return 1;
      return 0;
    });

    return list;
  }

  Future<void> _toggleLike(Map<String, dynamic> deal) async {
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
      itemId: deal['id'],
      itemType: 'deal',
      itemName: deal['title'] ?? '',
      itemImage: deal['imageUrl'] ?? '',
      price: (deal['salePrice'] ?? 0).toDouble(),
      currency: deal['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedDeals.add(deal['id']);
      } else {
        _likedDeals.remove(deal['id']);
      }
    });

    if (wasAdded) {
      try {
        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${deal['title']}',
          'description': '${_user!.displayName ?? 'User'} liked this deal',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': deal['id'],
          'itemType': 'deal',
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
        title: const Text('🎁 Special Deals'),
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
                      hintText: 'Search deals...',
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
                      _sortChip('discount', '🔥 Biggest Discount'),
                      _sortChip('price_low', '💰 Price ↑'),
                      _sortChip('price_high', '💎 Price ↓'),
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
                        _showExpiringSoon = false;
                      }
                    }),
                  ),
                  _quickChip(
                    '❤️ My Likes (${_likedDeals.length})',
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
                          _showExpiringSoon = false;
                        }
                      });
                    },
                  ),
                  _quickChip(
                    '⏰ Expiring Soon',
                    _showExpiringSoon,
                        () => setState(() {
                      _showExpiringSoon = !_showExpiringSoon;
                      if (_showExpiringSoon) {
                        _showFeaturedOnly = false;
                        _showLikesOnly = false;
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),

          // DISCOUNT FILTER
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _discountFilters.map((filter) {
                  final isSelected = _filterDiscount == filter['value'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _filterDiscount = filter['value']!),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.035,
                          vertical: height * 0.006),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter['label']!,
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
              stream: _service.getDeals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final deals = _filterAndSort(all);

                if (deals.isEmpty) {
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
                            '${deals.length} deal${deals.length > 1 ? 's' : ''}',
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
                        itemCount: deals.length,
                        itemBuilder: (context, i) => DealGridCard(
                          deal: deals[i],
                          isLiked: _likedDeals.contains(deals[i]['id']),
                          onLike: () => _toggleLike(deals[i]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DealDetailsScreen(
                                    deal: deals[i]),
                              ),
                            );
                          },
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: deals.length,
                        itemBuilder: (context, i) => DealListCard(
                          deal: deals[i],
                          isLiked: _likedDeals.contains(deals[i]['id']),
                          onLike: () => _toggleLike(deals[i]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DealDetailsScreen(
                                    deal: deals[i]),
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
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer,
                size: width * 0.15, color: Colors.red),
          ),
          SizedBox(height: height * 0.03),
          Text(
            _searchQuery.isEmpty
                ? 'No deals available'
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
                ? 'Deals will appear here once admin adds them'
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