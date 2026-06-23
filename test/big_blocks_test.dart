import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberlandia/screens/big_blocks/big_blocks_notifier.dart';

// Verifies the Big Blocks (2048) engine's classic invariants. A move always
// spawns one random tile, so we only assert specific cells and the score —
// never total tile counts (a random "2" could otherwise skew them).

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  int? valueAt(BigBlocksNotifier n, int x, int y) {
    for (final t in n.tiles) {
      if (t.x == x && t.y == y) return t.value;
    }
    return null;
  }

  test('two equal blocks merge and double', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [0, 0, 1],
      [1, 0, 1],
    ]);
    expect(n.move('left'), isTrue);
    expect(valueAt(n, 0, 0), 2);
    expect(n.score, 2);
  });

  test('only one merge per move: [1,1,1] left -> [2,1]', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [0, 0, 1],
      [1, 0, 1],
      [2, 0, 1],
    ]);
    expect(n.move('left'), isTrue);
    expect(valueAt(n, 0, 0), 2);
    expect(valueAt(n, 1, 0), 1);
    expect(n.score, 2);
  });

  test('four equal in a line make two pairs, not a 4', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [0, 0, 1],
      [1, 0, 1],
      [2, 0, 1],
      [3, 0, 1],
    ]);
    expect(n.move('left'), isTrue);
    expect(valueAt(n, 0, 0), 2);
    expect(valueAt(n, 1, 0), 2);
    expect(n.score, 4);
  });

  test('different values do not merge and a no-op move returns false', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [0, 0, 2],
      [1, 0, 4],
    ]);
    expect(n.move('left'), isFalse);
    expect(valueAt(n, 0, 0), 2);
    expect(valueAt(n, 1, 0), 4);
  });

  test('vertical merge: two 4s up -> one 8 at top', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [2, 1, 4],
      [2, 2, 4],
    ]);
    expect(n.move('up'), isTrue);
    expect(valueAt(n, 2, 0), 8);
    expect(n.score, 8);
  });

  test('undo restores the previous board and score', () {
    final n = BigBlocksNotifier();
    n.debugSetBoard([
      [0, 0, 1],
      [1, 0, 1],
    ]);
    n.move('left'); // -> a 2 at (0,0) + a random
    expect(n.canUndo, isTrue);
    n.undo();
    expect(valueAt(n, 0, 0), 1);
    expect(valueAt(n, 1, 0), 1);
    expect(n.score, 0);
  });
}
