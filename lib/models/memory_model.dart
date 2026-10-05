import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String note;
  final String memoryType; // 'photo' | 'video' | 'journal' | 'location'
  final List<String> mediaUrls;
  final List<String> mediaTypes; // 'image' | 'video'
  final String thumbnailUrl;
  final String location;
  final double latitude;
  final double longitude;
  final String destinationId;
  final DateTime? date;
  final String activity;
  final double rating;
  final bool favorite;
  final DateTime? capsuleOpenDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MemoryModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.note = '',
    this.memoryType = 'photo',
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.thumbnailUrl = '',
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.destinationId = '',
    this.date,
    this.activity = '',
    this.rating = 0.0,
    this.favorite = false,
    this.capsuleOpenDate,
    this.createdAt,
    this.updatedAt,
  });

  factory MemoryModel.fromMap(Map<String, dynamic> map, String id) {
    return MemoryModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      note: map['note'] ?? '',
      memoryType: map['memoryType'] ?? 'photo',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaTypes: List<String>.from(map['mediaTypes'] ?? []),
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      destinationId: map['destinationId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate(),
      activity: map['activity'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      favorite: map['favorite'] ?? false,
      capsuleOpenDate: (map['capsuleOpenDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'note': note,
      'memoryType': memoryType,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'thumbnailUrl': thumbnailUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'destinationId': destinationId,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'activity': activity,
      'rating': rating,
      'favorite': favorite,
      'capsuleOpenDate': capsuleOpenDate != null
          ? Timestamp.fromDate(capsuleOpenDate!)
          : null,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Helpers for the UI
  bool get isCapsuleLocked {
    if (capsuleOpenDate == null) return false;
    return capsuleOpenDate!.isAfter(DateTime.now());
  }

  int get year => date?.year ?? DateTime.now().year;

  String get formattedDate {
    if (date == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date!.month - 1]} ${date!.day}, ${date!.year}';
  }

  MemoryModel copyWith({
    String? title,
    String? description,
    String? note,
    String? memoryType,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    String? thumbnailUrl,
    String? location,
    double? latitude,
    double? longitude,
    String? destinationId,
    DateTime? date,
    String? activity,
    double? rating,
    bool? favorite,
    DateTime? capsuleOpenDate,
  }) {
    return MemoryModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      note: note ?? this.note,
      memoryType: memoryType ?? this.memoryType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      destinationId: destinationId ?? this.destinationId,
      date: date ?? this.date,
      activity: activity ?? this.activity,
      rating: rating ?? this.rating,
      favorite: favorite ?? this.favorite,
      capsuleOpenDate: capsuleOpenDate ?? this.capsuleOpenDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}