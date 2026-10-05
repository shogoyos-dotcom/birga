import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/game_grid.dart';
import 'contour.dart';
import '../logic/player_state.dart';
import 'palette.dart';

/// Hududni kataklar emas, silliq shakl sifatida chizadi.
///
/// Usul: hududning haqiqiy chegara chizig'i topiladi ([ContourBuilder]) va
/// Chaikin usuli bilan silliqlanadi. Shuning uchun pog'onali chekkalar
/// qolmaydi, teshiklar esa (ichkarida qolgan begona soha) o'z-o'zidan
/// kesib tashlanadi.
///
/// Har bir o'yinchi shakli `ui.Picture` sifatida keshlanadi va faqat
/// o'sha o'yinchi hududi o'zgarganda qayta yoziladi.
class TerritoryShapes {
  TerritoryShapes(this.grid, this.cellSize);

  /// Animatsiyalar hudud bilan bir xil ko'rinishi uchun ishlatadigan
  /// yumaloqlik qiymatlari.
  static const double growFactor = 0.3;
  static const double radiusFactor = 0.8;

  /// Chegarani necha marta silliqlash. Ko'proq = yumaloqroq, lekin
  /// nuqtalar soni har safar ikki barobar oshadi.
  static const int smoothPasses = 2;

  /// Pog'onalarni to'g'ri chiziqqa aylantirish chegarasi (katak ulushi).
  static const double simplifyTolerance = 0.8;

  final GameGrid grid;
  final double cellSize;

  final Map<int, _Cached> _cache = <int, _Cached>{};

  /// Oxirgi kadrda nechta shakl qayta yozilgani (profil uchun).
  int lastRebuildCount = 0;

  int get cachedCount => _cache.length;

  void render(ui.Canvas canvas, Iterable<PlayerState> players, Rect visible) {
    lastRebuildCount = 0;
    for (final p in players) {
      final bounds = grid.boundsOf(p.id);
      if (bounds == null) continue;
      final worldBounds = Rect.fromLTRB(
        bounds.$1 * cellSize,
        bounds.$2 * cellSize,
        (bounds.$3 + 1) * cellSize,
        (bounds.$4 + 1) * cellSize,
      );
      if (!worldBounds.overlaps(visible)) continue;

      final version = grid.versionOf(p.id);
      var cached = _cache[p.id];
      if (cached == null || cached.version != version) {
        cached?.picture.dispose();
        cached = _Cached(version, _record(p.id, p.colorIndex, bounds));
        _cache[p.id] = cached;
        lastRebuildCount++;
      }
      canvas.drawPicture(cached.picture);
    }
  }

  ui.Picture _record(int playerId, int colorIndex, (int, int, int, int) b) {
    final recorder = ui.PictureRecorder();
    final cull = Rect.fromLTRB(
      b.$1 * cellSize,
      b.$2 * cellSize,
      (b.$3 + 1) * cellSize,
      (b.$4 + 1) * cellSize,
    );
    final canvas = ui.Canvas(recorder, cull);
    canvas.drawPath(
      buildPath(grid, playerId, b, cellSize),
      Paint()
        ..color = Palette.territory(colorIndex)
        ..isAntiAlias = true,
    );
    return recorder.endRecording();
  }

  /// Hudud chegarasidan silliq `Path` yasaydi (testlar ham shuni chaqiradi).
  static Path buildPath(
    GameGrid grid,
    int playerId,
    (int, int, int, int) b,
    double cellSize,
  ) {
    final owner = grid.owner;
    final w = grid.width;
    bool inside(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= grid.height) return false;
      return owner[y * w + x] == playerId;
    }

    final loops = ContourBuilder.trace(inside, b.$1, b.$2, b.$3, b.$4);
    final path = Path()..fillType = PathFillType.nonZero;
    for (final raw in loops) {
      final pts = ContourBuilder.smooth(
        ContourBuilder.simplify(
          ContourBuilder.dropCollinear(raw),
          simplifyTolerance,
        ),
        iterations: smoothPasses,
      );
      if (pts.length < 3) continue;
      path.moveTo(pts[0].dx * cellSize, pts[0].dy * cellSize);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * cellSize, pts[i].dy * cellSize);
      }
      path.close();
    }
    return path;
  }

  void dispose() {
    for (final c in _cache.values) {
      c.picture.dispose();
    }
    _cache.clear();
  }
}

class _Cached {
  _Cached(this.version, this.picture);

  final int version;
  final ui.Picture picture;
}

/// Izni haqiqiy yo'l bo'ylab silliq lenta qilib chizadi.
class TrailPainter {
  TrailPainter(this.cellSize);

  final double cellSize;

  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void paint(ui.Canvas canvas, PlayerState p) {
    final pts = p.trailPath;
    if (pts.length < 2) return;

    final path = Path()..moveTo(pts[0] * cellSize, pts[1] * cellSize);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i] * cellSize, pts[i + 1] * cellSize);
    }
    // Yo'lning oxirini o'yinchining hozirgi joyiga ulaymiz, aks holda
    // lenta boshdan bir oz orqada qolib ko'rinadi.
    path.lineTo(p.x * cellSize, p.y * cellSize);

    _stroke
      ..color = Palette.trail(p.colorIndex)
      ..strokeWidth = cellSize * 1.15;
    canvas.drawPath(path, _stroke);
  }
}
