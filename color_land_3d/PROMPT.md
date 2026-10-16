# Color Land — loyihani davom ettirish uchun prompt

> Bu faylni yangi suhbatga to'liq nusxalab tashlang. Unda loyihaning
> nimaligi, qanday qurilgani, qaysi qoidalar o'rnatilgani va nima
> qilinib bo'lgani yozilgan.

---

## 1. Vazifa

Sen Godot 4.5.1 da yozilgan **Color Land** o'yinini davom ettirasan.
Bu Paper.io 2 uslubidagi hudud egallash o'yini, Android/Google Play
uchun.

**Qat'iy qoidalar:**

1. **Barcha kod izohlari, commit xabarlari va menga javoblaring
   o'zbek tilida.** Kod identifikatorlari (o'zgaruvchi, funksiya
   nomlari) inglizcha qoladi.
2. **Hamma personaj, ikonka, logotip va nom ORIGINAL bo'lsin.**
   Boshqa o'yinning rasmlari, belgilari yoki matnlarini nusxalama.
   Emoji ham ishlatilmaydi — belgilar kod bilan chiziladi
   (`scripts/ui/game_icon.gd`).
3. **Hech narsani taxmin qilma — o'lchab ko'rsat.** Har o'zgarishdan
   keyin testlar va 30 o'yinli sinov ishga tushiriladi, natija
   solishtiriladi.
4. **Kuchaytirgichlar faqat tanga bilan oshiriladi, kristall bilan
   emas** — "to'lab yutish" bo'lmasligi kerak.
5. Ish tarmog'i: `claude/dazzling-turing-2248jt`
   (`shogoyos-dotcom/birga`). Boshqa tarmoqqa push qilma.

---

## 2. Loyiha tuzilishi

```
birga/
  color_land_3d/     ← ishlaydigan loyiha (Godot 4.5.1)
  color_land/        ← eski Flutter 2D varianti, TEGILMAYDI
```

`color_land_3d/` ichi:

