# Birga Hamyon — Claude uchun kontekst

Shaxsiy hamyon + guruh hisob-kitobi + ombor. Bitta HTML fayl, build yo‘q.
Jonli: https://shogoyos-dotcom.github.io/birga/

> Bu repoda `color_land/` va `color_land_3d/` papkalari ham bor — ular
> **boshqa loyiha** (Flutter o‘yini). Birga Hamyon faqat ildizdagi
> `index.html`, `config.js`, `schema.sql`, `sw.js` va ikonkalar.

## Tuzilish

| Fayl | Nima |
|---|---|
| `index.html` | **Butun ilova** — HTML, CSS, JS bitta faylda (~2700 qator) |
| `config.js` | Supabase Project URL va anon kalit |
| `schema.sql` | Supabase jadvallari, RLS siyosatlari, taklif RPC lari |
| `sw.js` | Service worker (HTML uchun «avval tarmoq», qolgani «avval kesh») |
| `tests/` | Brauzer testlari — `tests/README.md` ga qarang |

## Kod uslubi

- **ES5 uslubida**: `var`, `function`, `forEach` — arrow function va `let/const` ishlatilmagan
- Hamma kod bitta IIFE ichida: `(function(){ "use strict"; ... })()`
- Ekranlar — satr qaytaradigan `viewXxx()` funksiyalari, `render()` ularni
  `#screen` ga joylaydi
- Bosishlar — bitta global `click` tinglovchisi, `data-act="..."` bo‘yicha
- Modallar — `openModal(title, bodyHtml, {onMount, onSubmit})`
- Saqlash — `save()` (localStorage), `commit()` = `save()` + `render()`
- Marshrut — `go(name, extra)`, holat `route` obyektida
- Barcha matn **o‘zbekcha**, tipografik apostrof bilan: `o‘`, `a‘zo` (ASCII `'` emas)

## Ma‘lumot

```
localStorage['birga_v1']          butun holat (hamyon, ombor, sozlamalar)
localStorage['birga_groups_cache'] guruhlarning zaxira nusxasi
Supabase                           guruhlar, a‘zolar, guruh amaliyotlari
```

Holat: `{version, currency, me, accounts, categories, transactions,
budget, groups, items, stock, settings}`

- `items` — tovar kartochkalari `{id, name, unit, min}`
- `stock` — harakatlar `{id, itemId, type:'in'|'out', qty, price, date, note, txId}`
- `txId` — «Kassaga ham yozilsin» orqali bog‘langan amaliyot; harakat
  tahrirlansa/o‘chsa u ham o‘zgaradi (`syncMoveTx`, `dropMove`)

## Hisob (auth)

Ilova **anonim** kirish bilan boshlanadi (`signInAnonymously`), keyin
foydalanuvchi xohlasa emailga bog‘laydi:

- `applySession(s)` — `SB_UID` va `SB_EMAIL` ni bitta joydan yangilaydi.
  Boshqa hech qayerda qo‘lda yozilmaydi
- `openLinkEmail()` — `updateUser({email, password})`: anonim hisob
  **doimiy hisobga aylanadi**, guruhlar va ombor saqlanib qoladi
- `openSignIn()` — `signInWithPassword`; shu qurilmadagi eski anonim hisob
  guruhlari ko‘rinmay qolishi haqida oldindan ogohlantiradi
- `signOutCloud()` — chiqgandan keyin **yana anonim kiradi**, aks holda
  ilovaning bulut qismi butunlay o‘chib qolardi; guruh keshi ham tozalanadi
- `onAuthStateChange` — boshqa oynada kirish/chiqish bo‘lsa ham holat yangilanadi

Supabase tomonida: **Anonymous** va **Email** provayderlari yoqiq, Email
ichida «Confirm email» o‘chirilgan bo‘lishi kerak.

