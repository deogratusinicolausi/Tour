import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final String location;
  final int likesCount;
  final int commentsCount;
  final int reportsCount;
  final int savesCount;
  final bool isHidden;
  final String hiddenReason;
  final DateTime createdAt;

  FeedPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.location,
    required this.likesCount,
    required this.commentsCount,
    required this.reportsCount,
    required this.savesCount,
    required this.isHidden,
    required this.hiddenReason,
    required this.createdAt,
  });

  factory FeedPostModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedPostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Traveler',
      userAvatar: map['userAvatar'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      mediaUrl: map['mediaUrl'] ?? map['imageUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      caption: map['caption'] ?? '',
      location: map['location'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      reportsCount: map['reportsCount'] ?? 0,
      savesCount: map['savesCount'] ?? 0,
      isHidden: map['isHidden'] ?? false,
      hiddenReason: map['hiddenReason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get thumbnailUrl {
    // If it's a video, attempt to generate a Cloudinary thumbnail from the mediaUrl or imageUrl
    final sourceUrl = mediaUrl.isNotEmpty ? mediaUrl : imageUrl;
    if (mediaType == 'video' && sourceUrl.isNotEmpty) {
      if (sourceUrl.contains('/upload/') && !sourceUrl.contains('f_jpg')) {
        return sourceUrl.replaceFirst(
          '/upload/',
          '/upload/so_0,w_800,h_1000,c_fill,q_auto,f_jpg/',
        );
      }
    }
    return imageUrl.isNotEmpty ? imageUrl : mediaUrl;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'location': location,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'reportsCount': reportsCount,
      'savesCount': savesCount,
      'isHidden': isHidden,
      'hiddenReason': hiddenReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedPostModel copyWith({
    bool? isHidden,
    String? hiddenReason,
    int? likesCount,
    String? mediaUrl,
    String? mediaType,
    int? commentsCount,
  }) {
    return FeedPostModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption,
      location: location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reportsCount: reportsCount,
      savesCount: savesCount,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      createdAt: createdAt,
    );
  }

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image' || mediaType.isEmpty;
}