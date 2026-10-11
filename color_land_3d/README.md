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
- **Uch xil o'yin**: botlar bilan (internetsiz), do'stlar bilan
  (bitta Wi-Fi tarmog'ida xona ochib) va internetda (o'z serveringiz
  orqali).
- **Onlayn reyting** — shahar, davlat, materik va dunyo bo'yicha.
  Server `server/leaderboard.py` da (faqat standart kutubxona).
- **Maydon o'yin boshlanishida tanlanadi** — sozlamalardan emas.
- **O'z rasmingiz** — avatar va hudud uchun telefondan rasm yuklash
  mumkin.
- **Sakkizta maydon**: dunyo xaritasi, oltita materik (Afrika, Osiyo,
  Yevropa, Shimoliy va Janubiy Amerika, Okeaniya) va erkin doira
  maydon. Sozlamalardan tanlanadi.
- **3D sahna**: maydon okeandan ko'tarilgan plato bo'lib quriladi
  (greedy meshing, dunyo uchun ~16 500 to'rtburchak), perspektiv
  kamera o'yinchini kuzatadi, yo'naltirilgan quyosh va soyalar.
- **Orollar ulangan**: juda kichik orollar olib tashlanadi, qolganlari
  esa eng qisqa suv oralig'i bo'ylab ko'prik bilan materikka ulanadi —
  xaritaning hamma yeriga yetib borish mumkin.
- **Qirg'oq zinapoyasiz**: arena geometriyasi generatorda hisoblanadi.
  Quruqlikning uzluksiz maydoni 0.5 sathida kesiladi (marching squares
  + chiziqli interpolatsiya), shuning uchun chegara katakka yopishmaydi
  va haqiqiy egri chiziq bo'ladi. O'yin faqat tayyor uchburchaklarni
  o'qiydi — dunyo arenasi 37 ms da quriladi.
- **Shaharlar**: Natural Earth 1:50m dan barcha davlat poytaxtlari va
  yirik shaharlar (dunyo xaritasida 1113 ta). Har shaharda nuqta,
  poytaxtlarda oltin ustun; nuqta ham, yozuv ham shahar aholisiga
  qarab kattalashadi. Nomi yoziladiganlar bir marta tanlanadi
  (muhimi oldin), shuning uchun ular o'yin davomida o'rin almashib
  miltillamaydi — uzoqdagisi asta so'nadi. Pastda: oraliq qanday
  tanlangan.
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
- **Sozlamalar**: rang, arena uslubi (6 ta), qiyinlik, til (15 ta),
  musiqa/ovoz/vibratsiya va ularning **balandligi**, **kuy tanlovi**
  (4 ta), poytaxt va naqsh kalitlari, kichik xarita, rekordni
  tozalash.
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
- **To'rtta kuy** — "Puls", "Neon", "Shiddat" va eski "Retro";
  pauzadan ham, sozlamalardan ham almashtiriladi va balandligi
  slayder bilan sozlanadi.
- **Belet va reklama** — o'limdan keyin davom etish, do'kon ekrani
  (`ContinueServices` — namuna; haqiqiy AdMob va Play Billing uchun
  shu fayl almashtiriladi).

- **iOS eksporti** — Xcode loyihasi to'liq yig'iladi (pastda).

Hali yo'q: haqiqiy AdMob/Play Billing plaginlari, maxsus eksport
shabloni bilan APK hajmini yanada kamaytirish, iOS uchun fotosurat
kutubxonasi plagini.

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

### Avtomatik o'ynab ko'rish

O'yinni haqiqiy sharoitda o'ynab chiqadigan uchta vosita bor.

```bash
# 30 ta o'yin: o'yinchini ham bot miyasi boshqaradi, har o'yindan
# keyin panjara va o'yinchilar holati tekshiriladi.
godot --headless --path . --script res://tools/playtest.gd -- 30 90

# Barcha ekranlar, maydonlar, uslublar va tillar ketma-ket ochiladi.
godot --path . --script res://tools/uitest.gd

# Maydon bo'yicha xotira va tugunlar soni.
godot --path . --script res://tools/memtest.gd

# Ovoz: avtobuslar, balandlik egri chizig'i, kuy almashtirish.
godot --headless --path . --script res://tools/audiotest.gd

# Kadr sakrashi: qaysi amal qancha vaqt oladi.
godot --headless --path . --script res://tools/spiketest.gd
```

`playtest.gd` quyidagilarni qidiradi: suvda yurib ketgan o'yinchi,
tiqilib qolgan o'yinchi, suvdagi hudud, o'lgan o'yinchining izi,
foizlar yig'indisining oshib ketishi, bo'sh hudud egallash va eng
sekin kadr. O'lim sabablari ham sanab beriladi.

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

### iOS (iPhone / iPad)

O'yin kodi platformaga bog'liq emas: hammasi GDScript va GDShader,
tashqi kutubxona yo'q. `iOS` preseti qo'shilgan va tekshirilgan —
Linux'da ham to'liq **Xcode loyihasi** yig'iladi:

```bash
godot --headless --path . --export-release "iOS" build/ios/ColorLand.ipa
```

Natija: `ColorLand.xcodeproj`, `ColorLand.xcframework`,
`MoltenVK.xcframework`, `ColorLand.pck`, `PrivacyInfo.xcprivacy` va
`Launch Screen.storyboard`. Godot ogohlantiradi:
*".ipa can only be built on macOS"* — ya'ni oxirgi qadam uchun
**Mac va Xcode** kerak.

Kerak bo'ladigan narsalar:

| Nima | Nega |
| --- | --- |
| Mac + Xcode | `.ipa` faqat macOS da yig'iladi |
| Apple Developer hisobi (yiliga $99) | App Store va TestFlight uchun |
| Team ID | `export_presets.cfg` dagi `application/app_store_team_id` — hozir bo'sh, usiz eksport boshlanmaydi |

Preset nima deydi: eng kam iOS 14.0, faqat tik (portrait) holat,
to'liq ekran, mahalliy tarmoq ruxsati (do'stlar bilan o'ynash uchun).

Nimalar o'z-o'zidan ishlaydi: Vulkan (MoltenVK orqali), ENet bilan
tarmoq o'yini, HTTP reyting, vibratsiya (`Input.vibrate_handheld`
iOS da ham bor), shriftlar va emoji.

