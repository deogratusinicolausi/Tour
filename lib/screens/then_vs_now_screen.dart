import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class ThenVsNowScreen extends StatefulWidget {
  const ThenVsNowScreen({super.key});

  @override
  State<ThenVsNowScreen> createState() => _ThenVsNowScreenState();
}

class _ThenVsNowScreenState extends State<ThenVsNowScreen> {
  final _service = MemoryService();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '⏳ Then vs Now',
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

                // Body
                Expanded(
                  child: StreamBuilder<List<MemoryModel>>(
                    stream: _service.getUserMemories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentGold),
                        );
                      }

                      final memories = snapshot.data ?? [];
                      final groups = _groupByLocation(memories);

                      // Filter only locations with 2+ years
                      final validGroups = groups.entries
                          .where((e) => e.value.length >= 2)
                          .toList();

                      if (validGroups.isEmpty) {
                        return _buildEmpty(width);
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: validGroups.length,
                        itemBuilder: (context, i) {
                          final entry = validGroups[i];
                          return _buildComparisonCard(
                              entry.key, entry.value, width);
                        },
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

  // ============================================================
  // GROUP BY LOCATION
  // ============================================================
  Map<String, List<MemoryModel>> _groupByLocation(
      List<MemoryModel> memories) {
    final map = <String, List<MemoryModel>>{};
    for (var m in memories) {
      if (m.location.isEmpty) continue;
      final key = m.location.toLowerCase().trim();
      map.putIfAbsent(key, () => []).add(m);
    }
    for (var v in map.values) {
      v.sort((a, b) =>
          (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
    }
    return map;
  }

  // ============================================================
  // COMPARISON CARD
  // ============================================================
  Widget _buildComparisonCard(
      String location, List<MemoryModel> memories, double width) {
    final first = memories.first;
    final last = memories.last;
    final firstDate = first.date ?? DateTime.now();
    final lastDate = last.date ?? DateTime.now();
    final yearDiff = lastDate.year - firstDate.year;

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location header
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: AppColors.accentGold, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  first.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (yearDiff > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$yearDiff years later',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Side-by-side
          Row(
            children: [
              Expanded(child: _buildSideCard(first, 'THEN')),
              const SizedBox(width: 8),
              Expanded(child: _buildSideCard(last, 'NOW')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideCard(MemoryModel m, String label) {
    final img = m.mediaUrls.isNotEmpty
        ? m.mediaUrls.first
        : m.thumbnailUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: label == 'NOW'
                    ? AppColors.accentGold
                    : Colors.white.withOpacity(0.15),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                    label == 'NOW' ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Image
              AspectRatio(
                aspectRatio: 1,
                child: img.isNotEmpty
                    ? Image.network(img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white54),
                    ))
                    : Container(
                  color: Colors.white10,
                  child: const Icon(Icons.image,
                      color: Colors.white30),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.date != null
                          ? DateFormat('MMM yyyy').format(m.date!)
                          : '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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

  Widget _buildEmpty(double width) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: width * 0.2,
                color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 20),
            const Text(
              'No past comparisons yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visit a place twice and add memories\nto see your THEN vs NOW',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}