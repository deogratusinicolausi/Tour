import 'package:flutter/foundation.dart';

enum AirTripMode {
  inactive,
  explore,
}

enum AirTripIntent {
  none,
  hover,
  select,
  back,
  scroll,
  zoom,
}

class AirTripService {
  AirTripService._internal();

  static final AirTripService instance =
      AirTripService._internal();

  final ValueNotifier<AirTripMode> mode =
      ValueNotifier<AirTripMode>(AirTripMode.inactive);

  final ValueNotifier<AirTripIntent> intent =
      ValueNotifier<AirTripIntent>(AirTripIntent.none);

  final ValueNotifier<String?> focusedItem =
      ValueNotifier<String?>(null);

  bool get isExploreMode =>
      mode.value == AirTripMode.explore;

  void enterExploreMode() {
    mode.value = AirTripMode.explore;

    debugPrint('🚀 AIRTRIP: EXPLORE MODE ACTIVATED');
  }

  void exitExploreMode() {
    mode.value = AirTripMode.inactive;
    intent.value = AirTripIntent.none;
    focusedItem.value = null;

    debugPrint('🛑 AIRTRIP: EXPLORE MODE CLOSED');
  }

  void setIntent(AirTripIntent newIntent) {
    intent.value = newIntent;

    debugPrint(
      '🧠 AIRTRIP INTENT: ${newIntent.name}',
    );
  }

  void focus(String id) {
    focusedItem.value = id;

    setIntent(AirTripIntent.hover);

    debugPrint(
      '🎯 AIRTRIP FOCUS: $id',
    );
  }

  void clearFocus() {
    focusedItem.value = null;
    setIntent(AirTripIntent.none);
  }

  void dispose() {
    mode.dispose();
    intent.dispose();
    focusedItem.dispose();
  }
}
