import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // booking, wishlist, review, deal, order, system
  final String category; // info, success, warning, error
  final String icon;
  final String imageUrl;
  final String actionType; // open_booking, open_review, open_deal, etc.
  final String actionId; // ID of item to open
  final bool isRead;
  final bool isPushed; // Sound played
  final DateTime? createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.category = 'info',
    this.icon = '🔔',
    this.imageUrl = '',
    this.actionType = '',
    this.actionId = '',
    this.isRead = false,
    this.isPushed = false,
    this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      category: map['category'] ?? 'info',
      icon: map['icon'] ?? '🔔',
      imageUrl: map['imageUrl'] ?? '',
      actionType: map['actionType'] ?? '',
      actionId: map['actionId'] ?? '',
      isRead: map['isRead'] ?? false,
      isPushed: map['isPushed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'icon': icon,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionId': actionId,
      'isRead': isRead,
      'isPushed': isPushed,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
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
    return '${diff.inDays ~/ 30}mo ago';
  }
}