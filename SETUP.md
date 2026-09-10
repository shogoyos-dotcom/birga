# Birga Hamyon (bulutli) — o‘rnatish qo‘llanmasi

Bu versiyada **shaxsiy hamyon** telefonda saqlanadi, **guruhlar** esa
haqiqiy serverda (Supabase) — do‘stlaringiz havola orqali qo‘shiladi,
sizga claude.ai kerak emas.

Vaqti: ~15–20 daqiqa. Bepul.

---

## 1-qadam — Supabase loyihasi (bepul)

1. https://supabase.com → **Start your project** → GitHub bilan kiring.
2. **New project**: nom bering, kuchli parol qo‘ying, region — Frankfurt (yaqinroq). **Create**.
3. 1–2 daqiqa kutasiz (loyiha tayyorlanadi).

## 2-qadam — Jadval va qoidalarni yaratish

1. Chap menyuda **SQL Editor** → **+ New query**.
2. Shu papkadagi **`schema.sql`** faylini to‘liq oching, hammasini nusxalab, oynaga joylang.
3. **Run** (pastda) — «Success» chiqishi kerak.

## 3-qadam — Anonim kirishni yoqish

1. **Authentication** → **Providers** (yoki **Sign In / Providers**).
2. **Anonymous** ni toping → **Enable** → **Save**.
   *(Bu do‘stlaringiz ro‘yxatdan o‘tmasdan qo‘shilishi uchun.)*

## 4-qadam — Kalitlarni `config.js` ga yozish

1. **Project Settings** (pastdagi tishli belgi) → **API**.
2. Ikkita qiymatni ko‘chiring:
   - **Project URL** → `config.js` dagi `supabaseUrl`
   - **anon / public** key → `config.js` dagi `supabaseAnonKey`
3. `config.js` shunga o‘xshash bo‘ladi:
   ```js
   window.BIRGA_CONFIG = {
     supabaseUrl: "https://abcd1234.supabase.co",
     supabaseAnonKey: "eyJhbGciOiJIUzI1NiIs...uzun_kalit..."
   };
   ```
   *(anon key ochiq kalit — brauzerda ko‘rinishi normal, xavfsiz.)*

## 5-qadam — Saytni internetga qo‘yish

Eng osoni — **Netlify Drop**:

1. https://app.netlify.com/drop
2. Butun **`birga-cloud`** papkasini oynaga sudrab tashlang.
3. 10 soniyada `https://nimadir-123.netlify.app` havolasi chiqadi. Tayyor.

*(Yoki: Vercel, Cloudflare Pages, GitHub Pages — hammasi bo‘ladi. Faqat
statik fayllar, build kerak emas.)*

## 6-qadam — Telefonga o‘rnatish

Havolani telefon brauzerida oching:

- **Android (Chrome):** ⋮ → **«Ilovani o‘rnatish»**
- **iPhone (Safari):** Ulashish → **«Bosh ekranga qo‘shish»**

---

## Ishlatish

**Guruh yaratish** (Guruhlar → +):
- Nom yozasiz, xohlasangiz a‘zolar ismini vergul bilan.
- Siz avtomatik **egasi** bo‘lasiz.

**A‘zo qo‘shish va taklif:**
- Guruh ichida → **Balanslar** → «A‘zolar» → **«A‘zo + taklif»**.
- Ism yozib saqlaysiz → shu odam uchun **shaxsiy taklif havolasi** chiqadi.
- **«Yuborish / ulashish»** tugmasi bilan Telegram/WhatsApp orqali jo‘natasiz.
- Do‘stingiz havolani telefonida ochadi → ilova o‘rnatiladi → «Qo‘shilish» →
  o‘sha a‘zo sifatida guruhga kiradi.

**Ruxsatlar** (faqat egasi ko‘radi, har a‘zo yonida):
- **Egasi** — hamma narsa, a‘zolar va ruxsatlarni boshqaradi.
- **Tahrirlaydi** — xarajat/tushum/hisob-kitob qo‘sha oladi.
- **Faqat ko‘radi** — hech narsa o‘zgartira olmaydi, faqat kuzatadi.
- Rolni istagan vaqt o‘zgartirasiz — server darrov qo‘llaydi.

Barcha o‘zgarishlar hamma a‘zoda **real vaqtda** yangilanadi.

---

## Nosozliklar

| Belgi | Sabab / yechim |
|---|---|
| «Bulut sozlanmagan» | `config.js` to‘ldirilmagan yoki `https://XXXX...` qolib ketgan |
| «Bulut bilan aloqa yo‘q» | internet yo‘q, yoki noto‘g‘ri URL/kalit |
| Guruh yaratganda xato | `schema.sql` to‘liq run bo‘lmagan — qayta running |
| Do‘st «Qo‘shilish»da xato | Anonymous provider yoqilmagan (3-qadam) |
| Havola «yaroqsiz» deydi | havola to‘liq nusxalanmagan (oxirigacha) |

Supabase bepul tarif: 500 MB baza, 50 000 oylik faol foydalanuvchi —
oilaviy/do‘stona foydalanish uchun yetib ortadi.
