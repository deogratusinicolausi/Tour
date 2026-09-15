import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get user's cart (Real-time)
  Stream<TripCartModel?> getCart(String userId) {
    return _firestore
        .collection('tripCarts')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TripCartModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ⭐️ Add item to cart
  Future<bool> addToCart(String userId, CartItem item) async {
    try {
      final docRef = _firestore.collection('tripCarts').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new cart
        await docRef.set({
          'userId': userId,
          'items': [item.toMap()],
          'currency': item.currency,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add to existing cart
        final data = doc.data()!;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        // Check if item already exists
        final existingIndex = items.indexWhere(
              (e) => e['itemId'] == item.itemId && e['itemType'] == item.itemType,
        );

        if (existingIndex >= 0) {
          // Update quantity
          items[existingIndex]['quantity'] =
              (items[existingIndex]['quantity'] ?? 1) + 1;
        } else {
          items.add(item.toMap());
        }

        await docRef.update({
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // ⭐️ Log activity for admin
      await _logCartActivity(userId, item, 'added');

      return true;
    } catch (e) {
      print('🔥 Error adding to cart: $e');
      return false;
    }
  }

  // ⭐️ Remove item from cart
  Future<bool> removeFromCart(String userId, String itemId) async {
    try {
      final docRef = _firestore.collection('tripCarts').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      items.removeWhere((e) => e['itemId'] == itemId);

      await docRef.update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 Error removing from cart: $e');
      return false;
    }
  }

  // ⭐️ Update quantity
  Future<bool> updateQuantity(
      String userId, String itemId, int quantity) async {
    try {
      final docRef = _firestore.collection('tripCarts').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

      final index = items.indexWhere((e) => e['itemId'] == itemId);
      if (index >= 0) {
        items[index]['quantity'] = quantity;
        await docRef.update({
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Clear cart
  Future<bool> clearCart(String userId) async {
    try {
      await _firestore.collection('tripCarts').doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Check if item is in cart
  Future<bool> isInCart(String userId, String itemId) async {
    try {
      final doc = await _firestore.collection('tripCarts').doc(userId).get();
      if (!doc.exists) return false;
      final items = (doc.data()!['items'] as List?) ?? [];
      return items.any((e) => e['itemId'] == itemId);
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Log activity for admin
  Future<void> _logCartActivity(
      String userId, CartItem item, String action) async {
    try {
      final userDoc =
      await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'User';

      await _firestore.collection('activities').add({
        'type': 'cart',
        'action': action,
        'title': 'Cart: ${item.itemName}',
        'description': '$userName $action ${item.itemName} to cart',
        'userId': userId,
        'userName': userName,
        'itemId': item.itemId,
        'itemType': item.itemType,
        'icon': '🛒',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error logging cart activity: $e');
    }
  }
}