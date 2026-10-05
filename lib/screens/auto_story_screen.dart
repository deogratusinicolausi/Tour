import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class AutoStoryScreen extends StatefulWidget {
  const AutoStoryScreen({super.key});

  @override
  State<AutoStoryScreen> createState() => _AutoStoryScreenState();
}

class _AutoStoryScreenState extends State<AutoStoryScreen> {
  final _service = MemoryService();
  String _story = '';
  bool _generating = true;

  @override
  void initState() {
    super.initState();
    _generateStory();
  }

  Future<void> _generateStory() async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 800));
    final memories = await _service.getUserMemories().first;

    if (!mounted) return;
    setState(() {
      _story = _buildStory(memories);
      _generating = false;
    });
  }

  // ============================================================
  // TEMPLATE-BASED STORY GENERATOR
  // ============================================================
  String _buildStory(List<MemoryModel> memories) {
    if (memories.isEmpty) return 'No memories yet. Start your journey!';

    // Sort chronologically
    final sorted = [...memories]
      ..sort((a, b) =>
          (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final buffer = StringBuffer();

    // Opening
    final firstDate = sorted.first.date ?? DateTime.now();
    final lastDate = sorted.last.date ?? DateTime.now();

    buffer.writeln('📖 MY JOURNEY\n');
    buffer.writeln(
        'From ${DateFormat('MMMM yyyy').format(firstDate)} to ${DateFormat('MMMM yyyy').format(lastDate)}, '
            'I created ${sorted.length} unforgettable memories across the world.\n');

    // Locations
    final locations = <String>{};
    for (var m in sorted) {
      if (m.location.isNotEmpty) locations.add(m.location);
    }
    if (locations.isNotEmpty) {
      buffer.writeln(
          'I explored ${locations.length} locations: ${locations.take(5).join(', ')}${locations.length > 5 ? ' and more' : ''}.\n');
    }

    // Activities
    final activities = <String>{};
    for (var m in sorted) {
      if (m.activity.isNotEmpty) activities.add(m.activity);
    }
    if (activities.isNotEmpty) {
      buffer.writeln(
          'My adventures included: ${activities.join(', ')}.\n');
    }

    // Favorite moments
    final favorites = sorted.where((m) => m.favorite).toList();
    if (favorites.isNotEmpty) {
      buffer.writeln('❤️ FAVORITE MOMENTS:\n');
      for (var f in favorites) {
        buffer.writeln('  • ${f.title}');
      }
      buffer.writeln();
    }

    // Highlights per year
    final byYear = <int, List<MemoryModel>>{};
    for (var m in sorted) {
      final y = m.year;
      byYear.putIfAbsent(y, () => []).add(m);
    }

    buffer.writeln('📅 YEAR BY YEAR:\n');
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    for (var y in years) {
      final mems = byYear[y]!;
      buffer.writeln('$y — ${mems.length} memories');
      for (var m in mems.take(3)) {
        buffer.writeln('  ✦ ${m.title}${m.location.isNotEmpty ? ' (${m.location})' : ''}');
      }
      buffer.writeln();
    }

    // Reflection
    buffer.writeln(
        'Looking back, every photo, every note, every place — they tell a story of a traveler who never stopped exploring. This is not just a collection of memories. This is my journey. 🌍');

    return buffer.toString();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _story));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Story copied!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

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
                          '📖 My Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_generating)
                        GestureDetector(
                          onTap: _copyToClipboard,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.copy,
                                color: Colors.black, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: _generating
                      ? _buildLoading(width)
                      : SingleChildScrollView(
                    padding:
                    EdgeInsets.all(width * 0.05),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding:
                          EdgeInsets.all(width * 0.06),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.3)),
                          ),
                          child: Text(
                            _story,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.black, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Writing your story...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.accentGold,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }
}