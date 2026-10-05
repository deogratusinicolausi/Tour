import 'package:cloud_firestore/cloud_firestore.dart';

class FeedCommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String imageUrl;     // optional — Cloudinary
  final int likesCount;
  final bool isHidden;       // admin moderation
  final String hiddenReason;
  final DateTime createdAt;

  FeedCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.imageUrl,
    required this.likesCount,
    required this.isHidden,
    required this.hiddenReason,
    required this.createdAt,
  });

  factory FeedCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedCommentModel(
      id: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Traveler',
      userAvatar: map['userAvatar'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      likesCount: (map['likesCount'] ?? 0) as int,
      isHidden: map['isHidden'] ?? false,
      hiddenReason: map['hiddenReason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'isHidden': isHidden,
      'hiddenReason': hiddenReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}