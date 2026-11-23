import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../data/capitals.dart';
import '../../data/world_map.dart';
import 'canvas_text.dart';
import 'contour.dart';
import 'palette.dart';

/// Dunyo xaritasini chizadi: quruqlik, qirg'oq chizig'i va poytaxtlar.
///
/// Xarita o'yin davomida o'zgarmaydi, shuning uchun hammasi bir marta
/// `ui.Picture` ga yoziladi va keyin har kadrda shunchaki chiziladi.
/// Kontur [ContourBuilder] bilan silliqlanadi — qirg'oq pog'onali
/// bo'lmaydi.
class WorldMapPainter {
  WorldMapPainter(this.cellSize);

  final double cellSize;

  /// Quruqlik konturi — jarayon davomida bir marta hisoblanadi
  /// (~35 ms), chunki niqob hech qachon o'zgarmaydi.
  static Path? _landPath;

  /// Xarita plitkalari: har biri alohida `ui.Picture`.
  ///
  /// Butun dunyo bitta rasm bo'lsa, har kadrda 7000 dan ortiq nuqtali
  /// kontur va 236 ta yozuv GPU ga beriladi — kuchsiz telefonda bu
  /// behuda ish, chunki ekranda xaritaning ~4% i ko'rinadi. Shuning
  /// uchun xarita plitkalarga bo'linadi va faqat ko'rinadiganlari
  /// chiziladi.
  final Map<int, ui.Picture> _tiles = <int, ui.Picture>{};
  String? _tilesKey;

  /// Bitta plitka tomoni (katak).
  static const int tileCells = 64;

  static int get _cols => (kWorldWidth + tileCells - 1) ~/ tileCells;
  static int get _rows => (kWorldHeight + tileCells - 1) ~/ tileCells;

  /// Qirg'oqni silliqlash darajasi.
  static const int smoothPasses = 2;
  static const double simplifyTolerance = 0.7;

  /// Poytaxt belgisining o'lchami (katak ulushi).
  static const double capitalDotCells = 0.42;

  /// Quruqlik konturini (katak birligida) qaytaradi.
  static Path landPath() {
    final cached = _landPath;
    if (cached != null) return cached;

    final land = decodeWorldLand();
    bool inside(int x, int y) {
      if (x < 0 || y < 0 || x >= kWorldWidth || y >= kWorldHeight) {
        return false;
      }
      return land[y * kWorldWidth + x] == 1;
    }

    final path = Path()..fillType = PathFillType.nonZero;
    for (final raw in ContourBuilder.trace(
      inside,
      0,
      0,
      kWorldWidth - 1,
      kWorldHeight - 1,
    )) {
      final pts = ContourBuilder.smooth(
        ContourBuilder.simplify(
          ContourBuilder.dropCollinear(raw),
          simplifyTolerance,
        ),
        iterations: smoothPasses,
      );
      if (pts.length < 3) continue;
      path.moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
    }
    return _landPath = path;
  }

  /// Ko'rinadigan plitkalarni chizadi. Uslub o'zgarsa qayta yoziladi.
  void render(ui.Canvas canvas, Rect visible) {
    final key = Palette.theme.id;
    if (_tilesKey != key) {
      dispose();
      _tilesKey = key;
    }
    final first = ((visible.left / cellSize) / tileCells).floor();
    final last = ((visible.right / cellSize) / tileCells).ceil();
    final top = ((visible.top / cellSize) / tileCells).floor();
    final bottom = ((visible.bottom / cellSize) / tileCells).ceil();

    for (
      var ty = top.clamp(0, _rows - 1);
      ty <= bottom.clamp(0, _rows - 1);
      ty++
    ) {
      for (
        var tx = first.clamp(0, _cols - 1);
        tx <= last.clamp(0, _cols - 1);
        tx++
      ) {
        canvas.drawPicture(_tile(tx, ty));
      }
    }
  }

