/// O'yin qiyinlik darajasi. Bot tezligi va tsikl uzunligiga ta'sir qiladi.
enum Difficulty {
  easy('Oson', 0.78, 0.7, 2.6),
  normal("O'rta", 0.92, 1.0, 1.9),
  hard('Qiyin', 1.06, 1.45, 1.3);

  const Difficulty(
    this.label,
    this.botSpeedFactor,
    this.botLoopFactor,
    this.botReactionDelay,
  );

  /// Bot tezligi o'yinchi tezligiga nisbatan.
  final double botSpeedFactor;

  /// Bot chizadigan tsiklning nisbiy uzunligi (kattaroq = jasurroq bot).
  final double botLoopFactor;

  /// Bot xavfga qancha sekin javob beradi (sekund).
  final double botReactionDelay;

  final String label;

  static Difficulty fromName(String? name) => Difficulty.values.firstWhere(
    (d) => d.name == name,
    orElse: () => Difficulty.normal,
  );
}