Hisob oynalarida `<form novalidate>` ishlatilgan — brauzerning o‘z tekshiruv
xabari o‘zbekcha bo‘lmasligi mumkin, shuning uchun xabarlarni o‘zimiz beramiz.

## Ombor bitta — qaysi profilda ishlasa, o‘shaniki

Ekranda **tanlagich yo‘q**. Ombor joriy **profil**ga tegishli, profil esa
**Profil ▸ «Profil»** kartasida tanlanadi (`profileCard()` → `data-act="oscope"`).

| Profil | Qayerda | Kim ko‘radi |
|---|---|---|
| **Shaxsiy profil** | `state.items` / `state.stock` (localStorage) | faqat shu qurilma |
| **Guruh profili** | Supabase `stock_items` / `stock_moves`, `g.items` / `g.stock` da keshlanadi | ruxsat berilgan a‘zolar |

Tanlov `state.settings.omborScope` da: `'local'` yoki guruh id si.

Ombor moduli **hech qachon to‘g‘ridan-to‘g‘ri `state.items`/`state.stock` ga
tegmaydi** — `curItems()` va `curStock()` orqali ishlaydi. Yozishda esa
`omborGroup()` tekshiriladi: guruh bo‘lsa `saveItemCloud` / `saveMoveCloud` /
`deleteItemCloud` / `deleteMoveCloud`, aks holda to‘g‘ridan-to‘g‘ri localStorage.

Guruh profiliga o‘tilganda telefonda eski tovarlar qolgan bo‘lsa, Ombor
ekranida `migrateCard()` chiqadi. `migrateStock()` ularni serverga ko‘chiradi
va **telefondagi nusxani tozalaydi** — shunda ombor haqiqatan bitta bo‘ladi.
Kassadagi pul amaliyotlariga tegilmaydi.

### Ikki xil ruxsat

| | Kim | Funksiya |
|---|---|---|
| **Yozish** | `owner`, `editor` | `omborCanEdit()` |
| **Ko‘rish** | `owner`, `editor`, va `can_stock = true` berilgan a‘zo | `canSeeStock(g)` / `omborCanSee()` |

Yangi a‘zo **sukut bo‘yicha `viewer` va `can_stock = false`** — ya‘ni guruh
xarajatlarini ko‘radi, omborni ko‘rmaydi. Guruh egasi a‘zolar ro‘yxatidagi
«Omborni ko‘rsin» tugmasi (`data-act="mstock"` → `setMemberStock`) bilan beradi.

Serverda `stock_visible(gid)` funksiyasi bor, `si_select` va `sm_select`
siyosatlari **shu funksiya orqali** ishlaydi (`is_member` emas!). Ruxsatsiz
a‘zoda so‘rov bo‘sh qaytadi, ilova esa qulf ekranini ko‘rsatadi va FAB ni
yashiradi.

`canSeeStock()` da **`myMember()` topilmasa `true` qaytadi**: bulut uzilgan
paytda SB_UID yo‘q, keshni bekorga to‘smaslik kerak. Asl himoya baribir RLS da.

«Kassaga ham yozilsin» faqat shaxsiy profil omborida bor; guruh omborida pul
harakati yozilmaydi (hali).

### Tovar turkumlari

Tovarda `cat` maydoni bor (`Tovar`, `Oziq-ovqat`, … — foydalanuvchi o‘zi yozadi;
`CAT_HINTS` faqat taklif). Bo‘sh bo‘lsa `NOCAT` = «Turkumsiz».

- `catOf(i)` / `allCats()` / `catTotals()` — turkum kesimidagi hisob
- Ombor ekranida «Turkumlar» kartasi: har turkum ustuni + **«Jami (hammasi
  birga)»**. Turkum bitta bo‘lsa karta chiqmaydi
- Tovarlar ekranida turkum chiplari (`data-act="icat"` → `route.cat`)

