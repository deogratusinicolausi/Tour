import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String itemId;
  final String itemType; // hotel, tour, beach, mountain, culture, food, deal
  final String itemName;
  final String userId;
  final String userName;
  final String userPhoto;
  final double rating; // 1.0 - 5.0
  final String title;
  final String comment;
  final List<String> photos;
  final bool verified; // User actually booked
  final int helpfulCount;
  final List<String> helpfulBy;
  final String adminReply;
  final DateTime? adminReplyAt;
  final String bookingId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    this.itemName = '',
    required this.userId,
    required this.userName,
    this.userPhoto = '',
    required this.rating,
    this.title = '',
    required this.comment,
    this.photos = const [],
    this.verified = false,
    this.helpfulCount = 0,
    this.helpfulBy = const [],
    this.adminReply = '',
    this.adminReplyAt,
    this.bookingId = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      title: map['title'] ?? '',
      comment: map['comment'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      verified: map['verified'] ?? false,
      helpfulCount: map['helpfulCount'] ?? 0,
      helpfulBy: List<String>.from(map['helpfulBy'] ?? []),
      adminReply: map['adminReply'] ?? '',
      adminReplyAt: (map['adminReplyAt'] as Timestamp?)?.toDate(),
      bookingId: map['bookingId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'itemName': itemName,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'title': title,
      'comment': comment,
      'photos': photos,
      'verified': verified,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'adminReply': adminReply,
      'adminReplyAt':
      adminReplyAt != null ? Timestamp.fromDate(adminReplyAt!) : null,
      'bookingId': bookingId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeAgo {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}