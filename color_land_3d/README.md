# Color Land 3D (Godot)

Hudud egallash arcade o'yinining **haqiqiy 3D** varianti: Godot 4.5,
GDScript, mobil (Vulkan) chizuvchi.

Flutter'dagi 2D variant `../color_land/` da turibdi va tegilmagan —
3D variant tayyor bo'lgunicha u ishlaydigan o'yin bo'lib qoladi.

## Hozirgi holat (1-bosqich)

Tayyor:

- **Mantiq qatlami to'liq ko'chirildi** — panjara, hudud egallash
  (flood fill), harakat, iz, o'lim qoidalari, dunyo xaritasi, suv
  qoidalari, botlar. Dvigatelga bog'liq emas va headless testlardan
  o'tadi (42 ta tekshiruv).
- **3D sahna**: dunyo xaritasi okeandan ko'tarilgan plato bo'lib
  quriladi (greedy meshing, ~7800 to'rtburchak), perspektiv kamera
  o'yinchini kuzatadi, yo'naltirilgan quyosh va soyalar.
- **Hududlar va izlar** — arena ustidagi tekstura (har katak bir
  piksel). Minglab katak o'zgarsa ham geometriya qayta qurilmaydi,
  faqat o'zgargan piksellar yangilanadi.
- Barmoq bilan boshqarish, eng sodda HUD.
- Android APK quriladi (arm64-v8a).

Hali yo'q (keyingi bosqichlar): menyu, sozlamalar, profil va avatarlar,
ovoz va musiqa, 5 til, do'kon va beletlar, natija oynasi, poytaxt
belgilari, APK hajmini kamaytirish.

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

**Diqqat:** hozirgi APK ~73 MB. Bu Godot'ning standart kutubxonasi
(`libgodot_android.so` 70 MB) hisobiga — keyingi bosqichda keraksiz
modullarni o'chirgan maxsus shablon bilan kamaytiriladi.

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
  render/       # 3D chizish
    arena_builder.gd     xaritadan plato meshi
    paint_layer.gd       egalik teksturasi
    game_view.gd         sahna, kamera, boshqaruv
data/           # generatsiya qilingan (../color_land/tool/make_world_map.py)
tests/          # headless testlar
tools/          # skrinshot vositasi
```

## Ma'lumot manbai

Dunyo xaritasi va poytaxtlar — [Natural Earth](https://www.naturalearthdata.com/)
1:110m (public domain). Generator Flutter loyihasida:

```bash
python3 ../color_land/tool/make_world_map.py 520 205
```

U bir vaqtning o'zida ikkala variant uchun ham ma'lumot yozadi.

## GDScript'dagi tuzoq

`TerritoryCapturer` da lambda ishlatilmaydi. GDScript lambdasi tashqi
o'zgaruvchini **nusxa** qilib oladi, shuning uchun ichida o'zgartirilgan
hisoblagich tashqarida eski holicha qolardi — Dart'dan to'g'ridan-to'g'ri
ko'chirilganda flood fill jim turib buzilgan edi; test ushlab qoldi.
