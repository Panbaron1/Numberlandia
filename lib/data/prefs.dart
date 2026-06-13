import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const _kSound = 'sound_enabled_v1';
  static const _kHaptics = 'haptics_enabled_v1';

  static Future<bool> soundEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSound) ?? true;
  }

  static Future<void> setSoundEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSound, v);
  }

  static Future<bool> hapticsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kHaptics) ?? true;
  }

  static Future<void> setHapticsEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHaptics, v);
  }
}
