import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../widgets/chat_bubble_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserPhoto;
  final bool isAdmin;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    this.otherUserName = 'TURIVA Support',
    this.otherUserPhoto = '',
    this.isAdmin = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _service = ChatService();
  final _cloudinary = CloudinaryService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _user = FirebaseAuth.instance.currentUser;

  bool _isUploading = false;
  bool _isOtherTyping = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _watchTyping();
  }

  Future<void> _markAsRead() async {
    await _service.markMessagesAsRead(widget.chatId, !widget.isAdmin);
  }

  void _watchTyping() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((doc) {
      if (mounted && doc.exists) {
        final typing = widget.isAdmin
            ? (doc.data()?['userTyping'] ?? false)
            : (doc.data()?['adminTyping'] ?? false);
        setState(() => _isOtherTyping = typing);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_user == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    await _service.sendMessage(
      chatId: widget.chatId,
      senderId: _user!.uid,
      senderName: _user!.displayName ?? 'User',
      senderPhoto: _user!.photoURL ?? '',
      receiverId: widget.isAdmin ? 'user' : 'admin',
      message: message,
      isFromUser: !widget.isAdmin,
    );

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
        await _service.sendMessage(
          chatId: widget.chatId,
          senderId: _user!.uid,
          senderName: _user!.displayName ?? 'User',
          senderPhoto: _user!.photoURL ?? '',
          receiverId: widget.isAdmin ? 'user' : 'admin',
          message: '📷 Photo',
          messageType: 'image',
          imageUrl: url,
          isFromUser: !widget.isAdmin,
        );
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
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM TOP HEADER (GLASS) ---
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: height * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CircleAvatar(
                            radius: width * 0.045,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: widget.otherUserPhoto.isNotEmpty
                                ? NetworkImage(widget.otherUserPhoto)
                                : null,
                            child: widget.otherUserPhoto.isEmpty
                                ? Icon(
                                    widget.isAdmin ? Icons.person : Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: width * 0.05,
                                  )
                                : null,
                          ),
                          SizedBox(width: width * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.otherUserName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_isOtherTyping)
                                  const Text(
                                    'typing...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- MESSAGES ---
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _service.getMessages(widget.chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: width * 0.15, color: Colors.white70),
                              SizedBox(height: height * 0.02),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(vertical: height * 0.01),
                        itemCount: messages.length + (_isOtherTyping ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == messages.length && _isOtherTyping) {
                            return const TypingIndicator();
                          }
                          return ChatBubble(
                            message: messages[i],
                            currentUserId: _user!.uid,
                          );
                        },
                      );
                    },
                  ),
                ),
                // --- INPUT AREA (GLASS) ---
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: height * 0.012,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _isUploading ? null : _pickAndSendImage,
                              child: Container(
                                padding: EdgeInsets.all(width * 0.025),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: _isUploading
                                    ? SizedBox(
                                        width: width * 0.05,
                                        height: width * 0.05,
                                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Icon(Icons.image, color: Colors.white, size: width * 0.055),
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (v) {
                                    _service.setTyping(widget.chatId, !widget.isAdmin, v.isNotEmpty);
                                  },
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
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
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentGold.withOpacity(0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.send, color: Colors.black, size: width * 0.055),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}