Serverda `stock_items.cat`. Eski serverda bu ustun yo‘q, shuning uchun
`sbHasItemCat` bayrog‘i bor: xato chiqsa turkumsiz qayta yuboriladi va
foydalanuvchiga SQL ni yangilash kerakligi **bir marta** aytiladi
(`catSqlHint`). Tovarning o‘zi baribir saqlanadi. `itemRow()` shu bayroqni
hisobga oladi — bulutga tovar yozadigan hamma joy shundan o‘tadi.

**Diqqat:** `itemRow()` ni ishlatgan har bir so‘rovga `isMissingCat` qayta
urinishi ham kerak. `migrateStock` da u unutilib, eski serverda butun
ko‘chirish «Bulut xatosi» bilan yiqilardi. Hozir ikkala joyda ham bor,
`roleNote()` esa Ombor ekranida doimiy ogohlantirish ko‘rsatadi.

## Narx o‘zi turadi

Yangi prihod/rasxodda narx maydoni **oxirgi shunday harakatning narxi** bilan
to‘ldiriladi — `lastPriceOf(itemId, type)`. Prihod va rasxod narxi **alohida**
eslab qolinadi. Tovar yoki tur almashsa narx ham moslashadi, lekin
**foydalanuvchi o‘zi yozgan narxga tegilmaydi**: `suggestPrice()` faqat
maydon bo‘sh bo‘lsa yoki ichida o‘zimiz qo‘ygan taklif tursa yangilaydi.
Miqdor esa har safar bo‘sh qoladi.

## Summa ↔ dona narxi

Ombor oynasida **uchta** bog‘liq maydon: Miqdor, Narx (1 dona), Summa (jami).

- miqdor yoki narx yozilsa → `summa = miqdor × narx`
- **summa yozilsa** → `narx = summa ÷ miqdor` (miqdor 0 dan katta bo‘lsa)

`syncing` bayrog‘i aylanma chaqiriqni to‘xtatadi: boshqa maydonga qiymat
qo‘yilganda `input` hodisasi yuborilmaydi. Narx butun songa yaxlitlanadi —
`parseAmount` baribir shunday saqlaydi, shuning uchun ko‘rinib turgan son
saqlanadigan son bilan bir xil bo‘ladi.

## Kimdan / kimga — ta‘minotchi va klient

Harakatda `party` maydoni bor: **prihodda ta‘minotchi, rasxodda klient**.
Izoh bundan alohida — ikkisi aralashmaydi.

- `partyHints(type)` — shu ombordagi oldingi nomlar, **yangisidan eskisiga**,
  takrorsiz. Prihod va rasxod ro‘yxati **alohida**
- `partyLabel(type)` — «Kimdan (ta‘minotchi)» yoki «Kimga (klient)»
- Oynada `<select>` + **«+ Yangi…»**: tanlanadi yoki yangisi yoziladi
  (tovardagidek). Tur almashsa `fillParty('')` ro‘yxatni qayta quradi
- Yozishda: `form.party.value==='__new' ? form.partyNew.value : form.party.value`

Serverda `stock_moves.party`. Eski serverda bu ustun yo‘q — `sbHasParty`
bayrog‘i `sbHasItemCat` kabi ishlaydi. `isMissingParty()` **aniq `party`
so‘zini** qidiradi, chunki `isMissingAudit()` ning qolipi juda keng
(`column` ham mos keladi) va u birinchi tekshirilsa audit bekorga
o‘chib qolardi. `sendRetry(send)` ikkala qayta urinishni bitta joyda
qiladi — `saveMoveCloud` ham, `migrateStock` ham shuni ishlatadi.

## Ombor ▸ «Harakatlar» — filtrli hisobot

`viewMoves()` (marshrut `moves`, Ombor ekranidagi tugmadan). Filtrlar:

