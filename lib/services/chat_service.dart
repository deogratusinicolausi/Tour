import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get or create chat between user and admin
  Future<String?> getOrCreateChat({
    required String userId,
    required String userName,
    required String userPhoto,
    String relatedItemId = '',
    String relatedItemType = '',
    String relatedItemName = '',
  }) async {
    try {
      // Check if chat exists
      final existing = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      // Create new chat
      final ref = await _firestore.collection('chats').add({
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

  // ⭐️ Get user chats (Real-time)
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime(2000);
        final bDate = b.lastMessageAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get messages (Real-time)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });
      return list;
    });
  }

  // ⭐️ Send message
  Future<String?> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderPhoto,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String imageUrl = '',
    String fileName = '',
    String fileUrl = '',
    required bool isFromUser,
  }) async {
    try {
      final ref = await _firestore
          .collection('chats')
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
        'fileName': fileName,
        'fileUrl': fileUrl,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chat
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      final currentUnreadUser = chatDoc.data()?['unreadByUser'] ?? 0;
      final currentUnreadAdmin = chatDoc.data()?['unreadByAdmin'] ?? 0;

      await chatRef.update({
        'lastMessage': messageType == 'text' ? message : '📷 Photo',
        'lastMessageType': messageType,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByUser': isFromUser ? currentUnreadUser : currentUnreadUser + 1,
        'unreadByAdmin':
        isFromUser ? currentUnreadAdmin + 1 : currentUnreadAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⭐️ Create notification for the receiver
      if (isFromUser) {
        // Notify admin
        await _firestore.collection('notifications').add({
          'userId': 'admin',
          'title': '💬 New Message',
          'body': '$senderName: ${messageType == 'text' ? message : '📷 Photo'}',
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
        // Notify user
        await _firestore.collection('notifications').add({
          'userId': receiverId,
          'title': '💬 New Message from Support',
          'body': messageType == 'text' ? message : '📷 Photo',
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
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        final data = doc.data();
        final senderId = data['senderId'] ?? '';

        // Mark as read only if not from current user
        if (isFromUser && senderId == 'admin') {
          await doc.reference.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        } else if (!isFromUser && senderId != 'admin') {
          await doc.reference.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Reset unread count
      final chatRef = _firestore.collection('chats').doc(chatId);
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
      final chatRef = _firestore.collection('chats').doc(chatId);
      if (isFromUser) {
        await chatRef.update({'userTyping': isTyping});
      } else {
        await chatRef.update({'adminTyping': isTyping});
      }
    } catch (e) {
      print('🔥 Error setting typing: $e');
    }
  }

  // ⭐️ Delete chat
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messages =
      await _firestore.collection('chats').doc(chatId).collection('messages').get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
      // Delete chat
      await _firestore.collection('chats').doc(chatId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('chats')
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