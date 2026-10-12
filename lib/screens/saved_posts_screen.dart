import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'feed_post_viewer_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with TickerProviderStateMixin {
  final _service = FeedUserService();
  final _scrollController = ScrollController();
  late AnimationController _bgController;

  // ⭐ Stream cached — haitengenezwi upya
  late Stream<List<FeedPostModel>> _savedStream;

  @override
  void initState() {
    super.initState();
    // ⭐ Cache stream
    _savedStream = _service.getSavedPosts();

    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════
          // 1️⃣ ANIMATED BACKGROUND
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0a0a1a),
                      Color.lerp(
                        const Color(0xFF1a0f2e),
                        const Color(0xFF16213e),
                        _bgController.value,
                      )!,
                      const Color(0xFF0a0a1a),
                    ],
                    stops: [
                      0.0,
                      0.5 + (_bgController.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // ═══════════════════════════════════════
          // 2️⃣ GLOW ORBS
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 80 - (_bgController.value * 60),
                    right: -80,
                    child: _glowOrb(
                      250,
                      AppColors.accentGold.withOpacity(0.18),
                    ),
                  ),
                  Positioned(
                    bottom: 200 + (_bgController.value * 40),
                    left: -100,
                    child: _glowOrb(
                      300,
                      Colors.purple.withOpacity(0.15),
                    ),
                  ),
                ],
              );
            },
          ),

          // ═══════════════════════════════════════
          // 3️⃣ MAIN CONTENT
          // ═══════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, width),
                Expanded(
                  child: StreamBuilder<List<FeedPostModel>>(
                    stream: _savedStream,
                    builder: (context, snapshot) {
                      // ⭐ Loading ya kwanza tu
                      if (!snapshot.hasData &&
                          snapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error, width);
                      }

                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty) {
                        return _buildEmptyState(width, height);
                      }

                      return RefreshIndicator(
                        color: AppColors.accentGold,
                        backgroundColor: const Color(0xFF1a1a2e),
                        onRefresh: () async {
                          setState(() {});
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          physics:
                          const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(width * 0.04),
                          itemCount: posts.length + 1,
                          itemBuilder: (context, i) {
                            // Stats header
                            if (i == 0) {
                              return _buildStatsHeader(posts, width);
                            }
                            return _StaggeredCard(
                              index: i - 1,
                              child: _buildSavedCard(
                                posts[i - 1],
                                width,
                                height,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // GLOW ORB
  // ═══════════════════════════════════════
  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // GLASS APP BAR
  // ═══════════════════════════════════════
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.02,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: width * 0.03,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: width * 0.05,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),

                // Title with shader
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: AppColors.accentGold,
                        size: width * 0.06,
                      ),
                      SizedBox(width: width * 0.02),
                      Flexible(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppColors.accentGold,
                              Colors.orange.shade300,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Saved Posts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  // ═══════════════════════════════════════
  // STATS HEADER
  // ═══════════════════════════════════════
  Widget _buildStatsHeader(List<FeedPostModel> posts, double width) {
    int totalLikes = 0;
    int totalVideos = 0;
    int totalImages = 0;

    for (var post in posts) {
      if (post.likesCount > 0) totalLikes += post.likesCount;
      if (post.isVideo) {
        totalVideos++;
      } else {
        totalImages++;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.04),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withOpacity(0.15),
            Colors.orange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Total saved
          Expanded(
            child: _statItem(
              '${posts.length}',
              'Saved',
              Icons.bookmark,
              AppColors.accentGold,
              width,
            ),
          ),
          _divider(width),
          // Total likes
          Expanded(
            child: _statItem(
              '$totalLikes',
              'Likes',
              Icons.favorite,
              Colors.redAccent,
              width,
            ),
          ),
          _divider(width),
          // Media breakdown
          Expanded(
            child: _statItem(
              '$totalVideos/$totalImages',
              'Video/Img',
              Icons.play_circle,
              Colors.blueAccent,
              width,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      String value,
      String label,
      IconData icon,
      Color color,
      double width,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: width * 0.05),
        SizedBox(height: width * 0.015),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: width * 0.026,
          ),
        ),
      ],
    );
  }

  Widget _divider(double width) {
    return Container(
      height: width * 0.12,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  // ═══════════════════════════════════════
  // SAVED CARD
  // ═══════════════════════════════════════
  Widget _buildSavedCard(
      FeedPostModel post, double width, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedPostViewerScreen(post: post),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: width * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ═══ IMAGE / VIDEO THUMBNAIL ═══
              Container(
                height: width * 0.55,
                width: double.infinity,
                color: const Color(0xFF0a0a1a),
                child: post.imageUrl.isNotEmpty
                    ? Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF0a0a1a),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0a0a1a),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 50,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.image,
                  color: Colors.white24,
                  size: 50,
                ),
              ),

              // ═══ GRADIENT OVERLAY ═══
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ═══ VIDEO ICON (center) ═══
              if (post.isVideo)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: width * 0.12,
                        ),
                      ),
                    ),
                  ),
                ),

              // ═══ SAVED BADGE (top-left) ═══
              Positioned(
                top: width * 0.025,
                left: width * 0.025,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.025,
                    vertical: width * 0.012,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: Colors.black,
                        size: width * 0.032,
                      ),
                      SizedBox(width: width * 0.008),
                      Text(
                        'SAVED',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: width * 0.024,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══ VIDEO BADGE (top-right) ═══
              if (post.isVideo)
                Positioned(
                  top: width * 0.025,
                  right: width * 0.025,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.02,
                      vertical: width * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: width * 0.03,
                        ),
                        SizedBox(width: width * 0.008),
                        Text(
                          'VIDEO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.022,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ═══ BOTTOM INFO ═══
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.all(width * 0.035),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                            ),
                            child: CircleAvatar(
                              radius: width * 0.035,
                              backgroundColor: Colors.black,
                              backgroundImage: post.userAvatar.isNotEmpty
                                  ? NetworkImage(post.userAvatar)
                                  : null,
                              child: post.userAvatar.isEmpty
                                  ? Text(
                                post.userName.isNotEmpty
                                    ? post.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : null,
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.userName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.036,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                            color: Colors.black,
                                            blurRadius: 4),
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
                        ],
                      ),
                      SizedBox(height: width * 0.015),

                      // Location
                      if (post.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.accentGold,
                              size: width * 0.032,
                            ),
                            SizedBox(width: width * 0.01),
                            Expanded(
                              child: Text(
                                post.location,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.028,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: width * 0.015),

                      // Caption
                      if (post.caption.isNotEmpty)
                        Text(
                          post.caption,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.032,
                            height: 1.3,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: width * 0.02),

                      // Stats row
                      Row(
                        children: [
                          // Likes
                          _statChip(
                            Icons.favorite,
                            '${post.likesCount}',
                            Colors.redAccent,
                            width,
                          ),
                          SizedBox(width: width * 0.03),
                          // Comments
                          _statChip(
                            Icons.chat_bubble_outline,
                            '${post.commentsCount}',
                            Colors.white70,
                            width,
                          ),
                          const Spacer(),
                          // Remove from saved (icon)
                          GestureDetector(
                            onTap: () => _unsavePost(post),
                            child: Container(
                              padding: EdgeInsets.all(width * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentGold
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.bookmark,
                                color: AppColors.accentGold,
                                size: width * 0.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(
      IconData icon,
      String label,
      Color color,
      double width,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: width * 0.04,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
        SizedBox(width: width * 0.008),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.03,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Future<void> _unsavePost(FeedPostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Remove from saved?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This post will be removed from your saved list.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _service.toggleSave(post.id, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Removed from saved'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ═══════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════
  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.08),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: width * 0.15,
                color: AppColors.accentGold,
              ),
            ),
            SizedBox(height: height * 0.03),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.accentGold,
                  Colors.orange.shade300,
                ],
              ).createShader(bounds),
              child: Text(
                'No Saved Posts',
                style: TextStyle(
                  fontSize: width * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: height * 0.015),
            Text(
              'Posts you save will appear here.\nTap the bookmark icon on any post!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.035,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════
  Widget _buildErrorState(Object? error, double width) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.15),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: width * 0.12,
              ),
            ),
            SizedBox(height: width * 0.06),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: width * 0.03,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STAGGERED CARD
// ═══════════════════════════════════════════════════════════
class _StaggeredCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredCard({required this.child, required this.index});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}