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
    extends State<AllFeaturedDestinationsScreen>
    with TickerProviderStateMixin {
  final service = FirestoreService();

  // ===== STATE =====
  String _selectedCountry = 'All';
  String _sortBy = 'recent';
  bool _isGridView = true;

  // ===== SCROLL =====
  final ScrollController _scrollController = ScrollController();

  // ⭐ ANIMATION
  late AnimationController _bgController;

  // ⭐ STREAM (cached)
  late Stream<List<Map<String, dynamic>>> _destinationsStream;

  @override
  void initState() {
    super.initState();

    // ⭐ Cache stream — inaundwa MARA MOJA tu
    _destinationsStream = service.getFeaturedDestinations();

    _bgController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  // ===== FILTER + SORT =====
  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> all) {
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

  // ===== RANK =====
  int _getRank(List<Map<String, dynamic>> sorted, int index) {
    if (_sortBy == 'rating' && index < 3) return index + 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══ ANIMATED BACKGROUND ═══
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0a0a1a),
                      Color.lerp(
                        const Color(0xFF1a0f2e),
                        Colors.indigo.shade900,
                        _bgController.value,
                      )!,
                      const Color(0xFF0a0a1a),
                    ],
                    stops: [
                      0.0,
                      0.5 + (_bgController.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ═══ GLOW ORBS ═══
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 - (_bgController.value * 80),
                    right: -100,
                    child: _glowOrb(
                      300,
                      AppColors.accentGold.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    bottom: 200 + (_bgController.value * 50),
                    left: -100,
                    child: _glowOrb(
                      350,
                      Colors.purple.withOpacity(0.15),
                    ),
                  ),
                ],
              );
            },
          ),

          // ═══ MAIN CONTENT ═══
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, width),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _destinationsStream,
                    builder: (context, snapshot) {
                      // ⭐ HAKUNA LOADING — onyesha content mara moja
                      final destinations = snapshot.data ?? [];
                      final filtered = _filterAndSort(destinations);

                      // ⭐ Kama bado hakuna data na kuna error
                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error, width);
                      }

                      // ⭐ Kama hakuna destinations
                      if (destinations.isEmpty && snapshot.connectionState == ConnectionState.done) {
                        return _buildEmptyState(width, height);
                      }

                      // ⭐ Kama bado hakuna data — onyesha scroll view tupu
                      if (destinations.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return RefreshIndicator(
                        color: AppColors.accentGold,
                        backgroundColor: Colors.black,
                        onRefresh: () async {
                          await Future.delayed(
                              const Duration(milliseconds: 800));
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildStatsHeader(destinations, width),
                            ),
                            SliverToBoxAdapter(
                              child: _buildFilterChips(
                                  width, height, destinations),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: width * 0.04,
                                right: width * 0.04,
                                top: width * 0.02,
                                bottom: width * 0.1,
                              ),
                              sliver: _isGridView
                                  ? SliverGrid(
                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: width * 0.04,
                                  mainAxisSpacing: width * 0.03,
                                  childAspectRatio: 0.72,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                      (context, i) => _StaggeredCard(
                                    index: i,
                                    child: _CosmicFeaturedCard(
                                      dest: filtered[i],
                                      width: width,
                                      height: height,
                                      rank: _getRank(filtered, i),
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
                                  ),
                                  childCount: filtered.length,
                                ),
                              )
                                  : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                      (context, i) => _StaggeredCard(
                                    index: i,
                                    child: _CosmicListCard(
                                      dest: filtered[i],
                                      width: width,
                                      height: height,
                                      rank: _getRank(filtered, i),
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
                                  ),
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

  // ═══ GLOW ORB ═══
  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  // ═══ GLASS APP BAR (bila scroll listener) ═══
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.02,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
              vertical: width * 0.02,
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
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.accentGold,
                        Colors.orange.shade300,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Featured Destinations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isGridView = !_isGridView),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: _isGridView ? 0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ STATS ═══
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
          _cosmicStatCard(
            icon: Icons.place,
            value: '$total',
            label: 'Destinations',
            color: AppColors.accentGold,
            width: width,
          ),
          SizedBox(width: width * 0.03),
          _cosmicStatCard(
            icon: Icons.public,
            value: '${countries.length}',
            label: 'Countries',
            color: Colors.blueAccent,
            width: width,
          ),
          SizedBox(width: width * 0.03),
          _cosmicStatCard(
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

  Widget _cosmicStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required double width,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: width * 0.035,
              horizontal: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(width * 0.02),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: width * 0.05),
                ),
                SizedBox(height: width * 0.02),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.042,
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

  // ═══ FILTER CHIPS ═══
  Widget _buildFilterChips(double width, double height,
      List<Map<String, dynamic>> destinations) {
    final countries = _getCountries(destinations);
    return SizedBox(
      height: height * 0.06,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        itemCount: countries.length + 3,
        itemBuilder: (context, i) {
          if (i < 3) {
            final sorts = [
              {'key': 'recent', 'label': '🕐 Recent'},
              {'key': 'rating', 'label': '⭐ Top'},
              {'key': 'name', 'label': '🔤 A-Z'},
            ];
            final s = sorts[i];
            final active = _sortBy == s['key'];
            return _cosmicChip(
              label: s['label']!,
              active: active,
              onTap: () => setState(() => _sortBy = s['key']!),
              width: width,
            );
          }

          final countryIndex = i - 3;
          final country = countries[countryIndex];
          final active = _selectedCountry == country;
          return _cosmicChip(
            label: country == 'All' ? '🌍 All' : country,
            active: active,
            onTap: () => setState(() => _selectedCountry = country),
            width: width,
          );
        },
      ),
    );
  }

  Widget _cosmicChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
            colors: [
              AppColors.accentGold,
              Colors.orange.shade400,
            ],
          )
              : null,
          color: active ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 1,
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
              letterSpacing: active ? 0.5 : 0,
            ),
          ),
        ),
      ),
    );
  }

  // ═══ EMPTY ═══
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
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.explore_outlined,
                size: width * 0.15,
                color: AppColors.accentGold,
              ),
            ),
            SizedBox(height: height * 0.03),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.accentGold, Colors.orange.shade300],
              ).createShader(bounds),
              child: Text(
                'No Featured Destinations',
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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

  // ═══ ERROR ═══
  Widget _buildErrorState(Object? error, double width) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.15),
              ),
              child: Icon(Icons.error_outline,
                  color: Colors.redAccent, size: width * 0.12),
            ),
            SizedBox(height: width * 0.06),
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

