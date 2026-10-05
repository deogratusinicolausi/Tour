import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloudinary_service.dart';
import '../models/feed_post_model.dart';
import 'notification_service.dart';
import '../models/feed_comment_model.dart';

class FeedUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  // ═══════════════════════════════════════════
  // POSTS
  // ═══════════════════════════════════════════

  // Create post
  Future<bool> createPost({
    required File mediaFile,
    required String mediaType, // 'image' or 'video'
    required String caption,
    required String location,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Upload to Cloudinary — image or video
      String? mediaUrl;
      if (mediaType == 'video') {
        mediaUrl = await _cloudinary.uploadVideo(
          mediaFile,
          folder: 'turiva/feed/videos',
        );
      } else {
        mediaUrl = await _cloudinary.uploadImage(
          mediaFile,
          folder: 'turiva/feed',
        );
      }

      if (mediaUrl == null) return false;

      // For video, use Cloudinary auto-generated thumbnail
      final thumbnailUrl = mediaType == 'video'
          ? mediaUrl.replaceFirst(
              '/upload/',
              '/upload/so_0,w_800,h_1000,c_fill,q_auto,f_jpg,fl_attachment/',
            )
          : mediaUrl;

      await _firestore.collection('feed_posts').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Traveler',
        'userAvatar': user.photoURL ?? '',
        'imageUrl': thumbnailUrl, // thumbnail (or the image itself)
        'mediaUrl': mediaUrl,      // full media
        'mediaType': mediaType,    // 'image' or 'video'
        'caption': caption,
        'location': location,
        'likesCount': 0,
        'commentsCount': 0,
        'reportsCount': 0,
        'savesCount': 0,
        'isHidden': false,
        'hiddenReason': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 createPost: $e');
      return false;
    }
  }

  // Get feed (visible posts only)
  Stream<List<FeedPostModel>> getFeed({int limit = 20}) {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => FeedPostModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get single post (real-time)
  Stream<FeedPostModel?> getPost(String postId) {
    return _firestore
        .collection('feed_posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return FeedPostModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ═══════════════════════════════════════════
  // LIKES (subcollection — track per user)
  // ═══════════════════════════════════════════

  // Check if current user liked post
  Stream<bool> isLiked(String postId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('feed_posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Toggle like
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final postRef = _firestore.collection('feed_posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(user.uid);

      // Get post info for notification
      final postDoc = await postRef.get();
      if (!postDoc.exists) return;
      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'] as String? ?? '';

      if (currentlyLiked) {
        // Unlike
        await likeRef.delete();
        await postRef.update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await postRef.update({
          'likesCount': FieldValue.increment(1),
        });

        // ⭐ Send notification to post owner
        await NotificationService().sendNotification(
          toUserId: postOwnerId,
          fromUserId: user.uid,
          fromUserName: user.displayName ?? 'Someone',
          fromUserAvatar: user.photoURL ?? '',
          type: 'like',
          postId: postId,
          postImageUrl: postData['imageUrl'] ?? '',
          message: '${user.displayName ?? 'Someone'} liked your post',
        );
      }
    } catch (e) {
      print('🔥 toggleLike: $e');
    }
  }

  // ═══════════════════════════════════════════
  // SAVES (bookmark)
  // ═══════════════════════════════════════════

  Stream<bool> isSaved(String postId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final saveRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_posts')
          .doc(postId);

      final postRef = _firestore.collection('feed_posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists) return;
      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'] as String? ?? '';

      if (currentlySaved) {
        await saveRef.delete();
        await postRef.update({
          'savesCount': FieldValue.increment(-1),
        });
      } else {
        await saveRef.set({
          'postId': postId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        await postRef.update({
          'savesCount': FieldValue.increment(1),
        });

        // ⭐ Send notification
        await NotificationService().sendNotification(
          toUserId: postOwnerId,
          fromUserId: user.uid,
          fromUserName: user.displayName ?? 'Someone',
          fromUserAvatar: user.photoURL ?? '',
          type: 'save',
          postId: postId,
          postImageUrl: postData['imageUrl'] ?? '',
          message: '${user.displayName ?? 'Someone'} saved your post',
        );
      }
    } catch (e) {
      print('🔥 toggleSave: $e');
    }
  }

  // Get user's saved posts
  Stream<List<FeedPostModel>> getSavedPosts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final postIds = snap.docs.map((d) => d.id).toList();
      if (postIds.isEmpty) return <FeedPostModel>[];

      final posts = <FeedPostModel>[];
      for (final id in postIds) {
        final doc = await _firestore.collection('feed_posts').doc(id).get();
        if (doc.exists) {
          posts.add(FeedPostModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      return posts;
    });
  }

  // ═══════════════════════════════════════════
  // COMMENTS (subcollection)
  // ═══════════════════════════════════════════

  // Get comments for post
  Stream<List<FeedCommentModel>> getComments(String postId, {int limit = 50}) {
    return _firestore
        .collection('feed_posts')
        .doc(postId)
        .collection('comments')
        .where('isHidden', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => FeedCommentModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // Add comment
  Future<bool> addComment({
    required String postId,
    required String text,
    File? imageFile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      String imageUrl = '';
      if (imageFile != null) {
        final url = await _cloudinary.uploadImage(
          imageFile,
          folder: 'turiva/comments',
        );
        if (url != null) imageUrl = url;
      }

      // ⭐ Get post info for notification
      final postDoc =
          await _firestore.collection('feed_posts').doc(postId).get();
      if (!postDoc.exists) return false;
      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'] as String? ?? '';

      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'postId': postId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Traveler',
        'userAvatar': user.photoURL ?? '',
        'text': text,
        'imageUrl': imageUrl,
        'likesCount': 0,
        'isHidden': false,
        'hiddenReason': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment commentsCount kwenye post
      await _firestore.collection('feed_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // ⭐ Send notification
      await NotificationService().sendNotification(
        toUserId: postOwnerId,
        fromUserId: user.uid,
        fromUserName: user.displayName ?? 'Someone',
        fromUserAvatar: user.photoURL ?? '',
        type: 'comment',
        postId: postId,
        postImageUrl: postData['imageUrl'] ?? '',
        message:
            '${user.displayName ?? 'Someone'} commented: "${text.length > 30 ? '${text.substring(0, 30)}...' : text}"',
      );

      return true;
    } catch (e) {
      print('🔥 addComment: $e');
      return false;
    }
  }

  // Delete own comment
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final commentRef = _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) return false;
      if ((commentDoc.data()?['userId']) != user.uid) return false;

      await commentRef.delete();
      await _firestore.collection('feed_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('🔥 deleteComment: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // SHARES
  // ═══════════════════════════════════════════

  // ⭐ Share post (increment + notify)
  Future<void> sharePost(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final postRef = _firestore.collection('feed_posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists) return;
      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'] as String? ?? '';

      // Increment share count
      await postRef.update({
        'sharesCount': FieldValue.increment(1),
      });

      // Log share
      await _firestore.collection('feed_shares').add({
        'postId': postId,
        'sharedBy': user.uid,
        'sharedAt': FieldValue.serverTimestamp(),
      });

      // Notify post owner
      await NotificationService().sendNotification(
        toUserId: postOwnerId,
        fromUserId: user.uid,
        fromUserName: user.displayName ?? 'Someone',
        fromUserAvatar: user.photoURL ?? '',
        type: 'share',
        postId: postId,
        postImageUrl: postData['imageUrl'] ?? '',
        message: '${user.displayName ?? 'Someone'} shared your post',
      );
    } catch (e) {
      print('🔥 sharePost: $e');
    }
  }

  // ═══════════════════════════════════════════
  // REPORT
  // ═══════════════════════════════════════════

  Future<void> reportPost(String postId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('feed_posts').doc(postId).update({
        'reportsCount': FieldValue.increment(1),
      });

      await _firestore.collection('feed_reports').add({
        'postId': postId,
        'reportedBy': user.uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 reportPost: $e');
    }
  }

  // ═══════════════════════════════════════════
  // DELETE OWN POST
  // ═══════════════════════════════════════════

  Future<bool> deleteOwnPost(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc =
      await _firestore.collection('feed_posts').doc(postId).get();
      if (!doc.exists) return false;
      if (doc.data()?['userId'] != user.uid) return false;

      await _firestore.collection('feed_posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('🔥 deleteOwnPost: $e');
      return false;
    }
  }
}