| Filtr | Qayerda | Nima qiladi |
|---|---|---|
| **Tovar** | `#mvitem` → `route.mi` | shu tovar harakatlari |
| **Ta‘minotchi** | `#mvsup` → `route.ms` | shu nom bilan **prihod**lar |
| **Klient** | `#mvcli` → `route.mc` | shu nom bilan **rasxod**lar |
| **Davr** | `data-act="repper"` | Oy / Yil / Davr — birlashgan hisobotdagidek |

Ta‘minotchi bilan klient **birga mantiqsiz** (harakat yo kirim, yo chiqim),
shuning uchun biri tanlansa ikkinchisi tozalanadi (`mountFns.moves`).

Filtr `route` da turadi — boshqa ekranga o‘tib qaytsa tozalanadi; davr esa
`state.settings.repPeriod` da, ya‘ni butun ilovada bitta.

Jami: harakatlar soni, jami prihod, sotuv, **Foyda (FIFO)** — oxirgisi
`fifo().perMove` dan, har tovar uchun bir marta hisoblanadi (`fc` keshi).

Qator bosilsa harakat tahrirlanadi — **«Kassaga ham yozilsin» shu yerdan
yetiladi**: avval prihod yoziladi (pul bermay), keyin to‘laganda shu
katakcha belgilanadi va `syncMoveTx` kassaga chiqim yozadi. Pul harakati
**harakatning sanasi** bilan yoziladi, to‘lov kuni bilan emas.

## Izoh takliflari

`noteHints()` — joriy ombordagi oldingi izohlar, **yangisidan eskisiga**,
takrorsiz, 20 tagacha. Izoh maydoni `list="notehints"` orqali ularga ulangan,
ya‘ni bir marta yozilgan nom keyingi safar tanlanadi.

## A‘zoning amaliyotlari

Balanslar ro‘yxatidagi a‘zo qatori bosiladi (`data-act="member-view"` →
`openMemberView`). Oynada: balansi, nechta amaliyotda qatnashgani, u to‘lagan
va uning ulushi (xarajat va tushum alohida), pastida esa amaliyotlar ro‘yxati
— har birida uning ulushi yozilgan. Qator bosilsa o‘sha amaliyot ochiladi
(`data-act="entry-view"`).

Ro‘yxatga a‘zo **to‘lovchi** bo‘lgan yoki **ulushi bor** amaliyotlar kiradi.

## Kim va qachon (audit)

`entries` va `stock_moves` da `created_by`/`created_at` **avvaldan bor** edi;
tahrir uchun `updated_by`/`updated_at` qo‘shildi. `stampRow(row, existing)`
yozishda to‘ldiradi, `auditBlock(g, r)` esa ko‘rsatadi:

- guruh amaliyoti — `openEntryView` dagi ma‘lumot jadvalida
- ombor harakati — tahrirlash oynasining tepasida

`memNameByUid(g, uid)` auth id ni guruhdagi ismga aylantiradi, `fmtWhen(iso)`
«26-noy 14:30» qiladi. O‘zgartirilmagan yozuvda «O‘zgartirdi» qatori
chiqmaydi.

Eski serverda bu ustunlar yo‘q — `sbHasAudit` bayrog‘i `sbHasItemCat` kabi
ishlaydi: xato chiqsa usiz qayta yuboriladi va bir marta ogohlantiriladi.

## Kalkulyator (summa maydonlarida)

Har bir `inputmode="numeric"` / `"decimal"` maydoniga **ifoda** yozsa bo‘ladi:
`3*45000+500`, `(100+50)*2`, `12,5*4`, `50:2`. Yozayotganda tagida `= …`
ko‘rinadi, maydondan chiqqanda esa o‘rniga shu son yoziladi.

