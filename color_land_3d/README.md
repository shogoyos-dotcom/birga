# Color Land 3D (Godot)

Hudud egallash arcade o'yinining **haqiqiy 3D** varianti: Godot 4.5,
GDScript, mobil (Vulkan) chizuvchi.

Flutter'dagi 2D variant `../color_land/` da turibdi va tegilmagan —
3D variant tayyor bo'lgunicha u ishlaydigan o'yin bo'lib qoladi.

## Hozirgi holat

Flutter variantidagi barcha funksiyalar ko'chirildi.

Tayyor:

- **Mantiq qatlami to'liq ko'chirildi** — panjara, hudud egallash
  (flood fill), harakat, iz, o'lim qoidalari, dunyo xaritasi, suv
  qoidalari, botlar. Dvigatelga bog'liq emas va headless testlardan
  o'tadi (94 ta tekshiruv).
- **3D sahna**: dunyo xaritasi okeandan ko'tarilgan plato bo'lib
  quriladi (greedy meshing, ~7800 to'rtburchak), perspektiv kamera
  o'yinchini kuzatadi, yo'naltirilgan quyosh va soyalar.
- **Hududlar va izlar** — arena ustidagi tekstura (har katak bir
  piksel). Minglab katak o'zgarsa ham geometriya qayta qurilmaydi,
  faqat o'zgargan piksellar yangilanadi. Chegaralar **shaderda**
  silliqlanadi (`render/arena.gdshader`): hudud egasi 4x4 katak
  bo'yicha kubik og'irlik bilan tanlanadi, shuning uchun chegara
  zinapoya emas, silliq egri chiziq bo'lib chiqadi.
- **Iz** — kataklardan emas, o'yinchining uzluksiz yo'lidan quriladigan
  lenta (`render/trail_ribbons.gd`). Kataklardan chizilgan chiziq
  silliqlangandan keyin ham to'lqinli ko'rinardi; yo'l esa mantiq
  qatlamida soddalashtirib boriladi, shuning uchun to'g'ri borgan
  joyda chiziq ham to'liq tekis.
- Barmoq bilan boshqarish, HUD (foiz, vaqt, o'ldirishlar, o'rin).
- To'liq o'yin tsikli: boshlash ekrani -> o'yin -> natija -> qayta
  o'ynash.
- Android APK quriladi (arm64-v8a) va ishga tushishi tekshirilgan.
- **Menyu, sozlamalar, profil, pauza, natija va do'kon** ekranlari —
  "Arcade Grid" uslubida, kod bilan quriladi.
- **Sozlamalar**: rang, arena uslubi (5 ta), qiyinlik, til (5 ta),
  musiqa/ovoz/vibratsiya, poytaxt va naqsh kalitlari, kichik xarita,
  rekordni tozalash.
- **Profil**: taxallus, 40 emoji, 12 odam tasviri va **249 davlat
  bayrog'i** (qidiruv bilan).
- **Hududda bayroq** — o'yinchi tanlagan davlat bayrog'i uning butun
  hududini egallaydi. Bayroq arena shaderida chiziladi va hudud
  shakliga aniq kesiladi (`AvatarPlacement` + `render/avatar_atlas.gd`).
- **Bosh** — o'yinchi rangidagi shar; ustida uning avatari (emoji yoki
  odam tasviri) turadi.
- **Poytaxtlar** — xaritadagi 236 poytaxt arena ustida ustun bo'lib
  turadi (bitta `MultiMesh`).
- **Kichik xarita** — egalik teksturasining o'zi kichraytirib
  ko'rsatiladi, qo'shimcha hisob yo'q.
- **Top-5 reyting**, hudud olinganda va o'limda chaqnash, ovoz va
  musiqa, vibratsiya.
- **Belet va reklama** — o'limdan keyin davom etish, do'kon ekrani
  (`ContinueServices` — namuna; haqiqiy AdMob va Play Billing uchun
  shu fayl almashtiriladi).

Hali yo'q: haqiqiy AdMob/Play Billing plaginlari, maxsus eksport
shabloni bilan APK hajmini yanada kamaytirish.

## Ishga tushirish

Godot 4.5.1 kerak. Loyihani ochib `scenes/main.tscn` ni ishga tushiring,
yoki buyruq satridan:

```bash
godot --path .
```

### Testlar (headless)

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Mantiq qatlami Godot tugunlariga bog'liq emas, shuning uchun testlar
sahna ochmasdan, bir soniyada o'tadi.

### Skrinshot (displaysiz konteynerda)

Konteynerda Vulkan yo'q, shuning uchun moslashuvchan chizuvchi bilan:

```bash
xvfb-run -a godot --path . \
  --rendering-driver opengl3 --rendering-method gl_compatibility \
  --resolution 720x1280 --fixed-fps 60 \
  --script res://tools/screenshot.gd -- 50 res://build/shot_3d.png
```

### Android APK

```bash
# Bir marta: qurish shablonini ochish
godot --headless --path . --install-android-build-template

# Keyin
godot --headless --path . --export-release "Android" build/ColorLand3D.apk
```

Kerak: Android SDK (build-tools, platform-tools), JDK 17+, Godot eksport
shablonlari va imzo kaliti. Yo'llar `export_presets.cfg` va Godot
muharrir sozlamalarida ko'rsatiladi.

Ikkita preset bor:

