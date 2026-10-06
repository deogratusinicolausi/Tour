import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'feed_post_viewer_screen.dart';

class UserFeedProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const UserFeedProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<UserFeedProfileScreen> createState() =>
      _UserFeedProfileScreenState();
}

class _UserFeedProfileScreenState extends State<UserFeedProfileScreen>
    with TickerProviderStateMixin {
  final _service = FeedUserService();
  late TabController _tabController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══ ANIMATED BACKGROUND ═══
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

          // ═══ GLOW ORBS ═══
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

          // ═══ MAIN CONTENT ═══
          NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: _GlassHeaderDelegate(
                  userId: widget.userId,
                  userName: widget.userName,
                  userAvatar: widget.userAvatar,
                  width: width,
                  tabController: _tabController,
                ),
              ),
            ],
            body: Column(
              children: [
                // ═══ TABS ═══
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e).withOpacity(0.6),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accentGold,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.grid_on, size: 20),
                        text: 'Posts',
                      ),
                      Tab(
                        icon: Icon(Icons.favorite, size: 20),
                        text: 'Liked',
                      ),
                    ],
                  ),
                ),

                // ═══ TAB CONTENT ═══
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsGrid(widget.userId, width),
                      _buildLikedGrid(widget.userId, width),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPostsGrid(String userId, double width) {
    return StreamBuilder<List<FeedPostModel>>(
      stream: _service.getUserPosts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return _buildEmpty(
              'No posts yet', Icons.photo_library_outlined, width);
        }
        return _buildGrid(posts, width);
      },
    );
  }

  Widget _buildLikedGrid(String userId, double width) {
    return StreamBuilder<List<FeedPostModel>>(
      stream: _service.getUserLikedPosts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return _buildEmpty(
              'No liked posts', Icons.favorite_border, width);
        }
        return _buildGrid(posts, width);
      },
    );
  }

  Widget _buildGrid(List<FeedPostModel> posts, double width) {
    return GridView.builder(
      padding: EdgeInsets.all(width * 0.02),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: width * 0.015,
        mainAxisSpacing: width * 0.015,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) => _StaggeredGridItem(
        index: i,
        child: _buildGridItem(posts[i], width),
      ),
    );
  }

  Widget _buildGridItem(FeedPostModel post, double width) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedPostViewerScreen(post: post),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            post.imageUrl.isNotEmpty
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
                ),
              ),
            )
                : Container(color: const Color(0xFF0a0a1a)),

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
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            if (post.isVideo)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

            Positioned(
              bottom: 6,
              left: 6,
              child: StreamBuilder<FeedPostModel?>(
                stream: _service.getPost(post.id),
                builder: (context, snapshot) {
                  final currentPost = snapshot.data ?? post;
                  return Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${currentPost.likesCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.accentGold,
      ),
    );
  }

  Widget _buildEmpty(String text, IconData icon, double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentGold.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              icon,
              size: width * 0.15,
              color: AppColors.accentGold,
            ),
          ),
          SizedBox(height: width * 0.04),
          Text(
            text,
            style: TextStyle(
              color: Colors.white54,
              fontSize: width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ⭐ GLASS HEADER DELEGATE
// ═══════════════════════════════════════════════════════════
class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userId;
  final String userName;
  final String userAvatar;
  final double width;
  final TabController tabController;

  _GlassHeaderDelegate({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.width,
    required this.tabController,
  });

  @override
  double get minExtent => 110;

  @override
  double get maxExtent => width * 0.72;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress =
    (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15 + progress * 10,
          sigmaY: 15 + progress * 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e).withOpacity(0.7 + progress * 0.25),
                Colors.purple.shade900.withOpacity(0.3 + progress * 0.4),
                const Color(0xFF0a0a1a).withOpacity(0.8 + progress * 0.2),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentGold
                            .withOpacity(0.3 - progress * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: width * 0.04,
                  right: width * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.accentGold,
                                Colors.orange.shade300,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              userName.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _shareProfile(context, userName, userId),
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
                              Icons.share_outlined,
                              color: Colors.white,
                              size: width * 0.05,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: width * 0.04),

                    Opacity(
                      opacity: (1 - progress * 1.5).clamp(0.0, 1.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGold
                                      .withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: width * 0.11,
                              backgroundColor: Colors.black,
                              backgroundImage: userAvatar.isNotEmpty
                                  ? NetworkImage(userAvatar)
                                  : null,
                              child: userAvatar.isEmpty
                                  ? Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.09,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : null,
                            ),
                          ),
                          SizedBox(width: width * 0.04),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        userName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.05,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.015),
                                    Icon(
                                      Icons.verified,
                                      color: AppColors.accentGold,
                                      size: width * 0.04,
                                    ),
                                  ],
                                ),
                                SizedBox(height: width * 0.008),
                                Text(
                                  'TURIVA Traveler',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: width * 0.03,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: width * 0.03),

                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('feed_posts')
                                      .where('userId', isEqualTo: userId)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final docs =
                                        snapshot.data?.docs ?? [];
                                    int totalLikes = 0;
                                    for (var doc in docs) {
                                      final count =
                                      ((doc.data() as Map)[
                                      'likesCount'] ??
                                          0) as int;
                                      if (count > 0) totalLikes += count;
                                    }
                                    return Row(
                                      children: [
                                        _statPill(
                                            '${docs.length}', 'Posts', width),
                                        SizedBox(width: width * 0.015),
                                        _statPill('$totalLikes', 'Likes',
                                            width),
                                        SizedBox(width: width * 0.015),
                                        _statPill(
                                            '${docs.length}', 'Trips', width),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String value, String label, double width) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.025,
        vertical: width * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.accentGold,
              fontSize: width * 0.034,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: width * 0.006),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.026,
            ),
          ),
        ],
      ),
    );
  }

  void _shareProfile(BuildContext context, String userName, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share,
                        color: AppColors.accentGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share @$userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Options
              _shareOption(
                icon: Icons.share,
                label: 'Share profile',
                sublabel: 'Send to friends',
                color: Colors.blue,
                onTap: () async {
                  Navigator.pop(context);
                  await _nativeShare(userName, userId);
                },
              ),
              _shareOption(
                icon: Icons.link,
                label: 'Copy link',
                sublabel: 'Copy profile link',
                color: Colors.purple,
                onTap: () async {
                  Navigator.pop(context);
                  await _copyLink(context, userName, userId);
                },
              ),
              _shareOption(
                icon: Icons.message,
                label: 'Send message',
                sublabel: 'Share via TURIVA chat',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💬 Chat feature coming soon'),
                    ),
                  );
                },
              ),
              _shareOption(
                icon: Icons.qr_code,
                label: 'QR code',
                sublabel: 'Show profile QR',
                color: AppColors.accentGold,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📱 QR code coming soon'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        sublabel,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════
// ⭐ STAGGERED GRID ITEM
// ═══════════════════════════════════════════════════════════

Future<void> _nativeShare(String userName, String userId) async {
  try {
    final shareText = ''' 🌍 Check out @$userName on TURIVA! 👤 Profile: https://turiva.app/user/$userId  Discover amazing travel posts, tips, and stories. Download TURIVA: https://turiva.app ''';
    await Share.share(
      shareText,
      subject: 'TURIVA - @$userName',
    );
  } catch (e) {
    debugPrint('🔥 Share error: $e');
  }
}

Future<void> _copyLink(BuildContext context, String userName, String userId) async {
  try {
    final link = 'https://turiva.app/user/$userId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('🔗 Profile link copied!'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('🔥 Copy error: $e');
  }
}

class _StaggeredGridItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredGridItem({required this.child, required this.index});

  @override
  State<_StaggeredGridItem> createState() => _StaggeredGridItemState();
}

class _StaggeredGridItemState extends State<_StaggeredGridItem>
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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
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