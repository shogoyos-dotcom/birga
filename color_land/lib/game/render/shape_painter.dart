import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/game_grid.dart';
import '../logic/player_state.dart';
import 'palette.dart';

/// Hududni kataklar emas, yumaloq birlashgan shakl sifatida chizadi.
///
/// Usul: har qatordagi ketma-ket kataklar bitta "yo'lak"ka birlashtiriladi,
/// har yo'lak esa biroz kattalashtirilgan, burchaklari yumaloq
/// to'rtburchak sifatida bitta `Path` ga qo'shiladi. Qo'shni qatorlar
/// bir-birini qoplagani uchun ichkarida chok ko'rinmaydi, tashqi burchaklar
/// esa yumaloq bo'lib chiqadi — pog'onali chekkalar yo'qoladi.
///
/// Har bir o'yinchi shakli `ui.Picture` sifatida keshlanadi va faqat
/// o'sha o'yinchi hududi o'zgarganda qayta yoziladi.
class TerritoryShapes {
  TerritoryShapes(this.grid, this.cellSize);

  /// Yo'laklarni qanchaga kattalashtirish (katak ulushi). Animatsiyalar ham
  /// shu qiymatlardan foydalanadi — shunda ko'rinish bir xil bo'ladi.
  static const double growFactor = 0.3;
  static const double radiusFactor = 0.8;

  final GameGrid grid;
  final double cellSize;

  final Map<int, _Cached> _cache = <int, _Cached>{};

  /// Oxirgi kadrda nechta shakl qayta yozilgani (profil uchun).
  int lastRebuildCount = 0;

  int get cachedCount => _cache.length;

  /// Yo'laklarni qanchaga kattalashtirish — qatorlar o'zaro qoplanishi uchun.
  double get _grow => cellSize * growFactor;

  /// Burchak radiusi.
  double get _radius => cellSize * radiusFactor;

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
      b.$1 * cellSize - _grow,
      b.$2 * cellSize - _grow,
      (b.$3 + 1) * cellSize + _grow,
      (b.$4 + 1) * cellSize + _grow,
    );
    final canvas = ui.Canvas(recorder, cull);

    final path = Path();
    final radius = Radius.circular(_radius);
    for (var y = b.$2; y <= b.$4; y++) {
      final row = y * grid.width;
      var runStart = -1;
      for (var x = b.$1; x <= b.$3 + 1; x++) {
        final mine = x <= b.$3 && grid.owner[row + x] == playerId;
        if (mine && runStart < 0) {
          runStart = x;
        } else if (!mine && runStart >= 0) {
          path.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                runStart * cellSize,
                y * cellSize - _grow,
                (x - runStart) * cellSize,
                cellSize + _grow * 2,
              ),
              radius,
            ),
          );
          runStart = -1;
        }
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.territory(colorIndex)
        ..isAntiAlias = true,
    );
    return recorder.endRecording();
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