Nimaga e'tibor kerak: **o'z rasmini yuklash**. iOS da Godot tizim
fayl oynasini bermaydi va ilova o'z "qumsaloni"dan tashqariga
chiqolmaydi, shuning uchun u yerda ilovaning hujjatlar papkasi
ochiladi (Files ilovasi orqali rasm tashlab qo'yish mumkin).
Haqiqiy fotosurat kutubxonasi uchun alohida iOS plagini kerak —
qolgan hamma narsa o'zgarishsiz ishlaydi.

## Xaritadagi shahar nomlari

Nomi yoziladigan shaharlar `render/capital_marks.gd` da bir marta,
xarita yuklanganda tanlanadi. Muhimi oldin (poytaxt + aholi), va
yozuvlari bir-birining ustiga tushmaydiganlar olinadi.

Avval bu tekshiruv **doira** edi: har nom atrofida 13 katak radius.
Doira eng uzun nomga moslab olingani uchun "Lima" ham "Ulaanbaatar"
ham bir xil joy egallardi, natijada ekranda atigi 5 ta nom qolardi.

Hozir **to'rtburchak**: yozuv gorizontal, shuning uchun kengligi nom
uzunligiga qarab o'sadi, balandligi esa deyarli o'zgarmaydi.

```
chetga chiqmaydi  <=>  |dx| < yarim_kenglik(a) + yarim_kenglik(b) + GAP_X
                  va   |dy| < GAP_Y
```

Oraliqlar `tools/nametest.gd` bilan sozlangan — u har xaritada
nechta shaharning nomi yozilishini va bitta ekranga nechtasi
tushishini sanaydi:

```bash
godot --headless --path . --script res://tools/nametest.gd
```

| Maydon | Shahar | Ilgari nomlanardi | Hozir | Bir ekranda ilgari / hozir |
| --- | --- | --- | --- | --- |
| world | 1113 | 143 (13%) | **485 (44%)** | 5.2 / **19.6** |
| asia | 430 | 89 (21%) | **249 (58%)** | 4.5 / **14.3** |
| africa | 223 | 72 (32%) | **169 (76%)** | 4.3 / **10.6** |
| north_america | 202 | 71 (35%) | **143 (71%)** | 4.1 / **9.0** |
| europe | 156 | 76 (49%) | **139 (89%)** | 3.9 / **8.1** |

Narxi: dunyo xaritasida +2.3 MB va +48 tugun (`memtest.gd`:
95.5 -> 97.8 MB).

Tugunlar havzasi (`POOL`) ko'rish doirasiga sig'adigan nomlardan
ko'p bo'lishi shart — aks holda eng chetdagi nom goh ko'rinib, goh
yo'qolib miltillaydi. `nametest.gd` shuni ham o'lchaydi: eng yomon
holatda 99, havza esa 150.

## Ovoz

```
assets/audio/
  music_pulse.ogg    "Puls"     112 BPM, 34 s   — standart
  music_neon.ogg     "Neon"      92 BPM, 42 s   — sokin
  music_sprint.ogg   "Shiddat"  140 BPM, 27 s   — tez
  music.ogg          "Retro"                    — eski chiptune
  capture/kill/death/tap.ogg                    — effektlar
```

Kuylar kod bilan yaratiladi:

```bash
python3 tool/make_music.py      # numpy va ffmpeg kerak
```

Sintez **additiv**: har bir nota garmonikalar yig'indisi, shuning
uchun "aliasing" shovqini yo'q. Baraban ham sintez qilinadi
(bochkaning chastotasi pasayadi, hi-hat — yorqin shovqin), ustiga
aks-sado va FFT-reverb qo'shiladi.

Ikkita narsa muhim bo'lib chiqdi:

1. **Master EQ.** Additiv sintezda butun quvvat bassda to'planadi
   (o'lchov: 20–120 Gc da 77%). Telefon karnayi 400 Gc dan pastini
   deyarli chiqarmaydi, shuning uchun kuy loyqa eshitilardi. EQ
   egri chizig'i gumburlashni kesadi va o'rta/yuqorini ko'taradi —
   endi taqsimot 40/27/24/4/5%.
2. **Limiter, `tanh` emas.** Avval cho'qqilar `tanh` bilan
   "yanchilgan" edi; bu garmonik buzilish beradi va OGG kodlagichi
   uni yomonlashtiradi (dekodlashda cho'qqi 0.62 dan 1.03 ga
   chiqib, kesilib ketardi). Hozir oldinga qarab ishlaydigan
   cheklovchi faqat baland joylarda kuchaytirishni silliq
   pasaytiradi — buzilish yo'q, cho'qqi 0.87–0.91.

Halqa uzluksiz: kuy bir marta chiziladi, reverb dumi boshiga
qo'shiladi. O'lchov — takrorlanish joyidagi eng katta sakrash
kuyning ichidagi oddiy sakrashdan katta emas.

Uchala kuy bir xil balandlikka (RMS) keltirilgan, shuning uchun
almashtirganda ovoz sakramaydi.

### Balandlik qanday boshqariladi

Ikki qatlam:

* har bir ovozning o'z `volume_db` si — miks (masalan o'lim tovushi
  "tap" dan 7 dB baland);
* `Music` va `Sfx` avtobuslari (`default_bus_layout.tres`) —
  o'yinchi sozlagan balandlik.

Shuning uchun slayderni surish miksni buzmaydi. Foiz dB ga
`pow(level, 1.7)` egri chizig'i bilan o'giriladi — slayder o'rtasida
ovoz quloqqa "yarmi" bo'lib eshitiladi; 0% da avtobus butunlay
o'chadi.

## Tuzilma

```
scripts/
  logic/        # dvigatelga bog'liq emas, testlardan o'tadi
    game_grid.gd         panjara, egalik, iz, quruqlik niqobi
    territory_capture.gd flood fill orqali hudud egallash
    game_world.gd        harakat, o'lim qoidalari, hodisalar
    bot_ai.gd            botlar xulq-atvori
    world_map.gd         maydon niqoblari va poytaxtlar
    match_builder.gd     o'yinchi + botlardan o'yin yig'ish
    avatar_placement.gd  hududdagi avatarning markazi va o'lchami
  render/       # 3D chizish
    arena_builder.gd     xaritadan plato meshi
    paint_layer.gd       egalik va rang teksturalari
    arena.gdshader       chegaralarni silliqlovchi shader
    avatar_atlas.gd      belgilar teksturasi va joylashuvi
    trail_ribbons.gd     izlar lentasi
    capital_marks.gd     poytaxt ustunlari (MultiMesh)
    palette.gd           ranglar va 6 arena uslubi
    game_view.gd         sahna, kamera, boshqaruv
  app/          # sozlamalar, matnlar, profil, ovoz, do'kon
  ui/           # ekranlar, komponentlar, avatar, kichik xarita
  net/          # tarmoq qatlami (uy egasi / mehmon)
server/         # reyting serveri (Python, standart kutubxona)
data/           # generatsiya qilingan (../color_land/tool/make_world_map.py)
tests/          # headless testlar
tools/          # skrinshot, sinov va o'lchov vositalari
tool/           # xarita, kuy va emoji shriftini generatsiya qilish
```

## Pul tizimi

Modullar `scripts/money/` da, o'yin mantig'idan butunlay alohida.
Har biri o'z ishini qiladi va o'z faylida saqlanadi.

| Modul | Avtoyuklash | Saqlanadi |
| --- | --- | --- |
| `monetization_config.gd` | — | hamma balans qiymati, bitta fayl |
| `analytics.gd` | `Metrics` | xotirada (tashqariga yuborilmaydi) |
| `currency_manager.gd` | `Wallet` | `user://wallet.cfg` |
| `reward_manager.gd` | — | holatsiz, faqat hisob |
| `shop_manager.gd` | `Shop` | `user://shop.cfg` |
| `daily_reward_manager.gd` | `Daily` | `user://daily.cfg` |
| `mission_manager.gd` | `Missions` | `user://missions.cfg` |
| `purchase_manager.gd` | `Purchases` | `user://purchases.cfg` |
| `ad_manager.gd` | `Ads` | holatsiz |
| `admob_manager.gd` | — | SDK bilan yagona aloqa nuqtasi |
| `logic/coin_field.gd` | — | xaritadagi tangalar (sof mantiq) |
| `render/city_coins.gd` | — | tangalarni chizadi |

**Bitta tuzoq.** Avtoyuklangan modullar bir-birini kompilyatsiya
paytida ko'rmaydi (`--script` rejimida global nom hali yo'q),
shuning uchun ular daraxtdan ish paytida olinadi:
`_wallet()`, `_metrics()`, `_purchases()`.

