import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Universal search across all collections
  Future<List<Map<String, dynamic>>> universalSearch(
      String query, {
        String category = 'all',
        double minPrice = 0,
        double maxPrice = 100000,
        double minRating = 0,
        String location = '',
        String sortBy = 'relevance',
      }) async {
    try {
      final q = query.toLowerCase().trim();
      final List<Map<String, dynamic>> results = [];

      // Collections za kutafuta
      final collections = category == 'all'
          ? ['hotels', 'tours', 'beaches', 'mountains', 'culture', 'food', 'destinations', 'deals']
          : [category];

      for (var collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('status', isEqualTo: 'active')
            .limit(50)
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final name = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
          final desc = (data['description'] ?? '').toString().toLowerCase();
          final loc = (data['location'] ?? data['country'] ?? '').toString().toLowerCase();

          // Filter by search query
          final matchesQuery = q.isEmpty ||
              name.contains(q) ||
              desc.contains(q) ||
              loc.contains(q);

          if (!matchesQuery) continue;

          // Get price
          final price = (data['price'] ?? data['priceFrom'] ?? data['salePrice'] ?? 0).toDouble();

          // Filter by price
          if (price > 0 && (price < minPrice || price > maxPrice)) continue;

          // Filter by rating
          final rating = (data['rating'] ?? 0).toDouble();
          if (rating < minRating) continue;

          // Filter by location
          if (location.isNotEmpty && !loc.contains(location.toLowerCase())) continue;

          results.add({
            'id': doc.id,
            'type': collection,
            'name': data['name'] ?? data['title'] ?? 'Unnamed',
            'description': data['description'] ?? '',
            'imageUrl': data['imageUrl'] ?? (data['images'] as List?)?.first ?? '',
            'price': price,
            'currency': data['currency'] ?? 'USD',
            'rating': rating,
            'location': data['location'] ?? data['country'] ?? '',
            'featured': data['featured'] ?? false,
          });
        }
      }

      // Sort results
      switch (sortBy) {
        case 'price_low':
          results.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
          break;
        case 'price_high':
          results.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
          break;
        case 'rating':
          results.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
          break;
        case 'name':
          results.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
          break;
        default:
        // Featured first
          results.sort((a, b) {
            if (a['featured'] == true && b['featured'] != true) return -1;
            if (a['featured'] != true && b['featured'] == true) return 1;
            return 0;
          });
      }

      return results;
    } catch (e) {
      print('🔥 Error in universal search: $e');
      return [];
    }
  }

  // ⭐️ Get search suggestions (auto-complete)
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final q = query.toLowerCase();
      final Set<String> suggestions = {};

      final collections = ['hotels', 'tours', 'beaches', 'mountains', 'culture', 'food'];

      for (var collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('status', isEqualTo: 'active')
            .limit(10)
            .get();

        for (var doc in snapshot.docs) {
          final name = (doc.data()['name'] ?? '').toString();
          if (name.toLowerCase().contains(q)) {
            suggestions.add(name);
          }
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Get trending searches (most booked items)
  Future<List<String>> getTrendingSearches() async {
    try {
      final Set<String> trending = {};

      final collections = ['hotels', 'tours', 'beaches'];
      for (var collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('featured', isEqualTo: true)
            .limit(5)
            .get();

        for (var doc in snapshot.docs) {
          final name = (doc.data()['name'] ?? '').toString();
          if (name.isNotEmpty) trending.add(name);
        }
      }

      return trending.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Get popular locations
  Future<List<String>> getPopularLocations() async {
    try {
      final Set<String> locations = {};

      final snapshot = await _firestore
          .collection('destinations')
          .where('status', isEqualTo: 'active')
          .limit(20)
          .get();

      for (var doc in snapshot.docs) {
        final loc = (doc.data()['location'] ?? doc.data()['country'] ?? '').toString();
        if (loc.isNotEmpty) locations.add(loc);
      }

      return locations.take(8).toList();
    } catch (e) {
      return [];
    }
  }
}