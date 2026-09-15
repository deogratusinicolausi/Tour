import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  // ⭐️ Play notification sound
  static Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ⭐️ Play success sound
  static Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ⭐️ Play warning sound
  static Future<void> playWarning() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/warning.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ⭐️ Play message sound
  static Future<void> playMessage() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ⭐️ Vibrate
  static Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      print('📳 Vibration error: $e');
    }
  }

  // ⭐️ Play sound by type
  static Future<void> playByType(String type) async {
    switch (type) {
      case 'booking':
      case 'order':
        await playSuccess();
        break;
      case 'wishlist':
        await playNotification();
        break;
      case 'review':
        await playMessage();
        break;
      case 'deal':
        await playNotification();
        break;
      case 'warning':
        await playWarning();
        break;
      default:
        await playNotification();
    }
    await vibrate();
  }
}