**Telefon klaviaturasida `+` va `×` tugmalari yo‘q!** `inputmode="numeric"`
Androidda faqat raqam, minus, probel va vergulni beradi — ya‘ni ifodani
*yozib bo‘lmaydi*. Shuning uchun maydon ostida o‘z tugmalarimiz turadi
(`.calcpad`: `+ − × ÷ ( )`), fokusda ko‘rinadi. Tugma `pointerdown` da
`preventDefault()` qiladi — fokus maydonda qoladi, klaviatura yopilmaydi.
`click` ham ulangan (klaviatura bilan ishlash uchun), 500 ms qo‘riqchi ikki
marta qo‘shib yuborishdan saqlaydi. **Buni sinaganda `hasTouch: true` bilan
sinang va amallarni faqat tugmadan kiriting** — aks holda test telefonda
mavjud bo‘lmagan klaviaturani taqlid qiladi va kamchilik ko‘rinmay qoladi.

- `calcEval(src)` — **`eval()` ishlatilmaydi**, o‘z tahlilchimiz: faqat raqam,
  `+ − * / ( )` va `× ÷ x :` belgilarini tushunadi, boshqasiga `null`
- `calcOf(v)` — oddiy son bo‘lsa `null`, ifoda bo‘lsa natija
- `parseAmount` va `parseQty` shu orqali o‘tadi, ya‘ni **hamma maydon** birdan
  kalkulyatorga aylandi
- `wireCalc(root)` ni `openModal` chaqiradi; hamma raqam maydoni modal ichida.
  `.split-line` ichidagilar **chiqarib tashlanadi** — ularda natija yon
  tomondagi `.calc` ustunida ko‘rinadi, qo‘shimcha qator flex qatorini buzardi

## Guruhda pulni bo‘lish — to‘rt rejim

`buildSplitBody(mode, …)` va `recalc()` da: `equal` (teng), `exact` (aniq
summa), `shares` (ulush nisbati), **`pct` (foiz)**.

### «Teng» + shaxsiy qo‘shimcha

Teng rejimidagi har bir qatorda **«+ shaxsiy»** maydoni bor (`.xinput`).
Hisob `splitEqualPlus(amount, ids, extra, allIds)` da: avval kimning nimasi
o‘ziniki bo‘lsa ayriladi, **qolgani belgilanganlar orasida teng bo‘linadi**.
69 000 dan 7 000 Izzatniki bo‘lsa, qolgan 62 000 ikkiga bo‘linadi →
Izzat 38 000, SHO 31 000.

- shaxsiy summa **belgilanmagan** a‘zoda ham hisobga olinadi (u faqat o‘zinikini
  to‘laydi, qolganiga qo‘shilmaydi)
- hech kim belgilanmasa — faqat shaxsiylar yoziladi, qolgani to‘lovchida qoladi
- shaxsiylar yig‘indisi summadan oshsa `_readSplits()` `null` qaytaradi

Qator `<label>` bo‘lgani uchun ichidagi maydon bosilganda belgilash tugmasi
**almashmaydi** — HTML spetsifikatsiyasi bo‘yicha interaktiv element ichidagi
bosish `<label>` ga o‘tmaydi.

`splitPct(amount, pairs)` — har kimga `%`. Foizlar yig‘indisi 100 dan **kam
bo‘lsa, qolgani bo‘linmaydi** va to‘lovchida qoladi; 100 dan **oshsa**
`_readSplits()` `null` qaytaradi, ya‘ni saqlanmaydi. Taqsimlashni
`splitWeighted` qiladi: `amount × jamiFoiz / 100` ni foizlar nisbatida
bo‘ladi, shuning uchun tiyin-tiyingacha to‘g‘ri chiqadi.

Tahrirlashda hozirgi summalardan foiz tiklanadi (`share/amount*100`).

**Foiz — pul emas, shuning uchun `parseAmount` ishlatilmaydi.** U butun songa
yaxlitlaydi va `27,5` ni `28` qilib qo‘yardi: jami 100 o‘rniga 101% chiqib
«oshib ketdi» deyilardi, summa ham noto‘g‘ri edi (18 480 ≠ 18 150). Hozir
foiz va ulush maydonlari `inputNums()` (ya‘ni `parseQty`) orqali o‘qiladi,
maydon `inputmode="decimal"` (Androidda nuqta/vergul chiqishi uchun),
`splitPct` esa `tot` ni 3 kasrga yaxlitlab float qoldig‘ini olib tashlaydi.
Taqqoslash ham aniq son bilan emas, chegara bilan: `>100.001` — oshdi,
`>99.999` — aynan 100%. Foizni ko‘rsatish `fmtPct()` da (`27,5`, `30`).

