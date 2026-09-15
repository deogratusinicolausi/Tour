import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../utils/colors.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMe = message.isMe(currentUserId);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.01,
      ),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: width * 0.04,
              backgroundColor: AppColors.primary,
              backgroundImage: message.senderPhoto.isNotEmpty
                  ? NetworkImage(message.senderPhoto)
                  : null,
              child: message.senderPhoto.isEmpty
                  ? const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: width * 0.02),
          ],
          Flexible(
            child: Container(
              padding: message.messageType == 'image'
                  ? EdgeInsets.all(width * 0.01)
                  : EdgeInsets.symmetric(
                horizontal: width * 0.035,
                vertical: width * 0.025,
              ),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.mainGradient : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (message.messageType == 'image' &&
                      message.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl,
                        width: width * 0.5,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: width * 0.5,
                            height: width * 0.5,
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: width * 0.5,
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),

                  // Text
                  if (message.messageType == 'text' &&
                      message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.grey.shade900,
                        fontSize: width * 0.037,
                        height: 1.3,
                      ),
                    ),

                  SizedBox(height: width * 0.01),

                  // Time + Read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeDisplay,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white70
                              : Colors.grey.shade500,
                          fontSize: width * 0.025,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: width * 0.01),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          color: message.isRead
                              ? Colors.lightBlue.shade200
                              : Colors.white70,
                          size: width * 0.035,
                        ),
                      ],
                    ],
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

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.01,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: width * 0.025,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(width, 0),
                SizedBox(width: width * 0.01),
                _dot(width, 1),
                SizedBox(width: width * 0.01),
                _dot(width, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double width, int index) {
    return _AnimatedDot(width: width, delay: index * 200);
  }
}

class _AnimatedDot extends StatefulWidget {
  final double width;
  final int delay;

  const _AnimatedDot({required this.width, required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width * 0.02,
          height: widget.width * 0.02,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(
              0.3 + (_controller.value * 0.7),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}