// ═══════════════════════════════════════════════════════════
// COSMIC FEATURED CARD (Grid)
// ═══════════════════════════════════════════════════════════
class _CosmicFeaturedCard extends StatefulWidget {
  final Map<String, dynamic> dest;
  final double width;
  final double height;
  final int rank;
  final VoidCallback onTap;

  const _CosmicFeaturedCard({
    required this.dest,
    required this.width,
    required this.height,
    required this.rank,
    required this.onTap,
  });

  @override
  State<_CosmicFeaturedCard> createState() => _CosmicFeaturedCardState();
}

class _CosmicFeaturedCardState extends State<_CosmicFeaturedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dest = widget.dest;
    final width = widget.width;
    final imageUrl = (dest['imageUrl'] ?? '').toString();
    final rating = (dest['rating'] ?? 0) as num;
    final hasVideos = (dest['videos'] as List?)?.isNotEmpty ?? false;
    final videoCount = (dest['videos'] as List?)?.length ?? 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.accentGold.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFF0a0a1a),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentGold,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF0a0a1a),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white24,
                            size: 50,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: const Color(0xFF0a0a1a),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),

                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                              Colors.black.withOpacity(0.95),
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Rank badge
                    if (widget.rank > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.025,
                              vertical: width * 0.015,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.rank == 1
                                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                                    : widget.rank == 2
                                    ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                                    : [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${widget.rank}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: width * 0.03,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Featured badge
                    if (dest['featured'] == true && widget.rank == 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.025,
                              vertical: width * 0.012,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    size: width * 0.03, color: Colors.black),
                                SizedBox(width: width * 0.01),
                                Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: width * 0.022,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Video badge
                    if (hasVideos)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                              vertical: width * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_fill,
                                    size: 12, color: Colors.white),
                                SizedBox(width: width * 0.005),
                                Text(
                                  '$videoCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bottom info
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dest['name'] ?? 'Unnamed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.038,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: width * 0.01),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: width * 0.028,
                                      color: AppColors.accentGold),
                                  SizedBox(width: width * 0.01),
                                  Expanded(
                                    child: Text(
                                      dest['location'] ?? '',
                                      style: TextStyle(
                                        fontSize: width * 0.026,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: width * 0.015),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.02,
                                      vertical: width * 0.008,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star,
                                            size: width * 0.026,
                                            color: AppColors.accentGold),
                                        SizedBox(width: width * 0.005),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: width * 0.026,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.all(width * 0.012),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.goldGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: width * 0.03,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COSMIC LIST CARD
// ═══════════════════════════════════════════════════════════
class _CosmicListCard extends StatelessWidget {
  final Map<String, dynamic> dest;
  final double width;
  final double height;
  final int rank;
  final VoidCallback onTap;

  const _CosmicListCard({
    required this.dest,
    required this.width,
    required this.height,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (dest['imageUrl'] ?? '').toString();
    final rating = (dest['rating'] ?? 0) as num;
    final hasVideos = (dest['videos'] as List?)?.isNotEmpty ?? false;
    final videoCount = (dest['videos'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.accentGold.withOpacity(0.3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: width * 0.35,
                          height: width * 0.35,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.05),
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white24),
                            ),
                          )
                              : Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(Icons.image,
                                color: Colors.white24),
                          ),
                        ),
                        if (hasVideos)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.015,
                                  vertical: width * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_circle_fill,
                                        size: 10, color: Colors.white),
                                    SizedBox(width: width * 0.005),
                                    Text(
                                      '$videoCount',
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
                          ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.035),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dest['name'] ?? 'Unnamed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: width * 0.03,
                                    color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dest['location'] ?? '',
                                    style: TextStyle(
                                      fontSize: width * 0.028,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: width * 0.03,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.all(width * 0.015),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: width * 0.035,
                                    color: Colors.black,
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
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STAGGERED CARD
// ═══════════════════════════════════════════════════════════
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
  late Animation<double> _scaleAnimation;

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
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}