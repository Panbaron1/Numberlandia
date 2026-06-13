import 'package:flutter/foundation.dart';

/// Simple two-operand kids calculator. No-fail by design: division is omitted,
/// values are clamped, and there is no error state.
class CalculatorNotifier extends ChangeNotifier {
  static const int _limit = 100000;

  int _acc = 0;
  String _entry = '0';
  String? _op; // '+', '−', '×'
  bool _fresh = true; // next digit starts a new entry

  String get display => _entry;
  String? get op => _op;
  int get value => int.tryParse(_entry) ?? 0;

  void digit(int d) {
    if (_fresh) {
      _entry = '$d';
      _fresh = false;
    } else if (_entry.replaceAll('-', '').length < 6) {
      _entry = _entry == '0' ? '$d' : '$_entry$d';
    }
    notifyListeners();
  }

  void setOp(String op) {
    _commit();
    _op = op;
    _entry = '$_acc';
    _fresh = true;
    notifyListeners();
  }

  void equals() {
    _commit();
    _op = null;
    _entry = '$_acc';
    _fresh = true;
    notifyListeners();
  }

  void clear() {
    _acc = 0;
    _entry = '0';
    _op = null;
    _fresh = true;
    notifyListeners();
  }

  void backspace() {
    if (_fresh) return;
    _entry = _entry.length <= 1 ? '0' : _entry.substring(0, _entry.length - 1);
    if (_entry.isEmpty || _entry == '-') _entry = '0';
    notifyListeners();
  }

  void _commit() {
    final e = int.tryParse(_entry) ?? 0;
    if (_op == null) {
      _acc = e;
    } else {
      _acc = switch (_op) {
        '+' => _acc + e,
        '−' => _acc - e,
        '×' => _acc * e,
        _ => e,
      };
    }
    _acc = _acc.clamp(-_limit, _limit);
  }
}
