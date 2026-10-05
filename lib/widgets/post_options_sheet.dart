import 'package:flutter/material.dart';
import '../models/feed_post_model.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/feed_post_details_screen.dart';

class PostOptionsSheet {
  static void show(BuildContext context, FeedPostModel post) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwnPost = user?.uid == post.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isOwnPost ? 'Your Post' : 'Post Options',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 60),
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 8),

              // Options
              _option(
                icon: Icons.bookmark_border,
                label: 'Save post',
                color: AppColors.accentGold,
                onTap: () async {
                  Navigator.pop(context);
                  await FeedUserService().toggleSave(post.id, false);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔖 Saved'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              _option(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📤 Share coming soon'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              if (!isOwnPost)
                _option(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(context, post);
                  },
                ),

              if (isOwnPost)
                _option(
                  icon: Icons.edit_outlined,
                  label: 'Edit caption',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✏️ Edit coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

              if (isOwnPost)
                _option(
                  icon: Icons.delete_outline,
                  label: 'Delete post',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete post?'),
                        content: const Text(
                            'This will permanently delete your post. Cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    final ok = await FeedUserService().deleteOwnPost(post.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '✅ Deleted' : '❌ Failed'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _option({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
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
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  static void _showReportDialog(BuildContext context, FeedPostModel post) {
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'False information',
      'Other',
    ];
    String? selected;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => RadioListTile<String>(
              title: Text(r),
              value: r,
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selected == null) return;
                await FeedUserService().reportPost(post.id, selected!);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Reported. Admin will review.')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }
}