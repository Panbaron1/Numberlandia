import 'package:flutter/foundation.dart';

class DoublingNotifier extends ChangeNotifier {
  static const int min = 1;
  static const int max = 5000; // doubled reaches 10,000

  int _value = 3;

  int get value => _value;
  int get doubled => _value * 2;

  void set(int v) {
    _value = v.clamp(min, max);
    notifyListeners();
  }

  void step(int d) => set(_value + d);

  /// Chain a doubling: the result becomes the new value (3 → 6 → 12 → …).
  void doubleIt() => set(_value * 2);
}