### Reklama qoidalari

Reklama SDK si bilan faqat `admob_manager.gd` gaplashadi; o'yin
kodi `AdManager` dan nariga o'tmaydi. Shuning uchun SDK
almashtirilsa bitta fayl o'zgaradi.

* mukofotli reklama **hech qachon o'z-o'zidan** chiqmaydi —
  o'yinchi tugmani bosishi shart;
* mukofot faqat video **to'liq ko'rilgani** tasdiqlangandan keyin
  beriladi; xato bo'lsa hech narsa olinmaydi va hech narsa
  yo'qolmaydi;
* majburiy reklama va banner hozir **o'chiq**
  (`INTERSTITIAL_ENABLED`, `BANNER_ENABLED`);
* NO ADS olinsa majburiy reklama va banner umuman yo'q, lekin
  mukofotli video qoladi — uni o'yinchi o'zi xohlaydi;
* ishlab chiqishda faqat Google ning **sinov** reklama ID lari;
  haqiqiylari `RELEASE_UNIT_IDS` ga do'konga chiqarishdan oldin
  yoziladi. Test buni tekshiradi.

### Kosmetika o'yinga ta'sir qilmaydi

Katalogdagi hech bir element tezlik, to'qnashuv o'lchami, hudud
egallash kuchi yoki botlarning xatti-harakatini o'zgartirmaydi —
sotiladigani faqat ko'rinish. Buni test ham tekshiradi: katalogda
`speed`, `power`, `size`, `damage`, `bonus` nomli maydon bo'lsa
test yiqiladi.

