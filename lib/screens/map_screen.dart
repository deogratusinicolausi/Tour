import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';

class MapScreen extends StatefulWidget {
  final double? destinationLat;
  final double? destinationLng;
  final String destinationName;

  const MapScreen({
    super.key,
    this.destinationLat,
    this.destinationLng,
    this.destinationName = 'Destination',
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _loadingLocation = false;
  Map<String, dynamic>? _selectedPark;
  LatLng? _manualLocation;
  double _heading = 0;
  String _mapStyle = 'satellite'; // satellite | streets | terrain

  // ⭐ Park boundary polygons
  List<Polygon> _parkPolygons = [];
  final Set<String> _loadedParkBoundaries = {};
  bool _loadingBoundaries = false;

  // ============================================================
  // PARKS with animal emoji
  // ============================================================
  final List<Map<String, dynamic>> _parks = [
    {'name': 'Serengeti', 'lat': -2.3333, 'lng': 34.8333, 'emoji': '🦁'},
    {'name': 'Ngorongoro', 'lat': -3.2360, 'lng': 35.4910, 'emoji': '🦏'},
    {'name': 'Tarangire', 'lat': -3.8333, 'lng': 36.0000, 'emoji': '🐘'},
    {'name': 'Lake Manyara', 'lat': -3.5000, 'lng': 35.8333, 'emoji': '🦩'},
    {'name': 'Arusha', 'lat': -3.2500, 'lng': 36.8333, 'emoji': '🦒'},
    {'name': 'Kilimanjaro', 'lat': -3.0674, 'lng': 37.3556, 'emoji': '🏔️'},
    {'name': 'Ruaha', 'lat': -7.6667, 'lng': 34.9167, 'emoji': '🐆'},
    {'name': 'Mikumi', 'lat': -7.4000, 'lng': 37.0000, 'emoji': '🦓'},
    {'name': 'Saadani', 'lat': -6.0000, 'lng': 38.7000, 'emoji': '🐢'},
    {'name': 'Gombe', 'lat': -4.6500, 'lng': 29.6333, 'emoji': '🐵'},
    {'name': 'Mahale', 'lat': -6.0000, 'lng': 29.7500, 'emoji': '🐒'},
    {'name': 'Katavi', 'lat': -6.9167, 'lng': 31.0000, 'emoji': '🐃'},
    {'name': 'Kitulo', 'lat': -9.0833, 'lng': 33.9167, 'emoji': '🌸'},
    {'name': 'Udzungwa', 'lat': -7.7500, 'lng': 36.8333, 'emoji': '🦋'},
  ];

  LatLng get _initialCenter {
    if (widget.destinationLat != null && widget.destinationLng != null) {
      return LatLng(widget.destinationLat!, widget.destinationLng!);
    }
    return const LatLng(-6.3690, 34.8888);
  }

  double get _initialZoom => 6;

  @override
  void initState() {
    super.initState();
    _startLocation();
    _startCompass();

    // ⭐ Load destination park boundary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.destinationName.isNotEmpty &&
          widget.destinationName != 'Destination') {
        _loadParkBoundary(widget.destinationName);
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // GPS
  // ============================================================
  Future<void> _startLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() => _currentPosition = position);
      });
    } catch (e) {
      debugPrint('GPS ERROR: $e');
    }
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _heading = event.heading!);
      }
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);

      _mapController.move(LatLng(position.latitude, position.longitude), 12);
    } catch (e) {
      _showMessage('Unable to get your location.');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _goToDestination() {
    if (widget.destinationLat == null || widget.destinationLng == null) return;
    _mapController.move(
      LatLng(widget.destinationLat!, widget.destinationLng!),
      14,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void _searchPark(String value) {
    setState(() => _searchText = value);
  }

  void _selectPark(Map<String, dynamic> park) {
    setState(() => _selectedPark = park);
    _mapController.move(LatLng(park['lat'], park['lng']), 11);
  }

  void _setManualLocation(LatLng point) {
    setState(() => _manualLocation = point);
    _showMessage(
      'Location selected: '
          '${point.latitude.toStringAsFixed(4)}, '
          '${point.longitude.toStringAsFixed(4)}',
    );
  }

  // ============================================================
  // DIRECTIONS
  // ============================================================
  Future<void> _openDirections(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&destination=$latitude,$longitude'
          '&travelmode=driving',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('DIRECTIONS ERROR: $e');
    }
  }

  // ============================================================
  // PARK BOUNDARY — fetch from OSM (cached in Firestore)
  // ============================================================
  Future<void> _loadParkBoundary(String parkName) async {
    if (_loadedParkBoundaries.contains(parkName)) return;
    _loadedParkBoundaries.add(parkName);

    try {
      // 1. Firestore cache first
      final cacheDoc = await FirebaseFirestore.instance
          .collection('park_boundaries')
          .doc(parkName.replaceAll(' ', '_'))
          .get();

      if (cacheDoc.exists) {
        final cachedRings = cacheDoc.data()?['rings'];
        if (cachedRings is List) {
          final polygons = <Polygon>[];
          for (var ring in cachedRings) {
            final points = _parseRing(ring as List);
            if (points.length >= 3) {
              polygons.add(Polygon(
                points: points,
                color: Colors.transparent,
                borderColor: const Color(0xFF22C55E),
                borderStrokeWidth: 2.5,
              ));
            }
          }
          if (mounted && polygons.isNotEmpty) {
            setState(() {
              _parkPolygons = [..._parkPolygons, ...polygons];
            });
            return;
          }
        }
      }

      // 2. Fetch from Nominatim — with FILTERS
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent('$parkName National Park')}'
        '&format=json&polygon_geojson=1&limit=5'
        '&countrycodes=tz',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'TURIVA/1.0 (contact@turiva.app)'},
      );

      if (res.statusCode != 200) {
        debugPrint('🔥 Nominatim status ${res.statusCode} for $parkName');
        return;
      }

      final List results = jsonDecode(res.body);
      if (results.isEmpty) {
        debugPrint('⚠️ No results for $parkName');
        return;
      }

      // 3. ⭐ FILTER — pick the correct park (not the region)
      Map<String, dynamic>? matched;
      final cleanName = parkName
          .toLowerCase()
          .replaceAll(' national park', '')
          .replaceAll(' conservation area', '')
          .trim();

      for (var r in results) {
        final cls = (r['class'] ?? '').toString();
        final typ = (r['type'] ?? '').toString();
        final displayName = (r['display_name'] ?? '').toString().toLowerCase();

        // Must contain the clean park name
        if (!displayName.contains(cleanName)) continue;

        // Must be a park type — NOT a region
        final isPark = typ == 'national_park' ||
            typ == 'protected_area' ||
            typ == 'nature_reserve' ||
            typ == 'park' ||
            cls == 'leisure';

        if (isPark) {
          matched = r;
          debugPrint('✅ Matched: $parkName → ${r['display_name']} ($typ)');
          break;
        }
      }

      if (matched == null) {
        debugPrint('⚠️ No park (only region) found for $parkName');
        return;
      }

      final geojson = matched['geojson'];
      if (geojson == null) return;

      // 4. Parse
      final rings = <List>[];

      if (geojson['type'] == 'Polygon') {
        final coords = geojson['coordinates'] as List;
        if (coords.isNotEmpty) rings.add(coords[0] as List);
      } else if (geojson['type'] == 'MultiPolygon') {
        final coords = geojson['coordinates'] as List;
        for (var poly in coords) {
          if (poly is List && poly.isNotEmpty) {
            rings.add(poly[0] as List);
          }
        }
      }

      if (rings.isEmpty) return;

      // 5. Build polygons
      final polygons = <Polygon>[];
      for (var ring in rings) {
        final points = _parseRing(ring);
        if (points.length >= 3) {
          polygons.add(Polygon(
            points: points,
            color: Colors.transparent,
            borderColor: const Color(0xFF22C55E),
            borderStrokeWidth: 2.5,
          ));
        }
      }

      if (mounted && polygons.isNotEmpty) {
        setState(() {
          _parkPolygons = [..._parkPolygons, ...polygons];
        });

        // 6. Cache
        try {
          await FirebaseFirestore.instance
              .collection('park_boundaries')
              .doc(parkName.replaceAll(' ', '_'))
              .set({
            'name': parkName,
            'rings': rings,
            'matchedName': matched['display_name'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('🔥 load boundary $parkName: $e');
    }
  }

  List<LatLng> _parseRing(List ring) {
    final points = <LatLng>[];
    for (var pt in ring) {
      if (pt is List && pt.length >= 2) {
        final lng = (pt[0] as num).toDouble();
        final lat = (pt[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Map<String, dynamic>? _nearestPark() {
    if (_currentPosition == null) return null;
    Map<String, dynamic>? nearest;
    double minDist = double.infinity;
    for (var p in _parks) {
      final d = _distanceKm(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        p['lat'],
        p['lng'],
      );
      if (d < minDist) {
        minDist = d;
        nearest = {...p, 'distance': d};
      }
    }
    return nearest;
  }

  // ============================================================
  // TILE URLS per style
  // ============================================================
  String get _baseTileUrl {
    switch (_mapStyle) {
      case 'streets':
        // OpenStreetMap — complete Tanzania data, free
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'terrain':
        // OpenTopoMap — terrain with elevation lines
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'satellite':
      default:
        // Esri Satellite — works everywhere
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // ============================================================
  // MARKERS
  // ============================================================
  Widget _destinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.black, size: 26),
        ),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accentGold),
          ),
          child: Text(
            widget.destinationName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _parkMarker(Map<String, dynamic> park) {
    final selected = _selectedPark?['name'] == park['name'];
    return GestureDetector(
      onTap: () => _selectPark(park),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 46 : 40,
            height: selected ? 46 : 40,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentGold : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black : AppColors.accentGold,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              park['emoji'] ?? '🏞️',
              style: TextStyle(fontSize: selected ? 24 : 20),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.7),
                width: 0.8,
              ),
            ),
            child: Text(
              park['name'],
              style: TextStyle(
                color: selected ? AppColors.accentGold : Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Blue dot
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _manualMarker() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.deepOrange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.person_pin_circle,
          color: Colors.white, size: 26),
    );
  }

  // ============================================================
  // SELECTED PARK CARD
  // ============================================================
  Widget _selectedParkCard() {
    if (_selectedPark == null) return const SizedBox.shrink();
    final park = _selectedPark!;

    String? distText;
    if (_currentPosition != null) {
      final d = _distanceKm(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        park['lat'],
        park['lng'],
      );
      distText = '${d.toStringAsFixed(0)} km away';
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accentGold),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        park['emoji'] ?? '🏞️',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            park['name'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (distText != null)
                            Text(
                              distText,
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedPark = null),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openDirections(park['lat'], park['lng']),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH SUGGESTIONS
  // ============================================================
  Widget _suggestions() {
    if (_searchText.trim().isEmpty) return const SizedBox.shrink();

    final matches = _parks.where((p) {
      return p['name']
          .toString()
          .toLowerCase()
          .contains(_searchText.toLowerCase());
    }).toList();

    if (matches.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: matches.take(5).map((p) {
                return ListTile(
                  dense: true,
                  leading: Text(
                    p['emoji'] ?? '🏞️',
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(
                    p['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Tap to zoom',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: AppColors.accentGold, size: 14),
                  onTap: () {
                    _selectPark(p);
                    _searchController.clear();
                    setState(() => _searchText = '');
                    FocusScope.of(context).unfocus();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STYLE SWITCHER
  // ============================================================
  Widget _styleSwitcher() {
    final styles = [
      {'key': 'satellite', 'icon': Icons.satellite_alt, 'label': 'Satellite'},
      {'key': 'streets', 'icon': Icons.map, 'label': 'Streets'},
      {'key': 'terrain', 'icon': Icons.terrain, 'label': 'Terrain'},
    ];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 90,
      left: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: styles.map((s) {
                final active = _mapStyle == s['key'];
                return GestureDetector(
                  onTap: () => setState(() => _mapStyle = s['key'] as String),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accentGold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: active ? Colors.black : AppColors.accentGold,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPASS
  // ============================================================
  Widget _compassButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 90,
      right: 75,
      child: Transform.rotate(
        angle: _heading * (math.pi / 180) * -1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold),
              ),
              child: const Icon(
                Icons.navigation,
                color: AppColors.accentGold,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEAREST PARK BANNER
  // ============================================================
  Widget _nearestBanner() {
    final np = _nearestPark();
    if (np == null) return const SizedBox.shrink();

    return Positioned(
      bottom: _selectedPark != null ? 220 : (_manualLocation != null ? 80 : 20),
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Text(
                  np['emoji'] ?? '🏞️',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEAREST PARK',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${np['name']} • ${np['distance'].toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: AppColors.accentGold, size: 14),
                  onPressed: () => _selectPark(np),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COORDINATES HUD
  // ============================================================
  Widget _coordsHud() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 146,
      left: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final hasDestination =
        widget.destinationLat != null && widget.destinationLng != null;

    final filteredParks = _parks.where((park) {
      if (_searchText.trim().isEmpty) return true;
      return park['name']
          .toString()
          .toLowerCase()
          .contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 2,
              maxZoom: 19,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onLongPress: (tapPosition, point) => _setManualLocation(point),
            ),
            children: [
              // ===== BASE LAYER =====
              TileLayer(
                urlTemplate: _baseTileUrl,
                subdomains: _mapStyle == 'satellite' ? [] : ['a', 'b', 'c'],
                userAgentPackageName: 'com.turiva.app',
                maxNativeZoom: 19,
                maxZoom: 19,
                tileProvider: NetworkTileProvider(
                  headers: {
                    'User-Agent': 'TURIVA/1.0 (contact@turiva.app)',
                  },
                ),
              ),

              // ===== ⭐ PARK BOUNDARY OUTLINE =====
              if (_parkPolygons.isNotEmpty)
                PolygonLayer(polygons: _parkPolygons),

              // ===== LABELS (only on satellite) =====
              if (_mapStyle == 'satellite')
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.turiva.app',
                  maxNativeZoom: 19,
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(),
                ),

              // Park markers
              MarkerLayer(
                markers: filteredParks.map((park) {
                  return Marker(
                    point: LatLng(park['lat'], park['lng']),
                    width: 90,
                    height: 75,
                    child: _parkMarker(park),
                  );
                }).toList(),
              ),

              // Destination marker
              if (hasDestination)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        widget.destinationLat!,
                        widget.destinationLng!,
                      ),
                      width: 150,
                      height: 90,
                      child: GestureDetector(
                        onTap: _goToDestination,
                        child: _destinationMarker(),
                      ),
                    ),
                  ],
                ),

              // User marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: _userMarker(),
                    ),
                  ],
                ),

              // Manual marker
              if (_manualLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _manualLocation!,
                      width: 50,
                      height: 50,
                      child: _manualMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // ======================================================
          // SEARCH BAR
          // ======================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.accentGold,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchPark,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.accentGold,
                        ),
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                            : null,
                        hintText: 'Search Tanzania parks...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Suggestions dropdown
          _suggestions(),

          // Style switcher (left)
          _styleSwitcher(),

          // Compass (right of switcher)
          _compassButton(),

          // Coordinates HUD
          _coordsHud(),

          // Map controls (right)
          Positioned(
            right: 14,
            top: MediaQuery.of(context).padding.top + 90,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.remove,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: _loadingLocation
                      ? Icons.hourglass_top
                      : Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                if (hasDestination) ...[
                  const SizedBox(height: 8),
                  _mapButton(
                    icon: Icons.location_on,
                    onTap: _goToDestination,
                  ),
                ],
              ],
            ),
          ),

          // Nearest park banner
          _nearestBanner(),

          // Destination info
          if (hasDestination && _selectedPark == null && _manualLocation == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.accentGold),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.park, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Viewing location',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.destinationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _goToDestination,
                          icon: const Icon(
                            Icons.center_focus_strong,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Manual location info
          if (_manualLocation != null && _selectedPark == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: '
                            '${_manualLocation!.latitude.toStringAsFixed(4)}, '
                            '${_manualLocation!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white54, size: 18),
                      onPressed: () =>
                          setState(() => _manualLocation = null),
                    ),
                  ],
                ),
              ),
            ),

          // Selected park card
          _selectedParkCard(),
        ],
      ),
    );
  }

  // ============================================================
  // MAP BUTTON
  // ============================================================
  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentGold.withOpacity(0.5),
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.accentGold,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}