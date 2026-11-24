# Birga Hamyon — o‘rnatish va ishlatish qo‘llanmasi

Ilova: **https://shogoyos-dotcom.github.io/birga/**

Ikki qismdan iborat:

| Qism | Qayerda ishlaydi | Server kerakmi |
|---|---|---|
| Shaxsiy hamyon, **ombor**, hisobotlar | Faqat shu telefonda | yo‘q |
| **Guruhlar** (do‘stlar bilan birga) | Supabase bulutida | ha |

Guruhlar kerak bo‘lmasa, hech narsa sozlamasangiz ham ilova ishlayveradi.

---

## 1-qism. Telefonga o‘rnatish

Havolani telefon brauzerida oching:

- **Android (Chrome):** ⋮ → **«Ilovani o‘rnatish»**
- **iPhone:** havolani **Safari**da oching → **Ulashish** ⬆️ → **«Bosh ekranga qo‘shish»**
  *(Chrome yoki Telegram ichidagi brauzerda ishlamaydi.)*

Ilova ichida ham tugma bor: **Profil ▸ «Telefonga o‘rnatish»**. Brauzer tayyor
bo‘lsa bir bosishda o‘rnatadi, bo‘lmasa qadamma-qadam ko‘rsatma chiqaradi.

O‘rnatilgach ilova bosh ekranda turadi, brauzer satrisiz ochiladi va
**internetsiz ham ishlaydi**.

---

## 2-qism. Guruhlar uchun server (Supabase)

Vaqti: ~15 daqiqa. Bepul.

### 1-qadam — loyiha yaratish
1. https://supabase.com → **Start your project** → GitHub bilan kiring
2. **New project**: nom, kuchli parol, region — Frankfurt. **Create**
3. 1–2 daqiqa kutasiz

### 2-qadam — jadval va qoidalar
1. Chap menyuda **SQL Editor** → **+ New query**
2. Shu papkadagi **`schema.sql`** ni to‘liq nusxalab oynaga joylang
3. **Run** — «Success» chiqishi kerak

### 3-qadam — anonim kirishni yoqish
**Authentication** → **Providers** → **Anonymous** → **Enable** → **Save**

*(Do‘stlaringiz ro‘yxatdan o‘tmasdan qo‘shilishi uchun.)*

### 4-qadam — kalitlarni `config.js` ga yozish
**Project Settings** → **API** bo‘limidan:

- **Project URL** → `supabaseUrl`
- **anon / public** key → `supabaseAnonKey`

```js
window.BIRGA_CONFIG = {
  supabaseUrl: "https://abcd1234.supabase.co",
  supabaseAnonKey: "eyJhbGciOiJIUzI1NiIs...uzun_kalit..."
};
```

> ⚠️ `supabaseUrl` — faqat **Project URL**. Oxiriga `/rest/v1/` qo‘shmang,
> ilova yo‘lni o‘zi qo‘shadi.
> *(anon key ochiq kalit — brauzerda ko‘rinishi normal.)*

