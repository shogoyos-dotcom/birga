# Testlar

Haqiqiy brauzerda (Chromium, Playwright) ishlaydigan testlar. Build yoki
test freymvorki yo‘q — har bir fayl oddiy `node` skripti.

## Ishga tushirish

```bash
npx http-server -p 8099 -s ..   # boshqa terminalda
cd tests && ./run.sh
```

Boshqa manzilda turgan bo‘lsa: `BIRGA_URL=http://localhost:3000 ./run.sh`

Bitta faylni alohida: `node 02-fifo.mjs`

## Qaysi fayl nimani tekshiradi

| Fayl | Nima |
|---|---|
| `01-ombor.mjs` | Tovar qo‘shish, prihod/rasxod, kassaga bog‘lanish, o‘chirishda ikkalasi birga o‘chishi, qayta yuklangandan keyin saqlanishi |
| `02-fifo.mjs` | FIFO: tannarx, foyda va qoldiq — 4 ta holat (bir partiya, ikki partiya, qoldiqsiz sotuv, sana tartibi) |
| `03-azolar-summalar.mjs` | Guruh xarajat/tushumi, ombor summalari, a‘zolar ro‘yxati, noldan boshlash |
| `04-oy-sql-ornatish.mjs` | Oy tanlash, grafik davri, SQL oynasi, o‘rnatish kartasi |
| `05-tovarlar.mjs` | Ombor grafigi, Tovarlar ekrani, 9 xil saralash, filtrlar, qidiruv |
| `06-kunlik-grafik.mjs` | Kunlik grafik: har bir sana, surilishi, qiymat o‘qi |
| `07-kunlik-hisobot.mjs` | Kunlar ro‘yxati va kunlik otchot (kategoriyalar, ombor, foyda) |
| `08-guruh-ombori.mjs` | Guruh ombori: tanlagich, «faqat ko‘rish» cheklovi, guruh ma‘lumotida FIFO |
| `09-hisob.mjs` | Email/parol oynalari va tekshiruvlari (tarmoqqa chiqmasdan) |
| `10-tillar.mjs` | Uch til: menyu, ekranlar, modal, atribut qiymatlari buzilmasligi |

## Yozish qoidalari

- Ma‘lumot `localStorage` ga `pg.evaluate` bilan joylanadi, keyin `reload`
- Bulutni o‘chirish uchun: `await pg.route('**/supabase*.js', r => r.abort())` —
  aks holda ulanish uzilganda ilova guruhlarni tozalaydi va test beqaror bo‘ladi
- `.kv` qatorlarida yorliq bilan raqam orasida bo‘sh joy yo‘q —
  `/Foyda \(FIFO\)\s*\+300 000/` kabi `\s*` bilan yozing
- `placeholder` matni `textContent` ga kirmaydi — elementni selektor bilan tekshiring
- Bulutsiz muhitda `myRole()` hamisha `viewer` qaytaradi — guruh ombori ustidagi
  «faqat ko‘rish» holatini aynan shu bilan sinaymiz (`08-guruh-ombori.mjs`)
