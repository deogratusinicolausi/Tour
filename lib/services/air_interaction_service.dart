import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class AirInteractionService {
  AirInteractionService._internal();

  static final AirInteractionService instance =
  AirInteractionService._internal();

  final ValueNotifier<Offset?> clickPosition =
  ValueNotifier<Offset?>(null);

  final ValueNotifier<bool> isClicking =
  ValueNotifier<bool>(false);

  final ValueNotifier<bool> isDragging =
  ValueNotifier<bool>(false);

  // ============================================================
  // CLICK
  // ============================================================

  void triggerClick(
      Offset position, {
        VoidCallback? onComplete,
      }) {
    clickPosition.value = position;
    isClicking.value = true;

    debugPrint(
      '🖱️ AIR CLICK REQUESTED AT: $position',
    );

    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        position: position,
        buttons: kPrimaryButton,
      ),
    );

    Future<void>.delayed(
      const Duration(milliseconds: 30),
          () {
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(
            position: position,
          ),
        );

        isClicking.value = false;

        debugPrint(
          '🖱️ AIR CLICK RELEASED AT: $position',
        );

        onComplete?.call();
      },
    );
  }

  // ============================================================
  // DRAG START
  // ============================================================

  void startDrag(Offset position) {
    if (isDragging.value) {
      return;
    }

    isDragging.value = true;
    clickPosition.value = position;

    debugPrint(
      '🤏🖱️ AIR DRAG STARTED AT: $position',
    );

    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        position: position,
        buttons: kPrimaryButton,
      ),
    );
  }

  // ============================================================
  // DRAG MOVE
  // ============================================================

  void updateDrag(Offset position) {
    if (!isDragging.value) {
      return;
    }

    clickPosition.value = position;

    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        position: position,
        buttons: kPrimaryButton,
      ),
    );
  }

  // ============================================================
  // DRAG END
  // ============================================================

  void endDrag(Offset position) {
    if (!isDragging.value) {
      return;
    }

    clickPosition.value = position;

    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        position: position,
      ),
    );

    isDragging.value = false;

    debugPrint(
      '🖱️🤏 AIR DRAG RELEASED AT: $position',
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    final position = clickPosition.value;
    if (isDragging.value && position != null) {
      GestureBinding.instance.handlePointerEvent(
        PointerUpEvent(
          position: position,
        ),
      );
    }

    clickPosition.value = null;
    isClicking.value = false;
    isDragging.value = false;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    clickPosition.dispose();
    isClicking.dispose();
    isDragging.dispose();
  }
}