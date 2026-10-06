# Color Land

Hudud egallash arkada o'yini — Flutter + Flame, faqat Android, portret.

Original o'yin: nomi, dizayni, ranglari va grafikasi shu loyihaga tegishli.
Hamma narsa kod bilan chiziladi, tashqi rasm fayllari ishlatilmaydi.

## Qisqacha qoidalar

- Har bir o'yinchi 5×5 katak hudud bilan boshlaydi.
- O'z hududingizdan chiqsangiz orqangizda **iz** qoladi.
- Hududingizga qaytsangiz iz va u o'rab olgan hamma narsa sizniki bo'ladi —
  raqib hududi ham.
- O'lasiz, agar: chegaraga ursangiz, o'z izingizni kessangiz, izingizga
  kimdir tegsa yoki butun hududingiz egallansa.
- Izga tekkan o'yinchi **+1 kill** oladi.

## Ishga tushirish

```bash
flutter pub get
flutter run              # qurilma yoki emulyatorda
flutter test             # 102 ta test
flutter analyze
```

## Loyiha tuzilmasi

```
lib/
  game/
    logic/        # Flutter'ga bog'liq emas — to'liq test qilinadi
      game_grid.dart          panjara, egalik va iz (Uint8List)
      territory_capture.dart  flood fill orqali hudud egallash
      game_world.dart         harakat, o'lim qoidalari, hodisalar
      bot_ai.dart             botlar xulq-atvori
      player_profile.dart     taxallus va avatar (emoji / odam / bayroq)
      match.dart              o'yinchi + botlardan o'yin yig'ish
    render/       # Flame komponentlari, keshlangan chizish
      game_theme.dart         arena uslublari (fon, panjara, ranglar)
      shape_painter.dart      hudud konturi + ui.Picture keshi
      contour.dart            chegarani topish, soddalashtirish, silliqlash
      avatar_painter.dart     avatarni tuvalga chizish
      color_land_game.dart    kamera, animatsiyalar, HUD manbasi
  data/
    countries.dart            ISO 3166-1: 249 davlat va bayrog'i
  i18n/           # 5 til: uz, en, ru, tr, kk
  storage/        # shared_preferences (rekord, rang, qiyinlik, til, profil)
  ui/
    theme/arcade.dart         dizayn tizimi: ranglar, tipografika, o'lchamlar
    widgets/ui_kit.dart       tugma, panel, chip, stat — umumiy komponentlar
    widgets/mini_map.dart     butun xaritaning kichik ko'rinishi
    widgets/game_hud.dart     foiz, vaqt, reyting, pauza
    menu_screen.dart          bosh menyu
    profile_screen.dart       taxallus va avatar
    game_screen.dart          o'yin, pauza va natija oynalari
test/             # flood fill, o'lim qoidalari, bot AI, rendering, tezlik
tool/             # skrinshot va ikonka generatorlari (test sifatida ishlaydi)
```

Mantiq rendering'dan to'liq ajratilgan: `lib/game/logic/` ichidagi hech bir
fayl Flutter yoki Flame'ni import qilmaydi.

## Dizayn: "Arcade Grid"

Butun interfeys bitta dizayn tizimidan quriladi — `lib/ui/theme/arcade.dart`:

