import 'package:flutter/foundation.dart';

/// Builds a number digit by digit (0–9 keypad). The value drives a numberblock
/// view. Capped at 4 digits (0–9999) so the blocks stay drawable.
class NumberInputNotifier extends ChangeNotifier {
  static const int maxDigits = 6;

  String _s = '0';

  String get text => _s;
  int get value => int.tryParse(_s) ?? 0;

  void digit(int d) {
    if (_s == '0') {
      _s = '$d';
    } else if (_s.length < maxDigits) {
      _s = '$_s$d';
    }
    notifyListeners();
  }

  void backspace() {
    _s = _s.length <= 1 ? '0' : _s.substring(0, _s.length - 1);
    if (_s.isEmpty) _s = '0';
    notifyListeners();
  }

  void clear() {
    _s = '0';
    notifyListeners();
  }
}
