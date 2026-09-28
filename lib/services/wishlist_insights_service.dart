import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistInsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 1. POPULARITY MAP — {itemId: likes count}
  // ============================================================
  Future<Map<String, int>> getPopularityMap() async {
    try {
      final snapshot = await _firestore.collection('wishlists').get();
      final map = <String, int>{};

      for (var doc in snapshot.docs) {
        final itemId = (doc.data()['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;
        map[itemId] = (map[itemId] ?? 0) + 1;
      }

      return map;
    } catch (e) {
      print('🔥 Error getting popularity: $e');
      return {};
    }
  }

  // ============================================================
  // 2. TRENDING ITEMS — most liked this week
  // ============================================================
  Future<List<Map<String, dynamic>>> getTrendingItems({
    int limit = 10,
    int days = 7,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('wishlists')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      // Group by itemId
      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': data['itemType'] ?? '',
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      // Sort by likes desc
      final list = grouped.values.toList()
        ..sort((a, b) =>
            (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    } catch (e) {
      print('🔥 Error getting trending: $e');
      return [];
    }
  }

  // ============================================================
  // 3. USER TASTE PROFILE — categories breakdown
  // ============================================================
  Future<Map<String, double>> getUserTasteProfile(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return {};

      final counts = <String, int>{};
      for (var doc in snapshot.docs) {
        final type = (doc.data()['itemType'] ?? '').toString();
        if (type.isEmpty) continue;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      final total = counts.values.fold<int>(0, (a, b) => a + b);
      if (total == 0) return {};

      // Convert to percentage
      final profile = <String, double>{};
      counts.forEach((type, count) {
        profile[type] = (count / total) * 100;
      });

      return profile;
    } catch (e) {
      print('🔥 Error getting taste profile: $e');
      return {};
    }
  }

  // ============================================================
  // 4. RECOMMENDATIONS — items you haven't liked but are popular
  // ============================================================
  Future<List<Map<String, dynamic>>> getRecommendations(
      String userId, {
        int limit = 5,
      }) async {
    try {
      // Get user's wishlist
      final userSnapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();

      final userItemIds = userSnapshot.docs
          .map((d) => (d.data()['itemId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      // Get user's preferred types
      final userTypes = userSnapshot.docs
          .map((d) => (d.data()['itemType'] ?? '').toString())
          .where((t) => t.isNotEmpty)
          .toSet();

      if (userTypes.isEmpty) return [];

      // Get all wishlists
      final allSnapshot = await _firestore.collection('wishlists').get();

      // Group by itemId, filter by type + exclude user's items
      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in allSnapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        final itemType = (data['itemType'] ?? '').toString();

        if (itemId.isEmpty) continue;
        if (userItemIds.contains(itemId)) continue;
        if (!userTypes.contains(itemType)) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': itemType,
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      // Sort by likes desc
      final list = grouped.values.toList()
        ..sort((a, b) =>
            (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    } catch (e) {
      print('🔥 Error getting recommendations: $e');
      return [];
    }
  }

  // ============================================================
  // 5. POPULARITY RANK — "#3 of 50"
  // ============================================================
  Future<Map<String, dynamic>?> getPopularityRank(String itemId) async {
    try {
      final map = await getPopularityMap();
      if (map.isEmpty) return null;

      // Sort by count desc
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final rank = entries.indexWhere((e) => e.key == itemId);
      if (rank == -1) return null;

      return {
        'rank': rank + 1,
        'total': entries.length,
        'likes': entries[rank].value,
      };
    } catch (e) {
      print('🔥 Error getting rank: $e');
      return null;
    }
  }

  // ============================================================
  // BONUS: POPULARITY BADGE — text based on likes
  // ============================================================
  String getPopularityBadge(int likes) {
    if (likes >= 100) return '🔥🔥🔥 SUPER HOT';
    if (likes >= 50) return '🔥🔥 Trending';
    if (likes >= 20) return '🔥 Popular';
    if (likes >= 5) return '⭐ Rising';
    return '';
  }

  // ============================================================
  // BONUS: TASTE ICON — for each type
  // ============================================================
  String getTypeIcon(String type) {
    switch (type) {
      case 'destination':
        return '📍';
      case 'hotel':
        return '🏨';
      case 'tour':
        return '🦁';
      case 'mountain':
        return '⛰️';
      case 'beach':
        return '🏖️';
      case 'culture':
        return '🎭';
      case 'food':
        return '🍛';
      default:
        return '❤️';
    }
  }
}