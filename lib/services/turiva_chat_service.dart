import 'package:cloud_firestore/cloud_firestore.dart';
import 'sound_service.dart';
import '../models/turiva_chat_model.dart';

class TurivaChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get or create chat
  Future<String?> getOrCreateChat({
    required String userId,
    required String userName,
    required String userPhoto,
    String relatedItemId = '',
    String relatedItemType = '',
    String relatedItemName = '',
  }) async {
    try {
      final existing = await _firestore
          .collection('turiva_chats')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final ref = await _firestore.collection('turiva_chats').add({
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'adminId': '',
        'adminName': 'TURIVA Support',
        'adminPhoto': '',
        'lastMessage': 'Chat started',
        'lastMessageType': 'text',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByUser': 0,
        'unreadByAdmin': 0,
        'userTyping': false,
        'adminTyping': false,
        'relatedItemId': relatedItemId,
        'relatedItemType': relatedItemType,
        'relatedItemName': relatedItemName,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error creating chat: $e');
      return null;
    }
  }

  // ⭐️ Get user chats
  Stream<List<TurivaChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('turiva_chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TurivaChatModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime(2000);
        final bDate = b.lastMessageAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get messages
  Stream<List<TurivaMessage>> getMessages(String chatId) {
    return _firestore
        .collection('turiva_chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TurivaMessage.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });
      return list;
    });
  }

  // ⭐️ Send text message
  Future<String?> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required String message,
    bool isFromUser = true,
  }) async {
    return _sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      receiverId: receiverId,
      message: message,
      messageType: 'text',
      isFromUser: isFromUser,
    );
  }

  // ⭐️ Send image message
  Future<String?> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required String imageUrl,
    bool isFromUser = true,
  }) async {
    return _sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      receiverId: receiverId,
      message: '📷 Photo',
      messageType: 'image',
      imageUrl: imageUrl,
      isFromUser: isFromUser,
    );
  }

  // ⭐️ Send voice message
  Future<String?> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required String voiceUrl,
    required int duration,
    bool isFromUser = true,
  }) async {
    return _sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      receiverId: receiverId,
      message: '🎤 Voice message',
      messageType: 'voice',
      voiceUrl: voiceUrl,
      voiceDuration: duration,
      isFromUser: isFromUser,
    );
  }

  // ⭐️ Send location
  Future<String?> sendLocationMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required double latitude,
    required double longitude,
    required String locationName,
    bool isFromUser = true,
  }) async {
    return _sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      receiverId: receiverId,
      message: '📍 $locationName',
      messageType: 'location',
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      isFromUser: isFromUser,
    );
  }

  // ⭐️ Private send message
  Future<String?> _sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required String message,
    required String messageType,
    String imageUrl = '',
    String voiceUrl = '',
    int voiceDuration = 0,
    String fileName = '',
    String fileUrl = '',
    int fileSize = 0,
    double latitude = 0.0,
    double longitude = 0.0,
    String locationName = '',
    required bool isFromUser,
  }) async {
    try {
      final ref = await _firestore
          .collection('turiva_chats')
          .doc(chatId)
          .collection('messages')
          .add({
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
        'isRead': false,
        'isDeleted': false,
        'isStarred': false,
        'replyTo': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final chatRef = _firestore.collection('turiva_chats').doc(chatId);
      final chatDoc = await chatRef.get();
      final currentUnreadUser = chatDoc.data()?['unreadByUser'] ?? 0;
      final currentUnreadAdmin = chatDoc.data()?['unreadByAdmin'] ?? 0;

      await chatRef.update({
        'lastMessage': message,
        'lastMessageType': messageType,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByUser': isFromUser ? currentUnreadUser : currentUnreadUser + 1,
        'unreadByAdmin':
        isFromUser ? currentUnreadAdmin + 1 : currentUnreadAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification
      if (isFromUser) {
        await _firestore.collection('notifications').add({
          'userId': 'admin',
          'title': '💬 New Message',
          'body': '$senderName: $message',
          'type': 'chat',
          'category': 'info',
          'icon': '💬',
          'actionType': 'open_chat',
          'actionId': chatId,
          'isRead': false,
          'isPushed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('notifications').add({
          'userId': receiverId,
          'title': '💬 New Message from Support',
          'body': message,
          'type': 'chat',
          'category': 'info',
          'icon': '💬',
          'actionType': 'open_chat',
          'actionId': chatId,
          'isRead': false,
          'isPushed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return ref.id;
    } catch (e) {
      print('🔥 Error sending message: $e');
      return null;
    }
  }

  // ⭐️ Mark messages as read
  Future<void> markMessagesAsRead(String chatId, bool isFromUser) async {
    try {
      final messages = await _firestore
          .collection('turiva_chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        final senderId = (doc.data())['senderId'] ?? '';
        if ((isFromUser && senderId == 'admin') ||
            (!isFromUser && senderId != 'admin')) {
          await doc.reference.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final chatRef = _firestore.collection('turiva_chats').doc(chatId);
      if (isFromUser) {
        await chatRef.update({'unreadByUser': 0});
      } else {
        await chatRef.update({'unreadByAdmin': 0});
      }
    } catch (e) {
      print('🔥 Error marking as read: $e');
    }
  }

  // ⭐️ Set typing status
  Future<void> setTyping(String chatId, bool isFromUser, bool isTyping) async {
    try {
      final chatRef = _firestore.collection('turiva_chats').doc(chatId);
      if (isFromUser) {
        await chatRef.update({'userTyping': isTyping});
      } else {
        await chatRef.update({'adminTyping': isTyping});
      }
    } catch (e) {
      print('🔥 Error setting typing: $e');
    }
  }

  // ⭐️ Delete message (for me)
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('turiva_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'message': 'This message was deleted',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Star message
  Future<bool> starMessage(String chatId, String messageId, bool isStarred) async {
    try {
      await _firestore
          .collection('turiva_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isStarred': isStarred});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Search messages
  Future<List<TurivaMessage>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('turiva_chats')
          .doc(chatId)
          .collection('messages')
          .where('isDeleted', isEqualTo: false)
          .get();

      final messages = snapshot.docs
          .map((doc) => TurivaMessage.fromMap(doc.data(), doc.id))
          .where((m) =>
          m.message.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return messages;
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Get ALL chats (Admin view)
  Stream<List<TurivaChatModel>> getAllChats() {
    return _firestore
        .collection('turiva_chats')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TurivaChatModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime(2000);
        final bDate = b.lastMessageAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get total unread (Admin)
  Stream<int> getTotalUnreadByAdmin() {
    return _firestore.collection('turiva_chats').snapshots().map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['unreadByAdmin'] ?? 0) as int;
      }
      return total;
    });
  }

  // ⭐️ Listen for new messages (Sound)
  void listenForNewMessages() {
    bool isFirstLoad = true;

    _firestore.collection('turiva_chats').snapshots().listen((snapshot) {
      if (isFirstLoad) {
        isFirstLoad = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null && (data['unreadByAdmin'] ?? 0) > 0) {
            SoundService.playByType('chat');
          }
        }
      }
    });
  }

  // ⭐️ Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('turiva_chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['unreadByUser'] ?? 0) as int;
      }
      return total;
    });
  }
}