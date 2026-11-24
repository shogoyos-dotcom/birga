# Birga Hamyon

Shaxsiy hamyon, guruh hisob-kitobi va ombor — bitta ilovada.
Telefonga o‘rnatiladi, internetsiz ham ishlaydi.

**Ilova:** https://shogoyos-dotcom.github.io/birga/

---

## Nima qiladi

### Shaxsiy hamyon
- Kirim va chiqim yozuvlari, kategoriyalar, bir nechta hisob (naqd, karta…)
- Oylik byudjet va uning bajarilishi
- Qidiruv, kategoriya/guruh/a‘zo bo‘yicha filtr
- Chek rasmini biriktirish

### Hisob
- Ilova anonim kirish bilan darhol ishlaydi — ro‘yxatdan o‘tish shart emas
- Xohlasangiz **email va parol** qo‘shasiz: hisob saqlanadi va istalgan
  qurilmadan kirasiz, guruhlar hamda ombor o‘sha yerda bo‘ladi

### Guruhlar (bulutda)
- Guruh yaratib, do‘stlarni **havola orqali** taklif qilasiz — ularga ro‘yxatdan o‘tish shart emas
- Xarajat va tushumlar a‘zolar orasida bo‘linadi, kim kimga qancha qarzdorligi o‘zi hisoblanadi
- Ruxsatlar: **egasi** (hammasi), **tahrirlaydi**, **faqat ko‘radi**
- Hamma a‘zoda real vaqtda yangilanadi

### Ombor
- Ombor **bitta** — u joriy **profil**ga tegishli. Profil **Profil ▸ «Profil»**
  dan tanlanadi: *Shaxsiy profil* (faqat shu telefon) yoki *guruh profili* (bulutda)
- Guruh omborini faqat **siz ruxsat bergan** a‘zolar ko‘radi
  («Omborni ko‘rsin»), **o‘zgartirishni** esa «Tahrirlaydi» roli beradi
- Tovarlar: nomi, o‘lchov birligi (dona, kg, litr, metr, quti…), eng kam qoldiq chegarasi
- **Prihod** (kirim) va **rasxod** (chiqim) harakatlari
- Qoldiq, tannarx va foyda **FIFO** usulida hisoblanadi — oldin kelgan tovar oldin ketadi
- «Kassaga ham yozilsin» — ombor harakati bilan birga pul harakati ham yoziladi
- Qidiruv, filtr (kam qolgan / tugagan / foyda keltirgan) va 9 xil saralash

### Hisobot va grafika
- **Asosiy:** oxirgi 1 / 3 / 6 / 12 oy bo‘yicha kirim-chiqim grafigi
- **1 oy** tanlansa — har bir kun alohida ustun, sanasi bilan
- **Kunlik hisobot:** kunni bossangiz o‘sha kunning sof natijasi, kategoriyalari,
  ombor harakatlari va FIFO foydasi, barcha amaliyotlari ko‘rinadi
- **Amaliyotlar:** kategoriyalar reytingi
- **Guruhlar:** guruhlar bo‘yicha xarajat
- **Ombor:** tovarlar bo‘yicha qiymat yoki foyda

---

## O‘rnatish

**Foydalanuvchi uchun** — havolani telefonda ochib:
- **Android (Chrome):** ⋮ → «Ilovani o‘rnatish»
- **iPhone (Safari):** Ulashish → «Bosh ekranga qo‘shish»

Ilova ichida ham tugma bor: **Profil ▸ «Telefonga o‘rnatish»**.

**Server (guruhlar uchun)** — `SETUP.md` ga qarang. Shaxsiy hamyon va ombor
serversiz, faqat telefonda ishlayveradi.

---

## Loyiha tuzilishi

| Fayl | Nima |
|---|---|
| `index.html` | Butun ilova — HTML, CSS va JS bitta faylda, kutubxonasiz |
| `config.js` | Supabase manzili va ochiq kaliti |
| `schema.sql` | Supabase jadvallari, RLS siyosatlari va taklif funksiyalari |
| `sw.js` | Service worker — offline rejim |
| `manifest.webmanifest`, `icon-*.png` | PWA: o‘rnatish va ikonkalar |
| `SETUP.md` | Supabase sozlash va ishlatish qo‘llanmasi |

Yagona tashqi bog‘liqlik — `@supabase/supabase-js` (CDN’dan, faqat guruhlar uchun).
Build, npm, kompilyatsiya kerak emas.

## Ma‘lumot qayerda saqlanadi

| Nima | Qayerda |
|---|---|
| Shaxsiy hamyon, sozlamalar, telefondagi ombor | Telefonning o‘zida (`localStorage`) |
| Guruhlar, a‘zolar, guruh amaliyotlari, **guruh ombori** | Supabase (bulut) |

Telefondagi ma‘lumot boshqa qurilmaga o‘tmaydi — **Profil ▸ «Ma‘lumotni ko‘chirish»**
orqali zaxira oling.

## Mahalliy ishga tushirish

```bash
# istalgan statik server bo'ladi
npx http-server -p 8080 .
# keyin: http://127.0.0.1:8080
```

## Joylash

GitHub Pages: `main` ga push qilinsa, sayt bir-ikki daqiqada o‘zi yangilanadi.
Netlify Drop, Vercel, Cloudflare Pages ham bo‘laveradi — faqat statik fayllar.
