import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class AirZoomService {
  AirZoomService._internal();

  static final AirZoomService instance =
      AirZoomService._internal();

  // Current zoom change.
  final ValueNotifier<double> zoomDelta =
      ValueNotifier<double>(0.0);

  // Current normalized zoom level.
  final ValueNotifier<double> zoomLevel =
      ValueNotifier<double>(1.0);

  static const double _deadZone = 0.015;
  static const double _sensitivity = 1.8;
  static const double _smoothing = 0.25;

  static const double _minimumZoom = 1.0;
  static const double _maximumZoom = 5.0;

  double? _lastDistance;
  double _smoothedDelta = 0.0;

  bool get isActive => _lastDistance != null;

  void update(List<Hand> hands) {
    if (hands.length < 2) {
      stop();
      return;
    }

    final first = hands[0];
    final second = hands[1];

    if (first.landmarks.isEmpty ||
        second.landmarks.isEmpty) {
      return;
    }

    // Landmark 0 = wrist.
    final firstWrist = first.landmarks[0];
    final secondWrist = second.landmarks[0];

    final dx = firstWrist.x - secondWrist.x;
    final dy = firstWrist.y - secondWrist.y;

    final distance = math.sqrt(
      (dx * dx) + (dy * dy),
    );

    // First frame establishes the starting distance.
    if (_lastDistance == null) {
      _lastDistance = distance;
      _smoothedDelta = 0.0;

      debugPrint(
        '👐 AIR ZOOM START '
        'distance: ${distance.toStringAsFixed(3)}',
      );

      return;
    }

    final previousDistance = _lastDistance!;
    final rawDelta = distance - previousDistance;

    _lastDistance = distance;

    // Ignore tiny camera movement.
    if (rawDelta.abs() < _deadZone) {
      _smoothedDelta *= 0.75;

      if (_smoothedDelta.abs() < 0.001) {
        _smoothedDelta = 0.0;
      }

      zoomDelta.value = _smoothedDelta;
      return;
    }

    final targetDelta =
        rawDelta * _sensitivity;

    _smoothedDelta +=
        (targetDelta - _smoothedDelta) *
            _smoothing;

    // Update zoom level.
    final newZoom =
        zoomLevel.value + _smoothedDelta;

    zoomLevel.value = newZoom.clamp(
      _minimumZoom,
      _maximumZoom,
    );

    zoomDelta.value = _smoothedDelta;

    debugPrint(
      '👐 AIR ZOOM '
      'distance: ${distance.toStringAsFixed(3)} '
      'delta: ${_smoothedDelta.toStringAsFixed(4)} '
      'zoom: ${zoomLevel.value.toStringAsFixed(2)}',
    );
  }

  void start() {
    _lastDistance = null;
    _smoothedDelta = 0.0;
    zoomDelta.value = 0.0;

    debugPrint('👐 AIR ZOOM READY');
  }

  void stop() {
    if (_lastDistance != null) {
      debugPrint('👐 AIR ZOOM STOP');
    }

    _lastDistance = null;
    _smoothedDelta = 0.0;
    zoomDelta.value = 0.0;
  }

  void reset() {
    _lastDistance = null;
    _smoothedDelta = 0.0;
    zoomDelta.value = 0.0;
    zoomLevel.value = 1.0;
  }

  void dispose() {
    zoomDelta.dispose();
    zoomLevel.dispose();
  }
}

