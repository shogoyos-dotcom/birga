import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../logic/player_profile.dart';

/// Emoji va bayroqlar uchun zaxira shriftlar ro'yxati.
///
/// Qurilmada `null` — Android o'zining emoji shriftini ishlatadi.
/// Widget testlarida esa tizim shriftlari yo'q, shuning uchun skrinshot
/// vositasi shu yerga yuklagan shrift nomini yozadi.
List<String>? avatarFontFallback;

/// Avatarni tuvalga chizadi.
///
/// Emoji va bayroqlar tizim shriftidan `ui.Paragraph` bo'lib chiziladi
/// (rasm fayllari kerak emas), odam tasvirlari esa oddiy shakllardan
/// yig'iladi. Paragraflar keshlanadi — har kadrda matn qayta
/// joylashtirilmaydi.
class AvatarPainter {
  AvatarPainter();

  final Map<String, ui.Paragraph> _glyphs = <String, ui.Paragraph>{};

  /// Odam tasvirlari uchun teri va kiyim ranglari.
  static const List<Color> _skins = <Color>[
    Color(0xFFF2C79B),
    Color(0xFFE0A878),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF5C3A21),
    Color(0xFFFFE0BD),
  ];
  static const List<Color> _shirts = <Color>[
    Color(0xFF2E7BFF),
    Color(0xFFFF4D6D),
    Color(0xFF14C38E),
    Color(0xFFFFA62B),
    Color(0xFF9B5DE5),
    Color(0xFF00C2D1),
  ];
  static const List<Color> _hairs = <Color>[
    Color(0xFF2B2118),
    Color(0xFF55331A),
    Color(0xFF8C5A2B),
    Color(0xFFD9A441),
    Color(0xFF9E9E9E),
    Color(0xFF3B2B5A),
  ];

  final Paint _fill = Paint()..isAntiAlias = true;

  /// Avatarni `center` atrofida `size` o'lchamda chizadi.
  void paint(ui.Canvas canvas, Avatar avatar, Offset center, double size) {
    if (avatar.kind == AvatarKind.figure) {
      _paintFigure(canvas, avatar.figureIndex, center, size);
      return;
    }
    final glyph = avatar.glyph;
    if (glyph.isEmpty) return;
    final paragraph = _glyphs.putIfAbsent(
      '$glyph@$size',
      () => _buildGlyph(glyph, size),
    );
    // Emoji glifi kvadrat emas (bayroqlar ayniqsa keng), shuning uchun
    // joylashtirish paragrafning haqiqiy o'lchamidan hisoblanadi —
    // shunda avatar hudud markazida turadi va chetiga chiqmaydi.
    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.width / 2, center.dy - paragraph.height / 2),
    );
  }

  /// Glif qancha joyni egallashi (slot o'lchamiga nisbatan). Emoji
  /// kvadratdan kengroq chiqadi, shuning uchun biroz kichraytiriladi.
  static const double glyphScale = 0.8;

  ui.Paragraph _buildGlyph(String glyph, double size) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: size * glyphScale,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: const Color(0xFF000000),
              fontFamilyFallback: avatarFontFallback,
            ),
          )
          ..addText(glyph);
    return builder.build()..layout(ui.ParagraphConstraints(width: size * 2.2));
  }

  /// Oddiy odam tasviri: bosh, soch, tana.
  void _paintFigure(ui.Canvas canvas, int index, Offset center, double size) {
    final skin = _skins[index % _skins.length];
    final shirt = _shirts[(index ~/ 2) % _shirts.length];
    final hair = _hairs[(index ~/ 3) % _hairs.length];

    final headR = size * 0.26;
    final headCenter = center + Offset(0, -size * 0.12);

    // Tana — yelkadan pastga kengayadigan shakl.
    final body = Path()
      ..moveTo(center.dx - size * 0.34, center.dy + size * 0.45)
      ..quadraticBezierTo(
        center.dx - size * 0.32,
        center.dy + size * 0.1,
        center.dx,
        center.dy + size * 0.1,
      )
      ..quadraticBezierTo(
        center.dx + size * 0.32,
        center.dy + size * 0.1,
        center.dx + size * 0.34,
        center.dy + size * 0.45,
      )
      ..close();
    _fill.color = shirt;
    canvas.drawPath(body, _fill);

    // Soch — boshning orqa qismi.
    _fill.color = hair;
    canvas.drawCircle(
      headCenter + Offset(0, -size * 0.04),
      headR * 1.08,
      _fill,
    );

    // Bosh.
    _fill.color = skin;
    canvas.drawCircle(headCenter, headR, _fill);

    // Soch — peshonadagi qism (yarim doira).
    _fill.color = hair;
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR * 1.02),
      3.34,
      2.3,
      true,
      _fill,
    );

    // Ko'zlar.
    _fill.color = const Color(0xFF2B2118);
    canvas.drawCircle(
      headCenter + Offset(-headR * 0.33, headR * 0.1),
      headR * 0.12,
      _fill,
    );
    canvas.drawCircle(
      headCenter + Offset(headR * 0.33, headR * 0.1),
      headR * 0.12,
      _fill,
    );
  }

  void dispose() => _glyphs.clear();
}
