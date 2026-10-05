import '../models/memory_model.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final int current;
  final int target;
  final double progress;

  Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.current,
    required this.target,
  }) : progress = target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

class AchievementService {
  // ============================================================
  // COMPUTE ALL ACHIEVEMENTS
  // ============================================================
  List<Achievement> computeAchievements(List<MemoryModel> memories) {
    // Country detection
    final countries = <String>{};
    final locations = <String>{};
    final activities = <String>{};
    int photos = 0;
    int videos = 0;
    int journals = 0;
    int favorites = 0;
    int safaris = 0;
    int mountains = 0;

    for (var m in memories) {
      if (m.location.isNotEmpty) {
        locations.add(m.location.toLowerCase());
        final parts = m.location.split(',');
        if (parts.length > 1) {
          countries.add(parts.last.trim().toLowerCase());
        }
      }
      if (m.activity.isNotEmpty) {
        activities.add(m.activity.toLowerCase());
        if (m.activity.toLowerCase().contains('safari')) safaris++;
        if (m.activity.toLowerCase().contains('trek') ||
            m.activity.toLowerCase().contains('hiking') ||
            m.activity.toLowerCase().contains('mountain')) {
          mountains++;
        }
      }
      for (var t in m.mediaTypes) {
        if (t == 'image') photos++;
        if (t == 'video') videos++;
      }
      if (m.note.isNotEmpty) journals++;
      if (m.favorite) favorites++;
    }

    final streak = _calculateStreak(memories);

    return [
      Achievement(
        id: 'first_star',
        emoji: '🌟',
        title: 'First Star',
        description: 'Create your first memory',
        unlocked: memories.isNotEmpty,
        current: memories.isEmpty ? 0 : 1,
        target: 1,
      ),
      Achievement(
        id: 'globetrotter',
        emoji: '🌍',
        title: 'Globetrotter',
        description: 'Visit 3 different countries',
        unlocked: countries.length >= 3,
        current: countries.length,
        target: 3,
      ),
      Achievement(
        id: 'explorer',
        emoji: '🎯',
        title: 'Explorer',
        description: 'Record 10 different locations',
        unlocked: locations.length >= 10,
        current: locations.length,
        target: 10,
      ),
      Achievement(
        id: 'safari_master',
        emoji: '🦁',
        title: 'Safari Master',
        description: 'Record 5 safari memories',
        unlocked: safaris >= 5,
        current: safaris,
        target: 5,
      ),
      Achievement(
        id: 'peak_bagger',
        emoji: '🏔️',
        title: 'Peak Bagger',
        description: 'Record a mountain or trek',
        unlocked: mountains >= 1,
        current: mountains,
        target: 1,
      ),
      Achievement(
        id: 'photographer',
        emoji: '📸',
        title: 'Photographer',
        description: 'Upload 50 photos',
        unlocked: photos >= 50,
        current: photos,
        target: 50,
      ),
      Achievement(
        id: 'cinematographer',
        emoji: '🎥',
        title: 'Cinematographer',
        description: 'Upload 10 videos',
        unlocked: videos >= 10,
        current: videos,
        target: 10,
      ),
      Achievement(
        id: 'storyteller',
        emoji: '✍️',
        title: 'Storyteller',
        description: 'Write 10 journal notes',
        unlocked: journals >= 10,
        current: journals,
        target: 10,
      ),
      Achievement(
        id: 'sentimental',
        emoji: '❤️',
        title: 'Sentimental',
        description: 'Mark 5 memories as favorites',
        unlocked: favorites >= 5,
        current: favorites,
        target: 5,
      ),
      Achievement(
        id: 'streak_master',
        emoji: '🔥',
        title: 'Streak Master',
        description: '3 consecutive months with memories',
        unlocked: streak >= 3,
        current: streak,
        target: 3,
      ),
      Achievement(
        id: 'collector',
        emoji: '💎',
        title: 'Collector',
        description: 'Create 25 memories',
        unlocked: memories.length >= 25,
        current: memories.length,
        target: 25,
      ),
      Achievement(
        id: 'legend',
        emoji: '👑',
        title: 'Travel Legend',
        description: 'Create 100 memories',
        unlocked: memories.length >= 100,
        current: memories.length,
        target: 100,
      ),
    ];
  }

  int _calculateStreak(List<MemoryModel> memories) {
    final months = <String>{};
    for (var m in memories) {
      if (m.date != null) {
        months.add('${m.date!.year}-${m.date!.month}');
      }
    }
    if (months.isEmpty) return 0;

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
}