**Balans bitta faylda.** `MonetizationConfig` dagi qiymatlar
loyihaning boshqa joyida takrorlanmaydi — balansni o'zgartirish
uchun o'yin kodiga tegilmaydi.

**Hamyon himoyasi.** Balans manfiy bo'lmaydi, yuqori chegarasi bor,
har o'zgarish jurnalga yoziladi (id, vaqt, tur, miqdor), va bir
`transaction_id` ikki marta qabul qilinmaydi — kunlik mukofot yoki
reklama mukofoti takror berilmaydi. `user://wallet.cfg` —
sozlamalardan alohida fayl.

**Bir o'yindan qancha tushadi.** Vaqt 10–100, hudud 10–500,
raqiblar 25–150, yo'lda yig'ilgan tangalar. Jami 3000 bilan
cheklangan. Odatdagi o'yin 60–250 tanga beradi.

### Xaritadagi tangalar

Har shaharda bitta tanga: kattaligi ham, qiymati ham **aholi
soniga** qarab (kvadrat ildiz bilan — kichik shahar ham ko'rinadi).
Eng kichigi 1 tanga, eng kattasi 25.

Tanga o'yin qoidalariga tegmaydi: tezlik, to'qnashuv va hudud
egallash o'zgarmaydi — faqat mukofot qo'shiladi. Shuning uchun
yig'ish `game_view.gd` da, `game_world.gd` da emas.

Aylanish va tebranish **shaderda**: 1113 ta tanga bitta
`MultiMesh` va har kadrda hech narsa yangilanmaydi. Tanga
olinganda faqat o'sha nusxaning o'lchami nolga tushadi.

Tanga to'liq aylanmaydi, chayqaladi (±54°) — aks holda yarim
vaqt qirrasi bilan turib ko'rinmay qolardi. Metall emas: bu
sahnada aks etadigan muhit yo'q, metall qoralashib ketardi.

### Hali qilinmagan

`ShopManager`, `DailyRewardManager`, `MissionManager`,
`AdManager` / `AdMobManager`, `PurchaseManager` (NO ADS) va
analitika hali yo'q. Reklama bo'yicha hozirgi holat: majburiy
reklama ham, banner ham yo'q; bitta ixtiyoriy mukofotli reklama
`ContinueServices` namunasida turadi.

## Ko'rinish: "Neon Arcade"

Interfeysning butun ko'rinishi `scripts/ui/ui_kit.gd` da — bitta
faylda. O'yin qoidalari, ekranlar tuzilishi va maydon mantig'i
bunga bog'liq emas: hamma komponentning nomi va parametri
o'zgarmagani uchun ekranlar kodi umuman tegilmay yangi ko'rinishga
o'tdi.

| Nima | Qanday |
| --- | --- |
| Fon | To'q binafsha `#120726`, panellar `#241b52` |
| Urg'u | Limon `#d8ff3e`, malina `#ff3d9a`, ko'k `#2e9bff`, binafsha `#9b4be0`, sariq `#ffd23f` |
| Tugma | `StyleBoxFlat.skew = 0.23` — qiyshaygan to'rtburchak; matn qiyshaymaydi, chunki Godot uni stildan alohida chizadi |
| "Rels" | O'sha stilning soyasi: `shadow_offset = (0, 5)`, o'lchami nol — tugma ostida yorqin chiziq bo'lib ko'rinadi. Och rangli tugmada limon ko'rinmaydi, shuning uchun malina qo'yiladi |
| Sarlavha | Exo 2 qalin kursiv, katta harflar — `UiKit.title()` |
| Matn | Rubik Medium |

### 15 til

`data/strings.json` da 15 til × 177 kalit:

| | |
| --- | --- |
| Lotin | English · O'zbekcha · Türkçe · Español · Português · Français · Deutsch · Bahasa Indonesia |
| Kirill | Русский · Қазақша |
| Boshqa yozuvlar | 简体中文 · 日本語 · 한국어 · हिन्दी · العربية |

Yangi til qo'shish: `tool/add_languages.py` ga blok qo'shiladi,
o'yin kodiga tegilmaydi. Test hamma tilda kalitlar to'plami bir
xilligini tekshiradi.

Birinchi ochilishda qurilma tili aniqlanadi; ro'yxatda bo'lmasa
**inglizcha**. Tanlov `user://settings.cfg` ga saqlanadi.

Arabcha o'ngdan chapga yoziladi va harflar ulanadi — buni Godot
o'zi (HarfBuzz) qiladi, qo'shimcha kod kerak emas.

**Shahar nomlari** ham tarjima qilinadi: ma'lumot Natural Earth
ning o'zidan keladi (`NAME_RU`, `NAME_ZH`, ...). To'liq
`ne_50m_populated_places` faylida 12 til bor — o'zbekcha va
qozoqcha yo'q, ular inglizchada qoladi. `tool/make_maps.py` faqat
**inglizchadan farq qiladigan** nomlarni `data/city_names.json`
ga yozadi, shuning uchun fayl 235 KB.

Kosmetika nomlari (Classic, Neon, Prism...) ataylab tarjima
qilinmaydi — ular o'yin atamasi.

**Yo'l-yo'lakay topilgan xato:** o'yin ichida HUD qatoridagi
"kill" so'zi va tugmalardagi "ON"/"OFF" kodda qotib qolgan edi —
til almashsa ham inglizcha qolardi. Ikkalasi ham endi
tarjimadan keladi.

### Yozuvlar uchun shriftlar

Rubik va Exo 2 lotin bilan kirillni qoplaydi, arabcha DejaVuSans
da bor. Xitoy, yapon, koreys va hind yozuvlari uchun Noto
shriftlari **faqat ishlatiladigan belgilarga** qisqartirilgan:

| Shrift | To'liq | Qisqartirilgan |
| --- | --- | --- |
| Noto Sans SC | 10.3 MB | 62 KB |
| Noto Sans JP | 5.4 MB | 73 KB |
| Noto Sans KR | 5.9 MB | 34 KB |
| Noto Sans Devanagari | 214 KB | 125 KB |

Jami 294 KB. Yangi tarjima qo'shilsa shriftlarni qayta
qisqartirish kerak, aks holda yangi belgi chiqmaydi.

### Nega Exo 2 va Rubik

Dizayn namunasidagi Chakra Petch va Barlow **kirill harflarini
bilmaydi** — ruscha va qozoqcha matn zaxira shriftga tushib,
butunlay boshqacha ko'rinardi. Exo 2 va Rubik o'sha texno-kursiv
ko'rinishni beradi va kirillni ham qoplaydi. Topilmagan belgi
baribir DejaVuSans dan olinadi.

Bitta kamchilik: `_display_font` va `_bold_font` statik
o'zgaruvchilarda turadi, shuning uchun Godot chiqishda "2 resurs
hali ishlatilmoqda" deb ogohlantiradi. Bu faqat yopilish paytida
va faqat vositalarda ko'rinadi; shriftni statikdan olib tashlasa,
`fallbacks` ro'yxati yo'qolish xavfi bor.

### "Color Lands" arena uslubi

Oltinchi uslub qo'shildi va standart qilib qo'yildi: och muz rangli
maydon (`cfe6f7`), chuqur indigo okean, to'yingan hudud ranglari.
Qolgan beshtasi joyida — sozlamalardan tanlanadi.

Ochiq maydonda oq yozuv yo'qoladi, shuning uchun shahar nomlari,
nuqtalari va konturi uslubga bog'landi: `Palette.on_land()`,
`on_land_dim()`, `on_land_outline()`, `city_dot()`. Ochiq maydonda
to'q siyoh va qalin oq kontur (14px), to'q maydonda aksincha.

## Shriftlar

Interfeys Rubik bilan, sarlavhalar Exo 2 bilan chiziladi; emoji va
bayroqlar esa NotoColorEmoji bilan. Ikkalasi ham kirillni biladi,
qolgan belgilar DejaVuSans dan olinadi.

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

## Hudud egallash qanday hisoblanadi

Iz yopilgach, uning **qo'shni kataklaridan** to'ldirish boshlanadi.
To'ldirish o'yinchining to'rtburchagi chetiga chiqib ketsa — demak bu
tashqari, darhol to'xtatiladi; chetga chiqmay tugasa — demak o'ralgan
joy va u o'yinchiga o'tadi.

Shuning uchun narx **egallangan maydonga** bog'liq, hududning
kattaligiga emas. Ilgari har safar butun to'rtburchak uch marta
aylanib chiqilardi va katta hududda bir nechta katak olish ham 15
millisekund olardi — kadr tushib ketardi. O'lchov (`tools/spiketest.gd`,
uch marta besh daqiqalik o'yin, 54 000 kadr):

| | Ilgari | Hozir |
| --- | --- | --- |
| Eng sekin kadr | 15.4 ms | **5.4 ms** |
| 3 ms dan oshgan kadrlar | 638 | **8** |
| 8192 kataklik to'rtburchak | 8.3 ms | **0.73 ms** |

Bitta farq bor: ilgari hududingiz ichida qolgan har qanday bo'sh joy
keyingi istalgan halqada o'z-o'zidan qo'shilib ketardi. Endi uni
egallash uchun atrofidan aylanib chiqish kerak.

## O'z izi haqidagi qoida

O'z izini **kesib** o'tgan o'yinchi o'ladi, lekin iz bo'ylab **ortga
qaytish** o'lim emas. Ingichka bo'g'ozga yoki kichik orolga kirib
qolgan o'yinchi boshqa yo'ldan chiqolmaydi — qaytishda u izning
ketma-ket kataklariga tegadi, shuning uchun har tegish oldingisining
qo'shnisi bo'lsa, bu qaytish deb hisoblanadi. Haqiqiy kesishda izga
butunlay boshqa joydan kiriladi va qoida ishlaydi.

Qirg'oqning ichki burchagida ikkala o'q ham to'silsa, o'yinchi to'xtab
qolmaydi: yo'nalishiga eng yaqin bo'sh tomon qidirilib, qirg'oq bo'ylab
sirpanadi.

## Uch xil o'yin

| Rejim | Nima kerak | Qanday ishlaydi |
| --- | --- | --- |
| Botlar bilan | hech narsa | Hammasi telefonda hisoblanadi |
| Do'stlar bilan | bitta Wi-Fi | Biri xona ochadi, qolganlari manzilni kiritib qo'shiladi |
| Internetda | o'z serveringiz | Server manzili sozlamalarda yoziladi |

Tarmoq modeli oddiy: **uy egasi** butun o'yinni hisoblaydi (botlar
ham), mehmonlar faqat yo'nalishini yuboradi va tayyor holatni oladi.
Pozitsiyalar sekundiga 15 marta ishonchsiz kanalda, o'zgargan kataklar
esa ishonchli kanalda bo'lib yuboriladi; yangi qo'shilganga butun
panjara bir marta siqib yuboriladi.

