import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_made_easy/cloudinary_made_easy.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'national_parks_screen.dart';
import '../utils/colors.dart';
import 'chat_list_screen.dart';
import 'my_bookings_screen.dart';
import 'create_trip_screen.dart';
import 'turiva_chat_list_screen.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  User? user;
  String? _photoUrl;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  double _imageSize = 500;

  // 🆕 UNBELIEVABLE FEATURES
  int _travelCount = 0;
  int _countriesVisited = 0;
  int _reviewsWritten = 0;
  int _savedDestinations = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    user = _auth.getCurrentUser();
    if (user != null) {
      _nameController.text = user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
      _photoUrl = user?.photoURL;

      // Fake stats for demo
      _travelCount = 12;
      _countriesVisited = 8;
      _reviewsWritten = 45;
      _savedDestinations = 23;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      await user?.updateDisplayName(_nameController.text.trim());
      await user?.reload();
      setState(() {
        user = _auth.getCurrentUser();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      // ✅ Initialize Cloudinary service
      final cloudinary = CloudinaryService(
        cloudName: 'zy9bpr85', // Weka Cloud Name yako hapa
        uploadPreset: 'turiva_profile', // Weka preset uliyounda hapa
      );

      // ✅ Pick and upload image
      final String? url = await cloudinary.pickAndUploadImage(
        onProgress: (progress) {
          print('Uploading: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (url != null) {
        setState(() => _isLoading = true);

        // ✅ Update user profile with new photo
        await user?.updatePhotoURL(url);
        await user?.reload();

        setState(() {
          user = _auth.getCurrentUser();
          _photoUrl = url;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

     return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // 3. Main Content
          SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: width * 0.05,
                    right: width * 0.05,
                    top: width * 0.05,
                    bottom: 120, // ⭐ Space for curved nav
                  ),
                  child: Column(
                    children: [
                      // 🆕 PROFILE HEADER
                      _buildProfileHeader(width, height),
                      SizedBox(height: height * 0.03),

                      // 🆕 STATS CARDS
                      _buildStatsSection(width),
                      SizedBox(height: height * 0.03),

                      // 🆕 PROFILE FORM
                      _buildProfileForm(width, height),
                      SizedBox(height: height * 0.03),

                      // 🆕 MY REVIEWS BUTTON
                      GestureDetector(
                        onTap: () {
                          // Navigate to user reviews
                        },
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(width * 0.03),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.rate_review,
                                    color: AppColors.accentGold,
                                    size: width * 0.05),
                              ),
                              SizedBox(width: width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('My Reviews',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: width * 0.038,
                                          color: Colors.black87,
                                        )),
                                    Text('View your reviews',
                                        style: TextStyle(
                                          fontSize: width * 0.028,
                                          color: Colors.grey.shade500,
                                        )),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: width * 0.035,
                                  color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.03),

                      // 🆕 TRAVEL MEMORIES
                      _buildTravelMemories(width, height),
                      SizedBox(height: height * 0.03),

                      // 🆕 LOGOUT BUTTON
                      _buildLogoutButton(width),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // ---- BUILD METHODS ----

  Widget _buildProfileHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 🆕 PROFILE AVATAR
          Stack(
            children: [
              Container(
                width: _imageSize / 4, // Tunagawa ili isizidi kioo lakini ifuate slider
                height: _imageSize / 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: _photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : const AssetImage('assets/default.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: width * 0.04,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),

          // ✅ Image Size Slider Controls
          Column(
            children: [
              Text(
                '📐 Image Size: ${_imageSize.toInt()} px',
                style: TextStyle(color: Colors.white70, fontSize: width * 0.03),
              ),
              Slider(
                value: _imageSize,
                min: 100,
                max: 800,
                activeColor: AppColors.accentGold,
                inactiveColor: Colors.white24,
                onChanged: (value) {
                  setState(() => _imageSize = value);
                },
              ),
            ],
          ),

          // 🆕 USER NAME & EMAIL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation next to the name
              SizedBox(
                width: width * 0.12,
                height: width * 0.12,
                child: Lottie.asset(
                  'assets/animations/profile_animation.json',
                  repeat: true,
                  animate: true,
                ),
              ),
              SizedBox(width: width * 0.02),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Traveler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: width * 0.035,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: height * 0.02),

          // 🆕 MEMBERSHIP BADGE
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.01,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.accentGold, size: 16),
                SizedBox(width: width * 0.02),
                Text(
                  'TURIVA TRAVELER 🏆',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double width) {
    final stats = [
      {'icon': '✈️', 'value': _travelCount, 'label': 'Trips'},
      {'icon': '🌍', 'value': _countriesVisited, 'label': 'Countries'},
      {'icon': '⭐', 'value': _reviewsWritten, 'label': 'Reviews'},
      {'icon': '❤️', 'value': _savedDestinations, 'label': 'Saved'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.map((stat) {
        return Container(
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)), // Add border
          ),
          child: Column(
            children: [
              Text(stat['icon'].toString(), style: TextStyle(fontSize: width * 0.06)),
              Text(
                stat['value'].toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat['label'].toString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: width * 0.025,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileForm(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.01),
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // GLASS
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)), // White border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chat_bubble_outline,
                        color: AppColors.primary, size: width * 0.05),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Messages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                              color: Colors.white,
                            )),
                        Text('Chat with TURIVA Support',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: width * 0.035, color: Colors.white70),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TurivaChatListScreen()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.01),
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // GLASS
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)), // White border
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chat_bubble_outline,
                        color: AppColors.primary, size: width * 0.05),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💬 Turiva Live Chat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                              color: Colors.white,
                            )),
                        Text('Chat with support',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: width * 0.035, color: Colors.white70),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyBookingsScreen(),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.01),
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // GLASS
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)), // White border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today,
                        color: AppColors.primary, size: width * 0.05),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Bookings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                              color: Colors.white,
                            )),
                        Text('View all your bookings',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: width * 0.035, color: Colors.white70),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.01),
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // GLASS
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)), // White border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flight_takeoff,
                        color: AppColors.accentGold, size: width * 0.05),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✈️ Create Multi-Destination Trip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                              color: Colors.white,
                            )),
                        Text('Plan a complete trip',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: width * 0.035, color: Colors.white70),
                ],
              ),
            ),
          ),
          Text(
            '👤 Profile Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.04),

          // Name Field
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
// For the Name Field
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // Add white border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accentGold), // Gold when focused
              ),
            ),
          ),
          SizedBox(height: width * 0.04),

          // Email Field (Read-only)
          TextField(
            controller: _emailController,
            readOnly: true,
            style: const TextStyle(color: Colors.white70),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: width * 0.06),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                padding: EdgeInsets.symmetric(vertical: height * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'UPDATE PROFILE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelMemories(double width, double height) {
    final memories = [
      {
        'emoji': '🏔️',
        'name': 'Kilimanjaro',
        'date': '2025',
        'url': 'https://www.tanzaniaparks.go.tz/kilimanjaro',
        'image': 'https://images.unsplash.com/photo-1544731612-de6a63c6cf1a?w=400',
      },
      {
        'emoji': '🏖️',
        'name': 'Zanzibar',
        'date': '2025',
        'url': 'https://www.zanzibartourism.go.tz',
        'image': 'https://images.unsplash.com/photo-1532346751886-792675b6c2b5?w=400',
      },
      {
        'emoji': '🦁',
        'name': 'Serengeti',
        'date': '2024',
        'url': 'https://www.serengeti.com',
        'image': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=400',
      },
      {
        'emoji': '🌿',
        'name': 'Ngorongoro',
        'date': '2024',
        'url': 'https://www.ngorongorocrater.org',
        'image': 'https://images.unsplash.com/photo-1587593810167-c8496c6c8e1f?w=400',
      },
    ];

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📸 Travel Memories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NationalParksScreen()),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(color: AppColors.accentGold),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          ...memories.map((memory) {
            return GestureDetector(
              onTap: () async {
                final Uri url = Uri.parse(memory['url']!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: height * 0.015),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(memory['image']!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Row(
                    children: [
                      Text(memory['emoji']!, style: TextStyle(fontSize: width * 0.07)),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory['name']!,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                              ),
                            ),
                            Text(
                              memory['date']!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.03,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: width * 0.04,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(double width) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade800,
          padding: EdgeInsets.symmetric(vertical: width * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white),
            SizedBox(width: width * 0.03),
            Text(
              'LOG OUT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}