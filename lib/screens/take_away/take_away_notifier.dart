import 'package:flutter/foundation.dart';

/// Take Away — subtract B from A. The result can go negative (introducing
/// negative numbers), shown as a "−" character.
class TakeAwayNotifier extends ChangeNotifier {
  static const int min = 0;
  static const int max = 500;

  int _a = 5;
  int _b = 2;

  int get a => _a;
  int get b => _b;
  int get diff => _a - _b;

  void setA(int v) {
    _a = v.clamp(min, max);
    notifyListeners();
  }

  void setB(int v) {
    _b = v.clamp(min, max);
    notifyListeners();
  }
}
