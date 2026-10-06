import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/feed_user_service.dart';
import '../models/coupon_model.dart';
import '../models/feed_post_model.dart';
import 'feed_post_details_screen.dart';
import 'create_post_screen.dart';
import '../services/coupon_service.dart';
import '../widgets/coupon_card_user.dart';
import '../utils/colors.dart';
import 'feed_post_viewer_screen.dart';
import 'hotels_list_screen.dart';
import 'profile_screen.dart';
import 'explore_all_screen.dart';
import 'destination_details_screen.dart';
import 'all_featured_destinations_screen.dart';
import 'tours_list_screen.dart';
import 'beaches_list_screen.dart';
import 'mountains_list_screen.dart';
import 'culture_list_screen.dart';
import 'food_list_screen.dart';
import 'deals_list_screen.dart';
import 'notifications_screen.dart';
import '../widgets/post_options_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'coupons_screen.dart';
import 'search_screen.dart';
import 'global_feed_screen.dart';


class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ), // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ), // 3. Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: width * 0.04,
                right: width * 0.04,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(width, height),
                  SizedBox(
                    height: 300,
                    child: Lottie.asset(
                      'assets/animations/diwali3.json',
                      repeat: true,
                      animate: true,
                      alignment: Alignment.center,
                    ),
                  ),
                  _buildSearchBar(width),
                  _buildCategories(width, height),
                  _buildFeaturedDestinations(width, height),
                  _buildTurivaFeed(width, height),
                  _buildFeaturedCoupons(width, height),
                  _buildSpecialOffers(width, height),
                  _buildRecommendations(width, height),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ---- BUILD METHODS ----

  void _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildNetworkImage(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.blueGrey,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.displayName ?? 'Traveler'} 👋',
                      style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Where to today?',
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ⭐ Real-time notification bell
                  Builder(builder: (context) {
                    final notifService = NotificationService();
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      return IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      );
                    }

                    return StreamBuilder<int>(
                      stream: notifService.getUnreadCount(user.uid),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (count > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'user_profile_avatar',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: width * 0.05,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: user?.photoURL != null &&
                                  user!.photoURL!.isNotEmpty
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null ||
                                  user!.photoURL!.isEmpty
                              ? Text(
                                  user?.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                    '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black26, blurRadius: 4)
                                  ],
                                ),
                              )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          // THE BIG TITLE
          Text(
            'Explore Tanzania',
            style: TextStyle(
              fontSize: width * 0.08,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: height * 0.01),
          // The Subtitle Glass Pill
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.008),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'Safaris • Coastal • Culture • Heritage',
              style: TextStyle(color: Colors.white, fontSize: width * 0.03),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double width) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.03, top: height * 0.02),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search destinations, hotels, experiences...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    vertical: height * 0.02, horizontal: 20),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(double width, double height) {
    final categories = [
      {
        'icon': '🏨',
        'name': 'Hotels',
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        'icon': '🦁',
        'name': 'Safari',
        'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      },
      {
        'icon': '🏖️',
        'name': 'Beaches',
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      },
      {
        'icon': '⛰️',
        'name': 'Mountains',
        'gradient': [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      },
      {
        'icon': '🎭',
        'name': 'Culture',
        'gradient': [const Color(0xFFfa709a), const Color(0xFFfee140)],
      },
      {
        'icon': '🍛',
        'name': 'Food',
        'gradient': [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Explore Categories',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExploreAllScreen(
                            categoryFilter: 'All',
                          )),
                );
              },
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: width * 0.01),
                  Icon(Icons.arrow_forward,
                      color: Colors.white.withOpacity(0.9), size: width * 0.04),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.03),

        // Categories List
        SizedBox(
          height: width * 0.32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _CategoryCard(
                category: categories[index],
                onTap: () => _handleCategoryTap(categories[index]),
              );
            },
          ),
        ),
        SizedBox(height: width * 0.04),
      ],
    );
  }

  void _handleCategoryTap(Map<String, dynamic> category) {
    Widget screen;
    switch (category['name']) {
      case 'Hotels':
        screen = const HotelsListScreen();
        break;
      case 'Safari':
        screen = const ToursListScreen();
        break;
      case 'Beaches':
        screen = const BeachesListScreen();
        break;
      case 'Mountains':
        screen = const MountainsListScreen();
        break;
      case 'Culture':
        screen = const CultureListScreen();
        break;
      case 'Food':
        screen = const FoodListScreen();
        break;
      default:
        screen = const HotelsListScreen();
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _buildFeaturedDestinations(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══ Header ═══
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Animated fire emoji
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: const Text('🔥', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 6),
                Text(
                  'Featured Destinations',
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllFeaturedDestinationsScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: width * 0.01),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.accentGold,
                    size: width * 0.04,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.02),

        // ═══ Slider ═══
        SizedBox(
          height: width * 0.6,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getFeaturedDestinations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentGold,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              final destinations = snapshot.data ?? [];
              if (destinations.isEmpty) {
                return _buildEmptyState(
                  'No featured destinations yet',
                  'Add content from admin app',
                  width,
                );
              }

              return _PremiumFeaturedSlider(
                destinations: destinations,
                width: width,
                height: height,
              );
            },
          ),
        ),
        SizedBox(height: width * 0.04),
      ],
    );
  }

  Widget _buildDestinationCard(
      Map<String, dynamic> dest, double width, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailsScreen(destination: dest),
          ),
        );
      },
      child: Container(
        width: width * 0.6,
        margin: EdgeInsets.only(right: width * 0.03),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (dest['imageUrl'] ?? '').toString().isNotEmpty
                  ? Image.network(
                      dest['imageUrl'],
                      width: width * 0.6,
                      height: width * 0.5,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: width * 0.6,
                          height: width * 0.5,
                          color: Colors.grey.shade200,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: width * 0.6,
                        height: width * 0.5,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    )
                  : Container(
                      width: width * 0.6,
                      height: width * 0.5,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            // Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Featured Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest['name'] ?? 'Unnamed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((dest['location'] ?? '').toString().isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 14),
                          SizedBox(width: width * 0.01),
                          Expanded(
                            child: Text(
                              dest['location'],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.03,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurivaFeed(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══ Header ═══
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalFeedScreen()),
              ),
              child: Row(
                children: [
                  const Text('📸', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    'TURIVA Feed',
                    style: TextStyle(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                // Post button
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppColors.accentGold, size: 28),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>  CreatePostScreen()),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalFeedScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: width * 0.01),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.accentGold,
                        size: width * 0.04,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: width * 0.02),

        // ═══ Feed List ═══
        SizedBox(
          height: width * 0.85,
          child: StreamBuilder<List<FeedPostModel>>(
            stream: FeedUserService().getFeed(limit: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentGold,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return _buildEmptyFeedState(width);
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  return _buildFeedCard(posts[i], width, height);
                },
              );
            },
          ),
        ),
        SizedBox(height: width * 0.04),
      ],
    );
  }

  Widget _buildFeedCard(FeedPostModel post, double width, double height) {
    final feedService = FeedUserService();
    final cardWidth = width * 0.5;
    final cardHeight = cardWidth * 1.35;

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
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.only(right: width * 0.025),
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
            fit: StackFit.expand,
            children: [
              // ═══ IMAGE / VIDEO ═══
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
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0a0a1a),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white24,
                        size: 40,
                      ),
                    ),

              // ═══ GRADIENT ═══
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // ═══ VIDEO PLAY ICON ═══
              if (post.isVideo)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(width * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: width * 0.08,
                    ),
                  ),
                ),

              // ═══ 3-DOTS MENU ═══
              Positioned(
                top: width * 0.025,
                right: width * 0.025,
                child: GestureDetector(
                  onTap: () => PostOptionsSheet.show(context, post),
                  child: Container(
                    padding: EdgeInsets.all(width * 0.015),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: width * 0.045,
                    ),
                  ),
                ),
              ),

              // ═══ BOTTOM INFO ═══
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                            ),
                            child: CircleAvatar(
                              radius: width * 0.032,
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
                                        fontSize: width * 0.028,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          Expanded(
                            child: Text(
                              post.userName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.028,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: width * 0.01),

                      // Location
                      if (post.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.accentGold,
                              size: width * 0.026,
                            ),
                            SizedBox(width: width * 0.005),
                            Flexible(
                              child: Text(
                                post.location,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.024,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: width * 0.015),

                      // ═══ ACTIONS ROW ═══
                      Row(
                        children: [
                          // ⭐ LIKE — real-time
                          StreamBuilder<FeedPostModel?>(
                            stream: feedService.getPost(post.id),
                            builder: (context, snap) {
                              final currentPost = snap.data ?? post;
                              return StreamBuilder<bool>(
                                stream: feedService.isLiked(post.id),
                                builder: (context, likeSnap) {
                                  final liked = likeSnap.data ?? false;
                                  return GestureDetector(
                                    onTap: () => feedService.toggleLike(
                                        post.id, liked),
                                    child: Row(
                                      children: [
                                        Icon(
                                          liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: liked
                                              ? Colors.redAccent
                                              : Colors.white,
                                          size: width * 0.042,
                                        ),
                                        SizedBox(width: width * 0.005),
                                        Text(
                                          '${currentPost.likesCount}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: width * 0.028,
                                            fontWeight: FontWeight.bold,
                                            shadows: const [
                                              Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 4),
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
                          SizedBox(width: width * 0.04),

                          // ⭐ COMMENT — opens viewer
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FeedPostViewerScreen(post: post),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: width * 0.042,
                                ),
                                SizedBox(width: width * 0.005),
                                Text(
                                  '${post.commentsCount}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.028,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                          color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // ⭐ SHARE
                          GestureDetector(
                            onTap: () async {
                              try {
                                final shareText = '''
🦁 Check out this amazing post on TURIVA!
📍 ${post.location}
👤 ${post.userName}

${post.caption}

Download TURIVA app: https://turiva.app
''';
                                await Share.share(shareText);
                                await feedService.sharePost(post.id);
                              } catch (e) {
                                debugPrint('🔥 Share error: $e');
                              }
                            },
                            child: Icon(
                              Icons.share_outlined,
                            color: Colors.white,
                              size: width * 0.042,
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

// ═══════════════════════════════════════════
// HELPER — Action Pill (with label)
// ═══════════════════════════════════════════
  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.02,
          vertical: width * 0.015,
        ),
        decoration: BoxDecoration(
          color: filled
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: filled
                ? color.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: width * 0.035),
            SizedBox(width: width * 0.01),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: width * 0.028,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ═══════════════════════════════════════════
// HELPER — Icon Pill (no label)
// ═══════════════════════════════════════════
  Widget _buildIconPill({
    required IconData icon,
    required Color color,
    required bool filled,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.022),
        decoration: BoxDecoration(
          color: filled
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: filled
                ? color.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: width * 0.038),
      ),
    );
  }

  Widget _buildEmptyFeedState(double width) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.05),
      padding: EdgeInsets.all(width * 0.08),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dynamic_feed,
              size: width * 0.15,
              color: AppColors.accentGold,
            ),
          ),
          SizedBox(height: width * 0.04),
          Text(
            'No posts yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.042,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            'Be the first to share your trip!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.032,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: width * 0.15, color: Colors.grey.shade300),
          SizedBox(height: width * 0.03),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.035,
            ),
          ),
          SizedBox(height: width * 0.01),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: width * 0.028,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCoupons(double width, double height) {
    final couponService = CouponService();

    return StreamBuilder<List<CouponModel>>(
      stream: couponService.getFeaturedCoupons(),
      builder: (context, snapshot) {
        final coupons = snapshot.data ?? [];
        if (coupons.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎁 Coupons & Offers',
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CouponsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            SizedBox(height: width * 0.02),
            SizedBox(
              height: height * 0.18,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (context, i) {
                  return Container(
                    width: width * 0.85,
                    margin: EdgeInsets.only(right: width * 0.03),
                    child: CouponCardUser(
                      coupon: coupons[i],
                      showApplyButton: false,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: width * 0.04),
          ],
        );
      },
    );
  }

  Widget _buildSpecialOffers(double width, double height) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getFeaturedDeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        final deals = snapshot.data ?? [];
        if (deals.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⭐ Special Offers',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.015),
            ...deals.take(2).map((deal) {
              return Container(
                margin: EdgeInsets.only(bottom: height * 0.015),
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Image
                    if ((deal['imageUrl'] ?? '').toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          deal['imageUrl'],
                          width: width * 0.15,
                          height: width * 0.15,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: width * 0.15,
                            height: width * 0.15,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.card_giftcard,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    SizedBox(width: width * 0.03),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎉 ${deal['discount'] ?? 0}% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            deal['title'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Price
                    if (deal['salePrice'] != null)
                      Text(
                        '${deal['currency'] ?? 'USD'} ${(deal['salePrice'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DealsListScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View All Special Deals'),
              ),
            ),
            SizedBox(height: height * 0.025),
          ],
        );
      },
    );
  }

  Widget _buildRecommendations(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Recommended for You',
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: height * 0.015),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getTours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final tours = snapshot.data ?? [];
            if (tours.isEmpty) {
              return _buildEmptyState(
                'No tours yet',
                'Add content from admin app',
                width,
              );
            }
            return Column(
              children: tours.take(3).map((item) {
                return Container(
                  margin: EdgeInsets.only(bottom: height * 0.015),
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Image
                      if ((item['images'] as List?)?.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            (item['images'] as List).first,
                            width: width * 0.15,
                            height: width * 0.15,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: width * 0.15,
                              height: width * 0.15,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      SizedBox(width: width * 0.04),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Unnamed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: height * 0.005),
                            Text(
                              item['tourType'] ?? 'Tour',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: width * 0.03),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: height * 0.008),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item['currency'] ?? 'USD'} ${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: height * 0.025),
      ],
    );
  }
}

// ============================================================
// ⭐ PREMIUM FEATURED SLIDER
// ============================================================
class _PremiumFeaturedSlider extends StatefulWidget {
  final List<Map<String, dynamic>> destinations;
  final double width;
  final double height;

  const _PremiumFeaturedSlider({
    required this.destinations,
    required this.width,
    required this.height,
  });

  @override
  State<_PremiumFeaturedSlider> createState() => _PremiumFeaturedSliderState();
}

class _PremiumFeaturedSliderState extends State<_PremiumFeaturedSlider>
    with TickerProviderStateMixin {
  final PageController _pageController =
      PageController(viewportFraction: 0.82);
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.destinations.length <= 1) return;

    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (!mounted || !_pageController.hasClients) return;

        final next = (_currentPage + 1) % widget.destinations.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 900),
          curve: Curves.fastOutSlowIn,
        );
      },
    );
  }

  void _pauseAutoSlide() {
    _autoSlideTimer?.cancel();
  }

  void _resumeAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startAutoSlide();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.length <= 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.width * 0.02),
        child: _buildPremiumCard(
          widget.destinations.first,
          widget.width,
          widget.height,
          true,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _pauseAutoSlide();
              } else if (notification is ScrollEndNotification) {
                _resumeAutoSlide();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.destinations.length,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                // Haptic feedback on Android
                // HapticFeedback.selectionClick();
              },
              itemBuilder: (context, i) {
                final isActive = i == _currentPage;
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isActive ? 1.0 : 0.88,
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.7,
                        child: _buildPremiumCard(
                          widget.destinations[i],
                          widget.width,
                          widget.height,
                          isActive,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        SizedBox(height: widget.width * 0.04),

        // ⭐ Premium Dots
        _buildPremiumDots(),
      ],
    );
  }

  Widget _buildPremiumDots() {
    final total = widget.destinations.length;
    // Kama 1 tu, hakuna dots
    if (total <= 1) return const SizedBox.shrink();

    // Kama 7 au chini, onyesha zote
    if (total <= 7) {
      return SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.goldGradient : null,
                color: isActive ? null : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(
                            0.4 + _pulseController.value * 0.4,
                          ),
                          blurRadius: 12 + _pulseController.value * 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            );
          }),
        ),
      );
    }

    // Kama zaidi ya 7, onyesha 7 (centered on current)
    final List<int> visibleIndices;
    if (_currentPage <= 3) {
      visibleIndices = List.generate(7, (i) => i);
    } else if (_currentPage >= total - 4) {
      visibleIndices = List.generate(7, (i) => total - 7 + i);
    } else {
      visibleIndices = List.generate(7, (i) => _currentPage - 3 + i);
    }

    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: visibleIndices.map((i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 24 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.goldGradient : null,
              color: isActive ? null : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(
                          0.4 + _pulseController.value * 0.4,
                        ),
                        blurRadius: 12 + _pulseController.value * 6,
                      ),
                    ]
                  : [],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // PREMIUM CARD — with all effects
  // ============================================================
  Widget _buildPremiumCard(
    Map<String, dynamic> dest,
    double width,
    double height,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailsScreen(destination: dest),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            (dest['imageUrl'] ?? '').toString().isNotEmpty
                ? Image.network(
                    dest['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.image, color: Colors.white54, size: 40),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dest['name'] ?? 'Unnamed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((dest['location'] ?? '').toString().isNotEmpty) ...[
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          SizedBox(width: width * 0.01),
                          Expanded(
                            child: Text(
                              dest['location'],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.03,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          width: width * 0.22,
          margin: EdgeInsets.only(right: width * 0.03),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.category['icon'] as String,
                  style: TextStyle(fontSize: width * 0.07),
                ),
              ),
              SizedBox(height: width * 0.02),
              Text(
                widget.category['name'] as String,
                style: TextStyle(
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
