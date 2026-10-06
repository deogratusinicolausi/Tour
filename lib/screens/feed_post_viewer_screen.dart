import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../models/feed_post_model.dart';
import '../models/feed_comment_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'user_feed_profile_screen.dart';

class FeedPostViewerScreen extends StatefulWidget {
  final FeedPostModel post;
  const FeedPostViewerScreen({super.key, required this.post});

  @override
  State<FeedPostViewerScreen> createState() => _FeedPostViewerScreenState();
}

class _FeedPostViewerScreenState extends State<FeedPostViewerScreen>
    with TickerProviderStateMixin {
  final _service = FeedUserService();
  final _commentController = TextEditingController();

  // ⭐ CURRENT POST (real-time)
  late FeedPostModel _currentPost;
  StreamSubscription<FeedPostModel?>? _postSub;

  // ═══ VIDEO ═══
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  Timer? _hideControlsTimer;

  // ═══ UI STATE ═══
  bool _isCommentSheetOpen = false;
  bool _isDescriptionExpanded = false;

  // ═══ ANIMATIONS ═══
  late AnimationController _likeAnimationController;
  late AnimationController _heartPulseController;
  late AnimationController _doubleTapController;
  late AnimationController _ambientController;
  late AnimationController _entryController;

  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initAnimations();
    _listenToPost();
    _service.recordView(widget.post.id);
    if (widget.post.isVideo) {
      _initializeVideo(widget.post.mediaUrl);
    }
    _startHideControlsTimer();

    // Entry animation
    _entryController.forward();
  }

  void _initAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartPulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _doubleTapController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ambientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _listenToPost() {
    _postSub = _service.getPost(widget.post.id).listen((post) {
      if (post != null && mounted) {
        setState(() => _currentPost = post);
      }
    });
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('🔥 Video init error: $e');
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _onDoubleTap(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
    _handleLike();
    _doubleTapController.forward(from: 0);
  }

  Future<void> _handleLike() async {
    _likeAnimationController.forward(from: 0);
    _heartPulseController.forward(from: 0);
    final currentlyLiked = await _service.isLiked(widget.post.id).first;
    await _service.toggleLike(widget.post.id, currentlyLiked);
  }

  void _openComments() {
    setState(() => _isCommentSheetOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        postId: widget.post.id,
        commentController: _commentController,
        service: _service,
      ),
    ).whenComplete(() {
      setState(() => _isCommentSheetOpen = false);
    });
  }

  Future<void> _handleShare() async {
    try {
      final shareText = '''
🦁 Check out this amazing post on TURIVA!
📍 ${_currentPost.location}
👤 ${_currentPost.userName}

${_currentPost.caption}

Download TURIVA app: https://turiva.app
''';
      await Share.share(shareText);
      await _service.sharePost(_currentPost.id);
    } catch (e) {
      debugPrint('🔥 Share error: $e');
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed == 2.0) {
        _playbackSpeed = 0.5;
      } else {
        _playbackSpeed = 1.0;
      }
      _videoController?.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekRelative(Duration offset) {
    if (_videoController == null || !_isVideoInitialized) return;

    final current = _videoController!.value.position;
    final total = _videoController!.value.duration;
    var newPos = current + offset;

    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > total) newPos = total;

    _videoController!.seekTo(newPos);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          offset.isNegative ? '⏪ -10s' : '⏩ +10s',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        width: 100,
      ),
    );

    _startHideControlsTimer();
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildOptionsSheet(),
    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetOption(
              icon: Icons.share,
              label: 'Share',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _handleShare();
              },
            ),
            _sheetOption(
              icon: Icons.link,
              label: 'Copy link',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔗 Link copied')),
                );
              },
            ),
            _sheetOption(
              icon: Icons.bookmark_border,
              label: 'Save',
              color: AppColors.accentGold,
              onTap: () async {
                Navigator.pop(context);
                final saved =
                await _service.isSaved(_currentPost.id).first;
                await _service.toggleSave(_currentPost.id, saved);
              },
            ),
            _sheetOption(
              icon: Icons.flag_outlined,
              label: 'Report',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            _sheetOption(
              icon: Icons.download_outlined,
              label: 'Download',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⬇️ Download coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
    );
  }

  void _showReportDialog() {
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'False information',
      'Other',
    ];
    String? selected;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text('Report post',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => RadioListTile<String>(
              title: Text(r,
                  style: const TextStyle(color: Colors.white70)),
              value: r,
              groupValue: selected,
              activeColor: AppColors.accentGold,
              onChanged: (v) => setState(() => selected = v),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selected == null) return;
                await _service.reportPost(_currentPost.id, selected!);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Reported')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _postSub?.cancel();
    _videoController?.dispose();
    _commentController.dispose();
    _likeAnimationController.dispose();
    _heartPulseController.dispose();
    _doubleTapController.dispose();
    _ambientController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _entryController,
        child: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: _onDoubleTap,
          onDoubleTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ═══ AMBIENT GLOW BEHIND MEDIA ═══
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return Center(
                    child: Container(
                      width: width * 0.9,
                      height: width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accentGold.withOpacity(
                              0.15 + _ambientController.value * 0.1,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ═══ MEDIA ═══
              _buildMedia(width),

              // ═══ CINEMATIC GRADIENT ═══
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.2, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // ═══ DOUBLE TAP HEART BURST ═══
              if (_doubleTapPosition != null)
                AnimatedBuilder(
                  animation: _doubleTapController,
                  builder: (context, _) {
                    final value = _doubleTapController.value;
                    if (value >= 1.0) return const SizedBox.shrink();
                    return Positioned(
                      left: _doubleTapPosition!.dx - 60,
                      top: _doubleTapPosition!.dy - 60,
                      child: Transform.scale(
                        scale: 0.5 + value * 1.5,
                        child: Opacity(
                          opacity: 1.0 - value,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 120,
                            shadows: [
                              Shadow(
                                color: Colors.redAccent,
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // ═══ TOP BAR ═══
              _buildTopBar(width),

              // ═══ VIDEO CONTROLS ═══
              if (_currentPost.isVideo &&
                  _showControls &&
                  _isVideoInitialized)
                _buildVideoControls(width),

              // ═══ SPEED CONTROL ═══
              if (_currentPost.isVideo &&
                  _showControls &&
                  _isVideoInitialized)
                Positioned(
                  bottom: height * 0.25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildSpeedControl(width),
                  ),
                ),

              // ═══ PROGRESS BAR ═══
              if (_currentPost.isVideo && _isVideoInitialized)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildProgressBar(width),
                ),

              // ═══ RIGHT ACTIONS ═══
              Positioned(
                right: width * 0.03,
                bottom: height * 0.18,
                child: _buildRightActions(width),
              ),

              // ═══ BOTTOM INFO ═══
              Positioned(
                left: width * 0.04,
                right: width * 0.2,
                bottom: height * 0.05,
                child: _buildBottomInfo(width),
              ),

              // ═══ VIEWED BADGE ═══
              StreamBuilder<bool>(
                stream: _service.hasViewed(widget.post.id),
                builder: (context, snapshot) {
                  final viewed = snapshot.data ?? false;
                  if (!viewed) return const SizedBox.shrink();

                  return Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentGold.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility,
                              color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Viewed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ TOP BAR ═══
  Widget _buildTopBar(double width) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: width * 0.03,
            ),
            child: Row(
              children: [
                // Back
                _glassButton(
                  icon: Icons.arrow_back_ios_new,
                  width: width,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Views pill
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: width * 0.035,
                      ),
                      SizedBox(width: width * 0.01),
                      Text(
                        '${_currentPost.likesCount + _currentPost.commentsCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.02),
                // More options
                _glassButton(
                  icon: Icons.more_vert,
                  width: width,
                  onTap: _showOptionsMenu,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ GLASS BUTTON ═══
  Widget _glassButton({
    required IconData icon,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.025),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: width * 0.05,
        ),
      ),
    );
  }

  // ═══ MEDIA ═══
  Widget _buildMedia(double width) {
    if (_currentPost.isVideo && _isVideoInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    if (_currentPost.isVideo && !_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentGold,
        ),
      );
    }
    return Center(
      child: Image.network(
        _currentPost.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.white24,
            size: 80,
          ),
        ),
      ),
    );
  }

  // ═══ VIDEO CONTROLS ═══
  Widget _buildVideoControls(double width) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _roundButton(
            icon: Icons.replay_10,
            onTap: () => _seekRelative(const Duration(seconds: -10)),
            width: width,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
              _startHideControlsTimer();
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.05),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGold.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: width * 0.12,
              ),
            ),
          ),
          _roundButton(
            icon: Icons.forward_10,
            onTap: () => _seekRelative(const Duration(seconds: 10)),
            width: width,
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.03),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: width * 0.07,
        ),
      ),
    );
  }

  // ═══ SPEED CONTROL ═══
  Widget _buildSpeedControl(double width) {
    return GestureDetector(
      onTap: _cycleSpeed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentGold.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: AppColors.accentGold,
              size: width * 0.04,
            ),
            SizedBox(width: width * 0.015),
            Text(
              '${_playbackSpeed}x',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ PROGRESS BAR ═══
  Widget _buildProgressBar(double width) {
    if (_videoController == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.03,
      ),
      child: VideoProgressIndicator(
        _videoController!,
        allowScrubbing: true,
        colors: VideoProgressColors(
          playedColor: AppColors.accentGold,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ═══ RIGHT ACTIONS ═══
  Widget _buildRightActions(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LIKE
        StreamBuilder<bool>(
          stream: _service.isLiked(_currentPost.id),
          builder: (context, snap) {
            final liked = snap.data ?? false;
            return _actionButton(
              icon: liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.redAccent : Colors.white,
              label: '${_currentPost.likesCount}',
              width: width,
              animation: liked ? _heartPulseController : null,
              glow: liked ? Colors.redAccent : null,
              onTap: _handleLike,
            );
          },
        ),
        SizedBox(height: width * 0.06),

        // COMMENT
        _actionButton(
          icon: Icons.chat_bubble,
          color: Colors.white,
          label: '${_currentPost.commentsCount}',
          width: width,
          onTap: _openComments,
        ),
        SizedBox(height: width * 0.06),

        // SAVE
        StreamBuilder<bool>(
          stream: _service.isSaved(_currentPost.id),
          builder: (context, snap) {
            final saved = snap.data ?? false;
            return _actionButton(
              icon: saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? AppColors.accentGold : Colors.white,
              label: '',
              width: width,
              glow: saved ? AppColors.accentGold : null,
              onTap: () => _service.toggleSave(_currentPost.id, saved),
            );
          },
        ),
        SizedBox(height: width * 0.06),

        // SHARE
        _actionButton(
          icon: Icons.share,
          color: Colors.white,
          label: 'Share',
          width: width,
          onTap: _handleShare,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required double width,
    required VoidCallback onTap,
    AnimationController? animation,
    Color? glow,
  }) {
    Widget content = Column(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: glow != null
                ? [
              BoxShadow(
                color: glow.withOpacity(0.5),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ]
                : null,
          ),
          child: Icon(
            icon,
            color: color,
            size: width * 0.08,
          ),
        ),
        SizedBox(height: width * 0.01),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.028,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
      ],
    );

    if (animation != null) {
      content = AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (animation.value * 0.3),
            child: child,
          );
        },
        child: content,
      );
    }

    return GestureDetector(onTap: onTap, child: content);
  }

  // ═══ BOTTOM INFO ═══
  Widget _buildBottomInfo(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // User
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserFeedProfileScreen(
                  userId: _currentPost.userId,
                  userName: _currentPost.userName,
                  userAvatar: _currentPost.userAvatar,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Flexible(
                child: Text(
                  '@${_currentPost.userName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.042,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: width * 0.01),
              Icon(
                Icons.verified,
                color: AppColors.accentGold,
                size: width * 0.035,
              ),
            ],
          ),
        ),
        SizedBox(height: width * 0.01),

        // Location
        if (_currentPost.location.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white70,
                size: width * 0.032,
              ),
              SizedBox(width: width * 0.01),
              Flexible(
                child: Text(
                  _currentPost.location,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.032,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        SizedBox(height: width * 0.02),

        // Caption
        if (_currentPost.caption.isNotEmpty)
          GestureDetector(
            onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
            child: Text(
              _currentPost.caption,
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.035,
                height: 1.3,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 6),
                ],
              ),
              maxLines: _isDescriptionExpanded ? null : 2,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COMMENTS SHEET
// ═══════════════════════════════════════════════════════════
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final TextEditingController commentController;
  final FeedUserService service;

  const _CommentsSheet({
    required this.postId,
    required this.commentController,
    required this.service,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  bool _isSending = false;

  // ⭐ Cache stream ili isirebuild
  late Stream<List<FeedCommentModel>> _commentsStream;

  @override
  void initState() {
    super.initState();
    // ⭐ Cache stream — haitengenezwi upya kila rebuild
    _commentsStream = widget.service.getComments(widget.postId);
  }

  Future<void> _send() async {
    final text = widget.commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final ok = await widget.service.addComment(
      postId: widget.postId,
      text: text,
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) widget.commentController.clear();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.accentGold, size: 18),
                  ),
                  SizedBox(width: width * 0.03),
                  Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Comments list
            Expanded(
              child: StreamBuilder<List<FeedCommentModel>>(
                stream: _commentsStream, // ✅ Cached — haitengenezwi upya
                builder: (context, snapshot) {
                  // ⭐ Loading ya kwanza tu
                  if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: width * 0.15,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No comments yet.\nBe the first!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.all(width * 0.04),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.goldGradient,
                              ),
                              child: CircleAvatar(
                                radius: width * 0.045,
                                backgroundColor: Colors.black,
                                backgroundImage: c.userAvatar.isNotEmpty
                                    ? NetworkImage(c.userAvatar)
                                    : null,
                                child: c.userAvatar.isEmpty
                                    ? Text(
                                  c.userName.isNotEmpty
                                      ? c.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          c.userName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: width * 0.034,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: width * 0.01),
                                      Icon(
                                        Icons.verified,
                                        color: AppColors.accentGold,
                                        size: width * 0.03,
                                      ),
                                      const Spacer(),
                                      Text(
                                        _timeAgo(c.createdAt),
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: width * 0.026,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.text,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.9),
                                      fontSize: width * 0.034,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: width * 0.028,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: width * 0.04),
                                      Icon(
                                        Icons.favorite_border,
                                        color: Colors.white54,
                                        size: width * 0.035,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${c.likesCount}',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: width * 0.026,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: const BoxDecoration(
                  color: Color(0xFF0a0a1a),
                  border: Border(
                    top: BorderSide(color: Colors.white12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: TextField(
                          controller: widget.commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle:
                            TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    GestureDetector(
                      onTap: _isSending ? null : _send,
                      child: Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold
                                  .withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: _isSending
                            ? SizedBox(
                          width: width * 0.05,
                          height: width * 0.05,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          Icons.send,
                          color: Colors.black,
                          size: width * 0.05,
                        ),
                      ),
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
}