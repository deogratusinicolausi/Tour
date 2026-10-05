import 'package:flutter/material.dart';
import '../models/feed_post_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'feed_post_details_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FeedUserService();
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Saved Posts'),
      ),
      body: StreamBuilder<List<FeedPostModel>>(
        stream: service.getSavedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No saved posts yet'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(width * 0.03),
            itemCount: posts.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedPostDetailsScreen(post: posts[i]),
                ),
              ),
              child: Container(
                margin: EdgeInsets.only(bottom: width * 0.03),
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: posts[i].imageUrl.isNotEmpty
                          ? Image.network(
                        posts[i].imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                          : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            posts[i].userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          if (posts[i].caption.isNotEmpty)
                            Text(
                              posts[i].caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                              TextStyle(color: Colors.grey.shade600),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text('${posts[i].likesCount}',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              const Icon(Icons.chat_bubble_outline,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${posts[i].commentsCount}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}