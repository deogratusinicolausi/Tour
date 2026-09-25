import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'air_interaction_service.dart';
import 'gesture_service.dart';
import 'hand_cursor_service.dart';

class PinchClickService {
  PinchClickService._internal();

  static final PinchClickService instance =
  PinchClickService._internal();

  final GestureService _gestureService =
  GestureService();

  final AirInteractionService _interactionService =
      AirInteractionService.instance;

  final ValueNotifier<bool> isPinching =
  ValueNotifier<bool>(false);

  final ValueNotifier<Offset?> clickPosition =
  ValueNotifier<Offset?>(null);

  bool _pinchActive = false;
  bool _clickInProgress = false;

  void update(Hand hand) {
    final gesture = _gestureService.detectGesture(hand);

    // ✊ Fist and 🖐️ open palm are control gestures.
    // They must never generate a pinch click.
    if (gesture == HandGesture.fist ||
        gesture == HandGesture.openPalm) {
      if (_pinchActive) {
        _pinchActive = false;
        debugPrint('🤏 PINCH CANCELLED');
      }

      isPinching.value = false;
      return;
    }

    final pinching = _gestureService.isPinching(hand);

    isPinching.value = pinching;

    // 🤏 PINCH START
    if (pinching &&
        !_pinchActive &&
        !_clickInProgress) {
      _pinchActive = true;

      debugPrint('🤏 PINCH START');

      final position =
          HandCursorService.instance.cursorPosition.value;

      if (position != null) {
        clickPosition.value = position;
        _clickInProgress = true;

        _interactionService.triggerClick(
          position,
          onComplete: () {
            _clickInProgress = false;
          },
        );

        debugPrint(
          '🖱️🤏 ONE CLICK AT: $position',
        );
      }
    }

    // 🤏 PINCH RELEASE
    if (!pinching && _pinchActive) {
      _pinchActive = false;

      debugPrint('🤏 PINCH RELEASE');
    }
  }
  void reset() {
    _pinchActive = false;
    _clickInProgress = false;
    isPinching.value = false;
    clickPosition.value = null;

    _interactionService.reset();
  }

  void dispose() {
    isPinching.dispose();
    clickPosition.dispose();
  }
}