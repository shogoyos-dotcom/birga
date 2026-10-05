import 'difficulty.dart';

/// O'yinning barcha sozlamalari bir joyda. Mantiq qatlami faqat shuni biladi.
class GameConfig {
  const GameConfig({
    this.gridWidth = 250,
    this.gridHeight = 250,
    this.startBlock = 5,
    this.botCount = 15,
    this.difficulty = Difficulty.normal,
    this.playerSpeed = 8.0,
    this.playerTurnRate = 14.0,
    this.botTurnRate = 9.0,
    this.botRespawnDelay = 3.0,
    this.maxStepDt = 1 / 30,
    this.selfHitGrace = 3,
  });

  /// Panjara o'lchami (katak).
  final int gridWidth;
  final int gridHeight;

  /// Boshlang'ich hudud joylashadigan kvadrat tomoni (bo'sh joy izlashda).
  final int startBlock;

  /// Boshlang'ich hudud doirasining radiusi (katak).
  double get startRadius => startBlock / 2;

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

  /// Oxirgi necha katak iz "o'ziniki" hisoblanmaydi.
  ///
  /// Barmoq bilan surishda yo'nalish doim biroz tebranadi va o'yinchi
  /// endigina chiqqan katagiga qaytib kirib qolishi mumkin. Buning uchun
  /// o'ldirish adolatsiz bo'lardi — qoida buzilmagan. Shuning uchun
  /// eng so'nggi bir necha katak hisobga olinmaydi; undan narigi izga
  /// tegish esa haqiqiy kesishish va o'limga olib keladi.
  final int selfHitGrace;

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
    selfHitGrace: selfHitGrace,
  );
}