| Preset | Hajm | Izoh |
| --- | --- | --- |
| `Android` | 75 MB | Kutubxona siqilmagan — eng ishonchli variant |
| `Android (siqilgan)` | 27 MB | Kutubxona APK ichida siqilgan; ishga tushish bir oz sekinroq |

Hajmning asosiy qismi — Godot dvigatelining o'zi
(`libgodot_android.so`, 70 MB, allaqachon stripped). Undan kichraytirish
uchun keraksiz modullarni o'chirib maxsus eksport shabloni
kompilyatsiya qilish kerak.

## Tuzilma

```
scripts/
  logic/        # dvigatelga bog'liq emas, testlardan o'tadi
    game_grid.gd         panjara, egalik, iz, quruqlik niqobi
    territory_capture.gd flood fill orqali hudud egallash
    game_world.gd        harakat, o'lim qoidalari, hodisalar
    bot_ai.gd            botlar xulq-atvori
    world_map.gd         dunyo niqobi va poytaxtlar
    match_builder.gd     o'yinchi + botlardan o'yin yig'ish
    avatar_placement.gd  hududdagi avatarning markazi va o'lchami
  render/       # 3D chizish
    arena_builder.gd     xaritadan plato meshi
    paint_layer.gd       egalik va rang teksturalari
    arena.gdshader       chegaralarni silliqlovchi shader
    avatar_atlas.gd      belgilar teksturasi va joylashuvi
    trail_ribbons.gd     izlar lentasi
    capital_marks.gd     poytaxt ustunlari (MultiMesh)
    palette.gd           ranglar va 5 arena uslubi
    game_view.gd         sahna, kamera, boshqaruv
  app/          # sozlamalar, matnlar, profil, ovoz, do'kon
  ui/           # ekranlar, komponentlar, avatar, kichik xarita
data/           # generatsiya qilingan (../color_land/tool/make_world_map.py)
tests/          # headless testlar
tools/          # skrinshot vositasi
tool/           # emoji shriftini qisqartirish
```

## Shriftlar

Interfeys DejaVuSans bilan chiziladi, emoji va bayroqlar esa
NotoColorEmoji bilan.

Ikki tuzoq bor:

1. **Emoji shrifti zaxira (`fallbacks`) sifatida ishlatilsa bayroqlar
   buziladi.** Bayroq ikki "regional indicator" belgisining
   ligaturasi; zaxiraga har belgi alohida tushadi va ligatura hosil
   bo'lmay, qutichali harflar chiqadi. Shuning uchun faqat emoji
   yoziladigan joylarda (avatar, hudud naqshi) emoji shrifti
   **bevosita** qo'yiladi — `UiKit.emoji_font()`.
2. **To'liq NotoColorEmoji 10.8 MB.** O'yin atigi 80 ta belgini
   ishlatadi, shuning uchun shrift qisqartirilgan (1.0 MB):

   ```bash
   pip install fonttools
   python3 tool/subset_emoji_font.py
   ```

   Skript kerakli belgilarni `scripts/app/profile.gd` dan o'qiydi va
   `ccmp` jadvalini saqlaydi (bayroq ligaturalari shu yerda).

## Ma'lumot manbai

Dunyo xaritasi va poytaxtlar — [Natural Earth](https://www.naturalearthdata.com/)
1:110m (public domain). Generator Flutter loyihasida:

```bash
python3 ../color_land/tool/make_world_map.py 520 205
```

U bir vaqtning o'zida ikkala variant uchun ham ma'lumot yozadi.

## Eksport tuzoqlari (qimmatga tushgan)

Bu uchtasi tufayli birinchi APK umuman ishga tushmagan edi. Hammasi
**faqat eksport qilingan qurilmada** chiqadi — muharrirdan ishga
tushirilganda o'yin bemalol ishlaydi.

1. **`.bin` fayli eksportga kirmaydi.** `export_filter="all_resources"`
   faqat Godot taniydigan resurslarni oladi; `world_land.bin` tushib
   qolgan. `include_filter="*.bin, *.json"` kerak.
2. **`assert()` release qurilishida o'chiriladi.** Fayl topilmaganini
   `assert` bilan tekshirish kifoya emas edi: release'da u yo'qoladi va
   keyingi qator `null` ga murojaat qilib segfault beradi. Endi haqiqiy
   `push_error` va zaxira yo'l bor.
3. **Eksportdan chiqarilgan skript global sinf bo'lmasin.** `tests/`
   papkasi eksportga kirmaydi, lekin `class_name` tufayli sinflar
   ro'yxatida qolgan edi — o'yin ishga tushganda yo'q faylni qidiradi.

Shuning uchun har o'zgarishdan keyin eksport **Linux varianti sifatida
qurilib, ishga tushirib ko'riladi** — Android'ga bormasdan ham xuddi
shu xatolar chiqadi:

```bash
godot --headless --path . --export-release "Linux" build/colorland.x86_64
xvfb-run -a build/colorland.x86_64 --audio-driver Dummy \
  --rendering-driver opengl3 --rendering-method gl_compatibility \
  --quit-after 400
```

## GDScript'dagi tuzoq

`TerritoryCapturer` da lambda ishlatilmaydi. GDScript lambdasi tashqi
o'zgaruvchini **nusxa** qilib oladi, shuning uchun ichida o'zgartirilgan
hisoblagich tashqarida eski holicha qolardi — Dart'dan to'g'ridan-to'g'ri
ko'chirilganda flood fill jim turib buzilgan edi; test ushlab qoldi.
