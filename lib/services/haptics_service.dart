import 'package:flutter/services.dart';
import '../data/prefs.dart';

class HapticsService {
  HapticsService._();
  static final HapticsService instance = HapticsService._();

  Future<void> light() async {
    if (!await Prefs.hapticsEnabled()) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!await Prefs.hapticsEnabled()) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> selection() async {
    if (!await Prefs.hapticsEnabled()) return;
    await HapticFeedback.selectionClick();
  }
}
