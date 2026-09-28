import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/wishlist_service.dart';
import '../services/wishlist_insights_service.dart';
import 'package:flutter/services.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import 'destination_details_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class MyWishlistScreen extends StatefulWidget {
  const MyWishlistScreen({super.key});

  @override
  State<MyWishlistScreen> createState() => _MyWishlistScreenState();
}

class _MyWishlistScreenState extends State<MyWishlistScreen> {
  final service = WishlistService();
  final insightsService = WishlistInsightsService();

  // ===== STATE =====
  String _selectedType = 'All';
  String _sortBy = 'recent';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ===== INSIGHTS =====
  Map<String, int> _popularityMap = {};
  Map<String, dynamic> _topRank = {};
  List<Map<String, dynamic>> _trendingItems = [];   // ⬅️ ONGEZA
  Map<String, double> _tasteProfile = {};          // ⬅️ ONGEZA
  List<Map<String, dynamic>> _recommendations = [];   // ⬅️ ONGEZA
  Map<String, double> _priceChanges = {};
  List<Map<String, dynamic>> _bundles = [];   // ⬅️ ONGEZA
  List<Map<String, dynamic>> _weeklyTrend = [];
  bool _insightsLoaded = false;
  bool _isConverting = false;   // ⬅️ ONGEZA

  // ValueNotifier for search to avoid full screen rebuilds
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');

  // ===== SCROLL =====
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final popular = await insightsService.getPopularityMap();

      // Top ranked item
      if (popular.isNotEmpty) {
        final entries = popular.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = entries.first;
        _topRank = {
          'itemId': top.key,
          'likes': top.value,
          'rank': 1,
        };
      }

      // Trending this week
      final trending = await insightsService.getTrendingItems(limit: 5);

      // Taste profile
      final user = FirebaseAuth.instance.currentUser;
      Map<String, double> taste = {};
      if (user != null) {
        taste = await insightsService.getUserTasteProfile(user.uid);
      }

    // Recommendations               ⬅️ ONGEZA
    List<Map<String, dynamic>> recs = [];
    if (user != null) {
    recs = await insightsService.getRecommendations(user.uid, limit: 5);
    }

      // ⬇️ ONGEZA: Smart Bundles — group items by country/destination
      List<Map<String, dynamic>> bundles = [];
      final items = await service.getUserWishlist(user!.uid).first;
      if (items.isNotEmpty) {
        final grouped = <String, List<Map<String, dynamic>>>{};

        for (var w in items) {
          final country = (w['country'] ?? w['location'] ?? '').toString();
          if (country.isEmpty) continue;
          grouped.putIfAbsent(country, () => []).add(w);
        }

        grouped.forEach((key, list) {
          if (list.length >= 2) {
            bundles.add({
              'name': key,
              'count': list.length,
              'items': list,
            });
          }
        });

        bundles.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      }

      // Weekly trend
      final weeklyTrend = await insightsService.getWeeklyLikeTrend();

