import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
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
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.55),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM TOP HEADER ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '💬 Turiva Live Chat',
                        style: TextStyle(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // --- REST OF YOUR CONTENT ---
                Expanded(
                  child: _user == null
                      ? const Center(
                          child: Text('Please login',
                              style: TextStyle(color: Colors.white)))
                      : StreamBuilder<List<TurivaChatModel>>(
                          stream: _service.getUserChats(_user!.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(color: Colors.white));
                            }
                            final chats = snapshot.data ?? [];
                            if (chats.isEmpty) {
                              return _buildEmptyState(width, height);
                            }
                            return ListView.builder(
                              padding: EdgeInsets.all(width * 0.04),
                              itemCount: chats.length,
                              itemBuilder: (context, i) =>
                                  _buildChatCard(chats[i], width, height),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => _startNewChat(),
              backgroundColor: AppColors.accentGold,
              icon: const Icon(Icons.add_comment, color: Colors.black),
              label: const Text(
                'New Chat',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // GLASS
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width * 0.25,
              height: width * 0.25,
              child: Lottie.asset(
                'assets/animations/chat_empty.json',
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.chat_bubble_outline, size: width * 0.15, color: Colors.white70),
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Text(
                'Chat with TURIVA Support for any questions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ],
        ),
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
          color: Colors.white.withOpacity(0.15), // GLASS
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(color: AppColors.accentGold, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                  backgroundColor: AppColors.accentGold, // GOLD
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.black, size: width * 0.07),
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
                            color: Colors.white, // WHITE
                          ),
                        ),
                      ),
                      Text(
                        chat.timeAgo,
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.accentGold
                              : Colors.white70,
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
                                ? Colors.white
                                : Colors.white70,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold, // GOLD
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadByUser}',
                            style: const TextStyle(
                              color: Colors.black, // BLACK on gold
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