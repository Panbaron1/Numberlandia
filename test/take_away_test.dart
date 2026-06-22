import 'package:flutter_test/flutter_test.dart';
import 'package:numberlandia/screens/take_away/take_away_notifier.dart';

void main() {
  test('Take Away allows negative results', () {
    final n = TakeAwayNotifier()
      ..setA(2)
      ..setB(7);
    expect(n.diff, -5); // was clamped to 0 before
  });

  test('Take Away still computes positive results', () {
    final n = TakeAwayNotifier()
      ..setA(9)
      ..setB(4);
    expect(n.diff, 5);
  });
}
