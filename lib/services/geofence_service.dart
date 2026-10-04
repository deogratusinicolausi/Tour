import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class GeofenceService {
  static StreamSubscription<Position>? _sub;
  static final Set<String> _notified = {};
  static const double _radiusKm = 15; // notify within 15 km

  // ⭐ START tracking
  static Future<void> start() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 500, // check every 500m of movement
      ),
    ).listen(_checkNearby);
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  // ⭐ CORE — check proximity to all POIs
  static Future<void> _checkNearby(Position pos) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load all geofenced POIs (cached after first load)
      final snapshot = await firestore
          .collection('geo_fences')
          .where('active', isEqualTo: true)
          .limit(200)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final distanceKm = _haversine(
          pos.latitude,
          pos.longitude,
          lat,
          lng,
        );

        if (distanceKm <= _radiusKm) {
          final key = doc.id;
          if (_notified.contains(key)) continue;

          _notified.add(key);

          await NotificationService.showNearbyNotification(
            id: key,
            title: '📍 Near ${data['name']}',
            body:
                '${distanceKm.toStringAsFixed(1)} km away • ${data['subtitle'] ?? 'Tap to explore'}',
            lat: lat,
            lng: lng,
            name: data['name'],
          );
        }
      }
    } catch (e) {
      print('🔥 Geofence error: $e');
    }
  }

  // ⭐ Haversine distance
  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _rad(double d) => d * math.pi / 180;
}