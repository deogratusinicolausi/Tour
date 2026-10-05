import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/memory_model.dart';
import '../services/cloudinary_service.dart';

class MemoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  // ============================================================
  // REAL-TIME STREAM — all memories for current user
  // ============================================================
  Stream<List<MemoryModel>> getUserMemories() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('memories')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MemoryModel.fromMap(d.data(), d.id))
          .toList();

      list.sort((a, b) {
        final aDate = a.date ?? DateTime(2000);
        final bDate = b.date ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ============================================================
  // FAVORITES ONLY
  // ============================================================
  Stream<List<MemoryModel>> getFavoriteMemories() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('memories')
        .where('userId', isEqualTo: user.uid)
        .where('favorite', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MemoryModel.fromMap(d.data(), d.id))
          .toList();

      list.sort((a, b) {
        final aDate = a.date ?? DateTime(2000);
        final bDate = b.date ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ============================================================
  // CREATE
  // ============================================================
  Future<String?> createMemory(MemoryModel memory) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = await _firestore.collection('memories').add({
        ...memory.toMap(),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity for admin
      try {
        await _firestore.collection('activities').add({
          'type': 'memory',
          'action': 'created',
          'title': 'New memory: ${memory.title}',
          'description': '${user.displayName ?? 'User'} added a memory',
          'userId': user.uid,
          'userName': user.displayName ?? 'User',
          'itemId': ref.id,
          'itemType': 'memory',
          'icon': '📸',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return ref.id;
    } catch (e) {
      print('🔥 createMemory: $e');
      return null;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================
  Future<bool> updateMemory(MemoryModel memory) async {
    try {
      await _firestore
          .collection('memories')
          .doc(memory.id)
          .update(memory.toMap());
      return true;
    } catch (e) {
      print('🔥 updateMemory: $e');
      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================
  Future<bool> deleteMemory(String memoryId) async {
    try {
      await _firestore.collection('memories').doc(memoryId).delete();
      return true;
    } catch (e) {
      print('🔥 deleteMemory: $e');
      return false;
    }
  }

  // ============================================================
  // TOGGLE FAVORITE
  // ============================================================
  Future<void> toggleFavorite(String memoryId, bool current) async {
    try {
      await _firestore
          .collection('memories')
          .doc(memoryId)
          .update({'favorite': !current});
    } catch (e) {
      print('🔥 toggleFavorite: $e');
    }
  }

  // ============================================================
  // UPLOAD MEDIA (image or video) to Cloudinary
  // ============================================================
  Future<String?> uploadMemoryImage(File file) async {
    try {
      return await _cloudinary.uploadImage(
        file,
        folder: 'turiva/memories/images',
      );
    } catch (e) {
      print('🔥 uploadMemoryImage: $e');
      return null;
    }
  }

  Future<String?> uploadMemoryImageBytes(Uint8List bytes) async {
    try {
      return await _cloudinary.uploadImageBytes(
        bytes,
        folder: 'turiva/memories/images',
      );
    } catch (e) {
      print('🔥 uploadMemoryImageBytes: $e');
      return null;
    }
  }

  // ============================================================
  // GROUP MEMORIES BY YEAR (for timeline)
  // ============================================================
  Map<int, List<MemoryModel>> groupByYear(List<MemoryModel> memories) {
    final map = <int, List<MemoryModel>>{};
    for (var m in memories) {
      final y = m.year;
      map.putIfAbsent(y, () => []).add(m);
    }
    return map;
  }

  // ============================================================
  // STATS (for Travel Passport)
  // ============================================================
  Future<Map<String, dynamic>> getPassportStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'total': 0,
        'countries': 0,
        'locations': 0,
        'favorites': 0,
        'photos': 0,
        'videos': 0,
      };
    }

    try {
      final snap = await _firestore
          .collection('memories')
          .where('userId', isEqualTo: user.uid)
          .get();

      final memories = snap.docs
          .map((d) => MemoryModel.fromMap(d.data(), d.id))
          .toList();

      final countries = <String>{};
      final locations = <String>{};
      int favorites = 0;
      int photos = 0;
      int videos = 0;

      for (var m in memories) {
        if (m.location.isNotEmpty) {
          locations.add(m.location.toLowerCase());
          // Very simple country guess from location string
          final parts = m.location.split(',');
          if (parts.length > 1) {
            countries.add(parts.last.trim().toLowerCase());
          }
        }
        if (m.favorite) favorites++;
        for (var type in m.mediaTypes) {
          if (type == 'image') photos++;
          if (type == 'video') videos++;
        }
      }

      return {
        'total': memories.length,
        'countries': countries.length,
        'locations': locations.length,
        'favorites': favorites,
        'photos': photos,
        'videos': videos,
      };
    } catch (e) {
      print('🔥 getPassportStats: $e');
      return {
        'total': 0,
        'countries': 0,
        'locations': 0,
        'favorites': 0,
        'photos': 0,
        'videos': 0,
      };
    }
  }
}