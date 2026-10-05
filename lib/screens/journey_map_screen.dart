import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class JourneyMapScreen extends StatefulWidget {
  const JourneyMapScreen({super.key});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen>
    with SingleTickerProviderStateMixin {
  final _service = MemoryService();
  late AnimationController _controller;
  List<MemoryModel> _memories = [];
  List<LatLng> _points = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final memories = await _service.getUserMemories().first;
    // Filter those with valid coordinates
    final valid = memories
        .where((m) => m.latitude != 0 && m.longitude != 0)
        .toList()
      ..sort((a, b) =>
          (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    if (mounted) {
      setState(() {
        _memories = valid;
        _points = valid
            .map((m) => LatLng(m.latitude, m.longitude))
            .toList();
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Default center: Tanzania
    final center = _points.isNotEmpty
        ? _points.first
        : const LatLng(-6.3690, 34.8888);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: _points.length > 1 ? 5 : 8,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Satellite tiles
              TileLayer(
                urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.turiva.app',
                maxNativeZoom: 19,
                maxZoom: 19,
                tileProvider: NetworkTileProvider(),
              ),

              // Animated Polyline
              if (_points.length > 1)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _visiblePoints(_controller.value),
                          strokeWidth: 4,
                          color: AppColors.accentGold,
                        ),
                      ],
                    );
                  },
                ),

              // Markers
              MarkerLayer(
                markers: List.generate(_memories.length, (i) {
                  final m = _memories[i];
                  final visible = i / _memories.length <= _controller.value;
                  if (!visible) return null;
                  return Marker(
                    point: LatLng(m.latitude, m.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            ],
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _controller.reset();
                      _controller.forward();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay,
                              color: Colors.black, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Replay',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info
          if (_memories.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: const ColorFilter.mode(
                      Colors.black, BlendMode.srcOver),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.accentGold),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route,
                                color: AppColors.accentGold),
                            const SizedBox(width: 8),
                            Text(
                              '${_memories.length} stops on your journey',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final visible =
                            (_controller.value * _memories.length)
                                .floor()
                                .clamp(0, _memories.length - 1);
                            final m = _memories[visible];
                            return Row(
                              children: [
                                Text(
                                  '📍 ${m.title}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESSIVE POLYLINE (line draws gradually)
  // ============================================================
  List<LatLng> _visiblePoints(double progress) {
    if (_points.length < 2) return _points;
    final total = _points.length - 1;
    final visible = (total * progress).floor();
    final partial = _points.take(visible + 1).toList();

    // Add interpolated point for smooth line
    if (visible < total && visible >= 0) {
      final a = _points[visible];
      final b = _points[visible + 1];
      final t = (total * progress) - visible;
      partial.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
    return partial;
  }
}