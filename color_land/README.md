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
flutter test             # 39 ta test
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
      match.dart              o'yinchi + botlardan o'yin yig'ish
    render/       # Flame komponentlari, keshlangan chizish
      grid_renderer.dart      chunk'larga bo'lingan ui.Picture keshi
      color_land_game.dart    kamera, animatsiyalar, HUD manbasi
  i18n/           # 5 til: uz, en, ru, tr, kk
  storage/        # shared_preferences (rekord, rang, qiyinlik, til)
  ui/             # menyu, o'yin ekrani, HUD, natija oynasi
test/             # flood fill, o'lim qoidalari, bot AI, rendering, tezlik
tool/             # skrinshot va ikonka generatorlari (test sifatida ishlaydi)
```

Mantiq rendering'dan to'liq ajratilgan: `lib/game/logic/` ichidagi hech bir
fayl Flutter yoki Flame'ni import qilmaydi.

## Tezlik

`flutter test test/performance_test.dart` o'lchaydi va chegaralarni
tekshiradi. Asosiy yechim — panjara 16×16 katakli "chunk"larga bo'lingan,
har biri `ui.Picture` sifatida keshlanadi va faqat o'zgargani qayta
yoziladi; bir kadrda qayta yoziladigan chunklar soni ham cheklangan.

## Yordamchi vositalar

```bash
flutter test tool/icon_test.dart        # ikonkalar + Play materiallari
flutter test tool/screenshot_test.dart  # build/shot_*.png skrinshotlar
```

## Google Play

`RELEASE.md` ga qarang — keystore yaratishdan `.aab` yuklashgacha.
