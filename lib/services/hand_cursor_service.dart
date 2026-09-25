import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class HandCursorService {
  HandCursorService._internal();

  static final HandCursorService instance =
  HandCursorService._internal();

  final ValueNotifier<Offset?> cursorPosition =
  ValueNotifier<Offset?>(null);

  Offset? _smoothedPosition;

  // ============================================================
  // TURIVA AIR CURSOR 2.0
  // ============================================================

  // Ignore extremely small landmark movements.
  static const double _deadZone = 1.5;

  // Maximum distance used to calculate adaptive movement.
  static const double _movementScale = 100.0;

  // Smoothing for precise/small movements.
  static const double _precisionSmoothing = 0.85;

  // Smoothing for fast movements.
  static const double _fastSmoothing = 0.995;

  // Prevent tiny cursor changes from constantly rebuilding
  // the Flutter widget tree.
  static const double _updateThreshold = 0.5;

  void updateFromHand(
      Hand hand, {
        required double screenWidth,
        required double screenHeight,
      }) {
    if (hand.landmarks.length < 21) {
      return;
    }

    // Landmark #8 = index fingertip.
    final indexTip = hand.landmarks[8];

    final x = indexTip.x.clamp(0.0, 1.0);
    final y = indexTip.y.clamp(0.0, 1.0);

    // ------------------------------------------------------------
    // CAMERA → SCREEN COORDINATE TRANSFORMATION
    //
    // TECNO front camera:
    // sensor orientation = 270°
    //
    // The hand_landmarker example applies camera rotation and
    // front-camera transformation before rendering landmarks.
    // For our portrait screen mapping, the normalized axes need
    // to be exchanged.
    //
    // Raw landmark:
    //   x = camera horizontal axis
    //   y = camera vertical axis
    //
    // TURIVA screen:
    //   x = camera y
    //   y = camera x
    // ------------------------------------------------------------

    final screenX = (1.0 - y) * screenWidth;
    final screenY = (1.0 - x) * screenHeight;

    final targetPosition = Offset(
      screenX,
      screenY,
    );

    // ------------------------------------------------------------
    // FIRST POSITION
    // ------------------------------------------------------------

    if (_smoothedPosition == null) {
      _smoothedPosition = targetPosition;

      cursorPosition.value = _smoothedPosition;

      return;
    }

    final currentPosition = _smoothedPosition!;

    final dx = targetPosition.dx - currentPosition.dx;
    final dy = targetPosition.dy - currentPosition.dy;

    final distance = math.sqrt(
      (dx * dx) + (dy * dy),
    );

    // ------------------------------------------------------------
    // NOISE FILTER
    // ------------------------------------------------------------

    if (distance < _deadZone) {
      return;
    }

    // ------------------------------------------------------------
    // ADAPTIVE SMOOTHING
    // ------------------------------------------------------------

    final movementRatio =
    (distance / _movementScale).clamp(0.0, 1.0);

    final smoothing =
        _precisionSmoothing +
            ((_fastSmoothing - _precisionSmoothing) *
                movementRatio);

    final nextPosition = Offset(
      currentPosition.dx + (dx * smoothing),
      currentPosition.dy + (dy * smoothing),
    );

    // ------------------------------------------------------------
    // SCREEN BOUNDARY
    // ------------------------------------------------------------

    final boundedPosition = Offset(
      nextPosition.dx.clamp(
        0.0,
        screenWidth,
      ),
      nextPosition.dy.clamp(
        0.0,
        screenHeight,
      ),
    );

    // ------------------------------------------------------------
    // MICRO UPDATE FILTER
    // ------------------------------------------------------------

    final updateDx =
        boundedPosition.dx - currentPosition.dx;

    final updateDy =
        boundedPosition.dy - currentPosition.dy;

    final updateDistance = math.sqrt(
      (updateDx * updateDx) +
          (updateDy * updateDy),
    );

    if (updateDistance < _updateThreshold) {
      return;
    }

    // ------------------------------------------------------------
    // COMMIT POSITION
    // ------------------------------------------------------------

    _smoothedPosition = boundedPosition;

    cursorPosition.value = _smoothedPosition;
  }

  // --------------------------------------------------------------
  // HIDE CURSOR
  // --------------------------------------------------------------

  void hide() {
    cursorPosition.value = null;
  }

  // --------------------------------------------------------------
  // FULL RESET
  // --------------------------------------------------------------

  void reset() {
    _smoothedPosition = null;
    cursorPosition.value = null;
  }

  // --------------------------------------------------------------
  // DISPOSE
  // --------------------------------------------------------------

  void dispose() {
    cursorPosition.dispose();
  }
}