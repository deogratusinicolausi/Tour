import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/deal_details_screen.dart';
import '../services/firestore_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import '../widgets/deal_card_widget.dart';

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

      final endDate = d['endDate'] != null
          ? (d['endDate'] as dynamic).toDate() as DateTime
          : null;
      final matchExpiring = !_showExpiringSoon ||
          (endDate != null &&
              endDate.difference(DateTime.now()).inDays <= 3 &&
              endDate.isAfter(DateTime.now()));

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== BACKGROUND =====
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
          Container(color: Colors.black.withOpacity(0.7)),

          // ===== CONTENT =====
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ===== APP BAR (scrolls away) =====
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  expandedHeight: 70,
                  toolbarHeight: 70,
                  flexibleSpace: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: width * 0.02,
                    ),
                    child: _buildGlassAppBar(context, width),
                  ),
                ),

                // ===== SEARCH + SORT =====
                SliverToBoxAdapter(
                  child: _buildGlassSearchBar(width, height),
                ),

                // ===== QUICK CHIPS =====
                SliverToBoxAdapter(
                  child: _buildGlassQuickChips(width, height),
                ),

                // ===== DISCOUNT FILTER =====
                SliverToBoxAdapter(
                  child: _buildGlassDiscountFilter(width, height),
                ),

                // ===== DEALS CONTENT =====
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.getDeals(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accentGold),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }

                    final all = snapshot.data ?? [];
                    final deals = _filterAndSort(all);

                    if (deals.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(width, height),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // Result count
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.01),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${deals.length} deal${deals.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Grid or list
                        if (_isGridView)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: width * 0.03,
                                mainAxisSpacing: width * 0.03,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: deals.length,
                              itemBuilder: (context, i) => DealGridCard(
                                deal: deals[i],
                                isLiked:
                                _likedDeals.contains(deals[i]['id']),
                                onLike: () => _toggleLike(deals[i]),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DealDetailsScreen(deal: deals[i]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding:
                            EdgeInsets.all(width * 0.04),
                            child: Column(
                              children: deals
                                  .map((d) => DealListCard(
                                deal: d,
                                isLiked:
                                _likedDeals.contains(d['id']),
                                onLike: () => _toggleLike(d),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DealDetailsScreen(deal: d),
                                    ),
                                  );
                                },
                              ))
                                  .toList(),
                            ),
                          ),

                        SizedBox(height: height * 0.05),
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GLASS APP BAR
  // ============================================================
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.03,
            vertical: width * 0.03,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              const Expanded(
                child: Text(
                  '🔥 Special Deals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isGridView = !_isGridView),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS SEARCH + SORT
  // ============================================================
  Widget _buildGlassSearchBar(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                cursorColor: AppColors.accentGold,
                decoration: InputDecoration(
                  hintText: 'Search deals...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding:
                  EdgeInsets.symmetric(vertical: height * 0.018),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.accentGold, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.012),
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
    );
  }

  // ============================================================
  // GLASS QUICK CHIPS
  // ============================================================
  Widget _buildGlassQuickChips(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
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
    );
  }

  // ============================================================
  // GLASS DISCOUNT FILTER
  // ============================================================
  Widget _buildGlassDiscountFilter(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _discountFilters.map((filter) {
            final isSelected = _filterDiscount == filter['value'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _filterDiscount = filter['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: width * 0.02),
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.035,
                    vertical: height * 0.008),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.red
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.red
                        : Colors.white.withOpacity(0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ]
                      : [],
                ),
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: width * 0.028,
                  ),
                ),
              ),
            );
          }).toList(),
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
        duration: const Duration(milliseconds: 200),
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
              color: AppColors.accentGold.withOpacity(0.4),
              blurRadius: 10,
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
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold.withOpacity(0.25)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
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
        margin: EdgeInsets.symmetric(horizontal: width * 0.1, vertical: 60),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_offer,
                  size: width * 0.12, color: Colors.white),
            ),
            SizedBox(height: height * 0.025),
            Text(
              _searchQuery.isEmpty ? 'No deals available' : 'No results found',
              style: TextStyle(
                fontSize: width * 0.048,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              _searchQuery.isEmpty
                  ? 'Deals will appear here once admin adds them'
                  : 'Try different filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.032,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⭐️ Countdown Timer Widget
class CountdownTimer extends StatefulWidget {
  final DateTime? endDate;

  const CountdownTimer({super.key, this.endDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateRemaining();
        _startTimer();
      }
    });
  }

  void _updateRemaining() {
    if (widget.endDate == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = widget.endDate!.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.endDate == null || _remaining == Duration.zero) {
      return const SizedBox();
    }

    final width = MediaQuery.of(context).size.width;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            days > 0
                ? '${days}d ${hours}h'
                : hours > 0
                    ? '${hours}h ${minutes}m'
                    : '${minutes}m ${seconds}s',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.025,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DealGridCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const DealGridCard({
    super.key,
    required this.deal,
    required this.isLiked,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = deal['discount'] ?? 0;
    final price = deal['salePrice'] ?? 0;
    final oldPrice = deal['regularPrice'] ?? 0;

    // Extract endDate for the timer
    final endDate = deal['endDate'] != null
        ? (deal['endDate'] as dynamic).toDate() as DateTime
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(
                      deal['imageUrl'] ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.image, color: Colors.white24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '\$$price',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$$oldPrice',
                              style: const TextStyle(
                                color: Colors.white54,
                                decoration: TextDecoration.lineThrough,
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
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onLike,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              // Added Countdown Timer Overlay
              if (endDate != null)
                Positioned(
                  bottom: 80, // Adjust based on title/price height
                  left: 8,
                  child: CountdownTimer(endDate: endDate),
                ),
              if (discount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DealListCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const DealListCard({
    super.key,
    required this.deal,
    required this.isLiked,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                deal['imageUrl'] ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      deal['title'] ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${deal['salePrice']}',
                      style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white70,
              ),
              onPressed: onLike,
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white38,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}