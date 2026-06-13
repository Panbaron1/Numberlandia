import 'package:flutter/foundation.dart';

/// Take Away — subtract B from A. No-fail: the result never goes below 0
/// (you can't take away more blocks than you have).
class TakeAwayNotifier extends ChangeNotifier {
  static const int min = 0;
  static const int max = 500;

  int _a = 5;
  int _b = 2;

  int get a => _a;
  int get b => _b;
  int get diff => (_a - _b) < 0 ? 0 : (_a - _b);

  void setA(int v) {
    _a = v.clamp(min, max);
    notifyListeners();
  }

  void setB(int v) {
    _b = v.clamp(min, max);
    notifyListeners();
  }
}
