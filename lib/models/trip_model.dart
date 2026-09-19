import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String coverImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalDays;
  final int totalTravelers;
  final double totalBudget;
  final String currency;
  final List<TripDay> days;
  final String status; // planning, confirmed, completed, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    this.description = '',
    this.coverImage = '',
    this.startDate,
    this.endDate,
    this.totalDays = 1,
    this.totalTravelers = 1,
    this.totalBudget = 0.0,
    this.currency = 'USD',
    this.days = const [],
    this.status = 'planning',
    this.createdAt,
    this.updatedAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      coverImage: map['coverImage'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      totalDays: map['totalDays'] ?? 1,
      totalTravelers: map['totalTravelers'] ?? 1,
      totalBudget: (map['totalBudget'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      days: (map['days'] as List?)
          ?.map((e) => TripDay.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      status: map['status'] ?? 'planning',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'totalDays': totalDays,
      'totalTravelers': totalTravelers,
      'totalBudget': totalBudget,
      'currency': currency,
      'days': days.map((d) => d.toMap()).toList(),
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get dateRange {
    if (startDate == null || endDate == null) return 'Dates not set';
    final start = '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    final end = '${endDate!.day}/${endDate!.month}/${endDate!.year}';
    return '$start - $end';
  }
}

class TripDay {
  final int dayNumber;
  final String title;
  final String notes;
  final List<TripItem> items;

  TripDay({
    required this.dayNumber,
    this.title = '',
    this.notes = '',
    this.items = const [],
  });

  factory TripDay.fromMap(Map<String, dynamic> map) {
    return TripDay(
      dayNumber: map['dayNumber'] ?? 1,
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      items: (map['items'] as List?)
          ?.map((e) => TripItem.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'notes': notes,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  double get dayBudget => items.fold(0.0, (sum, item) => sum + item.price);
}

class TripItem {
  final String itemId;
  final String itemType; // hotel, tour, beach, mountain, culture, food
  final String itemName;
  final String itemImage;
  final String time; // "09:00 AM"
  final double price;
  final String currency;
  final String notes;

  TripItem({
    required this.itemId,
    required this.itemType,
    required this.itemName,
    this.itemImage = '',
    this.time = '',
    this.price = 0.0,
    this.currency = 'USD',
    this.notes = '',
  });

  factory TripItem.fromMap(Map<String, dynamic> map) {
    return TripItem(
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      time: map['time'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'itemName': itemName,
      'itemImage': itemImage,
      'time': time,
      'price': price,
      'currency': currency,
      'notes': notes,
    };
  }
}