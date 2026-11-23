import 'package:flutter/material.dart';

/// "Arcade Grid" dizayn tizimi: ranglar, tipografika va o'lchamlar.
///
/// Interfeys chromasi (panellar, tugmalar, matn) har doim shu to'q
/// uslubda — uslub tanlash esa faqat arena ko'rinishini o'zgartiradi.
/// Shuning uchun menyu, profil va HUD hamma uslubda bir xil o'qiladi.
class Arcade {
  Arcade._();

  // ——— Fon va yuzalar ———
  /// Sahifa foni.
  static const Color bg = Color(0xFF100E1B);

  /// Panel yuzasi.
  static const Color panel = Color(0xFF1A1728);

  /// Panel ichidagi ko'tarilgan yuza (katakcha, input).
  static const Color surface = Color(0xFF231F38);

  /// Panel chizig'i.
  static const Color stroke = Color(0xFF2E2946);

  /// Modal ortidagi qorong'ilik.
  static const Color scrim = Color(0xE60A0812);

  // ——— Aksentlar ———
  /// Asosiy aksent — elektr ko'k.
  static const Color blue = Color(0xFF3D7BFF);
  static const Color blueBright = Color(0xFF6FA3FF);
  static const Color blueDeep = Color(0xFF1E46A8);

  /// Ikkinchi aksent — korall.
  static const Color coral = Color(0xFFFF6B5B);
  static const Color coralDeep = Color(0xFFB83A2E);

  /// Yordamchi: muvaffaqiyat va ogohlantirish.
  static const Color mint = Color(0xFF2FD6A6);
  static const Color gold = Color(0xFFFFC43D);

  // ——— Matn ———
  static const Color text = Color(0xFFF4F2FF);
  static const Color textDim = Color(0xFF9A93BD);
  static const Color textFaint = Color(0xFF635C85);

  // ——— O'lchamlar ———
  static const double radius = 16;
  static const double radiusSmall = 10;
  static const double radiusPill = 999;

  /// Raqamlar ustun bo'lib turishi uchun — kenglik o'zgarmaydi.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ——— Tipografika ———
  /// O'yin nomi.
  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 6,
    height: 1.0,
    color: text,
  );

  /// Oyna sarlavhasi.
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.4,
    color: text,
  );

  /// Bo'lim nomi — kichik, katta harflar, siyrak.
  static const TextStyle section = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: textFaint,
  );

  /// Oddiy matn.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: textDim,
  );

  /// Tugma yozuvi.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.4,
    color: Colors.white,
  );

  /// Yirik raqam (hisob, foiz).
  static const TextStyle number = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.0,
    color: text,
    fontFeatures: tabular,
  );

  /// Kichik raqam (HUD pilyulasi).
  static const TextStyle numberSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: text,
    fontFeatures: tabular,
  );

  /// Rangli yuza ustidagi neon yorug'lik.
  static List<BoxShadow> glow(Color color, {double strength = 1}) =>
      <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: 0.38 * strength),
          blurRadius: 18 * strength,
          spreadRadius: -2,
        ),
      ];

  /// Panel soyasi — yengil, chuqurlik hissi uchun.
  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Flutter mavzusi — matn va kursor ranglari shu yerdan keladi.
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: coral,
        surface: panel,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: blue,
        selectionColor: Color(0x553D7BFF),
      ),
    );
  }
}
