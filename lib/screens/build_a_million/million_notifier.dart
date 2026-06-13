import 'package:flutter/foundation.dart';

class MillionNotifier extends ChangeNotifier {
  static const int _max = 1000000;
  static const int _min = 0;

  int _value = 0;

  int get value => _value;

  bool get atMax => _value >= _max;
  bool get atMin => _value <= _min;

  // Place value breakdown
  int get millions => _value ~/ 1000000;
  int get hundredThousands => (_value % 1000000) ~/ 100000;
  int get tenThousands => (_value % 100000) ~/ 10000;
  int get thousands => (_value % 10000) ~/ 1000;
  int get hundreds => (_value % 1000) ~/ 100;
  int get tens => (_value % 100) ~/ 10;
  int get ones => _value % 10;

  void add(int amount) {
    _value = (_value + amount).clamp(_min, _max);
    notifyListeners();
  }

  void reset() {
    _value = 0;
    notifyListeners();
  }
}