- Fon `#100E1B`, panel `#1A1728`, chiziq `#2E2946`.
- Asosiy aksent — elektr ko'k `#3D7BFF`, ikkinchisi — korall `#FF6B5B`.
- Sarlavhalar va tugma yozuvlari KATTA HARFLARDA, siyrak oraliq bilan;
  muhim raqamlar yirik va qalin, `tabularFigures` bilan (raqam
  o'zgarganda kenglik sakramaydi).
- Tugmalarning holatlari aniq: oddiy, hover, bosilgan (pastga suriladi,
  "qalinligi" yo'qoladi) va o'chirilgan.

Arena — ekrandagi eng katta element. Yuzasi aniq panjaraga bo'lingan
(har katakda ingichka chiziq, har beshinchisida yo'g'onroq), chekkasi
neon chiziq bilan belgilangan. HUD chekkalarga surilgan: yuqori chapda
foiz va chiziq, yuqori o'ngda pauza va tor reyting, pastki chap burchakda
mini-xarita. Arenaning o'rtasi hech narsa bilan to'silmaydi.

Interfeys ranglari uslub tanlashga bog'liq emas — menyu, profil va HUD
hamma uslubda bir xil to'q ko'rinishda. Uslub tanlash faqat **arena**
ko'rinishini o'zgartiradi (fon, panjara, o'yinchi ranglari, qalinlik):
Arcade (standart), Neon, Tungi, Yorqin, Pastel.

## Profil

Bosh menyudagi profil kartasidan taxallus va avatar tanlanadi. Avatar uch
xil bo'ladi:

- **Emoji** — 40 ta belgi;
- **Odam** — 12 ta tasvir, kod bilan chiziladi (teri, soch va kiyim rangi
  har xil);
- **Bayroq** — ISO 3166-1 bo'yicha 249 ta davlat, izlash maydoni bilan.

Hech qanday rasm fayli saqlanmaydi: emoji va bayroqlar tizim shriftidan
chiziladi (bayroq kodi ikki "regional indicator" belgisiga aylantiriladi),
odam tasvirlari esa shakllardan yig'iladi — shuning uchun ilova hajmi
oshmaydi.

Tanlangan avatar o'yin ichida o'yinchining hududi ustida va reytingda
ko'rinadi. Avatar hududning eng "qalin" nuqtasiga qo'yiladi (masofa
transformatsiyasi), shuning uchun yarim oysimon yoki teshikli hududda ham
chetga tushib qolmaydi; joyi hudud shakli bilan birga keshlanadi.

## Tezlik

`flutter test test/performance_test.dart` o'lchaydi va chegaralarni
tekshiradi. Asosiy yechim — har bir o'yinchining hududi silliq shakl
sifatida bir marta `ui.Picture` ga yoziladi va faqat o'sha hudud
o'zgarganda qayta yoziladi; ekranga tushmagan hududlar umuman
chizilmaydi.

Kadr byudjeti 60 FPS da 16 600 µs. Oxirgi o'lchov (250x250 xarita,
15 ta o'yinchi, maydonning 30% i egallangan):

| Ish | Narxi |
| --- | --- |
| Mantiq (10 o'yinchi) | 7 µs/kadr |
| Keshlangan hududlarni chizish | 19 µs/kadr |
| Arena panjarasi (121 chiziq) | 35 µs/kadr |
| Avatarlar (15 ta, eng yomon holat) | 84 µs/kadr |
| Mini-xarita (441 to'rtburchak) | 289 µs, sekundiga ~8 marta |
| Bitta hudud shaklini qayta yozish | 491 µs, kadrda ~0.01 marta |

## Yordamchi vositalar

```bash
flutter test tool/icon_test.dart        # ikonkalar + Play materiallari
flutter test tool/screenshot_test.dart  # build/shot_*.png skrinshotlar
flutter test tool/themes_test.dart      # build/theme_*.png — har uslub
```

## Reklama va xaridlar

O'lgandan keyin o'yinchi ikki yo'l bilan davom etishi mumkin: **belet
sarflash** yoki **reklama ko'rish**. Beletlar do'kondan olinadi va
`shared_preferences` da saqlanadi.

Hozir ikkalasi ham **namuna** holatda ishlaydi
(`lib/services/continue_services.dart`): reklama o'rniga qisqa kutish,
xarid esa pulsiz. Shunda mexanikani hoziroq sinab ko'rish mumkin.

Haqiqiysiga o'tish uchun o'sha fayldagi ikki interfeysning yangi
amalga oshirishini yozib, `GameScreen` ga uzatish kifoya — o'yin kodi
o'zgarmaydi:

| Interfeys | Nima kerak |
|---|---|
| `RewardedAdService` | Google AdMob akkaunti, ilova ID si va "rewarded" reklama bloki; `google_mobile_ads` paketi; AndroidManifest ga AdMob ID |
| `StoreService` | Play Console da "Managed product" lar (`tickets_1`, `tickets_5`, `tickets_15`); `in_app_purchase` paketi |

Ikkalasi ham sizning akkauntingizni talab qiladi, shuning uchun ularni
men ulay olmayman.

## Cloud sessiyalarda qurish

Claude Code cloud sessiyalarida Flutter ham, Android SDK ham oldindan
o'rnatilmagan (Java, Gradle va git bor). `tool/cloud_setup.sh` ikkalasini
ham o'rnatadi.

Qo'yish tartibi:

1. Muhitning **Network access** sozlamasini **Full** qiling, yoki
   **Custom** tanlab `dl.google.com` va `maven.google.com` ni qo'shing va
   "Also include default list of common package managers" katagini
   belgilang. Android SDK va Gradle plagini faqat shu hostlardan keladi.
2. `tool/cloud_setup.sh` mazmunini muhit sozlamalaridagi **Setup script**
   maydoniga nusxalang (environment selector -> Cloud -> muhit ustida ⚙).

O'lchangan: toza muhitda **99 sekund** (Flutter 2.3 GB + Android SDK
472 MB, ikkalasi parallel yuklanadi). Bu hujjatdagi ~5 daqiqalik
chegaradan past, shuning uchun muhit keshlanadi va keyingi sessiyalar
tayyor diskdan boshlanadi — skript qaytadan ishlamaydi.

Skript idempotent: allaqachon o'rnatilgan bo'lsa o'tkazib yuboradi, va
har doim 0 kodi bilan tugaydi (aks holda sessiya ishga tushmaydi).

## Google Play

`RELEASE.md` ga qarang — keystore yaratishdan `.aab` yuklashgacha.
