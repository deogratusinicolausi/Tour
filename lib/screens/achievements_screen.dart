import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../services/achievement_service.dart';
import '../../utils/colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _service = MemoryService();
  final _achievements = AchievementService();
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
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏆 Achievements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your travel milestones',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12),
                            ),
                          ],
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
                else
                  Expanded(child: _buildBody(width)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double width) {
    final all = _achievements.computeAchievements(_memories);
    final unlocked = all.where((a) => a.unlocked).toList();
    final locked = all.where((a) => !a.unlocked).toList();

    return ListView(
      padding: EdgeInsets.all(width * 0.04),
      children: [
        // Summary
        _buildSummary(width, unlocked.length, all.length),
        const SizedBox(height: 24),

        // Unlocked section
        if (unlocked.isNotEmpty) ...[
          _sectionHeader(
              '⭐ Unlocked (${unlocked.length})', width),
          const SizedBox(height: 12),
          ...unlocked.map((a) => _buildBadge(a, width)),
          const SizedBox(height: 24),
        ],

        // Locked section
        if (locked.isNotEmpty) ...[
          _sectionHeader(
              '🔒 In Progress (${locked.length})', width),
          const SizedBox(height: 12),
          ...locked.map((a) => _buildBadge(a, width)),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSummary(double width, int unlocked, int total) {
    final ratio = total == 0 ? 0.0 : unlocked / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(width * 0.06),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentGold.withOpacity(0.2),
                AppColors.accentGold.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.accentGold.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$unlocked',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: width * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / $total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.08,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Achievements Unlocked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.accentGold.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.01),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBadge(Achievement a, double width) {
    final isUnlocked = a.unlocked;
    final pct = (a.progress * 100).toStringAsFixed(0);

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.accentGold.withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? AppColors.accentGold.withOpacity(0.7)
                    : Colors.white.withOpacity(0.2),
                width: isUnlocked ? 1.5 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                BoxShadow(
                  color:
                  AppColors.accentGold.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ]
                  : [],
            ),
            child: Row(
              children: [
                // Emoji badge
                Container(
                  width: width * 0.15,
                  height: width * 0.15,
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? AppColors.goldGradient
                        : null,
                    color: isUnlocked
                        ? null
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: isUnlocked
                        ? [
                      BoxShadow(
                        color: AppColors.accentGold
                            .withOpacity(0.6),
                        blurRadius: 15,
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      a.emoji,
                      style: TextStyle(
                        fontSize: width * 0.07,
                        color:
                        isUnlocked ? null : Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.title,
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(Icons.check_circle,
                                color: AppColors.accentGold,
                                size: 18),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: a.progress,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGold,
                                        borderRadius:
                                        BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${a.current}/${a.target} ($pct%)',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}