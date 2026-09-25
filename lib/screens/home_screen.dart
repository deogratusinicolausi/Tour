import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../widgets/coupon_card_user.dart';
import '../utils/colors.dart';
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
import 'coupons_screen.dart';
import 'search_screen.dart';


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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.displayName ?? 'Traveler'} 👋',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Where to today?',
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Builder(builder: (context) {
                    final _notifService = NotificationService();
                    final _user = FirebaseAuth.instance.currentUser;

                    if (_user != null) {
                      return StreamBuilder<int>(
                        stream: _notifService.getUnreadCount(_user.uid),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (widget.onProfileTap != null) {
                        widget.onProfileTap!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: width * 0.05,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.04,
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
                            categoryFilter: '',
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
        // Baadaye specialized screens can be added here
        screen = const HotelsListScreen();
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
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '🔥 Featured Destinations',
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
                  builder: (_) => const AllFeaturedDestinationsScreen(),
                ),
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
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.9),
                  size: width * 0.04,
                ),
              ],
            ),
          ),
        ]),
        SizedBox(height: width * 0.02),
        SizedBox(
          height: width * 0.5,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getFeaturedDestinations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final destinations = snapshot.data ?? [];
              if (destinations.isEmpty) {
                return _buildEmptyState(
                  'No featured destinations yet',
                  'Add content from admin app',
                  width,
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  return _buildDestinationCard(dest, width, height);
                },
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
