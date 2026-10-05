import 'dart:typed_data';

import 'game_grid.dart';

/// Hudud egallash natijasi.
class CaptureResult {
  CaptureResult(this.cells, this.takenFrom);

  /// Yangi egallangan kataklar indekslari (animatsiya uchun).
  final List<int> cells;

  /// Qaysi o'yinchidan necha katak tortib olindi (ID -> soni).
  final Map<int, int> takenFrom;

  bool get isEmpty => cells.isEmpty;
  int get count => cells.length;
}

/// Flood fill orqali hudud egallash.
///
/// Qoida: o'yinchining o'z kataklari "devor" deb olinadi va xaritaning
/// chetidan BFS yuritiladi. Chetdan yetib bo'lmagan barcha begona kataklar
/// o'ralib qolgan hisoblanadi va o'yinchiga o'tadi — shu bilan raqib hududi
/// ham o'rab olinsa egallanadi.
///
/// Scratch buferlar qayta ishlatiladi, shuning uchun har egallashda
/// yangi xotira ajratilmaydi.
class TerritoryCapturer {
  TerritoryCapturer(GameGrid grid)
    : _grid = grid,
      _reached = Uint8List(grid.cellCount),
      _queue = Int32List(grid.cellCount);

  final GameGrid _grid;
  final Uint8List _reached;
  final Int32List _queue;

  /// `trailCells` izini `playerId` hududiga aylantiradi va o'ralgan
  /// kataklarni ham unga beradi.
  CaptureResult capture(int playerId, List<int> trailCells) {
    final grid = _grid;
    final captured = <int>[];
    final takenFrom = <int, int>{};

    void claim(int i) {
      final prev = grid.owner[i];
      if (prev == playerId) return;
      if (prev != 0) takenFrom[prev] = (takenFrom[prev] ?? 0) + 1;
      grid.setOwnerIndex(i, playerId);
      captured.add(i);
    }

    // 1. Iz kataklari o'yinchiga o'tadi, iz belgisi olib tashlanadi.
    for (final i in trailCells) {
      if (grid.trail[i] == playerId) grid.setTrailIndex(i, 0);
      claim(i);
    }

    // 2. Xarita chetidan flood fill — o'z kataklaridan o'tmaydi.
    final w = grid.width;
    final h = grid.height;
    final owner = grid.owner;
    _reached.fillRange(0, _reached.length, 0);
    var head = 0;
    var tail = 0;

    void push(int i) {
      if (_reached[i] == 0 && owner[i] != playerId) {
        _reached[i] = 1;
        _queue[tail++] = i;
      }
    }

    for (var x = 0; x < w; x++) {
      push(x);
      push((h - 1) * w + x);
    }
    for (var y = 0; y < h; y++) {
      push(y * w);
      push(y * w + w - 1);
    }
    while (head < tail) {
      final i = _queue[head++];
      final x = i % w;
      if (x > 0) push(i - 1);
      if (x < w - 1) push(i + 1);
      if (i >= w) push(i - w);
      if (i < owner.length - w) push(i + w);
    }

    // 3. Yetib bo'lmagan begona kataklar — o'ralgan, demak o'yinchiga o'tadi.
    for (var i = 0; i < owner.length; i++) {
      if (_reached[i] == 0 && owner[i] != playerId) claim(i);
    }

    return CaptureResult(captured, takenFrom);
  }
}