## «Pulim» (Asosiy ekranning birinchi kartasi)

`pulimCard()` — foydalanuvchining asosiy savoliga javob: **naqd pulim qancha**.

```
Pulim — naqd        walletTotal()   = hamma hisoblar ochilish + amaliyotlar
Ombordagi tovar     stockTotal()    = FIFO qoldiq qiymati
Menga qaytariladi   owedToMe        } meNetForGroup bo‘yicha
Men qaytaraman      −iOwe           }
Sof boylik          cash + goods + owedToMe − iOwe
```

Nol bo‘lgan qatorlar chiqmaydi; hech biri bo‘lmasa faqat naqd raqami qoladi.

**Hozircha naqd to‘liq emas:** guruh amaliyotlari kassaga tegmaydi (ishchiga
berilgan pul `state.transactions` ga tushmaydi). Shuning uchun guruh bo‘lsa
karta ostida shuni aytadigan eslatma chiqadi. Keyingi qadam — ishchilar
daftarini kassaga bog‘lash; o‘shanda eslatma olib tashlanadi.

## Birlashgan hisobot (Asosiy ekran)

`combinedCard(ym)` — kassa hero dan keyin turadi, eski «Guruh hisob-kitobi»
kartasi o‘rniga:

- **Ombor** (joriy profilniki): sotuv, tannarx, FIFO foyda — tanlangan davr
  uchun; va **«Hozir ombordagi tovar»** (`stockTotal()`, davrga bog‘liq emas)
- **Ombordan tashqari** (`cashOutside`): shaxsiy kassadagi tushum/xarajat va
  ularning sofi
- **Guruh**: ulushingiz bo‘yicha tushum/xarajat (`groupMonthShares`), qarzlar
  (`meNetForGroup`) va ularning sofi — qarzlar **butun davr** uchun
- **Umumiy natija** = `S.sale + C.net + gDebt` — foydalanuvchi aynan shunday
  so‘radi. Uchta manbadan kamida **ikkitasi** bo‘lganda chiqadi (bittada u
  yuqoridagi qatorning takrori bo‘lib qolardi). **Sotuv — aylanma, foyda
  emas** (ichida tannarx bor), shuning uchun «Foyda (FIFO)» alohida qator
  bo‘lib turadi. Jamiga **faqat «Hozir ombordagi tovar» qo‘shilmaydi**

**`cashOutside()` ikki marta sanashdan saqlaydi:** «Kassaga ham yozilsin»
orqali ombor harakatiga bog‘langan amaliyotlar (`state.stock[].txId`) chiqarib
tashlanadi — ular ombor qismida allaqachon hisoblangan. `curStock()` emas,
aynan `state.stock`: `txId` faqat telefondagi harakatlarda bo‘ladi.

**«Hozir ombordagi tovar» jamiga qo‘shilmaydi** — u pul emas, tovar. Nima
qo‘shilgani va nima qo‘shilmagani karta ostidagi izohda yozilgan — formula
o‘zgarsa **izohni ham yangilang** (u lug‘atda kalit sifatida ham bor,
ikkalasi aynan bir xil bo‘lishi shart, aks holda tarjima mos tushmaydi).

**Nega ulush emas, qarz?** «Qarz» turidagi yozuvlarda pulni egasi beradi,
ulush esa butunlay boshqa a‘zoga yoziladi — ya‘ni `myShareIn()` 0 qaytaradi.
Jami avval `inc − exp` dan hisoblanardi va guruhda 568 263 so‘m turgani holda
**0** chiqardi. Shuning uchun jamiga `owedToMe − iOwe` qo‘shiladi. Tushum va
xarajat qatorlari qoldi, lekin jamiga kirmaydi — buni karta ostidagi izoh
aytib turadi.

