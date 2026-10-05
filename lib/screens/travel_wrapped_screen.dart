import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class TravelWrappedScreen extends StatefulWidget {
  const TravelWrappedScreen({super.key});

  @override
  State<TravelWrappedScreen> createState() => _TravelWrappedScreenState();
}

class _TravelWrappedScreenState extends State<TravelWrappedScreen> {
  final _service = MemoryService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> _slides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memories = await _service.getUserMemories().first;
    if (!mounted) return;

    final currentYear = DateTime.now().year;
    final yearMemories =
    memories.where((m) => m.year == currentYear).toList();

    // If no memories this year, use all
    final targetMemories =
    yearMemories.isNotEmpty ? yearMemories : memories;

    setState(() {
      _slides = _buildSlides(targetMemories, currentYear);
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _buildSlides(
      List<MemoryModel> memories, int year) {
    if (memories.isEmpty) {
      return [
        {
          'type': 'empty',
          'title': 'No memories yet',
          'subtitle': 'Start your journey to see your Wrapped',
        }
      ];
    }

    final slides = <Map<String, dynamic>>[];

    // Slide 1 — Opening
    slides.add({
      'type': 'opening',
      'year': year,
    });

    // Slide 2 — Total memories
    slides.add({
      'type': 'count',
      'value': memories.length,
      'label': 'memories created',
    });

    // Slide 3 — Locations
    final locations = <String>{};
    for (var m in memories) {
      if (m.location.isNotEmpty) locations.add(m.location);
    }
    if (locations.isNotEmpty) {
      slides.add({
        'type': 'list',
        'title': 'Places you explored',
        'items': locations.take(6).toList(),
        'emoji': '📍',
      });
    }

    // Slide 4 — Activities
    final activities = <String>{};
    for (var m in memories) {
      if (m.activity.isNotEmpty) activities.add(m.activity);
    }
    if (activities.isNotEmpty) {
      slides.add({
        'type': 'list',
        'title': 'Your adventures',
        'items': activities.take(6).toList(),
        'emoji': '🎯',
      });
    }

    // Slide 5 — Photos count
    int photos = 0;
    int videos = 0;
    for (var m in memories) {
      for (var t in m.mediaTypes) {
        if (t == 'image') photos++;
        if (t == 'video') videos++;
      }
    }
    if (photos > 0 || videos > 0) {
      slides.add({
        'type': 'media',
        'photos': photos,
        'videos': videos,
      });
    }

    // Slide 6 — Favorites
    final favorites = memories.where((m) => m.favorite).toList();
    if (favorites.isNotEmpty) {
      slides.add({
        'type': 'favorites',
        'count': favorites.length,
        'highlight': favorites.first.title,
      });
    }

    // Slide 7 — Most active month
    final monthCount = <int, int>{};
    for (var m in memories) {
      if (m.date != null) {
        monthCount[m.date!.month] = (monthCount[m.date!.month] ?? 0) + 1;
      }
    }
    if (monthCount.isNotEmpty) {
      final topMonth = monthCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final monthName =
      DateFormat('MMMM').format(DateTime(2000, topMonth));
      slides.add({
        'type': 'top_month',
        'month': monthName,
        'count': monthCount[topMonth],
      });
    }

    // Slide 8 — Closing
    slides.add({
      'type': 'closing',
      'year': year,
    });

    return slides;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child:
          CircularProgressIndicator(color: AppColors.accentGold),
        ),
      );
    }

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

          // Slides
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, i) => _buildSlide(_slides[i]),
          ),

          // Progress bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                _slides.length,
                    (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? AppColors.accentGold
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    final width = MediaQuery.of(context).size.width;

    switch (slide['type']) {
      case 'opening':
        return _centerSlide(
          width,
          [
            Text(
              '${slide['year']}',
              style: TextStyle(
                fontSize: width * 0.3,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
                height: 1,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TRAVEL WRAPPED',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your journey in review',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        );

      case 'count':
        return _centerSlide(
          width,
          [
            Text(
              '${slide['value']}',
              style: TextStyle(
                fontSize: width * 0.35,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide['label'],
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case 'list':
        return _centerSlide(
          width,
          [
            Text(
              slide['emoji'],
              style: TextStyle(fontSize: width * 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              slide['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            ...(slide['items'] as List).map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.5)),
                  ),
                  child: Text(
                    item.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        );

      case 'media':
        return _centerSlide(
          width,
          [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bigStat(
                    width, '📸', slide['photos'], 'Photos'),
                const SizedBox(width: 30),
                _bigStat(
                    width, '🎥', slide['videos'], 'Videos'),
              ],
            ),
          ],
        );

      case 'favorites':
        return _centerSlide(
          width,
          [
            const Text('❤️', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              '${slide['count']}',
              style: TextStyle(
                fontSize: width * 0.3,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'favorite memories',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'MOST CHERISHED',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slide['highlight'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'top_month':
        return _centerSlide(
          width,
          [
            const Text('🌟', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              'You traveled most in',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              slide['month'] ?? '',
              style: TextStyle(
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${slide['count']} memories',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        );

      case 'closing':
        return _centerSlide(
          width,
          [
            const Text('🌍', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text(
              'That was your',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${slide['year']}',
              style: TextStyle(
                fontSize: width * 0.2,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Keep exploring.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case 'empty':
      default:
        return _centerSlide(
          width,
          [
            const Text('📸', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              slide['title'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide['subtitle'] ?? '',
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        );
    }
  }

  Widget _centerSlide(double width, List<Widget> children) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _bigStat(
      double width, String emoji, int value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 10),
        Text(
          '$value',
          style: TextStyle(
            fontSize: width * 0.15,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}