import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/turiva_chat_model.dart';
import '../services/turiva_chat_service.dart';
import '../services/cloudinary_service.dart';
import '../services/sound_service.dart';
import '../utils/colors.dart';
import '../widgets/turiva_chat_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTurivaChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userName;
  final String userPhoto;

  const AdminTurivaChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.userName,
    this.userPhoto = '',
  });

  @override
  State<AdminTurivaChatDetailScreen> createState() =>
      _AdminTurivaChatDetailScreenState();
}

class _AdminTurivaChatDetailScreenState
    extends State<AdminTurivaChatDetailScreen> {
  final _service = TurivaChatService();
  final _cloudinary = CloudinaryService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _user = FirebaseAuth.instance.currentUser;

  bool _isUploading = false;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _watchTyping();
  }

  Future<void> _markAsRead() async {
    await _service.markMessagesAsRead(widget.chatId, false);
  }

  void _watchTyping() {
    _service.getMessages(widget.chatId).listen((_) {
      // Watch chat doc for typing
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_user == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Get admin name
    final adminDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    final adminName = adminDoc.data()?['name'] ?? 'TURIVA Support';
    final adminPhoto = adminDoc.data()?['photoUrl'] ?? '';

    await _service.sendTextMessage(
      chatId: widget.chatId,
      senderId: _user!.uid,
      senderName: adminName,
      senderPhoto: adminPhoto,
      receiverId: widget.userId,
      message: message,
      isFromUser: false,
    );

    SoundService.playByType('chat');
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
      if (pickedFile == null || _user == null) return;

      setState(() => _isUploading = true);

      String? url;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinary.uploadImageBytes(bytes,
            folder: 'turiva/chat');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/chat');
      }

      if (url != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        final adminName = adminDoc.data()?['name'] ?? 'TURIVA Support';
        final adminPhoto = adminDoc.data()?['photoUrl'] ?? '';

        await _service.sendImageMessage(
          chatId: widget.chatId,
          senderId: _user!.uid,
          senderName: adminName,
          senderPhoto: adminPhoto,
          receiverId: widget.userId,
          imageUrl: url,
          isFromUser: false,
        );

        SoundService.playByType('chat');
      }

      setState(() => _isUploading = false);
      _scrollToBottom();
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: width * 0.045,
              backgroundColor: Colors.white,
              backgroundImage: widget.userPhoto.isNotEmpty
                  ? NetworkImage(widget.userPhoto)
                  : null,
              child: widget.userPhoto.isEmpty
                  ? Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.045,
                ),
              )
                  : null,
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isUserTyping ? 'typing...' : 'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isUserTyping
                          ? Colors.amber.shade200
                          : Colors.green.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<TurivaMessage>>(
              stream: _service.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: height * 0.01),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => TurivaChatBubble(
                    message: messages[i],
                    currentUserId: _user!.uid,
                    onDelete: () => _service.deleteMessage(
                        widget.chatId, messages[i].id),
                    onStar: () => _service.starMessage(
                        widget.chatId,
                        messages[i].id,
                        !messages[i].isStarred),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: height * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndSendImage,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.025),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? SizedBox(
                        width: width * 0.05,
                        height: width * 0.05,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                          : Icon(Icons.image,
                          color: AppColors.primary,
                          size: width * 0.055),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: height * 0.015,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.03),
                      decoration: const BoxDecoration(
                        gradient: AppColors.mainGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send,
                          color: Colors.white, size: width * 0.055),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}