import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import 'destination_details_screen.dart';

class MyWishlistScreen extends StatefulWidget {
  const MyWishlistScreen({super.key});

  @override
  State<MyWishlistScreen> createState() => _MyWishlistScreenState();
}

class _MyWishlistScreenState extends State<MyWishlistScreen> {
  final service = WishlistService();

  // ===== STATE =====
  String _selectedType = 'All';
  String _sortBy = 'recent';

  // ===== SCROLL =====
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===== FILTER + SORT =====
  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> all) {
    var list = all.where((w) {
      if (_selectedType == 'All') return true;
      return (w['itemType'] ?? '').toString() == _selectedType;
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
                      // ===== LOADING =====
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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
                      final filtered = _filterAndSort(items);

                      // ===== EMPTY =====
                      if (items.isEmpty) {
                        return _buildEmptyWishlist(width, height);
                      }

                      // ===== CONTENT =====
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
                                  items, width),
                            ),

                            // ===== FILTER CHIPS =====
                            SliverToBoxAdapter(
                              child: _buildFilterChips(
                                  width, height, items),
                            ),

                            // ===== LIST =====
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
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