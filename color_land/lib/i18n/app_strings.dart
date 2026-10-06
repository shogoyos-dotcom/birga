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
    required this.diedSelfCross,
    required this.diedTrailHit,
    required this.diedTerritoryLost,
    required this.settings,
    required this.back,
    required this.themeLabel,
    required this.continueGame,
    required this.withTicket,
    required this.watchAd,
    required this.tickets,
    required this.shop,
    required this.buyTickets,
    required this.noTickets,
    required this.adNotReady,
    required this.purchaseFailed,
    required this.ticketsAdded,
    required this.ticketPack,
    required this.demoPurchaseNote,
    required this.close,
    required this.giveUp,
    required this.profile,
    required this.nickname,
    required this.nicknameHint,
    required this.avatarLabel,
    required this.tabEmoji,
    required this.tabFigure,
    required this.tabFlag,
    required this.searchCountry,
    required this.save,
    required this.profileSaved,
    required this.rulesShort,
    required this.noRoomToContinue,
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
  final String diedSelfCross;
  final String diedTrailHit;
  final String diedTerritoryLost;
  final String settings;
  final String back;
  final String themeLabel;
  final String continueGame;
  final String withTicket;
  final String watchAd;
  final String tickets;
  final String shop;
  final String buyTickets;
  final String noTickets;
  final String adNotReady;
  final String purchaseFailed;
  final String ticketsAdded;
  final String ticketPack;
  final String demoPurchaseNote;
  final String close;
  final String giveUp;
  final String profile;
  final String nickname;
  final String nicknameHint;
  final String avatarLabel;
  final String tabEmoji;
  final String tabFigure;
  final String tabFlag;
  final String searchCountry;
  final String save;
  final String profileSaved;
  final String rulesShort;
  final String noRoomToContinue;

  String difficultyName(Difficulty d) => switch (d) {
    Difficulty.easy => easy,
    Difficulty.normal => normal,
    Difficulty.hard => hard,
  };

  String deathReason(DeathCause cause) => switch (cause) {
    DeathCause.selfCross => diedSelfCross,
    DeathCause.trailHit => diedTrailHit,
    DeathCause.territoryLost => diedTerritoryLost,
    DeathCause.none => '',
  };

  static const AppStrings uz = AppStrings(
    rulesShort: "Hududingizdan chiqing, halqa chizing va qaytib keling — ichidagi hamma narsa sizniki bo'ladi.",
    profile: 'Profil',
    nickname: 'Taxallus',
    nicknameHint: 'Ismingizni kiriting',
    avatarLabel: 'Avatar',
    tabEmoji: 'Emoji',
    tabFigure: 'Odam',
    tabFlag: 'Bayroq',
    searchCountry: 'Davlatni izlash',
    save: 'Saqlash',
    profileSaved: 'Profil saqlandi',
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
    diedSelfCross: "O'z izingizni kesib o'tdingiz",
    diedTrailHit: 'Izingizga tegib ketishdi',
    diedTerritoryLost: 'Butun hududingiz egallandi',
    settings: 'Sozlamalar',
    back: 'Orqaga',
    continueGame: 'Davom etasizmi?',
    withTicket: 'Belet bilan',
    watchAd: "Reklama ko'rish",
    tickets: 'Beletlar',
    shop: "Do'kon",
    buyTickets: 'Belet sotib olish',
    noTickets: 'Beletingiz qolmadi',
    adNotReady: 'Reklama hali tayyor emas',
    purchaseFailed: 'Xarid amalga oshmadi',
    ticketsAdded: "Beletlar qo'shildi",
    ticketPack: 'ta belet',
    demoPurchaseNote: 'Sinov rejimi: pul olinmaydi',
    close: 'Yopish',
    giveUp: 'Tugatish',
    noRoomToContinue: 'Davom etish uchun joy qolmadi',
    themeLabel: 'Uslub',
  );

  static const AppStrings en = AppStrings(
    rulesShort: 'Leave your zone, draw a loop and come back — everything inside becomes yours.',
    profile: 'Profile',
    nickname: 'Nickname',
    nicknameHint: 'Enter your name',
    avatarLabel: 'Avatar',
    tabEmoji: 'Emoji',
    tabFigure: 'Person',
    tabFlag: 'Flag',
    searchCountry: 'Search country',
    save: 'Save',
    profileSaved: 'Profile saved',
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
    diedSelfCross: 'You crossed your own trail',
    diedTrailHit: 'Someone cut your trail',
    diedTerritoryLost: 'You lost all your land',
    settings: 'Settings',
    back: 'Back',
    continueGame: 'Continue?',
    withTicket: 'Use a ticket',
    watchAd: 'Watch an ad',
    tickets: 'Tickets',
    shop: 'Shop',
    buyTickets: 'Buy tickets',
    noTickets: 'You have no tickets',
    adNotReady: 'Ad is not ready yet',
    purchaseFailed: 'Purchase failed',
    ticketsAdded: 'Tickets added',
    ticketPack: 'tickets',
    demoPurchaseNote: 'Test mode: you are not charged',
    close: 'Close',
    giveUp: 'End run',
    noRoomToContinue: 'No room left to continue',
    themeLabel: 'Style',
  );

  static const AppStrings ru = AppStrings(
    rulesShort: 'Выйдите из своей зоны, очертите петлю и вернитесь — всё внутри станет вашим.',
    profile: 'Профиль',
    nickname: 'Никнейм',
    nicknameHint: 'Введите имя',
    avatarLabel: 'Аватар',
    tabEmoji: 'Эмодзи',
    tabFigure: 'Человек',
    tabFlag: 'Флаг',
    searchCountry: 'Поиск страны',
    save: 'Сохранить',
    profileSaved: 'Профиль сохранён',
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
    diedSelfCross: 'Вы пересекли свой след',
    diedTrailHit: 'Ваш след перерезали',
    diedTerritoryLost: 'Вы потеряли всю территорию',
    settings: 'Настройки',
    back: 'Назад',
    continueGame: 'Продолжить?',
    withTicket: 'Билетом',
    watchAd: 'Посмотреть рекламу',
    tickets: 'Билеты',
    shop: 'Магазин',
    buyTickets: 'Купить билеты',
    noTickets: 'Билетов не осталось',
    adNotReady: 'Реклама ещё не готова',
    purchaseFailed: 'Покупка не удалась',
    ticketsAdded: 'Билеты добавлены',
    ticketPack: 'билетов',
    demoPurchaseNote: 'Тестовый режим: оплата не списывается',
    close: 'Закрыть',
    giveUp: 'Завершить',
    noRoomToContinue: 'Нет места, чтобы продолжить',
    themeLabel: 'Стиль',
  );

  static const AppStrings tr = AppStrings(
    rulesShort: 'Bölgenden çık, bir halka çiz ve geri dön — içindeki her şey senin olur.',
    profile: 'Profil',
    nickname: 'Takma ad',
    nicknameHint: 'Adınızı girin',
    avatarLabel: 'Avatar',
    tabEmoji: 'Emoji',
    tabFigure: 'Kişi',
    tabFlag: 'Bayrak',
    searchCountry: 'Ülke ara',
    save: 'Kaydet',
    profileSaved: 'Profil kaydedildi',
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
    diedSelfCross: 'Kendi izini kestin',
    diedTrailHit: 'İzini kestiler',
    diedTerritoryLost: 'Tüm bölgeni kaybettin',
    settings: 'Ayarlar',
    back: 'Geri',
    continueGame: 'Devam?',
    withTicket: 'Bilet ile',
    watchAd: 'Reklam izle',
    tickets: 'Biletler',
    shop: 'Mağaza',
    buyTickets: 'Bilet al',
    noTickets: 'Biletin kalmadı',
    adNotReady: 'Reklam henüz hazır değil',
    purchaseFailed: 'Satın alma başarısız',
    ticketsAdded: 'Biletler eklendi',
    ticketPack: 'bilet',
    demoPurchaseNote: 'Test modu: ücret alınmaz',
    close: 'Kapat',
    giveUp: 'Bitir',
    noRoomToContinue: 'Devam için yer kalmadı',
    themeLabel: 'Stil',
  );

  static const AppStrings kk = AppStrings(
    rulesShort: 'Аймағыңнан шығып, ілмек сызып қайтыңыз — ішіндегінің бәрі сіздікі болады.',
    profile: 'Профиль',
    nickname: 'Лақап ат',
    nicknameHint: 'Атыңызды енгізіңіз',
    avatarLabel: 'Аватар',
    tabEmoji: 'Эмодзи',
    tabFigure: 'Адам',
    tabFlag: 'Жалау',
    searchCountry: 'Елді іздеу',
    save: 'Сақтау',
    profileSaved: 'Профиль сақталды',
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
    diedSelfCross: 'Өз ізіңізді кесіп өттіңіз',
    diedTrailHit: 'Ізіңізді кесіп кетті',
    diedTerritoryLost: 'Бүкіл аумағыңыз алынды',
    settings: 'Баптаулар',
    back: 'Артқа',
    continueGame: 'Жалғастырасыз ба?',
    withTicket: 'Билетпен',
    watchAd: 'Жарнама көру',
    tickets: 'Билеттер',
    shop: 'Дүкен',
    buyTickets: 'Билет сатып алу',
    noTickets: 'Билет қалмады',
    adNotReady: 'Жарнама әлі дайын емес',
    purchaseFailed: 'Сатып алу сәтсіз',
    ticketsAdded: 'Билеттер қосылды',
    ticketPack: 'билет',
    demoPurchaseNote: 'Сынақ режимі: ақы алынбайды',
    close: 'Жабу',
    giveUp: 'Аяқтау',
    noRoomToContinue: 'Жалғастыруға орын қалмады',
    themeLabel: 'Стиль',
  );

  static AppStrings of(AppLanguage language) => switch (language) {
    AppLanguage.uz => uz,
    AppLanguage.en => en,
    AppLanguage.ru => ru,
    AppLanguage.tr => tr,
    AppLanguage.kk => kk,
  };
}
