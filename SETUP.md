# Birga Hamyon — o‘rnatish va ishlatish qo‘llanmasi

Ilova: **https://shogoyos-dotcom.github.io/birga/**

Ikki qismdan iborat:

| Qism | Qayerda ishlaydi | Server kerakmi |
|---|---|---|
| Shaxsiy hamyon, hisobotlar | Faqat shu telefonda | yo‘q |
| **Mening omborim** | Faqat shu telefonda | yo‘q |
| **Guruhlar** va **guruh ombori** | Supabase bulutida | ha |

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

### 3-qadam — kirish usullarini yoqish

**Authentication** → **Providers** bo‘limida ikkita narsa:

1. **Anonymous** → **Enable** → **Save**
   *(Do‘stlaringiz ro‘yxatdan o‘tmasdan, havola orqali qo‘shilishi uchun.)*
2. **Email** → yoqilgan bo‘lishi kerak (odatda o‘zi yoqiq). Ichida
   **«Confirm email»** ni **o‘chiring** — aks holda har bir ro‘yxatdan o‘tishda
   pochtaga tasdiqlash xati kerak bo‘ladi, bepul tarifda esa Supabase soatiga
   bir nechta xat yuboradi va bu noqulaylik tug‘diradi.

> **Nega email kerak?** Anonim hisob brauzerdagi yashirin kalit bilan
> belgilanadi. Brauzer ma‘lumotlari tozalansa yoki telefon almashsa, o‘sha
> kalit yo‘qoladi va guruhlaringizga kira olmay qolasiz. Email va parol
> qo‘shsangiz — hisob saqlanadi.

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

Yangi a‘zo **«Faqat ko‘radi»** bo‘lib qo‘shiladi — ya‘ni u hech narsani
o‘zgartira olmaydi. Tahrirlash huquqini **siz** berasiz: a‘zo yonidagi
ro‘yxatdan «Tahrirlaydi» ni tanlaysiz.

Har kim o‘zi guruhdan chiqa oladi. Barcha o‘zgarishlar hamma a‘zoda
**real vaqtda** yangilanadi.

> Himoya ilovada emas, **serverda**. Ruxsati yo‘q odam ilovani o‘zgartirsa ham
> serverning o‘zi yozishga yo‘l qo‘ymaydi.

### Ombor

Ombor ikki xil bo‘lishi mumkin — Ombor ekranining tepasidagi tanlagichdan:

| | Kim ko‘radi | Kim o‘zgartiradi |
|---|---|---|
| **Mening omborim** | faqat siz, shu telefonda | siz |
| **☁ Guruh ombori** | guruhning **barcha a‘zolari** | faqat **egasi** va **«Tahrirlaydi»** ruxsati borlar |

Ya‘ni do‘koningiz omborini guruhga bog‘lasangiz: xodimlar qoldiqni va hisobotni
ko‘rib turadi, lekin siz ruxsat bermaguningizcha hech narsa o‘zgartira olmaydi.
Ma‘lumot serverda saqlanadi — telefon yo‘qolsa ham qolaveradi.

**Telefondagi omborni guruhga ko‘chirish:** guruh omborini tanlasangiz,
«Telefondagi ombor» kartasi chiqadi — bir bosishda hamma tovar va harakat
ko‘chadi (telefondagi nusxa zaxira sifatida qoladi).

> Guruh ombori ishlashi uchun **yangilangan `schema.sql`** kerak. Agar
> «Serverda ombor jadvallari yo‘q» degan ogohlantirish chiqsa —
> Profil ▸ «Serverni yangilash (SQL)» ni bajaring.

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

*(Bu katakcha faqat «Mening omborim» da bor. Guruh omborida pul harakati
alohida yozilmaydi — faqat qoldiq o‘zgaradi.)*

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

### Hisob: email va parol

**Profil ▸ Hisob** bo‘limida:

| Holat | Nima ko‘rinadi |
|---|---|
| Hisob anonim | «Email va parol qo‘shish» va «Mavjud hisobga kirish» |
| Email bog‘langan | emailingiz va «Chiqish» |

**«Email va parol qo‘shish»** — hozirgi hisobingizni saqlab qo‘yadi:
guruhlar, a‘zolar va ombor **joyida qoladi**, ustiga email qo‘shiladi.
Shundan keyin boshqa telefondan ham shu email bilan kirasiz va hammasi
o‘sha yerda bo‘ladi.

**«Mavjud hisobga kirish»** — boshqa qurilmada, allaqachon email qo‘shilgan
hisobga kirish uchun. Diqqat: kirgandan keyin shu qurilmadagi **eski anonim
hisob** guruhlari ko‘rinmay qoladi (ular serverda qolaveradi, lekin boshqa
hisobniki bo‘ladi).

Telefondagi shaxsiy hamyon va «Mening omborim» hisobga bog‘liq emas — ular
qurilmada qoladi.

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
| «Serverda ombor jadvallari yo‘q» | Xuddi shunday — SQL ni yangilang |
| A‘zo ombor yoza olmayapti | Uning roli «Faqat ko‘radi» — «Tahrirlaydi» ga o‘tkazing |
| Havola «yaroqsiz» deydi | Havola to‘liq nusxalanmagan |
| iPhone’da o‘rnatilmayapti | Safari’da ochish kerak, boshqa brauzerda ishlamaydi |
| «Email tasdiqlanmagan» | Authentication ▸ Providers ▸ Email ▸ «Confirm email» ni o‘chiring |
| Parolni tiklash xati kelmadi | Bepul tarifda xat limiti bor — biroz kutib qayta urining |
| Yangilanish ko‘rinmayapti | Ilovani yopib qayta oching |

Supabase bepul tarif: 500 MB baza, 50 000 oylik faol foydalanuvchi — oilaviy va
do‘stona foydalanish uchun yetib ortadi.
