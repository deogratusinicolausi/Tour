import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/turiva_chat_model.dart';
import '../services/turiva_chat_service.dart';
import '../utils/colors.dart';
import 'turiva_live_chat_screen.dart';

class TurivaChatListScreen extends StatefulWidget {
  const TurivaChatListScreen({super.key});

  @override
  State<TurivaChatListScreen> createState() => _TurivaChatListScreenState();
}

class _TurivaChatListScreenState extends State<TurivaChatListScreen> {
  final _service = TurivaChatService();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💬 Messages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _user == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<List<TurivaChatModel>>(
        stream: _service.getUserChats(_user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return _buildEmptyState(width, height);
          }

          return ListView.builder(
            padding: EdgeInsets.all(width * 0.04),
            itemCount: chats.length,
            itemBuilder: (context, i) => _buildChatCard(chats[i], width, height),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewChat(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add_comment, color: Colors.black),
        label: const Text(
          'New Chat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline,
                size: width * 0.15, color: AppColors.primary),
          ),
          SizedBox(height: height * 0.03),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.15),
            child: Text(
              'Chat with TURIVA Support for any questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: width * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(TurivaChatModel chat, double width, double height) {
    final hasUnread = chat.unreadByUser > 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TurivaLiveChatScreen(
              chatId: chat.id,
              otherUserName: 'TURIVA Support',
              isAdmin: false,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.012),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: width * 0.07,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: width * 0.07),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: width * 0.035,
                    height: width * 0.035,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TURIVA Support',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                        ),
                      ),
                      Text(
                        chat.timeAgo,
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          fontSize: width * 0.028,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.grey.shade800
                                : Colors.grey.shade500,
                            fontSize: width * 0.032,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: const BoxDecoration(
                            gradient: AppColors.mainGradient,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text(
                            '${chat.unreadByUser}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewChat() async {
    if (_user == null) return;

    final chatId = await _service.getOrCreateChat(
      userId: _user!.uid,
      userName: _user!.displayName ?? 'User',
      userPhoto: _user!.photoURL ?? '',
    );

    if (chatId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TurivaLiveChatScreen(
            chatId: chatId,
            otherUserName: 'TURIVA Support',
            isAdmin: false,
          ),
        ),
      );
    }
  }
}