      if (mounted) {
        setState(() {
          _popularityMap = popular;
          _trendingItems = trending;
          _tasteProfile = taste;
          _recommendations = recs;              // ⬅️ ONGEZA
          _bundles = bundles;                     // ⬅️ ONGEZA
          _weeklyTrend = weeklyTrend;
          _insightsLoaded = true;
        });
      }
    } catch (e) {
      print('🔥 Error loading insights: $e');
      if (mounted) {
        setState(() => _insightsLoaded = true);
      }
    }
  }

  // ===== CONVERT WISHLIST TO CART =====
  Future<void> _convertToCart(List<Map<String, dynamic>> itemsToConvert) async {
    if (itemsToConvert.isEmpty) {
      _showSnack('Hakuna items za ku-convert', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please login first', isError: true);
      return;
    }

    setState(() => _isConverting = true);

    final cartService = CartService();
    int successCount = 0;
    int failCount = 0;

    for (var item in itemsToConvert) {
      final price = (item['price'] as num?)?.toDouble() ?? 0;

      // Skip kama haina price (destinations mara nyingi ni 0)
      if (price <= 0) {
        failCount++;
        continue;
      }

      try {
        final added = await cartService.addToCart(
          user.uid,
          CartItem(
            itemId: (item['itemId'] ?? '').toString(),
            itemType: (item['itemType'] ?? '').toString(),
            itemName: (item['itemName'] ?? '').toString(),
            itemImage: (item['itemImage'] ?? '').toString(),
            price: price,
            currency: (item['currency'] ?? 'USD').toString(),
          ),
        );
        if (added) successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      setState(() => _isConverting = false);
      _showSnack(
        '✅ $successCount items zimeongezwa kwenye cart'
            '${failCount > 0 ? ' ($failCount zimeshindwa)' : ''}',
        isError: successCount == 0,
      );
    }
  }

  // ===== SHARE WISHLIST =====
  Future<void> _shareWishlist(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      _showSnack('Wishlist ni tupu', isError: true);
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('🌍 My TURIVA Wishlist (${items.length} items)');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();

      for (var item in items) {
        final icon = insightsService.getTypeIcon(
            (item['itemType'] ?? '').toString());
        buffer.writeln('$icon ${item['itemName']}');
      }

      buffer.writeln();
      buffer.writeln('📱 Get TURIVA app to explore more!');
      buffer.writeln('https://turiva.app');

      // ⬇️ BADILISHA kutoka Clipboard → Share Sheet
      await Share.share(
        buffer.toString(),
        subject: 'My TURIVA Wishlist',
      );
    } catch (e) {
      print('🔥 Error sharing: $e');
      _showSnack('Imeshindwa kushare', isError: true);
    }
  }

  // ===== SHARE SINGLE ITEM =====
  Future<void> _shareItem(Map<String, dynamic> item) async {
    try {
      final icon = insightsService.getTypeIcon(
          (item['itemType'] ?? '').toString());
      final text = '''
$icon ${item['itemName']} 📍 ${item['location'] ?? item['country'] ?? 'Tanzania'}

Check this out on TURIVA!
https://turiva.app/item/${item['itemId']}
      ''';

      await Share.share(
        text.trim(),
        subject: item['itemName'] ?? 'TURIVA',
      );
    } catch (e) {
      print('🔥 Error sharing: $e');
      _showSnack('Imeshindwa kushare', isError: true);
    }
  }

  // ===== HELPER: Snack =====
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.accentGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===== FILTER + SORT =====
  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> all) {
    final query = _searchQueryNotifier.value.toLowerCase().trim();

    var list = all.where((w) {
      // Type filter
      if (_selectedType != 'All' &&
          (w['itemType'] ?? '').toString() != _selectedType) {
        return false;
      }
      // Search filter
      if (query.isNotEmpty) {
        final name = (w['itemName'] ?? '').toString().toLowerCase();
        final type = (w['itemType'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !type.contains(query)) return false;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => (a['itemName'] ?? '')
            .toString()
            .compareTo((b['itemName'] ?? '').toString()));
        break;
      default:
        break;
    }

    return list;
  }

  // ===== UNIQUE TYPES =====
  List<String> _getTypes(List<Map<String, dynamic>> items) {
    final set = <String>{'All'};
    for (var w in items) {
      final t = (w['itemType'] ?? '').toString();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList();
    list.remove('All');
    list.sort();
    return ['All', ...list];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;

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
            child: Column(
              children: [
                _buildGlassAppBar(context, width),
                Expanded(
                  child: user == null
                      ? _buildLoginPrompt(width)
                      : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.getUserWishlist(user.uid),
                    builder: (context, snapshot) {
                      // ===== LOADING (Only first time) =====
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                          ),
                        );
                      }

                      // ===== ERROR =====
                      if (snapshot.hasError) {
                        return _buildErrorState(
                            snapshot.error, width);
                      }

                      final items = snapshot.data ?? [];

                      // ===== EMPTY WISHLIST (no items at all) =====
                      if (items.isEmpty) {
                        return _buildEmptyWishlist(width, height);
                      }

                      // ===== CONTENT (Wrapped in ValueListenableBuilder for Search) =====
                      return ValueListenableBuilder<String>(
                        valueListenable: _searchQueryNotifier,
                        builder: (context, query, _) {
                          final filtered = _filterAndSort(items);

                          return RefreshIndicator(
                            color: AppColors.accentGold,
                            backgroundColor: Colors.black,
                            onRefresh: () async {
                              await Future.delayed(
                                  const Duration(milliseconds: 800));
                            },
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics:
                              const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                // ===== STATS HEADER =====
                                SliverToBoxAdapter(
                                  child: _buildStatsHeader(
                                      filtered, width),
                                ),

                                // ===== SEARCH BAR =====
                                SliverToBoxAdapter(
                                  child: _buildSearchBar(width),
                                ),

                                // ===== TRENDING SECTION =====
                                if (_trendingItems.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildTrendingSection(width, height),
                                  ),

                                // ===== TASTE PROFILE =====
                                if (_tasteProfile.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildTasteProfile(width, height),
                                  ),

                                // ===== WEEKLY TREND CHART =====
                                if (_weeklyTrend.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildWeeklyChart(width, height),
                                  ),

                                // ===== RECOMMENDED FOR YOU =====   ⬅️ ONGEZA HAPA
                                if (_recommendations.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildRecommendedSection(width, height),
                                  ),

                                // ===== SMART BUNDLES =====
                                if (_bundles.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildBundlesSection(width, height),
                                  ),

                                // ===== FILTER CHIPS =====
                                SliverToBoxAdapter(
                                  child: _buildFilterChips(
                                      width, height, items),
                                ),

                                // ===== NO RESULTS (kama filtered ni empty) =====
                                if (filtered.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _buildNoResults(width, height),
                                  )
                                else
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    left: width * 0.04,
                                    right: width * 0.04,
                                    top: width * 0.02,
                                    bottom: width * 0.04,
                                  ),
                                  sliver: SliverList(
                                    delegate:
                                    SliverChildBuilderDelegate(
                                          (context, i) {
                                            return _wishlistCard(
                                              filtered[i],
                                              width,
                                              height,
                                              user.uid,
                                            );
                                      },
                                      childCount: filtered.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // ===== GLASS FAB =====
          Positioned(
            bottom: 160,
            right: width * 0.04,
            child: _buildGlassFAB(),
          ),
        ],
      ),
    );
  }

  // ===== GLASS FAB: Convert to Cart =====
  Widget _buildGlassFAB() {
    if (!_insightsLoaded) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getUserWishlist(
          FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final filtered = _filterAndSort(items);

        if (filtered.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: _isConverting ? null : () => _convertToCart(filtered),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),   // GLASS
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon (spinner kama ina-convert)
                    _isConverting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentGold,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_cart_checkout,
                            color: AppColors.accentGold,
                            size: 20,
                          ),
                    const SizedBox(width: 10),

                    // Label
                    Text(
                      _isConverting
                          ? 'Inaongeza...'
                          : 'Add ${filtered.length} to Cart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.3,
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
  }

  // ===== GLASS APP BAR (Parallax) =====
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, _) {
        final opacity = (offset / 200).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.03,
            vertical: width * 0.02,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 12 + opacity * 8, sigmaY: 12 + opacity * 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.02,
                  vertical: width * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15 + opacity * 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3 + opacity * 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // GestureDetector(
                    //   onTap: () => Navigator.pop(context),
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white.withOpacity(0.2),
                    //       shape: BoxShape.circle,
                    //     ),
                    //     child: const Icon(
                    //       Icons.arrow_back_ios_new,
                    //       color: Colors.white,
                    //       size: 18,
                    //     ),
                    //   ),
                    // ),
                    SizedBox(width: width * 0.03),
                    const Expanded(
                      child: Text(
                        '❤️ My Wishlist',
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
                    // ===== SHARE BUTTON =====
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: service.getUserWishlist(
                          FirebaseAuth.instance.currentUser?.uid ?? ''),
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) return const SizedBox.shrink();

                        return GestureDetector(
                          onTap: () => _shareWishlist(items),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== SEARCH BAR =====
  Widget _buildSearchBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.01,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) {
            _searchQueryNotifier.value = v;
          },
          decoration: InputDecoration(
            hintText: 'Search your wishlist...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.white70,
              size: 20,
            ),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _searchQueryNotifier,
              builder: (context, query, _) {
                return query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchQueryNotifier.value = '';
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: width * 0.035,
              horizontal: width * 0.02,
            ),
          ),
        ),
      ),
    );
  }

  // ===== TRENDING SECTION =====
  Widget _buildTrendingSection(double width, double height) {
    return Padding(
      padding: EdgeInsets.only(
        top: width * 0.02,
        bottom: width * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    'Trending This Week',
                    style: TextStyle(
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_trendingItems.length}',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          // Horizontal List
          SizedBox(
            height: height * 0.22,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              itemCount: _trendingItems.length,
              itemBuilder: (context, i) {
                final item = _trendingItems[i];
                final likes = (item['likes'] as int?) ?? 0;
                final imageUrl = (item['itemImage'] ?? '').toString();

                return GestureDetector(
                  onTap: () {
                    if ((item['itemType'] ?? '') == 'destination') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailsScreen(destination: item),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: width * 0.4,
                    margin: EdgeInsets.only(right: width * 0.03),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image
                          imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  cacheWidth: (width * 0.4 * 2).toInt(),
                                  errorBuilder: (_, __, ___) =>
                                      _trendingFallback(width),
                                )
                              : _trendingFallback(width),

                          // Gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Rank badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${i + 1}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Likes badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 9)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$likes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom info
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.all(width * 0.025),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['itemName'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.032,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: height * 0.003),
                                  Text(
                                    '${insightsService.getTypeIcon(item['itemType'] ?? '')} ${(item['itemType'] ?? '').toString().toUpperCase()}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: width * 0.022,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }

  // Fallback image for trending
  Widget _trendingFallback(double width) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.local_fire_department,
          size: width * 0.1,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

  // ===== TASTE PROFILE =====
  Widget _buildTasteProfile(double width, double height) {
    // Sort by percentage desc
    final entries = _tasteProfile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: EdgeInsets.only(
        top: width * 0.02,
        bottom: width * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 18)),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    'Your Taste Profile',
                    style: TextStyle(
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${_tasteProfile.length} categories',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.025,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          // Bars
          Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: entries.map((entry) {
                final type = entry.key;
                final percent = entry.value;
                final icon = insightsService.getTypeIcon(type);

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: width * 0.02),
                  child: Row(
                    children: [
                      // Icon + Name
                      SizedBox(
                        width: width * 0.3,
                        child: Row(
                          children: [
                            Text(icon,
                                style: TextStyle(fontSize: width * 0.04)),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.028,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 8,
                            color: Colors.white.withOpacity(0.1),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (percent / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: width * 0.03),

                      // Percentage
                      SizedBox(
                        width: width * 0.1,
                        child: Text(
                          '${percent.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontSize: width * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===== STATS HEADER =====
  Widget _buildStatsHeader(
      List<Map<String, dynamic>> items, double width) {
    final total = items.length;
    final types = <String>{};
    for (var w in items) {
      final t = (w['itemType'] ?? '').toString();
      if (t.isNotEmpty) types.add(t);
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.02,
      ),
      child: Row(
        children: [
          _statCard(
            icon: Icons.favorite,
            value: '$total',
            label: 'Total Likes',
            color: Colors.redAccent,
            width: width,
          ),
          SizedBox(width: width * 0.03),
          _statCard(
            icon: Icons.category,
            value: '${types.length}',
            label: 'Categories',
            color: AppColors.accentGold,
            width: width,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required double width,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: width * 0.03,
          horizontal: width * 0.02,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),   // ⬅️ Solid dark
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
            child: Row(
              children: [
                Icon(icon, color: color, size: width * 0.06),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.024,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // ===== WEEKLY TREND CHART =====
  Widget _buildWeeklyChart(double width, double height) {
    final maxLikes = _weeklyTrend
        .map((e) => (e['likes'] as int?) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.only(
        top: width * 0.02,
        bottom: width * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 18)),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: TextStyle(
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Likes zako kwa siku 7 zilizopita',
                        style: TextStyle(
                          fontSize: width * 0.026,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          // Chart
          Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.04),
            height: height * 0.22,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxLikes > 0 ? (maxLikes / 4).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _weeklyTrend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weeklyTrend[i]['day'].toString(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval:
                          maxLikes > 0 ? (maxLikes / 4).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_weeklyTrend.length - 1).toDouble(),
                minY: 0,
                maxY: (maxLikes > 0 ? maxLikes + 1 : 5).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _weeklyTrend.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        ((_weeklyTrend[i]['likes'] as int?) ?? 0)
                            .toDouble(),
                      ),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGold,
                        AppColors.accentGold.withOpacity(0.4),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.accentGold,
                        strokeWidth: 1,
                        strokeColor: Colors.black,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentGold.withOpacity(0.3),
                          AppColors.accentGold.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== RECOMMENDED SECTION =====
  Widget _buildRecommendedSection(double width, double height) {
    return Padding(
      padding: EdgeInsets.only(
        top: width * 0.02,
        bottom: width * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended For You',
                        style: TextStyle(
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Based on your taste profile',
                        style: TextStyle(
                          fontSize: width * 0.026,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_recommendations.length}',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          // Horizontal List
          SizedBox(
            height: height * 0.24,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              itemCount: _recommendations.length,
              itemBuilder: (context, i) {
                final item = _recommendations[i];
                final likes = (item['likes'] as int?) ?? 0;
                final imageUrl = (item['itemImage'] ?? '').toString();
                final type = (item['itemType'] ?? '').toString();

                return GestureDetector(
                  onTap: () {
                    // Navigation — item hapa haina data kamili ya destination,
                    // tu itemId/name/image/type/likes
                    // Kama unataka navigation, tunahitaji ku-fetch details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Opening ${item['itemName']}...'),
                        backgroundColor: AppColors.accentGold,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: width * 0.42,
                    margin: EdgeInsets.only(right: width * 0.03),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image
                          imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: (width * 0.42 * 2).toInt(),
                            errorBuilder: (_, __, ___) =>
                                _recommendFallback(width),
                          )
                              : _recommendFallback(width),

                          // Gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Type badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _typeColor(type),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${insightsService.getTypeIcon(type)} ${type.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),

                          // Likes badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.redAccent,
                                    size: 9,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$likes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom info
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.all(width * 0.025),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['itemName'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.032,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: height * 0.005),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.accentGold,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Popular with you',
                                        style: TextStyle(
                                          color: AppColors.accentGold,
                                          fontSize: width * 0.022,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
        ],
      ),
    );
  }

  // ===== SMART BUNDLES SECTION =====
  Widget _buildBundlesSection(double width, double height) {
    return Padding(
      padding: EdgeInsets.only(
        top: width * 0.02,
        bottom: width * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 18)),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Bundles',
                        style: TextStyle(
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Save more when you book together',
                        style: TextStyle(
                          fontSize: width * 0.026,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_bundles.length}',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          // Horizontal list
          SizedBox(
            height: height * 0.15,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              itemCount: _bundles.length,
              itemBuilder: (context, i) {
                final bundle = _bundles[i];
                final count = bundle['count'] as int;
                final name = bundle['name'] as String;

                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Viewing bundle: $name ($count items)'),
                        backgroundColor: AppColors.accentGold,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: width * 0.65,
                    margin: EdgeInsets.only(right: width * 0.03),
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentGold.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: width * 0.12,
                          height: width * 0.12,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentGold.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '🎁',
                              style: TextStyle(fontSize: width * 0.06),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.03),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: height * 0.005),
                              Text(
                                '$count items • Save up to 20%',
                                style: TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: width * 0.025,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.accentGold.withOpacity(0.7),
                          size: width * 0.035,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// Fallback image for recommendations
  Widget _recommendFallback(double width) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: width * 0.1,
          color: AppColors.accentGold.withOpacity(0.5),
        ),
      ),
    );
  }

  // ===== FILTER CHIPS =====
  Widget _buildFilterChips(double width, double height,
      List<Map<String, dynamic>> items) {
    final types = _getTypes(items);
    return SizedBox(
      height: height * 0.055,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        itemCount: types.length + 3,
        itemBuilder: (context, i) {
          if (i < 3) {
            final sorts = [
              {'key': 'recent', 'label': '🕐 Recent'},
              {'key': 'name', 'label': '🔤 A-Z'},
              {'key': 'favorites', 'label': '❤️ All Likes'},
            ];
            final s = sorts[i];
            final active = _sortBy == s['key'];
            return _chip(
              label: s['label']!,
              active: active,
              onTap: () => setState(() => _sortBy = s['key']!),
              width: width,
            );
          }

          final typeIndex = i - 3;
          final type = types[typeIndex];
          final active = _selectedType == type;
          return _chip(
            label: type == 'All' ? '🌍 All Types' : type.toUpperCase(),
            active: active,
            onTap: () => setState(() => _selectedType = type),
            width: width,
          );
        },
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.035,
          vertical: width * 0.02,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.4),
              blurRadius: 12,
            ),
          ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.03,
            ),
          ),
        ),
      ),
    );
  }

  // ===== LOGIN PROMPT =====
  Widget _buildLoginPrompt(double width) {
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
            Icon(Icons.login, size: width * 0.15, color: Colors.white70),
            SizedBox(height: width * 0.04),
            Text(
              'Please login',
              style: TextStyle(
                fontSize: width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              'Sign in to see your wishlist',
              style: TextStyle(color: Colors.white70, fontSize: width * 0.035),
            ),
          ],
        ),
      ),
    );
  }

  // ===== NO RESULTS =====
  Widget _buildNoResults(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.08),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.search_off,
                size: width * 0.15,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Try a different search term\nor clear your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.032,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: height * 0.03),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _searchQueryNotifier.value = '';
                setState(() {
                  _selectedType = 'All';
                });
              },
              icon: const Icon(Icons.refresh,
                  color: AppColors.accentGold, size: 18),
              label: const Text(
                'Clear Filters',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EMPTY WISHLIST =====
  Widget _buildEmptyWishlist(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.08),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.favorite_border,
                size: width * 0.15,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              'No likes yet',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Start liking destinations, hotels, tours\nand more to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.032,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ERROR STATE =====
  Widget _buildErrorState(Object? error, double width) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 48),
            SizedBox(height: width * 0.04),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.03,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===== WISHLIST CARD =====
  Widget _wishlistCard(
      Map<String, dynamic> item,
      double width,
      double height,
      String userId,
      ) {
    final itemType = (item['itemType'] ?? '').toString();
    final color = _typeColor(itemType);

    return GestureDetector(
      onTap: () {
        // Navigate to details based on type
        if (itemType == 'destination') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DestinationDetailsScreen(destination: item),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),   // ⬅️ Solid dark
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ===== Image =====
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: width * 0.3,
                height: width * 0.3,
                child: Stack(
                  children: [
                    (item['itemImage'] ?? '').toString().isNotEmpty
                        ? Image.network(
                      item['itemImage'],
                      fit: BoxFit.cover,
                      cacheWidth: (width * 0.3 * 2).toInt(),   // ⬅️ ONGEZA
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.broken_image,
                            color: Colors.white70),
                      ),
                    )
                        : Container(
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.image,
                          color: Colors.white70),
                    ),
                    // Type badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          itemType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // ===== POPULARITY BADGE =====
                    if (_insightsLoaded &&
                        (_popularityMap[item['itemId']] ?? 0) > 0)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentGold.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 9)),
                              const SizedBox(width: 2),
                              Text(
                                '${_popularityMap[item['itemId']]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Rank badge — only if top 3
                              if (_topRank['itemId'] == item['itemId'] &&
                                  _topRank['rank'] == 1) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '#1',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ===== Info =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.035),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['itemName'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ===== PRICE CHANGE BADGE =====
                    if (_getPriceChange(item) != 0) ...[
                      SizedBox(height: height * 0.005),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getPriceChange(item) < 0
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPriceChange(item) < 0
                                ? Colors.green.withOpacity(0.6)
                                : Colors.red.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPriceChange(item) < 0
                                  ? Icons.trending_down
                                  : Icons.trending_up,
                              color: _getPriceChange(item) < 0
                                  ? Colors.green
                                  : Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPriceChange(item) < 0
                                  ? 'Bei imeshuka ${_getPriceChange(item).abs().toStringAsFixed(0)}%'
                                  : 'Bei imepanda ${_getPriceChange(item).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _getPriceChange(item) < 0
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: width * 0.026,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: height * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (itemType == 'destination') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DestinationDetailsScreen(
                                        destination: item),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.visibility,
                                size: 14, color: Colors.white),
                            label: const Text('View',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: height * 0.008),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        // ===== SHARE BUTTON =====
                        GestureDetector(
                          onTap: () => _shareItem(item),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.5)),
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        GestureDetector(
                          onTap: () async {
                            await service.removeFromWishlist(
                                userId, item['itemId']);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.5)),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getPriceChange(Map<String, dynamic> item) {
    final whenLiked = (item['priceWhenLiked'] as num?)?.toDouble() ?? 0;
    final current = (item['price'] as num?)?.toDouble() ?? 0;

    if (whenLiked <= 0 || current <= 0 || whenLiked == current) return 0;

    return ((current - whenLiked) / whenLiked) * 100;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'destination':
        return Colors.green;
      case 'hotel':
        return Colors.blue;
      case 'tour':
        return Colors.orange;
      case 'mountain':
        return Colors.brown;
      case 'beach':
        return Colors.cyan;
      case 'culture':
        return Colors.purple;
      case 'food':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }
}

// ============================================================
// ===== STAGGERED FADE-IN WRAPPER =====
// ============================================================
class _StaggeredCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredCard({required this.child, required this.index});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

extension WishlistInsightsServiceWeeklyTrend on WishlistInsightsService {
  Future<List<Map<String, dynamic>>> getWeeklyLikeTrend() async {
    return [
      {'day': 'Mon', 'likes': 2},
      {'day': 'Tue', 'likes': 5},
      {'day': 'Wed', 'likes': 3},
      {'day': 'Thu', 'likes': 8},
      {'day': 'Fri', 'likes': 6},
      {'day': 'Sat', 'likes': 10},
      {'day': 'Sun', 'likes': 4},
    ];
  }
}