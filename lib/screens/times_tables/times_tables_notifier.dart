import 'package:flutter/foundation.dart';

class TimesTablesNotifier extends ChangeNotifier {
  int _a = 2;
  int _b = 3;

  static const int min = 1;
  static const int max = 100; // up to 100 × 100 = 10,000

  int get a => _a;
  int get b => _b;
  int get product => _a * _b;

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
