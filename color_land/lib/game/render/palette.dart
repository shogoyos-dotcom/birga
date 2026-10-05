import 'dart:ui';

/// O'yinchi ranglari. Har rangning uch varianti bor:
///  * `head`      — o'yinchi kvadrati (asosiy rang),
///  * `territory` — hududi (to'q variant),
///  * `trail`     — izi (och variant).
///
/// Ranglar oldindan hisoblanadi — har kadrda HSL konvertatsiyasi bo'lmaydi.
class Palette {
  Palette._();

  static const Color background = Color(0xFFF2F4F8);
  static const Color gridLine = Color(0x14202840);
  static const Color mapBorder = Color(0xFF3A4256);
  static const Color outside = Color(0xFFDFE4EC);

  /// Yorqin, bir-biridan yaxshi ajraladigan asosiy ranglar.
  static const List<Color> heads = <Color>[
    Color(0xFF2E7BFF), // ko'k
    Color(0xFFFF4D6D), // qizil-pushti
    Color(0xFF14C38E), // yashil
    Color(0xFFFFA62B), // to'q sariq
    Color(0xFF9B5DE5), // binafsha
    Color(0xFF00C2D1), // moviy
    Color(0xFFF15BB5), // pushti
    Color(0xFFFFD60A), // sariq
    Color(0xFF6C7BFF), // indigo
    Color(0xFF52B788), // zumrad
    Color(0xFFFF7A45), // marjon
    Color(0xFF00B4D8), // havorang
    Color(0xFFB5179E), // magenta
    Color(0xFF7CB518), // o't rangi
    Color(0xFFEF476F), // qizil
    Color(0xFF4CC9F0), // muz ko'k
  ];

  static final List<Color> _territories = List<Color>.unmodifiable(
    heads.map((c) => _shade(c, -0.14)),
  );
  static final List<Color> _trails = List<Color>.unmodifiable(
    heads.map((c) => _shade(c, 0.34)),
  );

  /// ARGB butun sonlar — chizishda rang solishtirish arzon bo'lsin.
  static final List<int> territoryValues = List<int>.unmodifiable(
    _territories.map(_argb),
  );
  static final List<int> trailValues = List<int>.unmodifiable(
    _trails.map(_argb),
  );

  static int get colorCount => heads.length;

  static Color head(int index) => heads[index % heads.length];

  static Color territory(int index) => _territories[index % heads.length];

  static Color trail(int index) => _trails[index % heads.length];

  static int _argb(Color c) =>
      ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
      (c.b * 255).round();

  /// `amount > 0` — oqartiradi, `< 0` — qoraytiradi.
  static Color _shade(Color c, double amount) {
    if (amount >= 0) {
      return Color.lerp(c, const Color(0xFFFFFFFF), amount)!;
    }
    return Color.lerp(c, const Color(0xFF000000), -amount)!;
  }
}