### Davr: oy, yil yoki tanlangan sanalar

`repPeriod()` → `state.settings.repPeriod` (`'month'` | `'year'` | `'range'`),
`data-act="repper"` tugmalari bilan almashadi. `'range'` da `repFrom`/`repTo`
ham saqlanadi; ularsiz `repPeriod()` **oyga qaytadi**, shuning uchun yarim
saqlangan holat ilovani buzmaydi. `repSel(ym)` davr qiymati va yorlig‘ini
bitta joydan beradi.

`monthStock(p)` va `groupMonthShares(p)` davrni `inPeriod(d, p)` orqali
tekshiradi: `p` **satr** bo‘lsa prefiks (`'2026-11'`, `'2026'`), **obyekt**
bo‘lsa `{from, to}` — ikkala chegara ham **ichiga kiradi**. Shuning uchun
bitta kod uchala davrga ham yaraydi va eski chaqiruvlar (`viewHome`,
`monthChart`) oy prefiksini berib ishlayveradi.

`openRangeModal()` — teskari berilgan sanalarni o‘zi almashtiradi.

Oy kesimini `fifo().perMove` beradi: u har bir rasxodning tannarxini saqlaydi,
shuning uchun davrni ajratish uchun qayta hisoblash shart emas.
`omborCanSee()` false bo‘lsa ombor qismi umuman hisoblanmaydi.

## Ombor hisobi — FIFO

`fifo(itemId)` harakatlarni **sana bo‘yicha** (sana teng bo‘lsa — kiritilish
tartibida) yurib chiqadi, partiyalar navbatini saqlaydi va qaytaradi:
`{cogs, sale, profit, leftValue, leftQty, short, perMove}`.

Qoldiq qiymati — qolgan partiyalar o‘z narxida. O‘rtacha narx **ishlatilmaydi**
(`avgInPrice` faqat ma‘lumot uchun ko‘rsatiladi).

## Grafika

- Inline SVG, kutubxonasiz. Ranglar: `--ch-in` (kirim) va `--ch-out` (chiqim)
- Bu ranglar **rang ko‘rligi bo‘yicha tekshirilgan** (deutan/protan/tritan
  ajralishi ΔE ≥ 8), yorug‘ va qorong‘i rejim uchun alohida qadamlar.
  **O‘zgartirsangiz qaytadan tekshiring** — odatdagi yashil/qizil juftlik
  bu testdan o‘tmaydi
- `monthChart(ym, n)` — oylik ustunlar; `dayChart(ym)` — kunlik, yon tomonga
  suriladi (`.chscroll`), qiymat o‘qi alohida SVG da (`.chaxis`)
- `barList(rows, cssVar)` — nomlangan gorizontal ustunlar; `cssVar` berilmasa
  ishoraga qarab rang (foyda/zarar)
- `balanceChart(g, net)` — guruh ekranidagi a‘zolar balansi: nol chizig‘idan
  **yuqorida yashil** (puli bor), **pastda qizil** (qarzdor). Ikkala tomon
  **bitta o‘lchovda** (`maxAbs`). Pastga o‘sadigan ustun uchun `colPathDown()`
  bor — `colPath()` ning teskarisi. A‘zo 2 tadan kam yoki hamma teng bo‘lsa
  grafik umuman chiqmaydi

## Oldin uchragan tuzoqlar

1. **`supabaseUrl` ga `/rest/v1/` qo‘shmaslik** — supabase-js yo‘lni o‘zi
   qo‘shadi. Baribir xato yozilsa, ilova `createClient` oldidan tozalaydi
