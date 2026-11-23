import 'dart:ui' show Locale;

/// Interfeys tillari.
enum AppLanguage {
  uz('uz', "O'zbekcha"),
  en('en', 'English'),
  ru('ru', 'Русский'),
  tr('tr', 'Türkçe'),
  kk('kk', 'Қазақша');

  const AppLanguage(this.code, this.nativeName);

  /// ISO 639-1 kodi.
  final String code;

  /// Tilning o'z nomi — ro'yxatda shunday ko'rsatiladi.
  final String nativeName;

  /// Ro'yxatdagi qisqa belgi. Bayroq emoji qurilmaga qarab ko'rinmasligi
  /// mumkin, shuning uchun til kodi ishlatiladi.
  String get badge => code.toUpperCase();

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.uz;
    for (final l in AppLanguage.values) {
      if (l.code == code) return l;
    }
    return AppLanguage.uz;
  }

  /// Tizim tiliga mos tilni tanlaydi, topilmasa — o'zbekcha.
  static AppLanguage fromSystem(List<Locale> locales) {
    for (final locale in locales) {
      for (final l in AppLanguage.values) {
        if (l.code == locale.languageCode) return l;
      }
    }
    return AppLanguage.uz;
  }
}
