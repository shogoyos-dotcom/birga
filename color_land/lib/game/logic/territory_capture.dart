import 'dart:math' as math;
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

    // 2. Flood fill. Butun xaritani emas, faqat o'yinchi hududini o'rab
    // turgan to'rtburchakni (bir katak kengaytirilgan holda) tekshiramiz.
    //
    // Bu to'g'ri, chunki "devor" vazifasini faqat shu o'yinchining kataklari
    // bajaradi: to'rtburchakdan tashqarida uning birorta katagi yo'q, demak
    // u yerdagi hamma bo'sh joy o'zaro va xarita cheti bilan tutashgan va
    // hech qachon "o'ralgan" bo'la olmaydi. To'rtburchak ichiga tashqaridan
    // kirish esa faqat uning chekka halqasi orqali mumkin — biz BFS ni
    // o'sha halqadan boshlaymiz.
    final bounds = grid.boundsOf(playerId);
    if (bounds == null) return CaptureResult(captured, takenFrom);

    final w = grid.width;
    final h = grid.height;
    final owner = grid.owner;
    final x0 = math.max(0, bounds.$1 - 1);
    final y0 = math.max(0, bounds.$2 - 1);
    final x1 = math.min(w - 1, bounds.$3 + 1);
    final y1 = math.min(h - 1, bounds.$4 + 1);

    for (var y = y0; y <= y1; y++) {
      _reached.fillRange(y * w + x0, y * w + x1 + 1, 0);
    }

    var head = 0;
    var tail = 0;

    void push(int x, int y) {
      final i = y * w + x;
      if (_reached[i] == 0 && owner[i] != playerId) {
        _reached[i] = 1;
        _queue[tail++] = i;
      }
    }

    for (var x = x0; x <= x1; x++) {
      push(x, y0);
      push(x, y1);
    }
    for (var y = y0; y <= y1; y++) {
      push(x0, y);
      push(x1, y);
    }
    while (head < tail) {
      final i = _queue[head++];
      final x = i % w;
      final y = i ~/ w;
      if (x > x0) push(x - 1, y);
      if (x < x1) push(x + 1, y);
      if (y > y0) push(x, y - 1);
      if (y < y1) push(x, y + 1);
    }

    // 3. Yetib bo'lmagan begona kataklar — o'ralgan, demak o'yinchiga o'tadi.
    for (var y = y0; y <= y1; y++) {
      final row = y * w;
      for (var x = x0; x <= x1; x++) {
        final i = row + x;
        // Suv hech qachon egallanmaydi: o'ralib qolgan ko'l ham ko'l
        // bo'lib qoladi. BFS esa suv ustidan erkin yuradi, shuning
        // uchun okeanga ulangan qo'ltiq ham egallanmaydi.
        if (_reached[i] == 0 && owner[i] != playerId && grid.isLandIndex(i)) {
          claim(i);
        }
      }
    }

    return CaptureResult(captured, takenFrom);
  }
}
