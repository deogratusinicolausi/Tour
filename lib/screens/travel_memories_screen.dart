import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';
import '../../widgets/memory_timeline_card.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';
import 'travel_passport_screen.dart';
import 'memory_replay_screen.dart';
import 'then_vs_now_screen.dart';
import 'auto_story_screen.dart';
import 'journey_map_screen.dart';
import 'travel_wrapped_screen.dart';
import 'memory_constellation_screen.dart';
import 'achievements_screen.dart';
import 'memory_stats_screen.dart';


class TravelMemoriesScreen extends StatefulWidget {
  const TravelMemoriesScreen({super.key});

  @override
  State<TravelMemoriesScreen> createState() => _TravelMemoriesScreenState();
}

class _TravelMemoriesScreenState extends State<TravelMemoriesScreen>
    with SingleTickerProviderStateMixin {
  final _service = MemoryService();
  late TabController _tabController;
  List<MemoryModel> _lastMemories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
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
          Container(color: Colors.black.withOpacity(0.75)),

          SafeArea(
            child: Column(
              children: [
                _buildGlassHeader(width),
                _buildTabBar(width),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMemoriesTab(width, height),
                      _buildFavoritesTab(width, height),
                      TravelPassportScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
          );
        },
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add_a_photo, color: Colors.black),
        label: const Text(
          'Add Memory',
          style:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS HEADER
  // ============================================================
  Widget _buildGlassHeader(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.03,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(width * 0.04),
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
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📸 Travel Memories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your journeys, your story',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.03,
                        ),
                      ),
                      // ⭐ Capsule counter
                      StreamBuilder<List<MemoryModel>>(
                        stream: _service.getUserMemories(),
                        builder: (context, snapshot) {
                          final memories = snapshot.data ?? [];
                          final locked = memories.where((m) => m.isCapsuleLocked).length;
                          if (locked == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '🔒 $locked locked capsule${locked > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Replay button
                StreamBuilder<List<MemoryModel>>(
                  stream: _service.getUserMemories(),
                  builder: (context, snapshot) {
                    final memories = snapshot.data ?? [];
                    if (memories.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryReplayScreen(
                              memories: memories,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow,
                                color: Colors.black, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Replay',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Menu Button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'wrapped':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TravelWrappedScreen(),
                          ),
                        );
                        break;
                      case 'constellation':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MemoryConstellationScreen(),
                          ),
                        );
                        break;
                      case 'achievements':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                        break;
                      case 'stats':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MemoryStatsScreen(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    _menuItem('wrapped', Icons.insights, '📊 Travel Wrapped'),
                    _menuItem(
                        'achievements', Icons.emoji_events, '🏆 Achievements'),
                    _menuItem('constellation', Icons.auto_awesome,
                        '🌌 Memory Constellation'),
                    _menuItem('stats', Icons.bar_chart, '📈 Memory Stats'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB BAR
  // ============================================================
  Widget _buildTabBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: '📸 Memories'),
                Tab(text: '❤️ Favorites'),
                Tab(text: '🪪 Passport'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEMORIES TAB
  // ============================================================
  Widget _buildMemoriesTab(double width, double height) {
    return StreamBuilder<List<MemoryModel>>(
      stream: _service.getUserMemories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        }

        final memories = snapshot.data ?? [];

        if (memories.isEmpty) {
          return _buildEmptyState(width, height);
        }

        final grouped = _service.groupByYear(memories);
        final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.04, vertical: width * 0.04),
          itemCount: years.length,
          itemBuilder: (context, yearIndex) {
            final year = years[yearIndex];
            final yearMemories = grouped[year]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year header
                Padding(
                  padding: EdgeInsets.symmetric(vertical: width * 0.03),
                  child: Row(
                    children: [
                      Text(
                        '$year',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: width * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${yearMemories.length} memories',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
                // Memories for this year
                ...yearMemories.map((m) => MemoryTimelineCard(
                  memory: m,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailScreen(memory: m),
                      ),
                    );
                  },
                  onFavorite: () async {
                    await _service.toggleFavorite(m.id, m.favorite);
                  },
                )),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FAVORITES TAB
  // ============================================================
  Widget _buildFavoritesTab(double width, double height) {
    return StreamBuilder<List<MemoryModel>>(
      stream: _service.getFavoriteMemories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(width * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      color: Colors.white.withOpacity(0.3),
                      size: width * 0.2),
                  SizedBox(height: height * 0.03),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap ❤️ on any memory to mark it as a favorite',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.04, vertical: width * 0.04),
          itemCount: favorites.length,
          itemBuilder: (context, i) => MemoryTimelineCard(
            memory: favorites[i],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryDetailScreen(memory: favorites[i]),
                ),
              );
            },
            onFavorite: () async {
              await _service.toggleFavorite(
                  favorites[i].id, favorites[i].favorite);
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.08),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(Icons.photo_camera,
                  color: Colors.black, size: width * 0.15),
            ),
            SizedBox(height: height * 0.04),
            const Text(
              'Your story starts here',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Capture your travel moments —\nphotos, videos, journals and locations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: height * 0.04),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddMemoryScreen()),
                );
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Create First Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}