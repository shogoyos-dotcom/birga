import 'dart:ui';

/// O'yinning vizual uslubi: fon, ranglar va qalinlik.
///
/// Hammasi bitta joyda — yangi uslub qo'shish uchun shu ro'yxatga bitta
/// yozuv qo'shilsa kifoya, qolgan kod o'zgarmaydi.
class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.outside,
    required this.mapBorder,
    required this.gridLine,
    required this.gridMajor,
    required this.heads,
    required this.territoryShade,
    required this.trailShade,
    required this.sideShade,
    required this.depthFactor,
    required this.dark,
  });

  final String id;

  /// Menyuda ko'rinadigan nom.
  final String name;

  /// Maydon yuzasining rangi.
  final Color background;

  /// Xaritadan tashqaridagi rang.
  final Color outside;

  final Color mapBorder;

  /// Arena panjarasining ingichka chizig'i (har katakda).
  final Color gridLine;

  /// Har beshinchi katakdagi yo'g'onroq chiziq — masshtab sezilsin.
  final Color gridMajor;

  /// O'yinchilarning asosiy ranglari.
  final List<Color> heads;

  /// Hudud rangi asosiy rangdan qanchaga to'qroq (manfiy = to'qroq).
  final double territoryShade;

  /// Iz rangi qanchaga ochroq.
  final double trailShade;

  /// Yon devor qanchaga to'qroq.
  final double sideShade;

  /// Hudud qalinligi (katak ulushi).
  final double depthFactor;

  /// Fon to'q bo'lsa — HUD matnlari oq bo'ladi.
  final bool dark;

  static const List<Color> _bright = <Color>[
    Color(0xFF2E7BFF),
    Color(0xFFFF4D6D),
    Color(0xFF14C38E),
    Color(0xFFFFA62B),
    Color(0xFF9B5DE5),
    Color(0xFF00C2D1),
    Color(0xFFF15BB5),
    Color(0xFFFFD60A),
    Color(0xFF6C7BFF),
    Color(0xFF52B788),
    Color(0xFFFF7A45),
    Color(0xFF00B4D8),
    Color(0xFFB5179E),
    Color(0xFF7CB518),
    Color(0xFFEF476F),
    Color(0xFF4CC9F0),
  ];

  static const List<Color> _pastel = <Color>[
    Color(0xFF7FA6F0),
    Color(0xFFF59CA9),
    Color(0xFF86D6B4),
    Color(0xFFF5C784),
    Color(0xFFBFA2E8),
    Color(0xFF8ED3DC),
    Color(0xFFF2A7CE),
    Color(0xFFF2DC8C),
    Color(0xFF9FAAF0),
    Color(0xFF9CCBAF),
    Color(0xFFF5B295),
    Color(0xFF8FC9E0),
    Color(0xFFD49BCB),
    Color(0xFFB7CE8C),
    Color(0xFFEE9DAE),
    Color(0xFF9FDBF0),
  ];

  static const List<Color> _neon = <Color>[
    Color(0xFF2BD9FF),
    Color(0xFFFF2D78),
    Color(0xFF3CFFA8),
    Color(0xFFFFB300),
    Color(0xFFB14DFF),
    Color(0xFF00E5FF),
    Color(0xFFFF4FD8),
    Color(0xFFFFE93D),
    Color(0xFF5C7BFF),
    Color(0xFF2EFFD5),
    Color(0xFFFF7A1A),
    Color(0xFF17C3FF),
    Color(0xFFFF37B0),
    Color(0xFF9CFF2E),
    Color(0xFFFF3355),
    Color(0xFF5BE9FF),
  ];

  /// Arcade uslubi uchun ranglar: elektr ko'k va korall atrofida.
  static const List<Color> _arcade = <Color>[
    Color(0xFF3D7BFF), // elektr ko'k — o'yinchi uchun birinchi rang
    Color(0xFFFF6B5B), // korall
    Color(0xFF2FD6A6),
    Color(0xFFFFC43D),
    Color(0xFF9B6BFF),
    Color(0xFF22D3EE),
    Color(0xFFFF5CA8),
    Color(0xFFA3E635),
    Color(0xFF6D8BFF),
    Color(0xFFFF8A4C),
    Color(0xFF34D399),
    Color(0xFFE879F9),
    Color(0xFF4CC9F0),
    Color(0xFFFFD166),
    Color(0xFFF2545B),
    Color(0xFF7DD3FC),
  ];

  /// Asosiy uslub: arcade kabinet — to'q binafsha-qora arena,
  /// aniq panjara, elektr ko'k va korall aksentlar.
  static const GameTheme arcade = GameTheme(
    id: 'arcade',
    name: 'Arcade',
    background: Color(0xFF26204A),
    outside: Color(0xFF0A0812),
    mapBorder: Color(0xFF3D7BFF),
    gridLine: Color(0x14FFFFFF),
    gridMajor: Color(0x2E6FA3FF),
    heads: _arcade,
    territoryShade: -0.08,
    trailShade: 0.28,
    sideShade: -0.5,
    depthFactor: 0.62,
    dark: true,
  );

  /// 1-variant: hozirgi yorqin uslub, ochiq fon.
  static const GameTheme bright = GameTheme(
    id: 'bright',
    name: 'Yorqin',
    background: Color(0xFFF7F9FC),
    outside: Color(0xFFA9C4DE),
    mapBorder: Color(0xFF3A4256),
    gridLine: Color(0x0F101828),
    gridMajor: Color(0x241B2A4A),
    heads: _bright,
    territoryShade: -0.14,
    trailShade: 0.34,
    sideShade: -0.42,
    depthFactor: 0.55,
    dark: false,
  );

  /// 2-variant: yumshoq pastel, issiq krem fon, past qalinlik.
  static const GameTheme pastel = GameTheme(
    id: 'pastel',
    name: 'Pastel',
    background: Color(0xFFFCF6EA),
    outside: Color(0xFFB6D2DC),
    mapBorder: Color(0xFF8A7F6E),
    gridLine: Color(0x0D6B5B43),
    gridMajor: Color(0x1F8A7F6E),
    heads: _pastel,
    territoryShade: -0.08,
    trailShade: 0.30,
    sideShade: -0.28,
    depthFactor: 0.38,
    dark: false,
  );

  /// 3-variant: to'q ko'k tun, yorqin ranglar yaqqol ajraladi.
  static const GameTheme night = GameTheme(
    id: 'night',
    name: 'Tungi',
    background: Color(0xFF2A3350),
    outside: Color(0xFF0D1120),
    mapBorder: Color(0xFF3D4760),
    gridLine: Color(0x12FFFFFF),
    gridMajor: Color(0x2A6E8ACF),
    heads: _bright,
    territoryShade: -0.06,
    trailShade: 0.26,
    sideShade: -0.45,
    depthFactor: 0.6,
    dark: true,
  );

  /// 4-variant: deyarli qora fon, neon ranglar, baland qalinlik.
  static const GameTheme neon = GameTheme(
    id: 'neon',
    name: 'Neon',
    background: Color(0xFF17203A),
    outside: Color(0xFF04060B),
    mapBorder: Color(0xFF2A3350),
    gridLine: Color(0x14FFFFFF),
    gridMajor: Color(0x332BD9FF),
    heads: _neon,
    territoryShade: -0.10,
    trailShade: 0.22,
    sideShade: -0.55,
    depthFactor: 0.75,
    dark: true,
  );

  static const List<GameTheme> all = <GameTheme>[
    arcade,
    neon,
    night,
    bright,
    pastel,
  ];

  /// Standart uslub.
  static const GameTheme fallback = arcade;

  static GameTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => fallback);
}