### 5-qadam — saytni joylash
`main` ga push qilsangiz GitHub Pages o‘zi yangilaydi. Yoki
[Netlify Drop](https://app.netlify.com/drop) ga papkani sudrab tashlang.

---

## Ruxsatlarni yangilash

Ilovaga yangi imkoniyat qo‘shilganda serverdagi qoidalar ham yangilanishi kerak.
Agar **guruhni o‘chirib bo‘lmasa** yoki **a‘zoni chiqarib bo‘lmasa**:

**Profil ▸ «Serverni yangilash (SQL)»** → **Nusxa olish** → Supabase ▸ SQL Editor ▸ **Run**

Yoki shu papkadagi `schema.sql` ni qaytadan to‘liq run qiling — xavfsiz,
qoidalar qayta yoziladi, ma‘lumotga tegilmaydi.

---

## Ishlatish

### Guruhlar

**Guruh yaratish:** Guruhlar → **+** → nom yozasiz. Siz avtomatik **egasi** bo‘lasiz.

**A‘zo qo‘shish:** guruh ichida → **Balanslar** → «A‘zolar» → **«A‘zo + taklif»** →
ism yozib saqlaysiz → **shaxsiy taklif havolasi** chiqadi → Telegram/WhatsApp
orqali yuborasiz. Do‘stingiz havolani ochadi → «Qo‘shilish» → o‘sha a‘zo
sifatida kiradi.

**Ruxsatlar** (har a‘zo yonida, faqat egasi o‘zgartiradi):

| Rol | Nima qila oladi |
|---|---|
| **Egasi** | Hammasi: a‘zo qo‘shish, rol berish, guruhni o‘chirish |
| **Tahrirlaydi** | Xarajat/tushum qo‘shish, a‘zoni chiqarish (egadan tashqari) |
| **Faqat ko‘radi** | Hech narsa o‘zgartira olmaydi |

Har kim o‘zi guruhdan chiqa oladi. Barcha o‘zgarishlar hamma a‘zoda
**real vaqtda** yangilanadi.

### Ombor

**Tovar qo‘shish:** Ombor → «Tovar qo‘shish» → nom, o‘lchov birligi va
xohlasangiz **«eng kam qoldiq»** chegarasi (shunga tushganda ⚠ chiqadi).

**Prihod / rasxod:** pastdagi **+** → turini tanlang → miqdor, narx, sana, izoh.
Tovar ro‘yxatida **«+ Yangi tovar…»** ham bor — oynani yopmasdan tovar ochasiz.

**«Kassaga ham yozilsin»** — belgilansangiz, ombor harakati bilan birga pul
harakati ham yoziladi:

| Harakat | Amaliyotlarda |
|---|---|
| Prihod | **chiqim** — tovarga to‘langan pul |
| Rasxod | **kirim** — sotuvdan tushgan pul |

Summa = miqdor × narx. Harakatni tahrirlasangiz yoki o‘chirsangiz, pul yozuvi
ham o‘zi bilan o‘zgaradi. Belgilamasangiz — faqat qoldiq o‘zgaradi.

**Foyda FIFO bo‘yicha** (oldin kelgan oldin ketadi): har bir sotuv eng eski
prihod partiyasidan yechiladi, tannarx o‘sha partiyaning narxida olinadi.

```
prihod 100 000 × 7      tannarx: 85 000 × 7 = 595 000
rasxod  85 000 × 25     foyda:   2 125 000 − 595 000 = 1 530 000
prihod  10 000 × 8      qoldiq:  15 000×7 + 10 000×8 = 185 000
```

**Tovarlar** ro‘yxatida qidiruv, filtr (kam qolgan / tugagan / foyda keltirgan)
va 9 xil saralash bor: nomi, qoldiq, narx, qoldiq qiymati, foyda, oxirgi harakat.

### Hisobotlar

- **Asosiy** → grafik ustidagi **1 / 3 / 6 / 12** — davr tanlanadi
- **1** tanlansa oyning har bir kuni ustun bo‘lib chiqadi (grafik yon tomonga suriladi)
- **Kunni** (ro‘yxatdan yoki grafikdan) bossangiz — o‘sha kunning to‘liq hisoboti:
  sof natija, kategoriyalar, ombor harakatlari va FIFO foydasi, barcha amaliyotlar
- Oy nomini (**«Noyabr 2026 ▾»**) bossangiz istalgan oyga o‘tasiz

### Zaxira

**Profil ▸ «Ma‘lumotni ko‘chirish / joylash»** — shaxsiy hamyon va ombor faqat
shu telefonda saqlanadi, boshqa qurilmaga shu orqali o‘tkaziladi.

**Profil ▸ «Hisobni noldan boshlash»** — amaliyotlar, ombor va byudjet tozalanadi,
hisob qoldig‘i 0 bo‘ladi. Kategoriyalar va guruhlar qoladi.

---

## Nosozliklar

| Belgi | Sabab / yechim |
|---|---|
| «Bulut sozlanmagan» | `config.js` to‘ldirilmagan yoki `https://XXXX...` qolib ketgan |
| «Bulut bilan aloqa yo‘q» | Internet yo‘q, yoki URL/kalit noto‘g‘ri |
| Guruh yaratganda xato | `schema.sql` to‘liq run bo‘lmagan — qaytadan running |
| Do‘st «Qo‘shilish»da xato | Anonymous provider yoqilmagan (3-qadam) |
| Guruh/a‘zo o‘chmayapti | Ruxsatlar eski — «Serverni yangilash (SQL)» ni bajaring |
| Havola «yaroqsiz» deydi | Havola to‘liq nusxalanmagan |
| iPhone’da o‘rnatilmayapti | Safari’da ochish kerak, boshqa brauzerda ishlamaydi |
| Yangilanish ko‘rinmayapti | Ilovani yopib qayta oching |

Supabase bepul tarif: 500 MB baza, 50 000 oylik faol foydalanuvchi — oilaviy va
do‘stona foydalanish uchun yetib ortadi.
