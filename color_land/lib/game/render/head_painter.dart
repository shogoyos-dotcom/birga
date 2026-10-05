import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/player_state.dart';
import 'palette.dart';

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

    // Odam o'yinchi botlar orasidan ajralib tursin.
    if (!p.isBot) {
      _stroke
        ..color = const Color(0xF2FFFFFF)
        ..strokeWidth = cellSize * 0.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(cellSize * 0.3),
          Radius.circular(cellSize * 0.6),
        ),
        _stroke,
      );
    }

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
