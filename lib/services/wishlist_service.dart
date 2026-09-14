import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> addToWishlist({
    required String userId,
    required String itemId,
    required String itemType,
    required String itemName,
    required String itemImage,
    required double price,
    required String currency,
  }) async {
    try {
      final existing = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.delete();
        return false;
      }

      await _firestore.collection('wishlists').add({
        'userId': userId,
        'itemId': itemId,
        'itemType': itemType,
        'itemName': itemName,
        'itemImage': itemImage,
        'price': price,
        'currency': currency,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 Error wishlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String userId, String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLiked(String userId, String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserWishlist(String userId) {
    return _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      list.sort((a, b) {
        final aDate =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bDate =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }
}