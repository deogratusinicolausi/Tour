import 'dart:js_interop';

import 'package:flutter_tts/interop_types.dart';

// ⭐ Web Speech API — JS Interop

@JS('speechSynthesis')
external SpeechSynthesis get speechSynthesis;

@JS('SpeechSynthesisUtterance')
extension type SpeechSynthesisUtterance._(JSObject _) implements JSObject {
  external SpeechSynthesisUtterance([JSString text]);
  external set lang(String value);
  external set rate(num value);
  external set pitch(num value);
  external set volume(num value);
}

@JS()
extension type SpeechSynthesis._(JSObject _) implements JSObject {
  external void speak(SpeechSynthesisUtterance utterance);
  external void cancel();
}

class WebTTS {
  static void speak(
      String text, {
        String lang = 'en-US',
        double rate = 0.9,
        double pitch = 1.0,
        double volume = 1.0,
      }) {
    try {
      speechSynthesis.cancel();
      final utterance = SpeechSynthesisUtterance(text.toJS);
      utterance.lang = lang;
      utterance.rate = rate;
      utterance.pitch = pitch;
      utterance.volume = volume;
      speechSynthesis.speak(utterance);
    } catch (e) {
      print('🔥 WebTTS error: $e');
    }
  }

  static void stop() {
    try {
      speechSynthesis.cancel();
    } catch (e) {
      print('🔥 WebTTS stop error: $e');
    }
  }
}