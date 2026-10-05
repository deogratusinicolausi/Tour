import 'package:flutter/material.dart';
import '../models/feed_post_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'feed_post_details_screen.dart';
import 'create_post_screen.dart';
import '../widgets/post_options_sheet.dart';
import 'profile_screen.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  State<GlobalFeedScreen> createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen>
    with TickerProviderStateMixin {
  final _service = FeedUserService();
  final _scrollController = ScrollController();
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════
          // 1️⃣ ANIMATED BACKGROUND GRADIENT
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _backgroundController,
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
                        _backgroundController.value,
                      )!,
                      const Color(0xFF0a0a1a),
                    ],
                    stops: [
                      0.0,
                      0.5 + (_backgroundController.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // ═══════════════════════════════════════
          // 2️⃣ FLOATING GLOW ORBS
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 - (_backgroundController.value * 50),
                    right: -50,
                    child: _buildGlowOrb(
                      200,
                      AppColors.accentGold.withOpacity(0.15),
                    ),
                  ),
                  Positioned(
                    bottom: 200 + (_backgroundController.value * 30),
                    left: -80,
                    child: _buildGlowOrb(
                      250,
                      Colors.purple.withOpacity(0.12),
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
                // ═══ CUSTOM APP BAR ═══
                _buildCustomAppBar(width),

                // ═══ FEED LIST ═══
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.accentGold,
                    backgroundColor: const Color(0xFF1a1a2e),
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(
                          const Duration(milliseconds: 500));
                    },
                    child: StreamBuilder<List<FeedPostModel>>(
                      stream: _service.getFeed(limit: 50),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGold,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final posts = snapshot.data ?? [];
                        if (posts.isEmpty) {
                          return _buildEmptyState(width);
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: posts.length,
                          itemBuilder: (context, i) =>
                              _buildCosmicPost(posts[i], width, i),
                        );
                      },
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

  // ═══════════════════════════════════════
  // HELPER — Glow orb
  // ═══════════════════════════════════════
  Widget _buildGlowOrb(double size, Color color) {
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
  // CUSTOM APP BAR
  // ═══════════════════════════════════════
  Widget _buildCustomAppBar(double width) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
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
                Icons.arrow_back,
                color: Colors.white,
                size: width * 0.055,
              ),
            ),
          ),
          SizedBox(width: width * 0.03),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.accentGold,
                      Colors.orange.shade300,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'TURIVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.055,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Text(
                  'Feed',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.03,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Create post button
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePostScreen(),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: width * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // COSMIC POST CARD
  // ═══════════════════════════════════════
  Widget _buildCosmicPost(FeedPostModel post, double width, int index) {
    // Kila post ina animation ya kuingia (staggered)
    return TweenAnimationBuilder<double>(
      key: ValueKey(post.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: width * 0.035,
          vertical: width * 0.025,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withOpacity(0.85),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ USER HEADER ═══
                _buildUserHeader(post, width),

                // ═══ MEDIA ═══
                _buildMedia(post, width),

                // ═══ CAPTION + LOCATION ═══
                if (post.caption.isNotEmpty || post.location.isNotEmpty)
                  _buildCaption(post, width),

                // ═══ ACTIONS ═══
                _buildActions(post, width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ USER HEADER ═══
  Widget _buildUserHeader(FeedPostModel post, double width) {
    return Padding(
      padding: EdgeInsets.all(width * 0.035),
      child: Row(
        children: [
          // ⭐ AVATAR — CLICKABLE
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: CircleAvatar(
                radius: width * 0.05,
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
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: width * 0.03),

          // Name + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white54,
                      size: width * 0.028,
                    ),
                    SizedBox(width: width * 0.01),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: width * 0.028,
                      ),
                    ),
                    if (post.location.isNotEmpty) ...[
                      SizedBox(width: width * 0.02),
                      Icon(
                        Icons.location_on,
                        color: AppColors.accentGold.withOpacity(0.8),
                        size: width * 0.028,
                      ),
                      SizedBox(width: width * 0.005),
                      Flexible(
                        child: Text(
                          post.location,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.028,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 3-dots
          GestureDetector(
            onTap: () => PostOptionsSheet.show(context, post),
            child: Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.more_horiz,
                color: Colors.white70,
                size: width * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ MEDIA ═══
  Widget _buildMedia(FeedPostModel post, double width) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
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
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white24,
                  size: 50,
                ),
              ),
            ),
          )
              : Container(
            color: const Color(0xFF0a0a1a),
            child: const Center(
              child: Icon(
                Icons.image,
                color: Colors.white24,
                size: 50,
              ),
            ),
          ),
        ),

        // Gradient overlay chini
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: width * 0.3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1a1a2e).withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),

        // Video play icon
        if (post.isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.5),
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

        // ⭐ Trending badge (kama likes > 10)
        if (post.likesCount > 10)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.025,
                vertical: width * 0.012,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange,
                    Colors.red.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: width * 0.03,
                  ),
                  SizedBox(width: width * 0.01),
                  Text(
                    'TRENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.024,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══ CAPTION ═══
  Widget _buildCaption(FeedPostModel post, double width) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        width * 0.04,
        width * 0.04,
        width * 0.04,
        0,
      ),
      child: Text(
        post.caption,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.038,
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ═══ ACTIONS ═══
  Widget _buildActions(FeedPostModel post, double width) {
    return Padding(
      padding: EdgeInsets.all(width * 0.035),
      child: Row(
        children: [
          // ⭐ LIKE — animated
          StreamBuilder<bool>(
            stream: _service.isLiked(post.id),
            builder: (context, snap) {
              final liked = snap.data ?? false;
              return _animatedAction(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likesCount}',
                color: liked ? Colors.redAccent : Colors.white,
                glow: liked ? Colors.redAccent : null,
                width: width,
                onTap: () => _service.toggleLike(post.id, liked),
              );
            },
          ),
          SizedBox(width: width * 0.02),

          // ⭐ COMMENT
          _animatedAction(
            icon: Icons.chat_bubble_outline,
            label: '${post.commentsCount}',
            color: Colors.white,
            width: width,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedPostDetailsScreen(post: post),
              ),
            ),
          ),

          const Spacer(),

          // ⭐ SAVE
          StreamBuilder<bool>(
            stream: _service.isSaved(post.id),
            builder: (context, snap) {
              final saved = snap.data ?? false;
              return _animatedAction(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                label: '',
                color: saved ? AppColors.accentGold : Colors.white,
                glow: saved ? AppColors.accentGold : null,
                width: width,
                onTap: () => _service.toggleSave(post.id, saved),
              );
            },
          ),
          SizedBox(width: width * 0.02),

          // ⭐ SHARE
          _animatedAction(
            icon: Icons.share_outlined,
            label: '',
            color: Colors.white,
            width: width,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📤 Share coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══ ANIMATED ACTION BUTTON ═══
  Widget _animatedAction({
    required IconData icon,
    required String label,
    required Color color,
    Color? glow,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? width * 0.025 : width * 0.035,
          vertical: width * 0.025,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: glow != null
              ? [
            BoxShadow(
              color: glow.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: width * 0.055),
            if (label.isNotEmpty) ...[
              SizedBox(width: width * 0.015),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══ EMPTY STATE ═══
  Widget _buildEmptyState(double width) {
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
                Icons.dynamic_feed,
                size: width * 0.2,
                color: AppColors.accentGold,
              ),
            ),
            SizedBox(height: width * 0.06),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.accentGold, Colors.orange.shade300],
              ).createShader(bounds),
              child: Text(
                'No posts yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: width * 0.03),
            Text(
              'Be the first to share your journey',
              style: TextStyle(
                color: Colors.white60,
                fontSize: width * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: width * 0.06),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePostScreen(),
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.08,
                  vertical: width * 0.04,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.black),
                    SizedBox(width: width * 0.02),
                    const Text(
                      'Create First Post',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}