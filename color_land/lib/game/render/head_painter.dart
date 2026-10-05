import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/player_state.dart';
import 'palette.dart';
import 'shape_painter.dart';

/// O'yinchini kub ko'rinishida chizadi: yerdagi soya, yon yuza va ustki
/// yuza. Shu uchtasi birga 3D hissini beradi.
///
/// Nom yozuvlari `ui.Paragraph` sifatida keshlanadi — har kadrda matn
/// qayta joylashtirilmaydi.
class HeadPainter {
  HeadPainter(this.cellSize);

  final double cellSize;

  /// Kub tomoni (katak ulushi).
  static const double sizeFactor = 2.0;

  final Paint _fill = Paint()..isAntiAlias = true;
  // Blursiz: MaskFilter.blur har kadrda qayta hisoblanadi va kuchsiz
  // qurilmada qimmatga tushadi.
  final Paint _shadow = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  final Map<int, ui.Paragraph> _labels = <int, ui.Paragraph>{};

  void paint(ui.Canvas canvas, PlayerState p) {
    final size = cellSize * sizeFactor;
    final depth = cellSize * TerritoryShapes.depthFactor * 1.3;
    final center = Offset(p.x * cellSize, p.y * cellSize);
    final radius = Radius.circular(cellSize * 0.42);

    RRect face(Offset at) => RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: size, height: size),
      radius,
    );

    // 1. Yerdagi soya — kub ko'tarilib turgandek ko'rinsin.
    _shadow.color = Palette.groundShadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, depth * 1.5),
        width: size * 0.95,
        height: size * 0.45,
      ),
      _shadow,
    );

    // 2. Yon yuza: ustki yuzaning pastga surilgan nusxasi.
    _fill.color = Palette.headSide(p.colorIndex);
    canvas.drawRRect(face(center + Offset(0, depth)), _fill);

    // 3. Ustki yuza.
    _fill.color = Palette.head(p.colorIndex);
    canvas.drawRRect(face(center), _fill);

    // 4. Yuqori chetidagi yorug'lik — yuza yaltirab turgandek.
    _stroke
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = cellSize * 0.16;
    canvas.drawRRect(face(center).deflate(cellSize * 0.1), _stroke);

    // Odam o'yinchi botlar orasidan ajralib tursin.
    if (!p.isBot) {
      _stroke
        ..color = const Color(0xF2FFFFFF)
        ..strokeWidth = cellSize * 0.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size + cellSize * 0.6,
            height: size + cellSize * 0.6,
          ),
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
        center.dy - size / 2 - cellSize * 1.6,
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