| papka | nima |
|---|---|
| `scripts/logic/` | **sof mantiq** — Godot tugunlariga bog'liq emas |
| `scripts/render/` | 3D chizish: arena, iz, tanga, effektlar |
| `scripts/ui/` | interfeys (kod bilan quriladi, sahna fayli yo'q) |
| `scripts/money/` | hamyon, do'kon, topshiriq, reklama, xarid |
| `scripts/app/` | sozlama, profil, matn, ovoz, reyting |
| `scripts/net/` | tarmoq o'yini (ENet) |
| `tests/` | headless testlar — **712 ta tekshiruv** |
| `tools/` | o'ynab ko'radigan vositalar (pastda) |
| `tool/` | Python generatorlari (xarita, matn, musiqa) |
| `data/` | xaritalar, matnlar (15 til), mamlakat shakllari |

Jami ~10 400 qator GDScript.

**Eng muhim me'moriy qoida:** o'yin mantig'i (`scripts/logic/`)
Godot tugunlariga bog'lanmaydi. Shuning uchun testlar sahna
ochmasdan, bir soniyada o'tadi va mantiqni chizishdan ajratib
tekshirish mumkin.

---

## 3. Avtoyuklanadigan modullar (`project.godot`)

```
Audio, Net, Board,
Metrics (analitika), Wallet (hamyon), Purchases, Shop,
Daily, Missions, Ads, Upgrades (kuchaytirgichlar),
Journey (mamlakatlar yo'li)
```

**Muhim tuzoq:** avtoyuklangan modullar bir-birini kompilyatsiya
paytida ko'rmaydi. `--script` rejimida ham global bo'lmaydi.
Shuning uchun ularga daraxtdan murojaat qilinadi:
`get_node_or_null("/root/Wallet")`.

---

## 4. Tekshirish vositalari

```bash
cd color_land_3d

# Testlar (712 ta tekshiruv, ~1 soniya)
godot --headless --path . --script res://tests/run_tests.gd

# 30 ta o'yin: o'yinchini ham bot miyasi boshqaradi
godot --headless --path . --script res://tools/playtest.gd -- 30 90

# Yo'ldagi tanga va sferalar: terilishi, qaytishi, tezlik, qalqon
godot --headless --path . --script res://tools/pickuptest.gd

# Pauza: dunyo to'xtaydimi, tanga joyida qoladimi
godot --headless --path . --script res://tools/pausetest.gd

# Shahar tangasi: olinadi, yo'qoladi, 30 soniyada qaytadi
godot --headless --path . --script res://tools/cointest.gd

# Barcha ekranlar, maydonlar, uslublar va 15 til ketma-ket ochiladi
xvfb-run -a godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility \
  --script res://tools/uitest.gd

# Skrinshot (konteynerda Vulkan yo'q)
xvfb-run -a godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --resolution 720x1280 \
  --fixed-fps 60 --script res://tools/screenshot.gd \
  -- 5 res://build/shot.png menu

# APK (30 MB)
godot --headless --path . --export-release "Android (siqilgan)" \
  build/ColorLand3D.apk
```

Boshqalar: `edgetest.gd` (chegara silliqligi + shader narxi),
`memtest.gd`, `audiotest.gd`, `spiketest.gd`, `fpstest.gd`.

**O'zgarmasligi kerak bo'lgan son:** 30 o'yinli sinov har safar
aynan shuni berishi shart —

```
o'rtacha: egallangan yer 32.3%, yetakchi 3.68%
o'lim sabablari: raqib kesdi 344 (83%), o'zini kesdi 71 (17%)
```

Agar bu son o'zgarsa — demak o'yin muvozanatiga tegib ketgansan.

---

## 5. Qilingan ishlar

### Boshlang'ich (1-bosqichgacha)

* Flutter 2D dan Godot 4.5.1 ga ko'chirish: dunyo xaritasi,
  6 ta qit'a maydoni, botlar, hudud egallash, iz kesish.
* Xaritalar Natural Earth 1:110m dan `tool/make_maps.py` bilan
  (public domain). `data/maps/*.bin` — jami 428 KB.
* 15 til, 214 kalit (`data/strings.json`).
* Pul tizimi: hamyon, do'kon (skin/iz/effekt/nishon), kunlik
  mukofot, topshiriqlar, reklama va xarid modullari.
* **Tuzatilgan xatolar:** do'kondagi narsalar ko'rinmasdi; pauza
  dunyoni to'xtatmasdi va tangalarni nolga tushirardi; qirg'oqdagi
  iz zinapoya bo'lib ko'rinardi.

### 1-bosqich — interfeys uslubi

* `scripts/ui/ui_kit.gd` butunlay qayta yozildi (552 qator) —
  butun o'yinning yagona uslub manbai. Ko'k gradient fon, oq
  matn + to'q ko'k kontur, poydevorli ("3D") tugmalar.
* `scripts/ui/game_icon.gd` — **kod bilan chiziladigan belgilar**,
  emoji o'rniga: tanga, bosh suyagi, kristall, yulduz, toj, chipta,
  chaqmoq, magnit, xalta, qalqon, soat, tishli g'ildirak, kubok,
  odam, reklamasiz.
* HUD qayta chizildi: to'lish chizig'i, kapsulalar, top-3 reyting
  va o'yinchining o'z qatori, minikarta (chap/o'ng/o'chiq).
* Shrift: Nunito ExtraBold (kirillcha bor; Lilita One va Fredoka
  da yo'q — tekshirib ko'rilgan).

### 2-bosqich — hudud va iz grafikasi

* Arena ustki yuzasi `render_mode unshaded` — och uslublar
  quyosh ostida oqarib ketardi.
* Tuman (`fog`) o'chirildi — hudud ranglari xira chiqardi
  (kutilgan `(222,53,100)` o'rniga `(237,155,181)`).
* Skin hududni bo'yaydi: 8 ta protsessual naqsh (urug', sepma,
  yoriq, cho'g', yulduz, barg, halqa), 768 ta kalitli palitra
  teksturasi. **Naqsh raqami alfa kanalda** — rang kanallari
  sRGB dan chiziqliga o'girilganda butun son omon qolmaydi.
* 5 ta yangi skin: Melon, Citrus, Donut, Forest, Galaxy.
* Iz oq chetli bo'ldi; yetakchining boshida toj.
* Hudud chegarasi: 6×6 kubik B-splayn "ovoz berish" shaderda.

### 3-bosqich — tangalar, kuchaytirgichlar, natija ekrani

**Ikki xil tanga** (ataylab boshqa-boshqa):

| | shahar tangasi | yo'ldagi tanga |
|---|---|---|
| modul | `logic/coin_field.gd` | `logic/pickup_field.gd` |
| olinishi | **hudud egallaganda** | **ustidan yurganda** |
| qaytishi | 30 soniya, o'sha joyda | 12 soniya, boshqa joyda |

* Sferalar: moviy — qalqon (bitta urilishni yutadi, iz
  tozalanadi, o'yinchi tirik qoladi), yashil — tezlik (4 soniya).
  Qalqon hududni yo'qotishdan asramaydi.
* `money/upgrade_manager.gd` — uchta kuchaytirgich, 5 darajali,
  narx 50 dan 1.8 barobar oshib boradi (50, 90, 162, 292, 525):
  Shiddat (tezlik ×1.35), Magnit (radius 1.1 → 3.85 katak),
  Qo'shimcha tanga (15×daraja).
* Natija ekrani: rekord lentasi, noldan o'sadigan chiziq, uchta
  katak, tanga qayerdan kelgani yozilgan karta.
* **Topilgan xato:** tez kadrda o'yinchi tanganing ustidan sakrab
  o'tib ketardi. Yig'ish endi **o'tilgan kesma** bo'ylab
  (`PickupField.take_along`).

### 4-bosqich — bosh menyu va mamlakatlar yo'li

* `tool/make_country_shapes.py` — 28 ta mamlakatning
  soddalashtirilgan konturi (Duglas-Pyoker, halqada 44 nuqtagacha),
  0..1 kvadratida. `data/country_shapes.json` — 21 KB.
* `logic/country_path.gd` + `app/country_store.gd` (`Journey`):
  birinchi mamlakat **O'zbekiston**, keyin qo'shnilar, so'ng dunyo.
  Nishon 120 dan boshlanib har safar 70 ga oshadi. Bir o'yin:
  1% maydon = 10 ochko, bitta o'ldirish = 5, eng kami 5.
  Ortgan ochko yo'qolmaydi.
* `ui/country_view.gd` — shakl pastdan yuqoriga to'ladi
  (`Geometry2D.intersect_polygons` bilan kesiladi).
* Bosh menyu qayta chizildi: yuqorida avatar/tanga/kristall/
  reklamasiz/sozlama, markazda mamlakat kartasi, pastda katta
  sariq dumaloq tugma, eng pastda to'rtta bo'lim tugmasi.
* Yangi **"Jihozlar"** ekrani (`Screen.GEAR`): kuchaytirgichlar,
  kiyilgan ko'rinish, rekord — avval bularning hammasi menyuda
  turardi va menyu juda uzun edi.
* Natija ekranida mamlakat shakli eski darajadan yangisiga
  to'lib boradi.

---

## 6. Godot tuzoqlari (bu loyihada yo'l-yo'lakay topilgan)

* Yangi `class_name` qo'shsang, avval
  `godot --headless --path . --editor --quit` ishga tushir —
  aks holda "Identifier not declared" chiqadi.
* `PanelContainer` bolasining anchor'larini **e'tiborsiz
  qoldiradi**. Anchor kerak bo'lsa oddiy `Control` + `Panel`.
* `MultiMeshInstance3D` da `_set(...)` deb metod yozma —
  `Object._set` bilan to'qnashadi.
* `GPUParticles3D` moslashuvchan (OpenGL) chizuvchida hech narsa
  chizmaydi — `CPUParticles3D` ishlatiladi.
* Headless rejimda `RenderingServer` soxta: `MultiMesh` nusxa
  matritsalarini saqlamaydi, o'qiganda birlik matritsa qaytaradi.
  Chizishni faqat skrinshot bilan tekshirib bo'ladi.
* `Tween` ni ekran tugunida emas, **animatsiya qilinadigan
  tugunning o'zida** yarat (`fill.create_tween()`) — aks holda
  ekran yopilgandan keyin ham ishlab, bo'shatilgan tugunga
  murojaat qiladi.
* `Image`/`Color` da alfa sRGB o'girishdan omon chiqadi, RGB —
  yo'q. Butun sonni alfada tashi.
* Och fondagi matn `UiKit.INK` (to'q ko'k) bo'lsin;
  `TEXT_DIM`/`TEXT_FAINT` faqat to'q fon uchun.

---

## 7. Ochiq masala

**Maydonda kulrang diagonal yo'l.** Maydon bo'ylab yumshoq
kulrang chiziq o'tadi. O'lchab aniqlangani: u arena ustki
shaderidan keladi (`ALBEDO` ni majburan qizil qilsang yo'qoladi),
rangi quruqlik rangining aynan 0.67 barobari. Tuman, soyalar,
okean to'ri, devor materiali va avatar qatlami birma-bir
o'chirib ko'rilgan — hech biri sabab emas. 2-bosqichdan oldin
ham bor edi. README dagi "Ochiq masala" bo'limida yozilgan.

---

## 8. Qolgan bosqichlar

**5-bosqich — qahramonlar va profil**
* Qahramonlar (personajlar) va ularni ochadigan topshiriqlar.
* Profil: ligalar, statistika.
* Sozlamalar ekrani va lokalizatsiyani yakunlash.

**6-bosqich — reklama va xaridlar**
* AdMob: banner, oraliq reklama, mukofotli video.
* Google Play xaridlari: "reklamasiz", tanga to'plamlari.

**Mendan kutilayotgani (hali yo'q):**
* Onlayn o'yin va reyting uchun VPS.
* Google Play uchun ishlab chiqarish kaliti (keystore).
* Apple Team ID.
* Haqiqiy AdMob birlik ID lari.

---

## 9. Ish tartibi

Har bosqichdan keyin **to'xtab**, nima qilganingni va qanday
tekshirishni ayt. Boshlashdan oldin loyihaning hozirgi holatini
ko'rib chiq va rejangni qisqacha menga ayt.

Har o'zgarishdan keyin:

1. `tests/run_tests.gd` — 712 ta tekshiruv o'tsin.
2. `tools/playtest.gd -- 30 90` — 32.3% / 3.68% / 344-71
   o'zgarmasin.
3. `tools/uitest.gd` — hamma ekran ochilsin.
4. Ko'rinishga tegsang — skrinshot olib ko'rsat.
5. Commit qil (xabar o'zbekcha), `claude/dazzling-turing-2248jt`
   ga push qil.
