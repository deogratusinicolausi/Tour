import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get reviews for item
  Stream<List<ReviewModel>> getItemReviews(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get all user reviews
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get review stats for item
  Future<Map<String, dynamic>> getItemRatingStats(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'average': 0.0,
          'total': 0,
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
        };
      }

      double sum = 0;
      int star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0;

      for (var doc in snapshot.docs) {
        final rating = ((doc.data())['rating'] ?? 0.0) as num;
        sum += rating;
        final rounded = rating.round();
        switch (rounded) {
          case 5:
            star5++;
            break;
          case 4:
            star4++;
            break;
          case 3:
            star3++;
            break;
          case 2:
            star2++;
            break;
          default:
            star1++;
        }
      }

      return {
        'average': sum / snapshot.docs.length,
        'total': snapshot.docs.length,
        '5': star5,
        '4': star4,
        '3': star3,
        '2': star2,
        '1': star1,
      };
    } catch (e) {
      return {
        'average': 0.0,
        'total': 0,
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };
    }
  }

  // ⭐️ Check if user already reviewed
  Future<bool> hasUserReviewed(String userId, String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Add review
  Future<String?> addReview(ReviewModel review) async {
    try {
      final ref =
      await _firestore.collection('reviews').add(review.toMap());

      // Log activity for admin
      await _firestore.collection('activities').add({
        'type': 'review',
        'action': 'created',
        'title': 'New Review: ${review.itemName}',
        'description':
        '${review.userName} gave ${review.rating.toStringAsFixed(1)}⭐',
        'userId': review.userId,
        'userName': review.userName,
        'itemId': review.itemId,
        'itemType': review.itemType,
        'icon': '⭐',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add notification for admin
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': 'admin',
        'title': '⭐ New Review!',
        'body': '${review.userName} gave ${review.rating.toStringAsFixed(1)}⭐',
        'type': 'review',
        'category': 'info',
        'icon': '⭐',
        'actionType': '',
        'actionId': review.itemId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      }


      );
      // ⭐️ Send notification to admin
      await _firestore.collection('notifications').add({
        'userId': 'admin',
        'title': '⭐ New Review Posted!',
        'body': '${review.userName} gave ${review.rating.toStringAsFixed(1)}⭐ to ${review.itemName}',
        'type': 'review',
        'category': 'info',
        'icon': '⭐',
        'actionType': '',
        'actionId': ref.id,
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error adding review: $e');
      return null;
    }
  }

  // ⭐️ Update review
  Future<bool> updateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .update(review.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Mark review as helpful
  Future<bool> markHelpful(String reviewId, String userId) async {
    try {
      final docRef = _firestore.collection('reviews').doc(reviewId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final helpfulBy = List<String>.from(data['helpfulBy'] ?? []);

      if (helpfulBy.contains(userId)) {
        helpfulBy.remove(userId);
      } else {
        helpfulBy.add(userId);
      }

      await docRef.update({
        'helpfulBy': helpfulBy,
        'helpfulCount': helpfulBy.length,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Check if user marked helpful
  Future<bool> isMarkedHelpful(String reviewId, String userId) async {
    try {
      final doc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!doc.exists) return false;
      final helpfulBy = List<String>.from(doc.data()!['helpfulBy'] ?? []);
      return helpfulBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Check if user has booked (verified review)
  Future<String?> getVerifiedBooking(
      String userId, String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('bookingStatus', whereIn: ['confirmed', 'completed'])
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id;
    } catch (e) {
      return null;
    }
  }
}