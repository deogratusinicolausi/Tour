import 'dart:async';

import 'package:flutter/foundation.dart';

import 'gesture_service.dart';
import 'hand_action_service.dart';

class HandControlService {
  HandControlService._internal();

  static final HandControlService instance =
  HandControlService._internal();

  final ValueNotifier<HandGesture> currentGesture =
  ValueNotifier<HandGesture>(HandGesture.none);

  final ValueNotifier<bool> enabled =
  ValueNotifier<bool>(false);

  final HandActionService _actionService =
  HandActionService.instance;

  final StreamController<HandGesture> _gestureController =
  StreamController<HandGesture>.broadcast();

  Stream<HandGesture> get gestureStream =>
      _gestureController.stream;

  HandGesture _lastGesture = HandGesture.none;

  DateTime _lastGestureTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _paused = false;

  void enable() {
    enabled.value = true;
    _paused = false;
  }

  void disable() {
    enabled.value = false;
    _paused = false;
    reset();
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  void reset() {
    _lastGesture = HandGesture.none;
    currentGesture.value = HandGesture.none;
  }

  void updateGesture(HandGesture gesture) {
    if (!enabled.value) {
      return;
    }

    if (_paused && gesture != HandGesture.openPalm) {
      return;
    }

    final now = DateTime.now();

    final difference =
        now.difference(_lastGestureTime).inMilliseconds;

    // Prevent the same gesture from firing continuously.
    if (gesture == _lastGesture && difference < 700) {
      return;
    }

    // Ignore empty detection.
    if (gesture == HandGesture.none) {
      currentGesture.value = HandGesture.none;
      return;
    }

    _lastGesture = gesture;
    _lastGestureTime = now;

    currentGesture.value = gesture;
    _gestureController.add(gesture);
    _performAction(gesture);
  }

  void _performAction(HandGesture gesture) {
    switch (gesture) {
      case HandGesture.openPalm:
        break;
      case HandGesture.fist:
        // Fist/Home is handled by AirCursorController.
        break;
      case HandGesture.pointing:
        // Pointing is cursor movement only.
        // Actual click is handled by PinchClickService.
        break;
      case HandGesture.none:
        _actionService.reset();
        break;
    }
  }

  void dispose() {
    currentGesture.dispose();
    _gestureController.close();
  }
}