  ui.Picture _tile(int tx, int ty) {
    final id = ty * _cols + tx;
    final cached = _tiles[id];
    if (cached != null) return cached;
    return _tiles[id] = _record(tx, ty);
  }

  ui.Picture _record(int tx, int ty) {
    final recorder = ui.PictureRecorder();
    // Chekka chiziqlar va yozuvlar plitka chegarasidan chiqadi, shuning
    // uchun kesish to'rtburchagi biroz kengaytiriladi.
    final pad = cellSize * 8;
    final tile = Rect.fromLTWH(
      tx * tileCells * cellSize,
      ty * tileCells * cellSize,
      tileCells * cellSize,
      tileCells * cellSize,
    );
    final canvas = ui.Canvas(recorder, tile.inflate(pad));
    canvas.clipRect(tile.inflate(pad));

    canvas.save();
    canvas.scale(cellSize);
    final path = landPath();

    // 1. Qirg'oqdagi yorug'lik — quruqlik suvdan ajralib tursin.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Palette.mapBorder.withValues(alpha: 0.16)
        ..isAntiAlias = true,
    );
    // 2. Quruqlik yuzasi.
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.background
        ..isAntiAlias = true,
    );
    // 3. Qirg'oq chizig'i.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = Palette.mapBorder.withValues(alpha: 0.75)
        ..isAntiAlias = true,
    );
    canvas.restore();
    _drawCapitals(canvas, tile.inflate(pad));
    return recorder.endRecording();
  }

  void _drawCapitals(ui.Canvas canvas, Rect area) {
    // Poytaxtlar — fon tafsiloti: ko'rinadi, lekin o'yinni to'smaydi.
    final dot = Paint()
      ..color = Palette.mapBorder.withValues(alpha: 0.75)
      ..isAntiAlias = true;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.14
      ..color = Palette.mapBorder.withValues(alpha: 0.3)
      ..isAntiAlias = true;
    final r = cellSize * capitalDotCells;

    // Belgilar hammasiga qo'yiladi, yozuvlar esa faqat joy yetganiga:
    // Yevropa yoki Janubiy Afrikada poytaxtlar juda zich va yozuvlar
    // bir-birini bosib ketadi. Ro'yxat aholisi bo'yicha saralangan,
    // shuning uchun zich joyda kattaroq shahar qoladi.
    final placed = <Rect>[];
    for (final c in kCapitals) {
      final at = Offset((c.x + 0.5) * cellSize, (c.y + 0.5) * cellSize);
      if (!area.contains(at)) continue;
      canvas.drawCircle(at, r, dot);
      canvas.drawCircle(at, r * 2.1, ring);

      final label = _label(c.name);
      final w = label.longestLine;
      final box = Rect.fromLTWH(
        at.dx - w / 2,
        at.dy + r * 2.1,
        w,
        label.height,
      ).inflate(cellSize * 0.2);
      if (placed.any(box.overlaps)) continue;
      placed.add(box);
      canvas.drawParagraph(
        label,
        Offset(at.dx - label.width / 2, at.dy + r * 2.1),
      );
    }
  }

  ui.Paragraph _label(String name) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: canvasFontFamily,
              textAlign: TextAlign.center,
              fontSize: cellSize * 1.0,
              fontWeight: FontWeight.w700,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              // Shrift ikkala joyda ham ko'rsatiladi: `TextStyle` da
              // zaxira ro'yxati berilsa, `ParagraphStyle` dagi shrift
              // hisobga olinmay qoladi.
              fontFamily: canvasFontFamily,
              fontFamilyFallback: canvasFontFallback,
              color: Palette.mapBorder.withValues(alpha: 0.6),
              letterSpacing: cellSize * 0.04,
            ),
          )
          ..addText(name);
    return builder.build()
      ..layout(ui.ParagraphConstraints(width: cellSize * 12));
  }

  void dispose() {
    for (final t in _tiles.values) {
      t.dispose();
    }
    _tiles.clear();
  }
}
