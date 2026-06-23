import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../data/prefs.dart';

/// A single block on the board. [id] is stable for its lifetime so the UI can
/// animate it (slide on move, pop on spawn/merge). A merge creates a *new* tile
/// (new id) that pops, while the two consumed tiles slide into its cell.
class Tile {
  final int id;
  int value;
  int x, y;
  Tile(this.id, this.value, this.x, this.y);
}

class _Snapshot {
  final List<List<int>> cells; // [x, y, value]
  final int score;
  final bool won;
  final bool keepGoing;
  _Snapshot(this.cells, this.score, this.won, this.keepGoing);
}

/// 2048-style merge engine. Same Numberblocks doubling chain as the rest of the
/// app: One + One = Two, Two + Two = Four … reach 2048.
///
/// Mechanics are a faithful port of the classic 2048 (one merge per tile per
/// move; four equal in a line make two pairs, not one) — verified headless.
class BigBlocksNotifier extends ChangeNotifier {
  static const int size = 4;
  static const int target = 2048;

  final _rng = math.Random();
  int _idSeq = 0;

  late List<List<Tile?>> _grid;

  /// Tiles consumed by a merge this move — kept for one render so they can be
  /// seen sliding into the survivor's cell (they paint *under* it).
  List<Tile> consumed = [];

  int score = 0;
  int best = 0;
  bool won = false;
  bool keepGoing = false;
  bool over = false;

  _Snapshot? _undo;

  BigBlocksNotifier() {
    _reset();
    _loadBest();
  }

  // ── Public state helpers ───────────────────────────────────────────────
  Iterable<Tile> get tiles sync* {
    for (final col in _grid) {
      for (final t in col) {
        if (t != null) yield t;
      }
    }
  }

  bool get showWin => won && !keepGoing;
  bool get canUndo => _undo != null;

  Future<void> _loadBest() async {
    best = await Prefs.bigBlocksBest();
    notifyListeners();
  }

  // ── Game lifecycle ─────────────────────────────────────────────────────
  void _reset() {
    _grid = List.generate(size, (_) => List<Tile?>.filled(size, null));
    consumed = [];
    score = 0;
    won = false;
    keepGoing = false;
    over = false;
    _undo = null;
    _addRandom();
    _addRandom();
  }

  void newGame() {
    _reset();
    notifyListeners();
  }

  void continuePlaying() {
    keepGoing = true;
    notifyListeners();
  }

  void undo() {
    final s = _undo;
    if (s == null) return;
    _grid = List.generate(size, (_) => List<Tile?>.filled(size, null));
    consumed = [];
    for (final c in s.cells) {
      _grid[c[0]][c[1]] = Tile(_idSeq++, c[2], c[0], c[1]);
    }
    score = s.score;
    won = s.won;
    keepGoing = s.keepGoing;
    over = false;
    _undo = null;
    notifyListeners();
  }

  // ── Board ops ──────────────────────────────────────────────────────────
  Tile? _at(int x, int y) =>
      (x >= 0 && x < size && y >= 0 && y < size) ? _grid[x][y] : null;

  List<List<int>> _emptyCells() {
    final r = <List<int>>[];
    for (int x = 0; x < size; x++) {
      for (int y = 0; y < size; y++) {
        if (_grid[x][y] == null) r.add([x, y]);
      }
    }
    return r;
  }

  void _addRandom() {
    final cells = _emptyCells();
    if (cells.isEmpty) return;
    final c = cells[_rng.nextInt(cells.length)];
    final v = _rng.nextDouble() < 0.9 ? 1 : 2; // mostly One, sometimes Two
    _grid[c[0]][c[1]] = Tile(_idSeq++, v, c[0], c[1]);
  }

  static const Map<String, List<int>> _vec = {
    'up': [0, -1],
    'down': [0, 1],
    'left': [-1, 0],
    'right': [1, 0],
  };

  _Snapshot _snapshot() {
    final cells = <List<int>>[];
    for (final t in tiles) {
      cells.add([t.x, t.y, t.value]);
    }
    return _Snapshot(cells, score, won, keepGoing);
  }

  /// Returns true if the move changed the board.
  bool move(String dir) {
    if (over) return false;
    final v = _vec[dir];
    if (v == null) return false;
    final vx = v[0], vy = v[1];

    final snap = _snapshot();
    consumed = [];
    final mergedThisMove = <Tile>{};
    bool moved = false;

    final xs = [for (int i = 0; i < size; i++) i];
    final ys = [for (int i = 0; i < size; i++) i];
    if (vx == 1) xs.sort((a, b) => b - a); // process from the moving edge
    if (vy == 1) ys.sort((a, b) => b - a);

    for (final x in xs) {
      for (final y in ys) {
        final tile = _grid[x][y];
        if (tile == null) continue;

        // Slide to the farthest free cell in the move direction.
        int cx = x, cy = y;
        while (true) {
          final nx = cx + vx, ny = cy + vy;
          if (nx < 0 || nx >= size || ny < 0 || ny >= size) break;
          if (_grid[nx][ny] == null) {
            cx = nx;
            cy = ny;
          } else {
            break;
          }
        }
        final nx = cx + vx, ny = cy + vy;
        final next = _at(nx, ny);

        if (next != null &&
            next.value == tile.value &&
            !mergedThisMove.contains(next)) {
          // Merge: new survivor pops in the target cell; both originals slide in.
          final merged = Tile(_idSeq++, tile.value * 2, nx, ny);
          mergedThisMove.add(merged);
          _grid[nx][ny] = merged;
          _grid[x][y] = null;
          tile.x = nx;
          tile.y = ny; // mover slides into the merge cell
          consumed.add(tile);
          consumed.add(next);
          score += merged.value;
          if (merged.value == target && !won) won = true;
          moved = true;
        } else if (cx != x || cy != y) {
          _grid[x][y] = null;
          _grid[cx][cy] = tile;
          tile.x = cx;
          tile.y = cy;
          moved = true;
        }
      }
    }

    if (moved) {
      _undo = snap;
      _addRandom();
      if (!_movesLeft()) over = true;
      if (score > best) {
        best = score;
        Prefs.setBigBlocksBest(best);
      }
      notifyListeners();
    }
    return moved;
  }

  /// Test hook: replace the board with a known layout of [x, y, value] cells.
  @visibleForTesting
  void debugSetBoard(List<List<int>> cells) {
    _grid = List.generate(size, (_) => List<Tile?>.filled(size, null));
    consumed = [];
    score = 0;
    won = false;
    keepGoing = false;
    over = false;
    _undo = null;
    for (final c in cells) {
      _grid[c[0]][c[1]] = Tile(_idSeq++, c[2], c[0], c[1]);
    }
  }

  bool _movesLeft() {
    if (_emptyCells().isNotEmpty) return true;
    for (int x = 0; x < size; x++) {
      for (int y = 0; y < size; y++) {
        final t = _grid[x][y];
        if (t == null) continue;
        for (final v in _vec.values) {
          final o = _at(x + v[0], y + v[1]);
          if (o != null && o.value == t.value) return true;
        }
      }
    }
    return false;
  }
}
