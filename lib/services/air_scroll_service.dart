import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class AirScrollService {
  AirScrollService._internal();

  static final AirScrollService instance = AirScrollService._internal();

  final ValueNotifier<double> scrollAmount = ValueNotifier<double>(0.0);

  // ============================================================
  // 🎯 SMOOTH SCROLL SETTINGS
  // ============================================================

  static const double _deadZone = 3.0;
  static const double _sensitivity = 1.25;
  static const double _smoothing = 0.35;
  static const double _maxScrollSpeed = 45.0;
  static const double _minimumScrollDelta = 0.5;

  Offset? _lastPosition;

  double _smoothedDelta = 0.0;

  // ============================================================
  // 🖐️ UPDATE SCROLL
  // ============================================================

  void update(Offset position) {
    if (_lastPosition == null) {
      _lastPosition = position;
      return;
    }

    final previousPosition = _lastPosition!;

    final rawDelta = position.dy - previousPosition.dy;

    _lastPosition = position;

    // ==========================================================
    // 🛑 DEAD ZONE
    // ==========================================================

    if (rawDelta.abs() < _deadZone) {
      // Slowly bring scrolling back to zero.
      _smoothedDelta *= 0.75;

      if (_smoothedDelta.abs() < _minimumScrollDelta) {
        _smoothedDelta = 0.0;
      }

      return;
    }

    // ==========================================================
    // 🎯 TARGET SCROLL
    // ==========================================================

    final targetScroll = rawDelta * _sensitivity;

    // ==========================================================
    // 🌊 SMOOTHING
    // ==========================================================

    _smoothedDelta += (targetScroll - _smoothedDelta) * _smoothing;

    // ==========================================================
    // 🛑 LIMIT SPEED
    // ==========================================================

    final limitedScroll = _smoothedDelta.clamp(
      -_maxScrollSpeed,
      _maxScrollSpeed,
    );

    _smoothedDelta = limitedScroll.toDouble();

    // ==========================================================
    // 🛑 IGNORE VERY SMALL MOVEMENT
    // ==========================================================

    if (_smoothedDelta.abs() < _minimumScrollDelta) {
      return;
    }

    scrollAmount.value = _smoothedDelta;

    debugPrint(
      '🖐️ SMOOTH SCROLL '
      'raw: ${rawDelta.toStringAsFixed(1)} '
      'scroll: ${_smoothedDelta.toStringAsFixed(2)}',
    );

    // ==========================================================
    // 🖱️ SEND SCROLL EVENT
    // ==========================================================

    GestureBinding.instance.handlePointerEvent(
      PointerScrollEvent(
        position: position,
        scrollDelta: Offset(
          0,
          -_smoothedDelta,
        ),
      ),
    );
  }

  // ============================================================
  // 🟢 START
  // ============================================================

  void start(Offset position) {
    _lastPosition = position;
    _smoothedDelta = 0.0;
    scrollAmount.value = 0.0;

    debugPrint(
      '🖐️ SMOOTH AIR SCROLL START: $position',
    );
  }

  // ============================================================
  // 🔴 STOP
  // ============================================================

  void stop() {
    _lastPosition = null;
    _smoothedDelta = 0.0;
    scrollAmount.value = 0.0;

    debugPrint(
      '🖐️ SMOOTH AIR SCROLL STOP',
    );
  }

  // ============================================================
  // 🔄 RESET
  // ============================================================

  void reset() {
    _lastPosition = null;
    _smoothedDelta = 0.0;
    scrollAmount.value = 0.0;
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  void dispose() {
    scrollAmount.dispose();
  }
}
