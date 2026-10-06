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
flutter test             # 129 ta test
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
      world_map_painter.dart  quruqlik, qirg'oq va poytaxtlar (plitkalab)
      shape_painter.dart      hudud konturi + ui.Picture keshi
      contour.dart            chegarani topish, soddalashtirish, silliqlash
      avatar_painter.dart     avatarni tuvalga chizish
      color_land_game.dart    kamera, animatsiyalar, HUD manbasi
  data/
    countries.dart            ISO 3166-1: 249 davlat va bayrog'i
    world_map.dart            dunyo quruqligi niqobi (generatsiya)
    capitals.dart             236 poytaxt va koordinatasi (generatsiya)
  services/
    audio_service.dart        ovoz effektlari, musiqa, vibratsiya
  i18n/           # 5 til: uz, en, ru, tr, kk
  storage/        # shared_preferences (rekord, rang, qiyinlik, til, profil)
  ui/
    theme/arcade.dart         dizayn tizimi: ranglar, tipografika, o'lchamlar
    widgets/ui_kit.dart       tugma, panel, chip, stat — umumiy komponentlar
    widgets/mini_map.dart     butun xaritaning kichik ko'rinishi
    widgets/game_hud.dart     foiz, vaqt, reyting, pauza
    menu_screen.dart          bosh menyu
    settings_screen.dart      rang, uslub, qiyinlik, til, ovoz
    profile_screen.dart       taxallus va avatar
    game_screen.dart          o'yin, pauza va natija oynalari
test/             # flood fill, o'lim qoidalari, bot AI, rendering, tezlik
tool/             # skrinshot va ikonka generatorlari (test sifatida ishlaydi)
```

Mantiq rendering'dan to'liq ajratilgan: `lib/game/logic/` ichidagi hech bir
fayl Flutter yoki Flame'ni import qilmaydi.

## Maydon — dunyo xaritasi

Arena 520x205 katak: ekvatorial proyeksiyadagi dunyo xaritasi
(Antarktidasiz, 83°N dan 58°S gacha). Kataklarning 30.5% i quruqlik —
o'ynaladigan joy; okean esa to'siq, xuddi xarita cheti kabi: unga
kirilmaydi, lekin o'ldirmaydi ham, o'yinchi qirg'oq bo'ylab sirpanadi.

Shu bilan birga:

- foizlar quruqlikka nisbatan hisoblanadi, okean hisobga olinmaydi;
- suv hech qachon egallanmaydi — halqa ichida qolgan ko'l ko'l bo'lib
  qoladi, okeanga ulangan qo'ltiq ham egallanmaydi;
- o'yinchilar faqat atrofida yetarli quruqlik bor joyda tug'iladi, kichik
  orolda qamalib qolmaydi;
- botlar suvni devor deb biladi va qirg'oqdan chetlanadi.

Xaritada **236 ta poytaxt** belgilangan. Yozuvlar zich joyda (Yevropa,
Janubiy Afrika) bir-birini bosmasligi uchun aholisi ko'proq shahar
ustunlik qiladi.

Ma'lumot manbai — [Natural Earth](https://www.naturalearthdata.com/)
1:110m (public domain). Fayllar repozitoriyda emas, generator ularni
o'zi yuklab oladi:

```bash
python3 tool/make_world_map.py        # lib/data/world_map.dart + capitals.dart
python3 tool/make_world_map.py 640 250  # boshqa o'lchamda
```

Quruqlik niqobi har katak uchun bitta bit, base64 da (17 KB) — alohida
asset fayli yo'q. Qirg'oq chizig'i hududlar bilan bir xil usulda
silliqlanadi, shuning uchun pog'onali bo'lmaydi; xarita plitkalarga
bo'lib keshlanadi va faqat ekranga tushgani chiziladi.

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

## Sozlamalar va ovoz

Bosh menyuda faqat o'ynash qoladi; barcha tanlovlar sozlamalar ekranida
(yuqori o'ngdagi tishli g'ildirak) uch bo'limga ajratilgan:

- **Ko'rinish** — o'yinchi rangi, vizual uslub;
- **O'yin** — qiyinlik, interfeys tili;
- **Ovoz va titrash** — musiqa, ovoz effektlari, vibratsiya (uchalasi
  alohida yoqiladi va `shared_preferences` da saqlanadi).

Ovoz fayllari ham kod bilan yaratilgan — tayyor audio yuklanmagan.
`tool/make_audio.py` sodda to'lqinlardan (kvadrat, uchburchak, shovqin)
to'rtta effekt va takrorlanadigan 15 soniyalik kuy yig'adi, keyin ffmpeg
bilan OGG ga siqadi:

```bash
python3 tool/make_audio.py     # assets/audio/*.ogg qayta yaratiladi
```

Hammasi birga 191 KB. Effektlar faqat o'yinchining o'z hodisalarida
chalinadi (hudud egallash, raqibni yiqitish, o'lim) — 15 ta bot bir
vaqtda shovqin qilmaydi. Vibratsiya `HapticFeedback` orqali, qo'shimcha
kutubxonasiz. Musiqa `mixWithOthers` rejimida chalinadi, shuning uchun
telefonda boshqa musiqa ketayotgan bo'lsa to'xtab qolmaydi.

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

Kadr byudjeti 60 FPS da 16 600 µs. Oxirgi o'lchov (dunyo xaritasi,
15 ta bot, quruqlikning 39% i egallangan):

| Ish | Narxi |
| --- | --- |
| Mantiq (10 o'yinchi) | 6 µs/kadr |
| Keshlangan hududlarni chizish | 24 µs/kadr |
| Dunyo xaritasi (ko'rinadigan plitkalar) | 29 µs/kadr |
| Arena panjarasi (136 chiziq) | 21 µs/kadr |
| Mini-xarita (336 to'rtburchak) | 225 µs, sekundiga ~8 marta |
| Bitta hudud shaklini qayta yozish | 596 µs, kadrda ~0.01 marta |
| Xarita plitkalarini tayyorlash | 52 ms, o'yin boshida bir marta |

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
