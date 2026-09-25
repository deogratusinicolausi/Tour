import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ ===== DESTINATIONS =====

  Stream<List<Map<String, dynamic>>> getDestinations() {
    return _firestore
        .collection('destinations')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((d) => d['status'] == 'active' || d['status'] == null)
          .toList();

      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
  }

  // ⭐️ ===== HOTELS =====


  Stream<List<Map<String, dynamic>>> getHotelsOrdered() {
    return _firestore
        .collection('hotels')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((t) => t['status'] == 'active' || t['status'] == null)
          .toList();

      // Sort client-side
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          // Compare timestamps or dates
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
  }

  // ⭐️ BEACHES — kutoka admin
  Stream<List<Map<String, dynamic>>> getBeaches() {
    return _firestore
        .collection('beaches')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((b) => b['status'] == 'active' || b['status'] == null)
          .toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });
      return list;
    });
  }

// ⭐️ Single beach
  Future<Map<String, dynamic>?> getBeach(String id) async {
    try {
      final doc = await _firestore.collection('beaches').doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ⭐️ MOUNTAINS — kutoka admin
  Stream<List<Map<String, dynamic>>> getMountains() {
    return _firestore
        .collection('mountains')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((m) => m['status'] == 'active' || m['status'] == null)
          .toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });
      return list;
    });
  }

  // ⭐️ CULTURE — kutoka admin
  Stream<List<Map<String, dynamic>>> getCulture() {
    return _firestore
        .collection('culture')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((c) => c['status'] == 'active' || c['status'] == null)
          .toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });
      return list;
    });
  }


  // ⭐️ FOOD — kutoka admin
  Stream<List<Map<String, dynamic>>> getFood() {
    return _firestore
        .collection('food')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((f) => f['status'] == 'active' || f['status'] == null)
          .toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });
      return list;
    });
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


  // ⭐️ DEALS — kutoka admin
  Stream<List<Map<String, dynamic>>> getDeals() {
    return _firestore
        .collection('deals')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((d) => d['status'] == 'active' || d['status'] == null)
          .toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> getFeaturedDeals() {
    return _firestore
        .collection('deals')
        .where('featured', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((d) => d['status'] == 'active' || d['status'] == null)
        .toList());
  }

  // ⭐️ ===== ACTIVITIES =====

  Stream<List<Map<String, dynamic>>> getActivities() {
    return _firestore
        .collection('activities')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((a) => a['status'] == 'active' || a['status'] == null)
          .toList();

      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
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

  // ⭐️ HOTELS — Real-time kutoka admin
  Stream<List<Map<String, dynamic>>> getHotels() {
    return _firestore
        .collection('hotels')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((h) => h['status'] == 'active' || h['status'] == null)
          .toList();

      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;
        try {
          return (bDate as dynamic).compareTo(aDate as dynamic);
        } catch (e) {
          return 0;
        }
      });

      return list;
    });
  }

// ⭐️ Single hotel details
  Future<Map<String, dynamic>?> getHotel(String id) async {
    try {
      final doc = await _firestore.collection('hotels').doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('🔥 Error getting hotel: $e');
      return null;
    }
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