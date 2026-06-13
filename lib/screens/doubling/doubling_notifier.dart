import 'package:flutter/foundation.dart';

class DoublingNotifier extends ChangeNotifier {
  static const int min = 1;
  static const int max = 10;

  int _value = 3;

  int get value => _value;
  int get doubled => _value * 2;

  void step(int d) {
    _value = (_value + d).clamp(min, max);
    notifyListeners();
  }
}
