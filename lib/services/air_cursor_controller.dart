import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'gesture_service.dart';
import 'hand_control_service.dart';
import 'hand_cursor_service.dart';
import 'air_interaction_service.dart';
import 'air_scroll_service.dart';

class AirCursorController {
  AirCursorController._internal();

  static final AirCursorController instance = AirCursorController._internal();

  final HandCursorService _cursorService = HandCursorService.instance;

  final AirInteractionService _airInteractionService =
      AirInteractionService.instance;

  final HandControlService _handControlService = HandControlService.instance;

  final GestureService _gestureService = GestureService();

  final AirScrollService _airScrollService = AirScrollService.instance;

  final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);

  final ValueNotifier<HandGesture> currentGesture =
      ValueNotifier<HandGesture>(HandGesture.none);

  final ValueNotifier<bool> backRequested = ValueNotifier<bool>(false);

  final ValueNotifier<int> detectedHands = ValueNotifier<int>(0);

  final ValueNotifier<int> detectedLandmarks = ValueNotifier<int>(0);

  final ValueNotifier<bool> pinchDetected = ValueNotifier<bool>(false);

  // ============================================================ // 🤏 AIR DRAG STATE // ============================================================

  bool _pinchInteractionActive = false;
  bool _dragActive = false;

  Offset? _pinchStartPosition;

  // Distance the fingertip must move before pinch becomes drag.
  static const double _dragStartThreshold = 35.0;

  // ============================================================ // 🖐️ AIR SCROLL STATE // ============================================================

  bool _scrollActive = false;

  void start() {
    if (isRunning.value) {
      return;
    }

    isRunning.value = true;

    _handControlService.enable();

    debugPrint('🟢 TURIVA AIR CURSOR STARTED');
  }

  void stop() {
    if (!isRunning.value) {
      return;
    }

    isRunning.value = false;

    _handControlService.disable();
    _cursorService.hide();

    debugPrint('🔴 TURIVA AIR CURSOR STOPPED');
  }

  void processHands(
    List<Hand> hands, {
    required double screenWidth,
    required double screenHeight,
  }) {
    if (!isRunning.value) {
      return;
    }

    // ============================================================
    // NO HAND DETECTED
    // ============================================================

    if (hands.isEmpty) {
      detectedHands.value = 0;
      detectedLandmarks.value = 0;
      pinchDetected.value = false;
      currentGesture.value = HandGesture.none;

      if (_scrollActive) {
        _airScrollService.stop();
        _scrollActive = false;
      }

      if (_dragActive) {
        final position = _cursorService.cursorPosition.value;

        if (position != null) {
          _airInteractionService.endDrag(position);
        }
      }

      _pinchInteractionActive = false;
      _dragActive = false;
      _pinchStartPosition = null;

      _gestureService.resetPinch();
      _gestureService.resetGestureState();
      _cursorService.hide();

      return;
    }

    // ============================================================
    // HAND DETECTED
    // ============================================================

    detectedHands.value = hands.length;

    final hand = hands.first;

    _cursorService.updateFromHand(
      hand,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    final gesture = _gestureService.detectGesture(hand);

    currentGesture.value = gesture;

    detectedLandmarks.value = hand.landmarks.length;

    // ============================================================
    // 🤏 PINCH DETECTION
    // ============================================================

    final isPinching = _gestureService.isPinching(
      hand,
      debug: true,
    );

    pinchDetected.value = isPinching;

    final currentPosition = _cursorService.cursorPosition.value;

    // ============================================================
    // 🤏 PINCH INTERACTION
    // ============================================================

    if (isPinching && currentPosition != null) {
      // ----------------------------------------------------------
      // PINCH START
      // ----------------------------------------------------------

      if (!_pinchInteractionActive) {
        _pinchInteractionActive = true;
        _dragActive = false;
        _pinchStartPosition = currentPosition;

        debugPrint(
          '🤏 PINCH INTERACTION START: $currentPosition',
        );
      }

      // ----------------------------------------------------------
      // CHECK FOR DRAG
      // ----------------------------------------------------------

      if (!_dragActive && _pinchStartPosition != null) {
        final dx = currentPosition.dx - _pinchStartPosition!.dx;

        final dy = currentPosition.dy - _pinchStartPosition!.dy;

        final distance = math.sqrt(
          (dx * dx) + (dy * dy),
        );

        if (distance >= _dragStartThreshold) {
          _dragActive = true;

          debugPrint(
            '🤏🖱️ DRAG ACTIVATED '
            '(distance: ${distance.toStringAsFixed(1)})',
          );

          _airInteractionService.startDrag(
            _pinchStartPosition!,
          );
        }
      }

      // ----------------------------------------------------------
      // DRAG MOVEMENT
      // ----------------------------------------------------------

      if (_dragActive) {
        _airInteractionService.updateDrag(
          currentPosition,
        );
      }
    }

    // ============================================================ // 🤏 PINCH HAS ABSOLUTE PRIORITY // ============================================================

    if (isPinching) {
      return;
    }

    // ============================================================
    // 🤏 PINCH RELEASE HAS PRIORITY
    // ============================================================

    if (!isPinching && _pinchInteractionActive) {
      // ----------------------------------------------------------
      // DRAG RELEASE
      // ----------------------------------------------------------

      if (_dragActive && currentPosition != null) {
        _airInteractionService.endDrag(
          currentPosition,
        );

        debugPrint(
          '🖱️ DRAG FINISHED',
        );
      }

      // ----------------------------------------------------------
      // NORMAL PINCH CLICK
      // ----------------------------------------------------------

      if (!_dragActive && _pinchStartPosition != null) {
        _airInteractionService.triggerClick(
          _pinchStartPosition!,
        );

        debugPrint(
          '🖱️🤏 PINCH CLICK AT: $_pinchStartPosition',
        );
      }

      _pinchInteractionActive = false;
      _dragActive = false;
      _pinchStartPosition = null;

      // Important:
      // Do not allow the same frame to activate scrolling.
      return;
    }

    // ============================================================ // 🖐️ OPEN PALM = AIR SCROLL // ============================================================

    if (gesture == HandGesture.openPalm) {
      // Open palm must NOT behave like pinch.
      _gestureService.resetPinch();
      pinchDetected.value = false;

      final position = _cursorService.cursorPosition.value;

      if (position != null) {
        if (!_scrollActive) {
          _scrollActive = true;
          _airScrollService.start(position);
          debugPrint('🖐️ AIR SCROLL ACTIVATED');
        }
        _airScrollService.update(position);
      }
      return;
    }

    // ============================================================
    // LEAVING OPEN PALM
    // ============================================================

    if (_scrollActive) {
      _airScrollService.stop();
      _scrollActive = false;
      debugPrint('🖐️ AIR SCROLL FINISHED');
    }

    // ============================================================
    // ✊ FIST / BACK
    // ============================================================

    if (gesture == HandGesture.fist && !backRequested.value) {
      backRequested.value = true;

      debugPrint(
        '✊ AIR CURSOR: FIST / BACK REQUESTED',
      );
    } else if (gesture != HandGesture.fist) {
      backRequested.value = false;
    }

    // ============================================================
    // NORMAL GESTURE CONTROL
    // ============================================================

    _handControlService.updateGesture(gesture);
  }

  void clearBackRequest() {
    backRequested.value = false;
  }

  void dispose() {
    isRunning.dispose();
  }
}
