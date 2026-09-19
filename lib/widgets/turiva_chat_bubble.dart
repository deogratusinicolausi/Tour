import 'package:flutter/material.dart';
import '../models/turiva_chat_model.dart';
import '../utils/colors.dart';

class TurivaChatBubble extends StatelessWidget {
  final TurivaMessage message;
  final String currentUserId;
  final VoidCallback? onDelete;
  final VoidCallback? onStar;

  const TurivaChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onDelete,
    this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMe = message.isMe(currentUserId);

    if (message.isDeleted) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: 4),
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: width * 0.02),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🚫 This message was deleted',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: width * 0.032,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showOptions(context, width),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: 4),
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
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isStarred)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.star,
                                color: AppColors.accentGold,
                                size: width * 0.03),
                            SizedBox(width: 4),
                            Text(
                              'Starred',
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey.shade600,
                                fontSize: width * 0.022,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Image
                    if (message.messageType == 'image' &&
                        message.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.imageUrl,
                          width: width * 0.5,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: width * 0.5,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),

                    // Voice message
                    if (message.messageType == 'voice') ...[
                      Row(
                        children: [
                          Icon(Icons.play_circle_fill,
                              color: isMe ? Colors.white : AppColors.primary,
                              size: width * 0.08),
                          SizedBox(width: width * 0.02),
                          Container(
                            height: 4,
                            width: width * 0.3,
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            '${message.voiceDuration}s',
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey.shade600,
                              fontSize: width * 0.028,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Location
                    if (message.messageType == 'location') ...[
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: isMe ? Colors.white : AppColors.primary,
                              size: width * 0.05),
                          SizedBox(width: width * 0.02),
                          Flexible(
                            child: Text(
                              message.locationName.isNotEmpty
                                  ? message.locationName
                                  : 'Shared location',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.grey.shade900,
                                fontSize: width * 0.033,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

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

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeDisplay,
                          style: TextStyle(
                            color:
                            isMe ? Colors.white70 : Colors.grey.shade500,
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
      ),
    );
  }

  void _showOptions(BuildContext context, double width) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                message.isStarred ? Icons.star : Icons.star_border,
                color: AppColors.accentGold,
              ),
              title: Text(message.isStarred ? 'Unstar' : 'Star message'),
              onTap: () {
                Navigator.pop(context);
                onStar?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TurivaTypingIndicator extends StatelessWidget {
  const TurivaTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: width * 0.025),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
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
            color: AppColors.primary
                .withOpacity(0.3 + (_controller.value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}