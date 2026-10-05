import 'difficulty.dart';

/// O'yinning barcha sozlamalari bir joyda. Mantiq qatlami faqat shuni biladi.
class GameConfig {
  const GameConfig({
    this.gridWidth = 150,
    this.gridHeight = 150,
    this.startBlock = 5,
    this.botCount = 9,
    this.difficulty = Difficulty.normal,
    this.playerSpeed = 8.0,
    this.playerTurnRate = 14.0,
    this.botTurnRate = 9.0,
    this.botRespawnDelay = 3.0,
    this.maxStepDt = 1 / 30,
  });

  /// Panjara o'lchami (katak).
  final int gridWidth;
  final int gridHeight;

  /// Boshlang'ich hudud tomoni (5 => 5x5).
  final int startBlock;

  final int botCount;
  final Difficulty difficulty;

  /// Katak/sekund.
  final double playerSpeed;

  /// Radian/sekund — burilish tezligi.
  final double playerTurnRate;
  final double botTurnRate;

  /// O'lgan bot necha sekunddan keyin qayta paydo bo'ladi.
  final double botRespawnDelay;

  /// Bir kadrda hisoblanadigan maksimal vaqt (lag paytida sakrashni oldini oladi).
  final double maxStepDt;

  int get cellCount => gridWidth * gridHeight;

  double get botSpeed => playerSpeed * difficulty.botSpeedFactor;

  GameConfig copyWith({Difficulty? difficulty, int? botCount}) => GameConfig(
    gridWidth: gridWidth,
    gridHeight: gridHeight,
    startBlock: startBlock,
    botCount: botCount ?? this.botCount,
    difficulty: difficulty ?? this.difficulty,
    playerSpeed: playerSpeed,
    playerTurnRate: playerTurnRate,
    botTurnRate: botTurnRate,
    botRespawnDelay: botRespawnDelay,
    maxStepDt: maxStepDt,
  );
}
