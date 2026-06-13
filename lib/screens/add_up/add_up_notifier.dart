import 'package:flutter/foundation.dart';

/// Two addends that combine into their sum. No-fail sandbox.
class AddUpNotifier extends ChangeNotifier {
  static const int min = 0;
  static const int max = 5000; // sum reaches 10,000

  int _a = 2;
  int _b = 3;

  int get a => _a;
  int get b => _b;
  int get sum => _a + _b;

  void setA(int v) {
    _a = v.clamp(min, max);
    notifyListeners();
  }

  void setB(int v) {
    _b = v.clamp(min, max);
    notifyListeners();
  }

  void stepA(int d) => setA(_a + d);
  void stepB(int d) => setB(_b + d);
}
