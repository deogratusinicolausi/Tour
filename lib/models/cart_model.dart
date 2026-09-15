import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String itemId;
  final String itemType; // hotel, tour, beach, mountain, culture, food, activity
  final String itemName;
  final String itemImage;
  final double price;
  final String currency;
  final int quantity;
  final int guests;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String notes;
  final DateTime addedAt;

  CartItem({
    required this.itemId,
    required this.itemType,
    required this.itemName,
    this.itemImage = '',
    required this.price,
    this.currency = 'USD',
    this.quantity = 1,
    this.guests = 1,
    this.checkIn,
    this.checkOut,
    this.notes = '',
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      quantity: map['quantity'] ?? 1,
      guests: map['guests'] ?? 1,
      checkIn: (map['checkIn'] as Timestamp?)?.toDate(),
      checkOut: (map['checkOut'] as Timestamp?)?.toDate(),
      notes: map['notes'] ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'itemName': itemName,
      'itemImage': itemImage,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'guests': guests,
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'notes': notes,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  double get totalPrice => price * quantity * guests;

  CartItem copyWith({
    int? quantity,
    int? guests,
    DateTime? checkIn,
    DateTime? checkOut,
    String? notes,
  }) {
    return CartItem(
      itemId: itemId,
      itemType: itemType,
      itemName: itemName,
      itemImage: itemImage,
      price: price,
      currency: currency,
      quantity: quantity ?? this.quantity,
      guests: guests ?? this.guests,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      notes: notes ?? this.notes,
      addedAt: addedAt,
    );
  }
}

class TripCartModel {
  final String userId;
  final List<CartItem> items;
  final String currency;
  final DateTime updatedAt;

  TripCartModel({
    required this.userId,
    this.items = const [],
    this.currency = 'USD',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory TripCartModel.fromMap(Map<String, dynamic> map) {
    return TripCartModel(
      userId: map['userId'] ?? '',
      items: (map['items'] as List?)
          ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      currency: map['currency'] ?? 'USD',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.length;
}