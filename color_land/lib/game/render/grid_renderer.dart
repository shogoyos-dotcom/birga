import 'dart:typed_data';
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
  GridRenderer(this.grid, this.cellSize, this.colorIndexById) {
    _chunkWorld = grid.chunkCells * cellSize;
  }

  final GameGrid grid;
  final double cellSize;

  /// O'yinchi ID -> rang indeksi (panjarada faqat ID saqlanadi).
  final Uint8List colorIndexById;
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
    final cx1 = (visible.right / _chunkWorld).floor().clamp(
      0,
      grid.chunksX - 1,
    );
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
    if (t != 0) {
      return Palette.trailValues[colorIndexById[t] % Palette.colorCount];
    }
    final o = grid.owner[i];
    if (o != 0) {
      return Palette.territoryValues[colorIndexById[o] % Palette.colorCount];
    }
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

/// O'yinchi kvadratini va nomini chizadi.
///
/// Nom yozuvlari `ui.Paragraph` sifatida keshlanadi — har kadrda matn
/// qayta joylashtirilmaydi.
class HeadPainter {
  HeadPainter(this.cellSize);

  final double cellSize;

  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  final Map<int, ui.Paragraph> _labels = <int, ui.Paragraph>{};

  void paint(ui.Canvas canvas, PlayerState p) {
    final size = cellSize * 1.9;
    final center = Offset(p.x * cellSize, p.y * cellSize);
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellSize * 0.45),
    );

    // Yengil soya — kvadrat maydondan "ko'tarilib" turgandek ko'rinadi.
    _fill.color = const Color(0x33101828);
    canvas.drawRRect(rrect.shift(Offset(0, cellSize * 0.22)), _fill);

    _fill.color = Palette.territory(p.colorIndex);
    canvas.drawRRect(rrect, _fill);

    _fill.color = Palette.head(p.colorIndex);
    canvas.drawRRect(rrect.deflate(cellSize * 0.26), _fill);

    _stroke
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = cellSize * 0.14;
    canvas.drawRRect(rrect.deflate(cellSize * 0.07), _stroke);

    _drawLabel(canvas, p, center, size);
  }

  void _drawLabel(ui.Canvas canvas, PlayerState p, Offset center, double size) {
    final paragraph = _labels.putIfAbsent(p.id, () => _buildLabel(p));
    canvas.drawParagraph(
      paragraph,
      Offset(
        center.dx - paragraph.width / 2,
        center.dy - size / 2 - cellSize * 1.5,
      ),
    );
  }

  ui.Paragraph _buildLabel(PlayerState p) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: cellSize * 1.15,
              fontWeight: FontWeight.w700,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: const Color(0xFF26314A),
              shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 3)],
            ),
          )
          ..addText(p.name);
    return builder.build()
      ..layout(ui.ParagraphConstraints(width: cellSize * 12));
  }

  void dispose() => _labels.clear();
}
