/// Reyting qatori.
class ScoreRow {
  const ScoreRow({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.percent,
    required this.isHuman,
  });

  final int id;
  final String name;
  final int colorIndex;
  final double percent;
  final bool isHuman;
}

/// HUD uchun o'yin holatining qisqacha surati.
///
/// Mantiq har kadrda yangilanadi, HUD esa sekundiga ~8 marta — shunda
/// Flutter widgetlari keraksiz qayta qurilmaydi.
class HudSnapshot {
  const HudSnapshot({
    required this.percent,
    required this.kills,
    required this.elapsed,
    required this.rank,
    required this.alivePlayers,
    required this.top,
  });

  const HudSnapshot.empty()
    : percent = 0,
      kills = 0,
      elapsed = 0,
      rank = 1,
      alivePlayers = 1,
      top = const <ScoreRow>[];

  /// O'yinchi egallagan maydon foizi.
  final double percent;
  final int kills;
  final double elapsed;

  /// O'yinchining reytingdagi o'rni (1 dan boshlab).
  final int rank;
  final int alivePlayers;

  /// Top-5 reyting.
  final List<ScoreRow> top;

  String get formattedTime {
    final total = elapsed.floor();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
