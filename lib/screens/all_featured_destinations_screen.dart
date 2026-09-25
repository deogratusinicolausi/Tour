import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'destination_details_screen.dart';

class AllFeaturedDestinationsScreen extends StatefulWidget {
  const AllFeaturedDestinationsScreen({super.key});

  @override
  State<AllFeaturedDestinationsScreen> createState() =>
      _AllFeaturedDestinationsScreenState();
}

class _AllFeaturedDestinationsScreenState
    extends State<AllFeaturedDestinationsScreen> {
  final service = FirestoreService();

  // ===== STATE =====
  String _selectedCountry = 'All';
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
    var list = all.where((d) {
      if (_selectedCountry == 'All') return true;
      return (d['country'] ?? '').toString() == _selectedCountry;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) => ((b['rating'] ?? 0) as num)
            .compareTo((a['rating'] ?? 0) as num));
        break;
      case 'name':
        list.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
        break;
      default:
        break;
    }

    return list;
  }

  // ===== UNIQUE COUNTRIES =====
  List<String> _getCountries(List<Map<String, dynamic>> destinations) {
    final set = <String>{'All'};
    for (var d in destinations) {
      final c = (d['country'] ?? '').toString();
      if (c.isNotEmpty) set.add(c);
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
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.getFeaturedDestinations(),
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
                        return _buildErrorState(snapshot.error, width);
                      }

                      final destinations = snapshot.data ?? [];
                      final filtered = _filterAndSort(destinations);

                      // ===== EMPTY =====
                      if (destinations.isEmpty) {
                        return _buildEmptyState(width, height);
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
                              child:
                              _buildStatsHeader(destinations, width),
                            ),

                            // ===== FILTER CHIPS =====
                            SliverToBoxAdapter(
                              child: _buildFilterChips(
                                  width, height, destinations),
                            ),

                            // ===== GRID =====
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: width * 0.04,
                                right: width * 0.04,
                                top: width * 0.02,
                                bottom: width * 0.04,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: width * 0.03,
                                  mainAxisSpacing: width * 0.03,
                                  childAspectRatio: 0.68,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                      (context, i) {
                                    return _StaggeredCard(
                                      index: i,
                                      child: _FeaturedCard(
                                        dest: filtered[i],
                                        width: width,
                                        height: height,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DestinationDetailsScreen(
                                                      destination:
                                                      filtered[i]),
                                            ),
                                          );
                                        },
                                      ),
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

  // ===== GLASS APP BAR (Parallax aware) =====
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
                        '🔥 Featured Destinations',
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
      List<Map<String, dynamic>> destinations, double width) {
    final total = destinations.length;
    final countries = <String>{};
    double avgRating = 0;
    int ratedCount = 0;

    for (var d in destinations) {
      final c = (d['country'] ?? '').toString();
      if (c.isNotEmpty) countries.add(c);

      final r = (d['rating'] ?? 0) as num;
      if (r > 0) {
        avgRating += r;
        ratedCount++;
      }
    }

    final avg = ratedCount > 0 ? (avgRating / ratedCount) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.02,
      ),
      child: Row(
        children: [
          _statCard(
            icon: Icons.place,
            value: '$total',
            label: 'Destinations',
            color: AppColors.accentGold,
            width: width,
          ),
          SizedBox(width: width * 0.03),
          _statCard(
            icon: Icons.public,
            value: '${countries.length}',
            label: 'Countries',
            color: Colors.blueAccent,
            width: width,
          ),
          SizedBox(width: width * 0.03),
          _statCard(
            icon: Icons.star,
            value: avg.toStringAsFixed(1),
            label: 'Avg Rating',
            color: Colors.orangeAccent,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: width * 0.03,
              horizontal: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: width * 0.05),
                SizedBox(height: width * 0.015),
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
        ),
      ),
    );
  }

  // ===== FILTER CHIPS =====
  Widget _buildFilterChips(double width, double height,
      List<Map<String, dynamic>> destinations) {
    final countries = _getCountries(destinations);
    return SizedBox(
      height: height * 0.055,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        itemCount: countries.length + 3,
        itemBuilder: (context, i) {
          // Sort chips first
          if (i < 3) {
            final sorts = [
              {'key': 'recent', 'label': '🕐 Recent'},
              {'key': 'rating', 'label': '⭐ Top Rated'},
              {'key': 'name', 'label': '🔤 A-Z'},
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

          // Country chips
          final countryIndex = i - 3;
          final country = countries[countryIndex];
          final active = _selectedCountry == country;
          return _chip(
            label: country == 'All' ? '🌍 All' : country,
            active: active,
            onTap: () => setState(() => _selectedCountry = country),
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

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(double width, double height) {
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
                Icons.explore_outlined,
                size: width * 0.15,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              'No featured destinations',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Featured destinations will appear here\nonce admin marks them as featured.',
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

// ============================================================
// ===== FEATURED CARD (with Hero + tap scale) =====
// ============================================================
class _FeaturedCard extends StatefulWidget {
  final Map<String, dynamic> dest;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.dest,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dest = widget.dest;
    final width = widget.width;
    final height = widget.height;
    final imageUrl = (dest['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Hero
              Stack(
                children: [
                  SizedBox(
                    height: height * 0.13,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Hero(
                      tag: 'dest_${dest['id']}',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(
                            width, height * 0.13, Icons.broken_image),
                      ),
                    )
                        : _imageFallback(width, height * 0.13,
                        Icons.image_not_supported),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  if (dest['featured'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                              AppColors.accentGold.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 10, color: Colors.black),
                            SizedBox(width: 3),
                            Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if ((dest['videos'] as List?)?.isNotEmpty ?? false)
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
                            const Icon(Icons.videocam,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${(dest['videos'] as List).length}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dest['name'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.032,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: width * 0.025,
                              color: Colors.white70),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              dest['location'] ?? '',
                              style: TextStyle(
                                fontSize: width * 0.022,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
  }

  Widget _imageFallback(double width, double height, IconData icon) {
    return Container(
      height: height,
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Icon(icon,
            size: width * 0.1, color: Colors.white.withOpacity(0.4)),
      ),
    );
  }
}