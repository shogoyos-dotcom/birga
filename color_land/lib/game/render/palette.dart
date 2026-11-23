import 'dart:ui';

import 'game_theme.dart';

/// O'yinchi ranglari va fon. Hamma rang joriy [GameTheme] dan kelib
/// chiqadi va uslub o'zgarganda bir marta qayta hisoblanadi — har
/// kadrda HSL konvertatsiyasi bo'lmaydi.
class Palette {
  Palette._();

  static GameTheme _theme = GameTheme.fallback;

  static GameTheme get theme => _theme;

  static set theme(GameTheme value) {
    if (identical(_theme, value)) return;
    _theme = value;
    _rebuild();
  }

  static List<Color> _territories = const <Color>[];
  static List<Color> _trails = const <Color>[];
  static List<Color> _sides = const <Color>[];
  static List<Color> _headSides = const <Color>[];
  static List<int> _territoryValues = const <int>[];
  static List<int> _trailValues = const <int>[];

  static bool _ready = false;

  static void _rebuild() {
    final heads = _theme.heads;
    _territories = List<Color>.unmodifiable(
      heads.map((c) => _shade(c, _theme.territoryShade)),
    );
    _trails = List<Color>.unmodifiable(
      heads.map((c) => _shade(c, _theme.trailShade)),
    );
    _sides = List<Color>.unmodifiable(
      heads.map((c) => _shade(c, _theme.sideShade)),
    );
    _headSides = List<Color>.unmodifiable(
      heads.map((c) => _shade(c, _theme.sideShade * 0.7)),
    );
    _territoryValues = List<int>.unmodifiable(_territories.map(_argb));
    _trailValues = List<int>.unmodifiable(_trails.map(_argb));
    _ready = true;
  }

  static void _ensure() {
    if (!_ready) _rebuild();
  }

  static Color get background => _theme.background;
  static Color get outside => _theme.outside;
  static Color get mapBorder => _theme.mapBorder;
  static Color get gridLine => _theme.gridLine;
  static Color get gridMajor => _theme.gridMajor;
  static double get depthFactor => _theme.depthFactor;

  static List<Color> get heads => _theme.heads;
  static int get colorCount => _theme.heads.length;

  /// Yerga tushadigan soya — to'q fonda kuchliroq bo'lishi kerak.
  static Color get groundShadow =>
      _theme.dark ? const Color(0x4D000000) : const Color(0x26101828);

  static Color head(int index) => _theme.heads[index % colorCount];

  static Color territory(int index) {
    _ensure();
    return _territories[index % colorCount];
  }

  static Color trail(int index) {
    _ensure();
    return _trails[index % colorCount];
  }

  /// Hudud "qalinligi" (yon devor) rangi.
  static Color side(int index) {
    _ensure();
    return _sides[index % colorCount];
  }

  /// O'yinchi kubining yon yuzasi.
  static Color headSide(int index) {
    _ensure();
    return _headSides[index % colorCount];
  }

  /// ARGB butun sonlar — chizishda rang solishtirish arzon bo'lsin.
  static List<int> get territoryValues {
    _ensure();
    return _territoryValues;
  }

  static List<int> get trailValues {
    _ensure();
    return _trailValues;
  }

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
