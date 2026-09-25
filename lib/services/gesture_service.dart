import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

enum HandGesture {
  none,
  openPalm,
  fist,
  pointing,
}

class GestureService {
  bool _pinchActive = false;

  HandGesture _stableGesture = HandGesture.none;
  HandGesture _candidateGesture = HandGesture.none;
  int _candidateFrames = 0;
  static const int _gestureConfirmationFrames = 3;

  static const double _pinchStartThreshold = 0.15;
static const double _pinchReleaseThreshold = 0.22;

  HandGesture detectGesture(Hand hand) {
    final landmarks = hand.landmarks;

    if (landmarks.length != 21) {
      return _stableGesture;
    }

    final indexOpen = _isFingerExtended(
      landmarks,
      tip: 8,
      pip: 6,
    );

    final middleOpen = _isFingerExtended(
      landmarks,
      tip: 12,
      pip: 10,
    );

    final ringOpen = _isFingerExtended(
      landmarks,
      tip: 16,
      pip: 14,
    );

    final pinkyOpen = _isFingerExtended(
      landmarks,
      tip: 20,
      pip: 18,
    );

    final openFingers = [
      indexOpen,
      middleOpen,
      ringOpen,
      pinkyOpen,
    ].where((value) => value).length;

    debugPrint(
      '🖐️ GESTURE DEBUG '
      'index=$indexOpen '
      'middle=$middleOpen '
      'ring=$ringOpen '
      'pinky=$pinkyOpen '
      'openFingers=$openFingers',
    );

    // ============================================================
    // RAW GESTURE DETECTION
    // ============================================================

    HandGesture detectedGesture = HandGesture.none;

    // 🖐️ OPEN PALM
    if (openFingers >= 3) {
      detectedGesture = HandGesture.openPalm;
    }

    // ☝️ POINTING
    else if (indexOpen &&
        !middleOpen &&
        !ringOpen &&
        !pinkyOpen) {
      detectedGesture = HandGesture.pointing;
    }

    // ✊ FIST
    else if (openFingers == 0) {
      detectedGesture = HandGesture.fist;
    }

    // ============================================================
    // 🛡️ GESTURE STABILITY FILTER
    // ============================================================

    if (detectedGesture == _candidateGesture) {
      _candidateFrames++;
    } else {
      _candidateGesture = detectedGesture;
      _candidateFrames = 1;
    }

    // ============================================================
    // CONFIRM GESTURE
    // ============================================================

    if (_candidateFrames >= _gestureConfirmationFrames) {
      if (_stableGesture != _candidateGesture) {
        debugPrint(
          '🧠 STABLE GESTURE: '
          '${_candidateGesture.name}',
        );
      }

      _stableGesture = _candidateGesture;
    }

    return _stableGesture;
  }

  bool _isFingerExtended(
      List<Landmark> landmarks, {
        required int tip,
        required int pip,
      }) {
    final tipPoint = landmarks[tip];
    final pipPoint = landmarks[pip];

    final wrist = landmarks[0];

    final tipDistance = _distance(
      tipPoint.x,
      tipPoint.y,
      wrist.x,
      wrist.y,
    );

    final pipDistance = _distance(
      pipPoint.x,
      pipPoint.y,
      wrist.x,
      wrist.y,
    );

    return tipDistance > pipDistance * 1.03;
  }

  bool isPinching(
    Hand hand, {
    bool debug = false,
  }) {
    if (hand.landmarks.length < 21) {
      if (_pinchActive) {
        _pinchActive = false;
        if (debug) {
          debugPrint(
            '🤏 PINCH RESET → HAND LOST',
          );
        }
      }

      return false;
    }

    final thumbTip = hand.landmarks[4];
    final indexTip = hand.landmarks[8];

    final dx = thumbTip.x - indexTip.x;
    final dy = thumbTip.y - indexTip.y;

    final distance = math.sqrt(
      (dx * dx) + (dy * dy),
    );

    // ============================================================
    // 🤏 PINCH START
    // ============================================================

    if (!_pinchActive &&
        distance <= _pinchStartThreshold) {
      _pinchActive = true;

      if (debug) {
        debugPrint(
          '🤏 PINCH START '
          'distance=${distance.toStringAsFixed(3)}',
        );
      }

      return true;
    }

    // ============================================================
    // 🤏 PINCH RELEASE
    // ============================================================

    if (_pinchActive &&
        distance >= _pinchReleaseThreshold) {
      _pinchActive = false;

      if (debug) {
        debugPrint(
          '🤏 PINCH RELEASE '
          'distance=${distance.toStringAsFixed(3)}',
        );
      }

      return false;
    }

    // ============================================================
    // 🤏 KEEP PINCH ACTIVE
    // ============================================================

    return _pinchActive;
  }

  void resetPinch() {
    _pinchActive = false;
  }

  void resetGestureState() {
    _stableGesture = HandGesture.none;
    _candidateGesture = HandGesture.none;
    _candidateFrames = 0;
  }

  double _distance(
      double x1,
      double y1,
      double x2,
      double y2,
      ) {
    final dx = x1 - x2;
    final dy = y1 - y2;

    return math.sqrt(
      dx * dx + dy * dy,
    );
  }
}
