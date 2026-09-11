import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import '../utils/colors.dart';
import 'category_screen.dart'; // Ensure this file exists

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
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
              // 1. Header with welcome
              _buildHeader(width, height),

              // Lottie Animation between Header and Search Bar
              SizedBox(
                height: 300,
                child: Lottie.asset(
                  'assets/animations/diwali3.json',
                  repeat: true,
                  animate: true,
                  alignment: Alignment.center
                ),
              ),

              // 2. Search bar
              _buildSearchBar(width),

              // 3. Categories
              _buildCategories(width, height),

              // 4. Featured destinations
              _buildFeaturedDestinations(width, height),

              // 5. Special offers
              _buildSpecialOffers(width, height),

              // 6. Recommendations
              _buildRecommendations(width, height),
            ],
          ),
        ),
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
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user?.displayName ?? 'Traveler'} 👋',
                style: TextStyle(
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Where to today?',
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
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
              radius: width * 0.06,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double width) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search destinations, tours, hotels...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: height * 0.015),
        ),
        onTap: () {
          // Navigate to search page
        },
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
                color: Colors.grey.shade800,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all categories
              },
              child: Text(
                'See All',
                style: TextStyle(color: AppColors.primary),
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
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(
                        categoryName: category['name'] as String,
                        icon: category['icon'] as String,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: width * 0.22,
                  margin: EdgeInsets.only(right: width * 0.03),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: category['gradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (category['gradient'] as List<Color>)[0]
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with glow
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          category['icon'] as String,
                          style: TextStyle(fontSize: width * 0.07),
                        ),
                      ),
                      SizedBox(height: width * 0.02),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: width * 0.04),
      ],
    );
  }

  Widget _buildFeaturedDestinations(double width, double height) {
    final destinations = [
      {
        'name': 'Serengeti',
        'image': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=400',
        'price': 'Starting at \$200'
      },
      {
        'name': 'Zanzibar',
        'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
        'price': 'Starting at \$150'
      },
      {
        'name': 'Kilimanjaro',
        'image': 'https://images.unsplash.com/photo-1544731612-de6a63c6cf1a?w=400',
        'price': 'Starting at \$180'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🔥 Featured Destinations',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: width * 0.02),
        SizedBox(
          height: width * 0.5,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return Container(
                width: width * 0.6,
                margin: EdgeInsets.only(right: width * 0.03),
                child: Stack(
                  children: [
                    _buildNetworkImage(dest['image']!, width * 0.6, width * 0.5),
                    Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dest['name']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dest['price']!,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: width * 0.04),
      ],
    );
  }

  Widget _buildSpecialOffers(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⭐ Special Offers',
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: height * 0.015),
        Container(
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            gradient: AppColors.mainGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎉 20% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'All Safari Packages',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Book Now',
                  style: TextStyle(color: AppColors.accentGold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.025),
      ],
    );
  }

  Widget _buildRecommendations(double width, double height) {
    final recommendations = [
      {'name': 'Ngorongoro Crater', 'type': 'Tour', 'price': '\$120'},
      {'name': 'Lake Manyara', 'type': 'Safari', 'price': '\$90'},
      {'name': 'Arusha National Park', 'type': 'Hiking', 'price': '\$75'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Recommended for You',
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: height * 0.015),
        ...recommendations.map((item) {
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
                Container(
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['price']!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                        ),
                      ),
                      Text(
                        item['type']!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: width * 0.04,
                ),
              ],
            ),
          );
        }),
        SizedBox(height: height * 0.025),
      ],
    );
  }
}