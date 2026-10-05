import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class MemoryStatsScreen extends StatefulWidget {
  const MemoryStatsScreen({super.key});

  @override
  State<MemoryStatsScreen> createState() => _MemoryStatsScreenState();
}

class _MemoryStatsScreenState extends State<MemoryStatsScreen> {
  final _service = MemoryService();
  List<MemoryModel> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memories = await _service.getUserMemories().first;
    if (mounted) {
      setState(() {
        _memories = memories;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.85)),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(width * 0.04),
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
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '📈 Memory Stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentGold),
                    ),
                  )
                else if (_memories.isEmpty)
                  _buildEmpty(width)
                else
                  Expanded(
                    child: ListView(
                      padding:
                      EdgeInsets.all(width * 0.04),
                      children: [
                        _buildOverviewGrid(width),
                        const SizedBox(height: 20),
                        _buildYearChart(width),
                        const SizedBox(height: 20),
                        _buildTopList(
                          width,
                          '📍 Top Locations',
                          _topLocations(),
                          Icons.location_on,
                        ),
                        const SizedBox(height: 20),
                        _buildTopList(
                          width,
                          '🎯 Top Activities',
                          _topActivities(),
                          Icons.local_activity,
                        ),
                        const SizedBox(height: 20),
                        _buildStreakCard(width),
                        const SizedBox(height: 40),
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

  // ============================================================
  // OVERVIEW GRID
  // ============================================================
  Widget _buildOverviewGrid(double width) {
    int photos = 0, videos = 0, favorites = 0;
    final locations = <String>{};
    final countries = <String>{};

    for (var m in _memories) {
      for (var t in m.mediaTypes) {
        if (t == 'image') photos++;
        if (t == 'video') videos++;
      }
      if (m.favorite) favorites++;
      if (m.location.isNotEmpty) {
        locations.add(m.location);
        final parts = m.location.split(',');
        if (parts.length > 1) countries.add(parts.last.trim());
      }
    }

    final stats = [
      {'icon': '📸', 'value': '${_memories.length}', 'label': 'Memories'},
      {'icon': '🌍', 'value': '$countries', 'label': 'Countries'},
      {'icon': '📍', 'value': '$locations', 'label': 'Locations'},
      {'icon': '❤️', 'value': '$favorites', 'label': 'Favorites'},
      {'icon': '🖼️', 'value': '$photos', 'label': 'Photos'},
      {'icon': '🎥', 'value': '$videos', 'label': 'Videos'},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: width * 0.02,
      mainAxisSpacing: width * 0.02,
      childAspectRatio: 0.8,
      children: stats.map((s) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s['icon']!,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s['value']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s['label']!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // YEAR CHART
  // ============================================================
  Widget _buildYearChart(double width) {
    final byYear = <int, int>{};
    for (var m in _memories) {
      byYear[m.year] = (byYear[m.year] ?? 0) + 1;
    }
    final years = byYear.keys.toList()..sort();
    final maxCount = byYear.values.isEmpty
        ? 1
        : byYear.values.reduce((a, b) => a > b ? a : b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Memories per Year',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...years.map((y) {
                final count = byYear[y]!;
                final ratio = count / maxCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$y',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.08),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentGold
                                          .withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP LIST
  // ============================================================
  Widget _buildTopList(
      double width,
      String title,
      List<MapEntry<String, int>> items,
      IconData icon,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text(
                  'No data yet',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 13),
                )
              else
                ...items.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(icon,
                            color: AppColors.accentGold, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.value}',
                            style: const TextStyle(
                              color: AppColors.accentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STREAK
  // ============================================================
  Widget _buildStreakCard(double width) {
    final streak = _calculateStreak();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentGold.withOpacity(0.2),
                AppColors.accentGold.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.accentGold.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Travel Streak',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streak > 0
                          ? '$streak consecutive months with memories!'
                          : 'Add memories to build your streak',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  List<MapEntry<String, int>> _topLocations() {
    final map = <String, int>{};
    for (var m in _memories) {
      if (m.location.isNotEmpty) {
        map[m.location] = (map[m.location] ?? 0) + 1;
      }
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<MapEntry<String, int>> _topActivities() {
    final map = <String, int>{};
    for (var m in _memories) {
      if (m.activity.isNotEmpty) {
        map[m.activity] = (map[m.activity] ?? 0) + 1;
      }
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  int _calculateStreak() {
    final months = <String>{};
    for (var m in _memories) {
      if (m.date != null) {
        months.add('${m.date!.year}-${m.date!.month}');
      }
    }
    if (months.isEmpty) return 0;

    // Count consecutive months ending now
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 24; i++) {
      final d = DateTime(now.year, now.month - i);
      final key = '${d.year}-${d.month}';
      if (months.contains(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  Widget _buildEmpty(double width) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart,
                  size: width * 0.2,
                  color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 20),
              const Text(
                'No stats yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add memories to see your travel stats',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}