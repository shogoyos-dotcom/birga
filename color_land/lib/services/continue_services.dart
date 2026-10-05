/// O'limdan keyin davom etish uchun ikki yo'l: belet va reklama.
///
/// ⚠️ Bu fayldagi amalga oshirishlar — **namuna**. Haqiqiy reklama va
/// xaridlar uchun quyidagilar kerak va ularni faqat ilova egasi qila oladi:
///
///  * **Reklama** — Google AdMob akkaunti, ilova ID si va "rewarded"
///    reklama bloki. `pubspec.yaml` ga `google_mobile_ads` qo'shiladi,
///    `AndroidManifest.xml` ga AdMob ilova ID si yoziladi va
///    [RewardedAdService] ning haqiqiy varianti yoziladi.
///  * **Xaridlar** — Play Console da "Managed product" lar yaratiladi
///    (masalan `tickets_5`), `in_app_purchase` paketi qo'shiladi va
///    [StoreService] ning haqiqiy varianti yoziladi.
///
/// Interfeyslar shuning uchun alohida: o'yin kodi o'zgarmaydi, faqat shu
/// ikki klassning o'rniga haqiqiylari qo'yiladi.
library;

/// Do'kondagi belet to'plami.
class TicketPack {
  const TicketPack({
    required this.id,
    required this.tickets,
    required this.price,
    this.bestValue = false,
  });

  /// Play Console dagi mahsulot ID si.
  final String id;

  final int tickets;

  /// Ko'rsatish uchun narx (haqiqiy do'konda do'kondan olinadi).
  final String price;

  /// Ro'yxatda ajratib ko'rsatiladimi.
  final bool bestValue;
}

/// Mukofotli reklama ko'rsatish.
abstract class RewardedAdService {
  /// Reklama yuklanganmi.
  bool get isReady;

  /// Reklamani ko'rsatadi. To'liq ko'rilsa `true` qaytaradi.
  Future<bool> showRewarded();

  /// Keyingi safar uchun oldindan yuklab qo'yadi.
  Future<void> preload();
}

/// Belet sotib olish.
abstract class StoreService {
  Future<List<TicketPack>> packs();

  /// Xarid muvaffaqiyatli bo'lsa, olingan beletlar sonini qaytaradi;
  /// bekor qilinsa yoki xato bo'lsa — 0.
  Future<int> buy(TicketPack pack);
}

/// Namuna reklama xizmati: haqiqiy reklama o'rniga qisqa kutish.
///
/// AdMob ulanmaguncha o'yin shu bilan ishlaydi, shunda davom etish
/// mexanikasini hoziroq sinab ko'rish mumkin.
class DemoRewardedAdService implements RewardedAdService {
  bool _ready = true;

  @override
  bool get isReady => _ready;

  @override
  Future<void> preload() async {
    _ready = true;
  }

  @override
  Future<bool> showRewarded() async {
    if (!_ready) return false;
    _ready = false;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _ready = true;
    return true;
  }
}

/// Namuna do'kon: pul olinmaydi, xarid darhol muvaffaqiyatli hisoblanadi.
class DemoStoreService implements StoreService {
  static const List<TicketPack> _packs = <TicketPack>[
    TicketPack(id: 'tickets_1', tickets: 1, price: '—'),
    TicketPack(id: 'tickets_5', tickets: 5, price: '—', bestValue: true),
    TicketPack(id: 'tickets_15', tickets: 15, price: '—'),
  ];

  @override
  Future<List<TicketPack>> packs() async => _packs;

  @override
  Future<int> buy(TicketPack pack) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return pack.tickets;
  }
}
