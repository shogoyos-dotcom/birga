import '../../data/countries.dart';

/// Avatar turi.
enum AvatarKind {
  /// Emoji belgisi.
  emoji,

  /// Kod bilan chiziladigan odam tasviri.
  figure,

  /// Davlat bayrog'i (ISO 3166-1 kodi).
  flag,
}

/// O'yinchining avatari.
///
/// Rasm fayllari saqlanmaydi: emoji va bayroqlar tizim shriftidan
/// chiziladi, odam tasvirlari esa kod bilan.
class Avatar {
  const Avatar(this.kind, this.value);

  const Avatar.emoji(String emoji) : this(AvatarKind.emoji, emoji);

  const Avatar.figure(int index) : this(AvatarKind.figure, '$index');

  const Avatar.flag(String countryCode) : this(AvatarKind.flag, countryCode);

  final AvatarKind kind;

  /// Emoji belgisi, odam tasviri raqami yoki davlat kodi.
  final String value;

  /// Ekranda chiziladigan matn (emoji yoki bayroq). Odam tasviri uchun
  /// bo'sh — u shakllar bilan chiziladi.
  String get glyph => switch (kind) {
    AvatarKind.emoji => value,
    AvatarKind.flag => countryByCode(value)?.flag ?? '',
    AvatarKind.figure => '',
  };

  /// Odam tasvirining raqami (boshqa turlarda 0).
  int get figureIndex =>
      kind == AvatarKind.figure ? (int.tryParse(value) ?? 0) : 0;

  String encode() => '${kind.name}:$value';

  static Avatar decode(String? raw) {
    if (raw == null || !raw.contains(':')) return defaultAvatar;
    final parts = raw.split(':');
    final kind = AvatarKind.values.firstWhere(
      (k) => k.name == parts.first,
      orElse: () => AvatarKind.figure,
    );
    return Avatar(kind, parts.sublist(1).join(':'));
  }

  static const Avatar defaultAvatar = Avatar.figure(0);

  @override
  bool operator ==(Object other) =>
      other is Avatar && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// Tanlash uchun emoji to'plami.
// dart format off
const List<String> kAvatarEmojis = <String>[
  '😀', '😎', '🤩', '🥳', '😈', '🤖', '👻', '💀',
  '🦊', '🐱', '🐶', '🐼', '🐸', '🦁', '🐯', '🐵',
  '🦄', '🐙', '🦖', '🐢', '🦅', '🐝', '🦋', '🐬',
  '🔥', '⚡', '💎', '🌟', '🍀', '🌈', '🍕', '🍩',
  '⚽', '🏀', '🎮', '🎧', '🚀', '👑', '🎯', '🏆',
];
// dart format on

/// Odam tasvirlari soni (kod bilan chiziladi).
const int kFigureCount = 12;

/// O'yinchi profili: taxallus va avatar.
class PlayerProfile {
  const PlayerProfile({required this.nickname, required this.avatar});

  final String nickname;
  final Avatar avatar;

  /// Taxallus uchun chegaralar.
  static const int maxNicknameLength = 12;

  /// Bo'sh yoki faqat probel bo'lsa, standart nom ishlatiladi.
  static String sanitize(String raw, String fallback) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= maxNicknameLength
        ? trimmed
        : trimmed.substring(0, maxNicknameLength);
  }
}