2. **RLS jim to‘xtatadi** — ruxsat bo‘lmasa server xato qaytarmaydi, qatorni
   shunchaki o‘chirmaydi. Shuning uchun `deleteGroupCloud` va `removeMember`
   o‘chirgandan keyin **natijani tekshiradi** va aniq xabar beradi
3. **`navigator.clipboard.writeText` promise qaytaradi** — `try/catch` uni
   ushlamaydi. `copyText()` yordamchisidan foydalaning
4. **Bulut uzilganda `state.groups` tozalanadi** — testlarda Supabase CDN sini
   bloklang, aks holda natija beqaror bo‘ladi
5. **`.kv` qatorida yorliq bilan qiymat orasida bo‘sh joy yo‘q** — testda
   `\s*` bilan yozing. Shuningdek, karta ostidagi **izoh matni** ham ekranda
   bor: «Umumiy natija yo‘q» kabi tekshiruvni `#screen` matni bo‘yicha emas,
   aynan `.kv` qatori bo‘yicha qiling
6. Xato xabarlari foydalanuvchini **aniq ishga** yo‘naltirsin (masalan
   «Profil ▸ Serverni yangilash (SQL)»), fayl nomiga emas
7. **`loadGroups()` so‘roviga yangi jadval qo‘shsangiz, eski sxemani ham
   o‘ylang.** `stock_items` qo‘shilganda, SQL ni hali ishga tushirmagan
   foydalanuvchilarda butun guruhlar ishlamay qolgan edi (PGRST200). Hozir
   `sbHasStock` bayrog‘i bor: bunday xatoda so‘rov omborsiz qayta yuboriladi,
   foydalanuvchiga esa SQL ni yangilash kerakligi aytiladi

8. **`main` ni shoxga qo‘shishda `-X ours` emas, `-s ours` ishlating.**
   Bu repoda har PR `main` ga **squash** bilan qo‘shiladi, shuning uchun shox
   tarixi `main` niki bilan ajralib qoladi. `-X ours` faqat *to‘qnashgan*
   bo‘laklarni bizniki bilan hal qiladi — qolganini `main` dan oladi va
   sinalgan kodni eski holiga qaytarib qo‘yishi mumkin. Shunday bo‘lib, bir
   marta shart, bir marta esa hujjatdagi band qaytib kelgan (ikki nusxa
   bo‘lib qolgan). `-s ours` esa butun daraxtni bizniki qoldiradi — bu
   to‘g‘ri, chunki shoxda `main` da yo‘q narsa bo‘lmaydi.

   **Har safar ikkala tekshiruvni bajaring:**

   ```bash
   BEFORE=$(git rev-parse HEAD)
   git merge --no-edit -s ours origin/main
   git diff --stat $BEFORE HEAD        # BO'SH bo'lishi shart
   git diff --stat origin/main HEAD    # faqat o'zingiz qilgan o'zgarish
   ```

## Ishni tekshirish

```bash
npx http-server -p 8099 -s .
cd tests && npm install && ./run.sh
```

Kod o‘zgarganda **testni ham yangilang**. Yangi imkoniyat qo‘shilsa — unga
test yozing; `tests/README.md` da qoidalar bor.

Sintaksisni tez tekshirish (bitta faylda HTML ichida JS bo‘lgani uchun):

```bash
python3 - <<'PY'
import io,re
s=io.open('index.html',encoding='utf-8').read()
p=re.findall(r'<script(?![^>]*src=)[^>]*>(.*?)</script>', s, re.S)
io.open('/tmp/app.js','w',encoding='utf-8').write('\n;\n'.join(p))
PY
node --check /tmp/app.js
```

## Joylash

`main` ga push → GitHub Pages bir-ikki daqiqada yangilaydi.
`schema.sql` o‘zgarsa, foydalanuvchi uni Supabase ▸ SQL Editor da qo‘lda
run qilishi kerak — ilovada shu uchun **Profil ▸ «Serverni yangilash (SQL)»**
tugmasi bor.
