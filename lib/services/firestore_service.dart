import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ ===== DESTINATIONS =====

  Stream<List<Map<String, dynamic>>> getDestinations() {
    return _firestore
        .collection('destinations')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getFeaturedDestinations() {
    return _firestore
        .collection('destinations')
        .where('status', isEqualTo: 'active')
        .where('featured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getDestinationsByCountry(
      String country) {
    return _firestore
        .collection('destinations')
        .where('status', isEqualTo: 'active')
        .where('country', isEqualTo: country)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ⭐️ ===== HOTELS =====

  Stream<List<Map<String, dynamic>>> getHotels() {
    return _firestore
        .collection('hotels')
        .snapshots()
        .map((snapshot) {
      print('🔥 Hotels found: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getHotelsOrdered() {
    return _firestore
        .collection('hotels')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getFeaturedHotels() {
    return _firestore
        .collection('hotels')
        .where('featured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ⭐️ ===== TOURS =====

  Stream<List<Map<String, dynamic>>> getTours() {
    return _firestore
        .collection('tours')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getFeaturedTours() {
    return _firestore
        .collection('tours')
        .where('status', isEqualTo: 'active')
        .where('featured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ⭐️ ===== ACTIVITIES =====

  Stream<List<Map<String, dynamic>>> getActivities() {
    return _firestore
        .collection('activities')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ⭐️ ===== DEALS =====

  Stream<List<Map<String, dynamic>>> getDeals() {
    return _firestore
        .collection('deals')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getFeaturedDeals() {
    return _firestore
        .collection('deals')
        .where('status', isEqualTo: 'active')
        .where('featured', isEqualTo: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ⭐️ ===== SEARCH =====

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final q = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Search destinations
    final destSnapshot = await _firestore
        .collection('destinations')
        .where('status', isEqualTo: 'active')
        .get();
    for (var doc in destSnapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      if (name.contains(q)) {
        results.add({'id': doc.id, 'type': 'destination', ...data});
      }
    }

    // Search hotels
    final hotelSnapshot = await _firestore
        .collection('hotels')
        .where('status', isEqualTo: 'active')
        .get();
    for (var doc in hotelSnapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      if (name.contains(q)) {
        results.add({'id': doc.id, 'type': 'hotel', ...data});
      }
    }

    // Search tours
    final tourSnapshot = await _firestore
        .collection('tours')
        .where('status', isEqualTo: 'active')
        .get();
    for (var doc in tourSnapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      if (name.contains(q)) {
        results.add({'id': doc.id, 'type': 'tour', ...data});
      }
    }

    return results;
  }
  Future<Map<String, int>> getBookingStats() async {
    try {
      final all = await _firestore.collection('bookings').get();
      int pending = 0;
      int confirmed = 0;
      int cancelled = 0;
      int completed = 0;
      double revenue = 0;

      for (var doc in all.docs) {
        final data = doc.data();
        final status = data['bookingStatus'] ?? 'pending';
        final amount = (data['amount'] ?? 0.0).toDouble();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            revenue += amount;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'completed':
            completed++;
            revenue += amount;
            break;
        }
      }

      return {
        'total': all.docs.length,
        'pending': pending,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'completed': completed,
        'revenue': revenue.toInt(),
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'cancelled': 0,
        'completed': 0,
        'revenue': 0,
      };
    }
  }
}