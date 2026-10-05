import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/feed_post_model.dart';
import '../models/feed_comment_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';

class FeedPostDetailsScreen extends StatefulWidget {
  final FeedPostModel post;
  const FeedPostDetailsScreen({super.key, required this.post});

  @override
  State<FeedPostDetailsScreen> createState() => _FeedPostDetailsScreenState();
}

class _FeedPostDetailsScreenState extends State<FeedPostDetailsScreen> {
  final _service = FeedUserService();
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  final _scrollController = ScrollController();

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  File? _commentImage;
  bool _isSending = false;

  Future<void> _initializeVideo(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    if (mounted) {
      setState(() => _isVideoInitialized = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickCommentImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );
    if (picked != null) {
      setState(() => _commentImage = File(picked.path));
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _commentImage == null) return;

    setState(() => _isSending = true);

    final ok = await _service.addComment(
      postId: widget.post.id,
      text: text,
      imageFile: _commentImage,
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
      _commentImage = null;
    });

    if (ok) {
      _commentController.clear();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _snack('❌ Failed to add comment');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showReportDialog() async {
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'False information',
      'Other',
    ];
    String? selected;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report post'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r),
                value: r,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              )),
              if (selected == 'Other')
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Reason'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = selected == 'Other'
                  ? controller.text.trim()
                  : selected ?? '';
              if (reason.isEmpty) return;
              await _service.reportPost(widget.post.id, reason);
              if (mounted) {
                Navigator.pop(context);
                _snack('✅ Reported. Admin will review.');
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ POST CONTENT (real-time) ═══
                  StreamBuilder<FeedPostModel?>(
                    stream: _service.getPost(widget.post.id),
                    builder: (context, snapshot) {
                      final post = snapshot.data ?? widget.post;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User header
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accentGold,
                              backgroundImage: post.userAvatar.isNotEmpty
                                  ? NetworkImage(post.userAvatar)
                                  : null,
                              child: post.userAvatar.isEmpty
                                  ? Text(post.userName.isNotEmpty
                                  ? post.userName[0].toUpperCase()
                                  : '?')
                                  : null,
                            ),
                            title: Text(
                              post.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: post.location.isNotEmpty
                                ? Text('📍 ${post.location}',
                                style: const TextStyle(
                                    color: Colors.white60))
                                : null,
                          ),
                          // Media: video au image
                          if (post.isVideo) ...[
                            // Video player
                            AspectRatio(
                              aspectRatio: _isVideoInitialized && _videoController != null
                                  ? _videoController!.value.aspectRatio
                                  : 16 / 9,
                              child: _isVideoInitialized && _videoController != null
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        VideoPlayer(_videoController!),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _videoController!.value.isPlaying
                                                  ? _videoController!.pause()
                                                  : _videoController!.play();
                                            });
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            child: Center(
                                              child: Icon(
                                                _videoController!.value.isPlaying
                                                    ? Icons.pause_circle
                                                    : Icons.play_circle,
                                                size: 80,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      color: Colors.black,
                                      child: const Center(
                                          child: CircularProgressIndicator(color: AppColors.accentGold)),
                                    ),
                            ),
                            // Initialize video kwa mara ya kwanza
                            Builder(builder: (context) {
                              if (!_isVideoInitialized) {
                                _initializeVideo(post.mediaUrl);
                              }
                              return const SizedBox.shrink();
                            }),
                          ] else if (post.imageUrl.isNotEmpty) ...[
                            Image.network(
                              post.imageUrl,
                              width: width,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: height * 0.4,
                                color: Colors.grey.shade900,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white54),
                              ),
                            ),
                          ],
                          // Actions
                          Padding(
                            padding: EdgeInsets.all(width * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Like button
                                    StreamBuilder<bool>(
                                      stream: _service.isLiked(post.id),
                                      builder: (context, snap) {
                                        final liked = snap.data ?? false;
                                        return IconButton(
                                          icon: Icon(
                                            liked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: liked
                                                ? Colors.redAccent
                                                : Colors.white,
                                          ),
                                          onPressed: () => _service.toggleLike(
                                              post.id, liked),
                                        );
                                      },
                                    ),
                                    Text('${post.likesCount}',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.chat_bubble_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text('${post.commentsCount}',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    const Spacer(),
                                    // Save
                                    StreamBuilder<bool>(
                                      stream: _service.isSaved(post.id),
                                      builder: (context, snap) {
                                        final saved = snap.data ?? false;
                                        return IconButton(
                                          icon: Icon(
                                            saved
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: saved
                                                ? AppColors.accentGold
                                                : Colors.white,
                                          ),
                                          onPressed: () => _service.toggleSave(
                                              post.id, saved),
                                        );
                                      },
                                    ),
                                    // Share
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.white),
                                      onPressed: () async {
                                        try {
                                          final shareText = '''
🦁 Check out this amazing post on TURIVA!
📍 ${post.location}
👤 ${post.userName}

${post.caption}

Download TURIVA app: https://turiva.app''';
                                          await Share.share(shareText);
                                          await _service.sharePost(post.id);
                                        } catch (e) {
                                          debugPrint('🔥 share: $e');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                if (post.caption.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    post.caption,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              'Comments',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ═══ COMMENTS LIST ═══
                  StreamBuilder<List<FeedCommentModel>>(
                    stream: _service.getComments(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accentGold)),
                        );
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: comments
                            .map((c) => _buildCommentItem(c, width))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ═══ COMMENT INPUT ═══
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.all(width * 0.03),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  if (_commentImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _commentImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _commentImage = null),
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image,
                            color: AppColors.accentGold),
                        onPressed: _pickCommentImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_isSending)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.accentGold,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.send,
                              color: AppColors.accentGold),
                          onPressed: _sendComment,
                        ),
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

  Widget _buildCommentItem(FeedCommentModel comment, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: width * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: width * 0.04,
            backgroundColor: AppColors.accentGold,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (comment.text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.text,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.032,
                    ),
                  ),
                ],
                if (comment.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      comment.imageUrl,
                      width: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}