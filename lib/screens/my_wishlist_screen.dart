import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wishlist_service.dart';

class MyWishlistScreen extends StatelessWidget {
  const MyWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final service = WishlistService();

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
            child: Column(
              children: [
                // --- CUSTOM TOP HEADER ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.015,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '❤️ My Wishlist',
                        style: TextStyle(
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // --- REST OF YOUR CONTENT ---
                Expanded(
                  child: user == null
                      ? const Center(child: Text('Please login', style: TextStyle(color: Colors.white)))
                      : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.getUserWishlist(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return _buildEmptyWishlist(width);
                      }
                      return ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _wishlistCard(items[i], width, height, service, user.uid),
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

  Widget _buildEmptyWishlist(double width) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: width * 0.15, color: Colors.white70),
            SizedBox(height: width * 0.04),
            Text(
              'No likes yet',
              style: TextStyle(
                fontSize: width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              'Start liking destinations!',
              style: TextStyle(color: Colors.white70, fontSize: width * 0.035),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishlistCard(
      Map<String, dynamic> item,
      double width,
      double height,
      WishlistService service,
      String userId,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: (item['itemImage'] ?? '').toString().isNotEmpty
                ? Image.network(
              item['itemImage'],
              width: width * 0.3,
              height: width * 0.3,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: width * 0.3,
                height: width * 0.3,
                color: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.image, color: Colors.white70),
              ),
            )
                : Container(
              width: width * 0.3,
              height: width * 0.3,
              color: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.image, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width * 0.035),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (item['itemType'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    item['itemName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.04,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: height * 0.01),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.visibility, size: 14, color: Colors.white),
                          label: const Text('View',
                              style: TextStyle(fontSize: 11, color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.008),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5), width: 1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      IconButton(
                        icon: const Icon(Icons.favorite,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          await service.removeFromWishlist(
                              userId, item['itemId']);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
}