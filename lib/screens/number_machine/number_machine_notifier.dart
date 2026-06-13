import 'package:flutter/foundation.dart';

enum MachineOp {
  doubleIt,
  tripleIt,
  addTen,
  subtractTen,
  addHundred,
  subtractHundred,
}

extension MachineOpX on MachineOp {
  String get label => switch (this) {
        MachineOp.doubleIt      => '× 2',
        MachineOp.tripleIt      => '× 3',
        MachineOp.addTen        => '+ 10',
        MachineOp.subtractTen   => '− 10',
        MachineOp.addHundred    => '+ 100',
        MachineOp.subtractHundred => '− 100',
      };

  String get emoji => switch (this) {
        MachineOp.doubleIt      => '🔁',
        MachineOp.tripleIt      => '🔃',
        MachineOp.addTen        => '➕',
        MachineOp.subtractTen   => '➖',
        MachineOp.addHundred    => '⬆️',
        MachineOp.subtractHundred => '⬇️',
      };

  int apply(int n) => switch (this) {
        MachineOp.doubleIt        => (n * 2).clamp(-999999, 999999),
        MachineOp.tripleIt        => (n * 3).clamp(-999999, 999999),
        MachineOp.addTen          => (n + 10).clamp(-999999, 999999),
        MachineOp.subtractTen     => (n - 10).clamp(-999999, 999999),
        MachineOp.addHundred      => (n + 100).clamp(-999999, 999999),
        MachineOp.subtractHundred => (n - 100).clamp(-999999, 999999),
      };
}

class NumberMachineNotifier extends ChangeNotifier {
  int _input = 5;
  MachineOp _op = MachineOp.doubleIt;
  int? _output; // null = not yet run

  int get input => _input;
  MachineOp get op => _op;
  int? get output => _output;

  void setInput(int v) {
    _input = v.clamp(-999, 999);
    _output = null;
    notifyListeners();
  }

  void stepInput(int d) => setInput(_input + d);

  void setOp(MachineOp op) {
    _op = op;
    _output = null;
    notifyListeners();
  }

  void run() {
    _output = _op.apply(_input);
    notifyListeners();
  }

  /// Feed the output back as the new input
  void feedBack() {
    if (_output == null) return;
    _input = _output!.clamp(-999, 999);
    _output = null;
    notifyListeners();
  }
}