### Doimiy server (VPS uchun)

Linux eksporti xuddi shu o'yin, lekin `--server` bilan interfeyssiz
xona bo'lib ishlaydi:

```bash
godot --headless --path . --export-release "Linux" colorland.x86_64
./colorland.x86_64 --server --headless --port 7777
```

Keyin o'yinchilar "Internetda" bo'limiga serveringiz IP sini yozadi.
7777 porti ochiq bo'lishi kerak (UDP).

## Onlayn reyting

Natija har o'yindan keyin serverga yuboriladi; ro'yxat shahar, davlat,
materik va dunyo kesimida ko'rsatiladi. Server manzili sozlamalarda
("Reyting serveri"), shahar esa profilda yoziladi.

```bash
python3 server/leaderboard.py --port 8080 --db colorland.db
```

Namuna server SQLite ga yozadi va hisob (akkaunt) talab qilmaydi —
haqiqiy chiqarishda oldiga HTTPS proksi qo'yish kerak. API:

```
POST /score  {name, country, city, continent, percent, kills}
GET  /top?scope=world|continent|country|city&key=<qiymat>
```

## Ma'lumot manbai

Maydonlar — [Natural Earth](https://www.naturalearthdata.com/) 1:110m
(public domain). Generator shu loyihada:

```bash
pip install  # kerak emas, faqat standart kutubxona
python3 tool/make_maps.py
```

Har maydon uchun `data/maps/<id>.bin` yoziladi (siqilgan): mantiq
niqobi va tayyor arena geometriyasi — ustki yuza uchburchaklari hamda
devor kesmalari, 1/64 katak aniqligida. Shaharlar
`data/maps/index.json` da. Jami 428 KB.

Flutter (2D) varianti hamon `../color_land/tool/make_world_map.py` dan
foydalanadi — u tegilmagan.

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
