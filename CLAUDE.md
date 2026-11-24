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
   `\s*` bilan yozing
6. Xato xabarlari foydalanuvchini **aniq ishga** yo‘naltirsin (masalan
   «Profil ▸ Serverni yangilash (SQL)»), fayl nomiga emas
7. **`loadGroups()` so‘roviga yangi jadval qo‘shsangiz, eski sxemani ham
   o‘ylang.** `stock_items` qo‘shilganda, SQL ni hali ishga tushirmagan
   foydalanuvchilarda butun guruhlar ishlamay qolgan edi (PGRST200). Hozir
   `sbHasStock` bayrog‘i bor: bunday xatoda so‘rov omborsiz qayta yuboriladi,
   foydalanuvchiga esa SQL ni yangilash kerakligi aytiladi

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
