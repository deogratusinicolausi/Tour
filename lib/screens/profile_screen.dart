import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload to Firebase Storage (you need to set this up)
        // For now, just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Image selected! (Storage setup needed)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF00695C),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.05),
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

                // 🆕 TRAVEL MEMORIES
                _buildTravelMemories(width, height),
                SizedBox(height: height * 0.03),

                // 🆕 LOGOUT BUTTON
                _buildLogoutButton(width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- BUILD METHODS ----

  Widget _buildProfileHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // 🆕 PROFILE AVATAR
          Stack(
            children: [
              CircleAvatar(
                radius: width * 0.12,
                backgroundColor: Colors.white,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null
                    ? Text(
                  user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(
                    fontSize: width * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
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

          // 🆕 USER NAME & EMAIL
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

          SizedBox(height: height * 0.02),

          // 🆕 MEMBERSHIP BADGE
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF5A623).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFF5A623), size: 16),
                SizedBox(width: width * 0.02),
                Text(
                  'TURIVA TRAVELER 🏆',
                  style: TextStyle(
                    color: const Color(0xFFF5A623),
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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
                backgroundColor: const Color(0xFFF5A623),
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
      '🏔️ Kilimanjaro - 2025',
      '🏖️ Zanzibar - 2025',
      '🦁 Serengeti - 2024',
      '🌿 Ngorongoro - 2024',
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
                onPressed: () {},
                child: Text(
                  'See All',
                  style: TextStyle(color: const Color(0xFFF5A623)),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          ...memories.map((memory) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.03,
                vertical: height * 0.015,
              ),
              margin: EdgeInsets.only(bottom: height * 0.01),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                memory,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: width * 0.035,
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