import '../game/logic/difficulty.dart';
import '../game/logic/game_events.dart';
import 'app_language.dart';

/// Interfeys matnlari. Har bir maydon majburiy — shuning uchun yangi satr
/// qo'shilsa, tarjimasi unutilgan til kompilyatsiya xatosi beradi.
class AppStrings {
  const AppStrings({
    required this.play,
    required this.chooseColor,
    required this.record,
    required this.difficulty,
    required this.easy,
    required this.normal,
    required this.hard,
    required this.language,
    required this.you,
    required this.territory,
    required this.kills,
    required this.time,
    required this.gameOver,
    required this.playAgain,
    required this.menu,
    required this.newRecord,
    required this.dragToMove,
    required this.pause,
    required this.resume,
    required this.leaderboard,
    required this.diedWall,
    required this.diedSelfCross,
    required this.diedTrailHit,
    required this.diedTerritoryLost,
    required this.settings,
    required this.back,
  });

  final String play;
  final String chooseColor;
  final String record;
  final String difficulty;
  final String easy;
  final String normal;
  final String hard;
  final String language;
  final String you;
  final String territory;
  final String kills;
  final String time;
  final String gameOver;
  final String playAgain;
  final String menu;
  final String newRecord;
  final String dragToMove;
  final String pause;
  final String resume;
  final String leaderboard;
  final String diedWall;
  final String diedSelfCross;
  final String diedTrailHit;
  final String diedTerritoryLost;
  final String settings;
  final String back;

  String difficultyName(Difficulty d) => switch (d) {
    Difficulty.easy => easy,
    Difficulty.normal => normal,
    Difficulty.hard => hard,
  };

  String deathReason(DeathCause cause) => switch (cause) {
    DeathCause.wall => diedWall,
    DeathCause.selfCross => diedSelfCross,
    DeathCause.trailHit => diedTrailHit,
    DeathCause.territoryLost => diedTerritoryLost,
    DeathCause.none => '',
  };

  static const AppStrings uz = AppStrings(
    play: "O'ynash",
    chooseColor: 'Rang tanlang',
    record: 'Rekord',
    difficulty: 'Qiyinlik',
    easy: 'Oson',
    normal: "O'rta",
    hard: 'Qiyin',
    language: 'Til',
    you: 'Siz',
    territory: 'Hudud',
    kills: "O'ldirishlar",
    time: 'Vaqt',
    gameOver: "O'yin tugadi",
    playAgain: "Qayta o'ynash",
    menu: 'Menyu',
    newRecord: 'Yangi rekord!',
    dragToMove: 'Yurish uchun ekranni suring',
    pause: 'Pauza',
    resume: 'Davom etish',
    leaderboard: 'Reyting',
    diedWall: 'Chegaraga urildingiz',
    diedSelfCross: "O'z izingizni kesib o'tdingiz",
    diedTrailHit: 'Izingizga tegib ketishdi',
    diedTerritoryLost: 'Butun hududingiz egallandi',
    settings: 'Sozlamalar',
    back: 'Orqaga',
  );

  static const AppStrings en = AppStrings(
    play: 'Play',
    chooseColor: 'Choose a colour',
    record: 'Best',
    difficulty: 'Difficulty',
    easy: 'Easy',
    normal: 'Normal',
    hard: 'Hard',
    language: 'Language',
    you: 'You',
    territory: 'Territory',
    kills: 'Kills',
    time: 'Time',
    gameOver: 'Game over',
    playAgain: 'Play again',
    menu: 'Menu',
    newRecord: 'New record!',
    dragToMove: 'Drag anywhere to steer',
    pause: 'Pause',
    resume: 'Resume',
    leaderboard: 'Leaderboard',
    diedWall: 'You hit the wall',
    diedSelfCross: 'You crossed your own trail',
    diedTrailHit: 'Someone cut your trail',
    diedTerritoryLost: 'You lost all your land',
    settings: 'Settings',
    back: 'Back',
  );

  static const AppStrings ru = AppStrings(
    play: 'Играть',
    chooseColor: 'Выберите цвет',
    record: 'Рекорд',
    difficulty: 'Сложность',
    easy: 'Лёгкий',
    normal: 'Средний',
    hard: 'Сложный',
    language: 'Язык',
    you: 'Вы',
    territory: 'Территория',
    kills: 'Убийства',
    time: 'Время',
    gameOver: 'Игра окончена',
    playAgain: 'Играть снова',
    menu: 'Меню',
    newRecord: 'Новый рекорд!',
    dragToMove: 'Проведите пальцем, чтобы двигаться',
    pause: 'Пауза',
    resume: 'Продолжить',
    leaderboard: 'Рейтинг',
    diedWall: 'Вы врезались в границу',
    diedSelfCross: 'Вы пересекли свой след',
    diedTrailHit: 'Ваш след перерезали',
    diedTerritoryLost: 'Вы потеряли всю территорию',
    settings: 'Настройки',
    back: 'Назад',
  );

  static const AppStrings tr = AppStrings(
    play: 'Oyna',
    chooseColor: 'Renk seç',
    record: 'Rekor',
    difficulty: 'Zorluk',
    easy: 'Kolay',
    normal: 'Orta',
    hard: 'Zor',
    language: 'Dil',
    you: 'Sen',
    territory: 'Bölge',
    kills: 'Eleme',
    time: 'Süre',
    gameOver: 'Oyun bitti',
    playAgain: 'Tekrar oyna',
    menu: 'Menü',
    newRecord: 'Yeni rekor!',
    dragToMove: 'Yön vermek için ekranı kaydır',
    pause: 'Duraklat',
    resume: 'Devam et',
    leaderboard: 'Sıralama',
    diedWall: 'Sınıra çarptın',
    diedSelfCross: 'Kendi izini kestin',
    diedTrailHit: 'İzini kestiler',
    diedTerritoryLost: 'Tüm bölgeni kaybettin',
    settings: 'Ayarlar',
    back: 'Geri',
  );

  static const AppStrings kk = AppStrings(
    play: 'Ойнау',
    chooseColor: 'Түс таңдаңыз',
    record: 'Рекорд',
    difficulty: 'Қиындық',
    easy: 'Оңай',
    normal: 'Орташа',
    hard: 'Қиын',
    language: 'Тіл',
    you: 'Сіз',
    territory: 'Аумақ',
    kills: 'Жойғандар',
    time: 'Уақыт',
    gameOver: 'Ойын бітті',
    playAgain: 'Қайта ойнау',
    menu: 'Мәзір',
    newRecord: 'Жаңа рекорд!',
    dragToMove: 'Бағыт беру үшін экранды сырғытыңыз',
    pause: 'Кідіріс',
    resume: 'Жалғастыру',
    leaderboard: 'Рейтинг',
    diedWall: 'Шекараға соғылдыңыз',
    diedSelfCross: 'Өз ізіңізді кесіп өттіңіз',
    diedTrailHit: 'Ізіңізді кесіп кетті',
    diedTerritoryLost: 'Бүкіл аумағыңыз алынды',
    settings: 'Баптаулар',
    back: 'Артқа',
  );

  static AppStrings of(AppLanguage language) => switch (language) {
    AppLanguage.uz => uz,
    AppLanguage.en => en,
    AppLanguage.ru => ru,
    AppLanguage.tr => tr,
    AppLanguage.kk => kk,
  };
}
