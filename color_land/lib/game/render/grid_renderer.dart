import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/game_grid.dart';
import '../logic/player_state.dart';
import 'palette.dart';

/// Panjarani "chunk"larga bo'lib keshlab chizadi.
///
/// Har bir chunk uchun bir marta `ui.Picture` yoziladi va faqat o'zgargan
/// chunklar qayta yoziladi. Shu bilan 150x150 = 22 500 katak har kadrda
/// qayta chizilmaydi; ekranda ko'rinadigan ~12-20 chunk chiziladi.
class GridRenderer {
  GridRenderer(this.grid, this.cellSize) {
    _chunkWorld = grid.chunkCells * cellSize;
  }

  final GameGrid grid;
  final double cellSize;
  late final double _chunkWorld;

  final Map<int, ui.Picture> _cache = <int, ui.Picture>{};
  final Paint _paint = Paint()..isAntiAlias = false;

  /// Oxirgi kadrda nechta chunk qayta yozilgani (profil uchun).
  int lastRebuildCount = 0;

  /// Keshda saqlanayotgan chunklar soni.
  int get cachedChunks => _cache.length;

  /// O'zgargan chunklarni keshdan chiqaradi. Har kadr boshida chaqiriladi.
  void invalidateDirty() {
    if (grid.dirtyChunks.isEmpty) return;
    for (final key in grid.dirtyChunks) {
      _cache.remove(key)?.dispose();
    }
    grid.dirtyChunks.clear();
  }

  void dispose() {
    for (final p in _cache.values) {
      p.dispose();
    }
    _cache.clear();
  }

  /// `visible` — dunyo koordinatalaridagi ko'rinadigan to'rtburchak.
  void render(ui.Canvas canvas, Rect visible) {
    lastRebuildCount = 0;
    final cx0 = (visible.left / _chunkWorld).floor().clamp(0, grid.chunksX - 1);
    final cx1 = (visible.right / _chunkWorld).floor().clamp(0, grid.chunksX - 1);
    final cy0 = (visible.top / _chunkWorld).floor().clamp(0, grid.chunksY - 1);
    final cy1 = (visible.bottom / _chunkWorld).floor().clamp(
      0,
      grid.chunksY - 1,
    );

    for (var cy = cy0; cy <= cy1; cy++) {
      for (var cx = cx0; cx <= cx1; cx++) {
        final key = cy * grid.chunksX + cx;
        final picture = _cache[key] ??= _record(cx, cy);
        canvas.drawPicture(picture);
      }
    }
  }

  /// Katakning rangi (ARGB) yoki 0 — bo'sh.
  int _cellColor(int i) {
    final t = grid.trail[i];
    if (t != 0) return Palette.trailValues[(t - 1) % Palette.colorCount];
    final o = grid.owner[i];
    if (o != 0) return Palette.territoryValues[(o - 1) % Palette.colorCount];
    return 0;
  }

  /// Bir chunkni yozadi. Qatorlar bo'ylab bir xil rangli kataklar bitta
  /// to'rtburchakka birlashtiriladi — chizish chaqiruvlari kamayadi.
  ui.Picture _record(int cx, int cy) {
    lastRebuildCount++;
    final x0 = cx * grid.chunkCells;
    final y0 = cy * grid.chunkCells;
    final x1 = (x0 + grid.chunkCells).clamp(0, grid.width);
    final y1 = (y0 + grid.chunkCells).clamp(0, grid.height);

    final recorder = ui.PictureRecorder();
    final cullRect = Rect.fromLTWH(
      x0 * cellSize,
      y0 * cellSize,
      (x1 - x0) * cellSize,
      (y1 - y0) * cellSize,
    );
    final canvas = ui.Canvas(recorder, cullRect);

    for (var y = y0; y < y1; y++) {
      final rowBase = y * grid.width;
      var runColor = 0;
      var runStart = x0;
      for (var x = x0; x <= x1; x++) {
        final color = x < x1 ? _cellColor(rowBase + x) : -1;
        if (color == runColor) continue;
        if (runColor != 0 && x > runStart) {
          _paint.color = Color(runColor);
          canvas.drawRect(
            Rect.fromLTWH(
              runStart * cellSize,
              y * cellSize,
              (x - runStart) * cellSize,
              cellSize,
            ),
            _paint,
          );
        }
        runColor = color;
        runStart = x;
      }
    }
    return recorder.endRecording();
  }
}

/// O'yinchi kvadratini (boshini) chizadi.
class HeadPainter {
  HeadPainter(this.cellSize);

  final double cellSize;

  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  void paint(ui.Canvas canvas, PlayerState p) {
    final size = cellSize * 1.9;
    final center = Offset(p.x * cellSize, p.y * cellSize);
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellSize * 0.45),
    );

    _fill.color = const Color(0x33000000);
    canvas.drawRRect(rrect.shift(Offset(0, cellSize * 0.18)), _fill);

    _fill.color = Palette.head(p.colorIndex);
    canvas.drawRRect(rrect, _fill);

    _stroke
      ..color = Palette.territory(p.colorIndex)
      ..strokeWidth = cellSize * 0.22;
    canvas.drawRRect(rrect.deflate(cellSize * 0.11), _stroke);
  }
}
