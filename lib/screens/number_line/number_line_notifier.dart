import 'package:flutter/foundation.dart';

class NumberLineNotifier extends ChangeNotifier {
  static const int minValue = -1000000;
  static const int maxValue = 1000000;

  int _current = 0;

  // viewOffset is the number-space position of the viewport center.
  // It's a double so dragging between integers is smooth.
  double _viewOffset = 0.0;

  int get current => _current;
  double get viewOffset => _viewOffset;

  int get prevNum => (_current - 1).clamp(minValue, maxValue);
  int get nextNum => (_current + 1).clamp(minValue, maxValue);

  // Dart's % operator preserves sign: -3 % 2 == -1.
  // Using .abs() makes even/odd correct for all integers.
  bool get isEven => _current.abs() % 2 == 0;

  // Jump to a specific integer and snap viewport
  void jumpTo(int value) {
    _current = value.clamp(minValue, maxValue);
    _viewOffset = _current.toDouble();
    notifyListeners();
  }

  void step(int delta) => jumpTo(_current + delta);

  // Called continuously during drag — updates viewport without snapping current
  void pan(double numberDelta) {
    _viewOffset = (_viewOffset + numberDelta).clamp(
      minValue.toDouble(),
      maxValue.toDouble(),
    );
    // Update current to nearest integer as the user drags
    final snapped = _viewOffset.round().clamp(minValue, maxValue);
    if (snapped != _current) {
      _current = snapped;
    }
    notifyListeners();
  }

  // Called when drag ends — snap viewport exactly to current integer
  void snapToCurrent() {
    _viewOffset = _current.toDouble();
    notifyListeners();
  }
}
