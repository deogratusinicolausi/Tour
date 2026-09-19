import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Create trip
  Future<String?> createTrip(TripModel trip) async {
    try {
      final ref = await _firestore.collection('trips').add(trip.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error creating trip: $e');
      return null;
    }
  }

  // ⭐️ Get user trips
  Stream<List<TripModel>> getUserTrips(String userId) {
    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get single trip
  Future<TripModel?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (!doc.exists) return null;
      return TripModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ⭐️ Update trip
  Future<bool> updateTrip(TripModel trip) async {
    try {
      await _firestore
          .collection('trips')
          .doc(trip.id)
          .update(trip.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Calculate trip budget
  double calculateTripBudget(TripModel trip) {
    return trip.days.fold(0.0, (sum, day) => sum + day.dayBudget);
  }
}