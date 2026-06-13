import 'package:flutter/foundation.dart';
import 'prefs.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  bool _sound = true;
  bool _haptics = true;

  bool get sound => _sound;
  bool get haptics => _haptics;

  Future<void> load() async {
    _sound = await Prefs.soundEnabled();
    _haptics = await Prefs.hapticsEnabled();
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    _sound = v;
    await Prefs.setSoundEnabled(v);
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    _haptics = v;
    await Prefs.setHapticsEnabled(v);
    notifyListeners();
  }
}
