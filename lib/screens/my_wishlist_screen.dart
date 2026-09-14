import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';

class MyWishlistScreen extends StatelessWidget {
  const MyWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final service = WishlistService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('❤️ My Wishlist'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getUserWishlist(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: width * 0.2, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                    'No likes yet',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start liking destinations!',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(width * 0.04),
            itemCount: items.length,
            itemBuilder: (context, i) => _wishlistCard(
                items[i], width, height, service, user.uid),
          );
        },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                color: Colors.grey.shade200,
                child: const Icon(Icons.image),
              ),
            )
                : Container(
              width: width * 0.3,
              height: width * 0.3,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (item['itemType'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
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
                      color: Colors.grey.shade800,
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
                          icon: const Icon(Icons.visibility, size: 14),
                          label: const Text('View',
                              style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.008),
                            side: const BorderSide(
                                color: AppColors.primary, width: 1),
                            foregroundColor: AppColors.primary,
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