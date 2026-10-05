import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/memory_model.dart';
import '../../utils/colors.dart';

class MemoryReplayScreen extends StatefulWidget {
  final List<MemoryModel> memories;

  const MemoryReplayScreen({super.key, required this.memories});

  @override
  State<MemoryReplayScreen> createState() => _MemoryReplayScreenState();
}

class _MemoryReplayScreenState extends State<MemoryReplayScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Sort memories chronologically
    final sorted = [...widget.memories]
      ..sort((a, b) => (a.date ?? DateTime.now())
          .compareTo(b.date ?? DateTime.now()));

    if (sorted.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No memories to replay',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════════
          // ⭐ MAIN CAROUSEL — Slideshow of memories
          // ═══════════════════════════════════════════
          PageView.builder(
            controller: _pageController,
            itemCount: sorted.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              final m = sorted[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // ⭐ IMAGE SLIDER PREVIEW (auto-slide within this memory)
                  if (m.mediaUrls.isNotEmpty)
                    PageView.builder(
                      itemCount: m.mediaUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          m.mediaUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.broken_image, color: Colors.white24),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                          size: 80,
                        ),
                      ),
                    ),

                  // ⭐ Gradient overlay for readability
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.95),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ═══════════════════════════════════════════
          // TOP BAR (close + counter)
          // ═══════════════════════════════════════════
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      '🎬 ${_currentIndex + 1} / ${sorted.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // BOTTOM INFO CARD
          // ═══════════════════════════════════════════
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: false,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Day label
                      Text(
                        'DAY ${_currentIndex + 1}',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        sorted[_currentIndex].title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Location
                      if (sorted[_currentIndex].location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.accentGold,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sorted[_currentIndex].location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      // Date + media count
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white54,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sorted[_currentIndex].formattedDate,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (sorted[_currentIndex].mediaUrls.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.photo_library,
                                    color: Colors.white54,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${sorted[_currentIndex].mediaUrls.length} photos',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Description
                      if (sorted[_currentIndex].description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          sorted[_currentIndex].description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ⭐ PROGRESS BAR
                      Row(
                        children:
                        List.generate(sorted.length, (i) {
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              decoration: BoxDecoration(
                                color: i <= _currentIndex
                                    ? AppColors.accentGold
                                    : Colors.white24,
                                borderRadius:
                                BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Swipe hint
                      Center(
                        child: Text(
                          _currentIndex == sorted.length - 1
                              ? '🎉 End of journey'
                              : '👆 Swipe to continue',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}