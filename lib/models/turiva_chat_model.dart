import 'package:cloud_firestore/cloud_firestore.dart';

class TurivaChatModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String adminId;
  final String adminName;
  final String adminPhoto;
  final String lastMessage;
  final String lastMessageType; // text, image, voice, file, location
  final DateTime? lastMessageAt;
  final int unreadByUser;
  final int unreadByAdmin;
  final bool userTyping;
  final bool adminTyping;
  final String relatedItemId;
  final String relatedItemType;
  final String relatedItemName;
  final String status; // active, closed, archived
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TurivaChatModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto = '',
    this.adminId = '',
    this.adminName = 'TURIVA Support',
    this.adminPhoto = '',
    this.lastMessage = '',
    this.lastMessageType = 'text',
    this.lastMessageAt,
    this.unreadByUser = 0,
    this.unreadByAdmin = 0,
    this.userTyping = false,
    this.adminTyping = false,
    this.relatedItemId = '',
    this.relatedItemType = '',
    this.relatedItemName = '',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory TurivaChatModel.fromMap(Map<String, dynamic> map, String id) {
    return TurivaChatModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? 'TURIVA Support',
      adminPhoto: map['adminPhoto'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: map['lastMessageType'] ?? 'text',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadByUser: map['unreadByUser'] ?? 0,
      unreadByAdmin: map['unreadByAdmin'] ?? 0,
      userTyping: map['userTyping'] ?? false,
      adminTyping: map['adminTyping'] ?? false,
      relatedItemId: map['relatedItemId'] ?? '',
      relatedItemType: map['relatedItemType'] ?? '',
      relatedItemName: map['relatedItemName'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'adminId': adminId,
      'adminName': adminName,
      'adminPhoto': adminPhoto,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageAt':
      lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadByUser': unreadByUser,
      'unreadByAdmin': unreadByAdmin,
      'userTyping': userTyping,
      'adminTyping': adminTyping,
      'relatedItemId': relatedItemId,
      'relatedItemType': relatedItemType,
      'relatedItemName': relatedItemName,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeAgo {
    if (lastMessageAt == null) return '';
    final diff = DateTime.now().difference(lastMessageAt!);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
  }
}

class TurivaMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderPhoto;
  final String receiverId;
  final String message;
  final String messageType; // text, image, voice, file, location
  final String imageUrl;
  final String voiceUrl;
  final int voiceDuration;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final bool isStarred;
  final String replyTo;
  final DateTime? createdAt;

  TurivaMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto = '',
    required this.receiverId,
    this.message = '',
    this.messageType = 'text',
    this.imageUrl = '',
    this.voiceUrl = '',
    this.voiceDuration = 0,
    this.fileName = '',
    this.fileUrl = '',
    this.fileSize = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.locationName = '',
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.isStarred = false,
    this.replyTo = '',
    this.createdAt,
  });

  factory TurivaMessage.fromMap(Map<String, dynamic> map, String id) {
    return TurivaMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhoto: map['senderPhoto'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      messageType: map['messageType'] ?? 'text',
      imageUrl: map['imageUrl'] ?? '',
      voiceUrl: map['voiceUrl'] ?? '',
      voiceDuration: map['voiceDuration'] ?? 0,
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      locationName: map['locationName'] ?? '',
      isRead: map['isRead'] ?? false,
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      isDeleted: map['isDeleted'] ?? false,
      isStarred: map['isStarred'] ?? false,
      replyTo: map['replyTo'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isDeleted': isDeleted,
      'isStarred': isStarred,
      'replyTo': replyTo,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  bool isMe(String currentUserId) => senderId == currentUserId;

  String get timeDisplay {
    if (createdAt == null) return '';
    final hour = createdAt!.hour.toString().padLeft(2, '0');
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}