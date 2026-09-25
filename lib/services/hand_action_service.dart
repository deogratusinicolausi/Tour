import 'package:flutter/foundation.dart';

enum HandAction {
  none,
  next,
  previous,
  back,
  select,
  confirm,
  pause,
}

class HandActionService {
  HandActionService._internal();

  static final HandActionService instance =
  HandActionService._internal();

  final ValueNotifier<HandAction> currentAction =
  ValueNotifier<HandAction>(HandAction.none);

  void perform(HandAction action) {
    currentAction.value = action;

    debugPrint('🤚 TURIVA HAND ACTION: $action');
  }

  void reset() {
    currentAction.value = HandAction.none;
  }

  void dispose() {
    currentAction.dispose();
  }
}