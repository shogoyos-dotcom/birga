/// O'yin qiyinligi. Bot tezligi, tsikl uzunligi va ehtiyotkorligiga ta'sir
/// qiladi. Matnli nomlar `AppStrings` da — bu yerda faqat raqamlar.
enum Difficulty {
  easy(
    botSpeedFactor: 0.80,
    botLoopFactor: 0.70,
    reactionDelay: 0.55,
    dangerRadius: 6.0,
    huntRadius: 9.0,
  ),
  normal(
    botSpeedFactor: 0.95,
    botLoopFactor: 1.00,
    reactionDelay: 0.30,
    dangerRadius: 9.0,
    huntRadius: 15.0,
  ),
  hard(
    botSpeedFactor: 1.08,
    botLoopFactor: 1.45,
    reactionDelay: 0.12,
    dangerRadius: 12.0,
    huntRadius: 22.0,
  );

  const Difficulty({
    required this.botSpeedFactor,
    required this.botLoopFactor,
    required this.reactionDelay,
    required this.dangerRadius,
    required this.huntRadius,
  });

  /// Bot tezligi o'yinchi tezligiga nisbatan.
  final double botSpeedFactor;

  /// Bot chizadigan tsiklning nisbiy uzunligi — kattaroq = jasurroq bot.
  final double botLoopFactor;

  /// Bot qarorini necha sekundda bir qayta ko'rib chiqadi.
  final double reactionDelay;

  /// Raqib shu masofadan yaqin kelsa bot uyiga qaytadi (katak).
  final double dangerRadius;

  /// Himoyasiz izni shu masofadan ko'rsa hujum qiladi (katak).
  final double huntRadius;

  static Difficulty fromName(String? name) => Difficulty.values.firstWhere(
    (d) => d.name == name,
    orElse: () => Difficulty.normal,
  );
}
