import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1050 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Bulutsiz muhitda meId(g) '__me__' qaytaradi — guruhdagi o'z qatorimiz shu id bilan.
const ME = '__me__';
const now = new Date(), Y = now.getFullYear(), M = now.getMonth() + 1;
const ym = Y + '-' + String(M).padStart(2, '0');
const dd = n => ym + '-' + String(n).padStart(2, '0');
// shu yilning BOSHQA oyi (yillik filtrni oydan ajratish uchun)
const OM = M === 1 ? 2 : 1;
const od = n => Y + '-' + String(OM).padStart(2, '0') + '-' + String(n).padStart(2, '0');
// o'tgan yil — yillik hisobotga ham kirmasin
const PREVY = (Y - 1) + '-06-10';

// Foydalanuvchining haqiqiy holati: «Qarz» — pulni MEN berganman, ulushim 0.
// Ya'ni ulush bo'yicha tushum/xarajat 0, lekin menga 568 263 qaytarilishi kerak.
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Etiketka', role: 'viewer', user_id: 'u2' },
            { id: 'm3', name: 'Izzat', role: 'viewer', user_id: 'u3' },
            { id: 'm4', name: 'Ismoil', role: 'viewer', user_id: 'u4' }],
  expenses: [
    { id: 'e1', type: 'expense', title: 'Qarz', amount: 495438, paidBy: ME, date: dd(24), splits: [{ memberId: 'm2', share: 495438 }] },
    { id: 'e2', type: 'expense', title: 'Qarz', amount: 13065,  paidBy: ME, date: dd(24), splits: [{ memberId: 'm4', share: 13065 }] },
    { id: 'e3', type: 'expense', title: 'Qarz', amount: 59760,  paidBy: ME, date: dd(24), splits: [{ memberId: 'm3', share: 59760 }] }
  ],
  settlements: [], items: [], stock: []
};

await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }],
    categories: [{ id: 'c1', name: 'Ijara', kind: 'expense' }, { id: 'c2', name: 'Xizmat', kind: 'income' }],
    transactions: [
      { id: 't1', accountId: 'a', categoryId: 'c2', amount: 400000, type: 'income',  note: 'Xizmat', date: o.cIn },
      { id: 't2', accountId: 'a', categoryId: 'c1', amount: 150000, type: 'expense', note: 'Ijara',  date: o.cIn },
      // ombor prihodiga BOG'LANGAN — «Ombordan tashqari» ga kirmasligi kerak
      { id: 't3', accountId: 'a', categoryId: 'c1', amount: 999999, type: 'expense', note: 'Tovar puli', date: o.cIn }
    ],
    budget: { monthly: 0 }, groups: [o.g],
    items: [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }],
    // hamma kelish narxi 10 000 — FIFO navbati natijani o'zgartirmasin
    stock: [
      { id: 'p1', itemId: 'i1', type: 'in',  qty: 200, price: 10000, date: o.oIn,  txId: null },
      { id: 'p2', itemId: 'i1', type: 'in',  qty: 100, price: 10000, date: o.cIn,  txId: 't3' },
      { id: 's1', itemId: 'i1', type: 'out', qty: 50,  price: 15000, date: o.oOut, txId: null },  // boshqa oy
      { id: 's2', itemId: 'i1', type: 'out', qty: 60,  price: 15000, date: o.cOut, txId: null },  // shu oy
      { id: 's3', itemId: 'i1', type: 'out', qty: 5,   price: 99000, date: o.prevY, txId: null }  // o'tgan yil
    ]
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp, cIn: dd(3), cOut: dd(7), oIn: od(5), oOut: od(10), prevY: PREVY });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(1000);

const card = () => pg.locator('.card', { hasText: 'Birlashgan hisobot' });
must(await card().count() === 1, '«Birlashgan hisobot» kartasi bor');
let t = (await card().textContent()).replace(/\s+/g, ' ');

// ---------- OY: 60 × 15 000 = 900 000 ; tannarx 60 × 10 000 = 600 000 ----------
must(/Sotuv\s*900 000/.test(t),                 'Oy: sotuv 900 000');
must(/Sotilganning tannarxi\s*600 000/.test(t), 'Oy: tannarx 600 000');
must(/Foyda \(FIFO\)\s*\+300 000/.test(t),      'Oy: ombor foydasi +300 000');
must(!/495 000/.test(t),                        'O‘tgan yilning sotuvi aralashmagan');

// ---------- ombordagi qoldiq qiymati ----------
// kelgan 300, sotilgan 110 → qolgan 190 × 10 000 = 1 900 000
must(/Hozir ombordagi tovar\s*1 900 000/.test(t), 'Hozir ombordagi tovar 1 900 000');

// ---------- ombordan tashqari pul (ikki marta sanalmasin) ----------
must(/Ombordan tashqari/.test(t),  '«Ombordan tashqari» bo‘limi bor');
must(/Tushum\s*400 000/.test(t),   'Tashqari tushum 400 000');
must(/Xarajat\s*150 000/.test(t),  'Tashqari xarajat 150 000');
must(!/999 999/.test(t), 'Ombor prihodiga bog‘langan amaliyot tashqariga KIRMAYDI');
must(/Sof\s*\+250 000/.test(t),    'Tashqari sof +250 000');

// ---------- guruh: ulush 0, lekin qarz bor ----------
must(/Tushum \(ulushingiz\)\s*0/.test(t),  'Ulush bo‘yicha tushum 0 (pulni men berganman)');
must(/Xarajat \(ulushingiz\)\s*0/.test(t), 'Ulush bo‘yicha xarajat 0');
must(/Menga qaytariladi\s*568 263/.test(t),'Menga qaytariladi 568 263');
must(/Guruh bo‘yicha sof\s*\+568 263/.test(t), 'Guruh bo‘yicha sof +568 263');

// ---------- ASOSIY TUZATISH: qarz jamiga kiradi ----------
must(/Umumiy natija \(sotuv \+ guruh\)\s*\+1 468 263/.test(t),
     'Umumiy natija +1 468 263 = sotuv 900 000 + guruh sof 568 263');
must(!/Umumiy natija \(sotuv \+ guruh\)\s*\+1 118 263/.test(t),
     'Foyda emas, aynan SOTUV qo‘shilgan');
must(!/Umumiy natija\s*0 /.test(t), 'Guruhda pul bor ekan, jami 0 emas');
must(await card().locator('.kv', { hasText: 'Umumiy natija' }).count() === 1, 'Jami qatori bitta');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-oy.png' });

// ---------- YIL ----------
await card().locator('[data-act="repper"][data-p="year"]').click(); await pg.waitForTimeout(500);
t = (await card().textContent()).replace(/\s+/g, ' ');
// yil: 900 000 + 750 000 = 1 650 000 ; tannarx 1 100 000 ; foyda 550 000
must(/Yil\s*/.test(t) && new RegExp('Yil ' + Y).test(t), 'Sarlavhada yil: Yil ' + Y);
must(/Sotuv\s*1 650 000/.test(t),                 'Yil: sotuv 1 650 000 (900 000 + 750 000)');
must(/Sotilganning tannarxi\s*1 100 000/.test(t), 'Yil: tannarx 1 100 000');
must(/Foyda \(FIFO\)\s*\+550 000/.test(t),        'Yil: foyda +550 000');
must(!/495 000/.test(t),                          'Yil: o‘tgan yilning sotuvi kirmaydi');
must(/Umumiy natija \(sotuv \+ guruh\)\s*\+2 218 263/.test(t),
     'Yil: umumiy +2 218 263 = sotuv 1 650 000 + guruh sof 568 263');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-yil.png' });

// tanlov saqlanadimi
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(/Sotuv\s*1 650 000/.test((await card().textContent()).replace(/\s+/g, ' ')),
     'Yillik tanlov qayta yuklangandan keyin ham saqlanadi');
await card().locator('[data-act="repper"][data-p="month"]').click(); await pg.waitForTimeout(500);
must(/Sotuv\s*900 000/.test((await card().textContent()).replace(/\s+/g, ' ')), 'Oyga qaytdi');

// ---------- DAVR: istalgan sanadan istalgan sanagacha ----------
// shu oyga chegara sinovi uchun yana uchta sotuv qo'shamiz
await pg.evaluate(o => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.stock.push(
    { id: 'r0', itemId: 'i1', type: 'in',  qty: 500, price: 10000, date: o.d1,  txId: null },
    { id: 'r1', itemId: 'i1', type: 'out', qty: 10,  price: 15000, date: o.d14, txId: null }, // chegaradan oldin
    { id: 'r2', itemId: 'i1', type: 'out', qty: 20,  price: 15000, date: o.d15, txId: null }, // chegara kuni
    { id: 'r3', itemId: 'i1', type: 'out', qty: 40,  price: 15000, date: o.d20, txId: null }, // chegara kuni
    { id: 'r4', itemId: 'i1', type: 'out', qty: 50,  price: 15000, date: o.d21, txId: null }  // chegaradan keyin
  );
  localStorage.setItem('birga_v1', JSON.stringify(st));
}, { d1: dd(1), d14: dd(14), d15: dd(15), d20: dd(20), d21: dd(21) });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

await card().locator('[data-act="repper"][data-p="range"]').click(); await pg.waitForTimeout(500);
must(await pg.locator('#modal input[name="from"]').count() === 1 &&
     await pg.locator('#modal input[name="to"]').count() === 1, 'Davr oynasida ikkita sana maydoni bor');
await pg.fill('#modal input[name="from"]', dd(15));
await pg.fill('#modal input[name="to"]', dd(20));
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(600);
t = (await card().textContent()).replace(/\s+/g, ' ');
// 20 + 40 = 60 dona × 15 000 = 900 000 (10 va 50 chegaradan tashqarida)
must(/Sotuv\s*900 000/.test(t),                 'Davr: chegara kunlari ham kiradi (20+40 = 900 000)');
must(/Sotilganning tannarxi\s*600 000/.test(t), 'Davr: tannarx 600 000');
must(/Foyda \(FIFO\)\s*\+300 000/.test(t),       'Davr: foyda +300 000');
must(!/1 650 000/.test(t) && !/2 400 000/.test(t), 'Davrdan tashqaridagi sotuvlar kirmaydi');
must(new RegExp(String(dd(15).slice(8)).replace(/^0/, '') + '-\\S+ ' + Y + ' — ').test(t),
     'Yorliqda tanlangan sanalar ko‘rinadi: ' + t.slice(t.indexOf('Davr') + 4, t.indexOf('Davr') + 50));
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-davr.png' });

// teskari bersa o'rni almashsin
await card().locator('[data-act="repper"][data-p="range"]').click(); await pg.waitForTimeout(400);
await pg.fill('#modal input[name="from"]', dd(20));
await pg.fill('#modal input[name="to"]', dd(15));
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(600);
must(/Sotuv\s*900 000/.test((await card().textContent()).replace(/\s+/g, ' ')),
     'Teskari sana berilsa o‘rni almashadi');

// qayta yuklanganda saqlansin
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(/Sotuv\s*900 000/.test((await card().textContent()).replace(/\s+/g, ' ')),
     'Tanlangan davr qayta yuklangandan keyin ham saqlanadi');

// oyga qaytsa — butun oy qaytsin (10+20+40+50+60 = 180 × 15 000 = 2 700 000)
await card().locator('[data-act="repper"][data-p="month"]').click(); await pg.waitForTimeout(500);
must(/Sotuv\s*2 700 000/.test((await card().textContent()).replace(/\s+/g, ' ')),
     'Oyga qaytsa butun oy hisoblanadi (2 700 000)');

// ---------- faqat kassa bo'lsa ham karta chiqsin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items = []; st.stock = []; st.groups = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.removeItem('birga_groups_cache');
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
t = await pg.locator('#screen').textContent();
must(/Birlashgan hisobot/.test(t), 'Ombor ham guruh ham bo‘lmasa, kassa uchun karta chiqadi');
must(/Ombordan tashqari/.test(t), 'Faqat kassa bo‘limi ko‘rinadi');
must(!/Ombor · /.test(t) && !/Guruh bo‘yicha sof/.test(t), 'Ombor va guruh bo‘limlari yo‘q');
// endi 999 999 ham bog'lanmagan (ombor o'chdi) — shuning uchun tashqariga kiradi
// izohda ham «Umumiy natija» so'zi bor — shuning uchun aynan .kv qatorini qidiramiz
must(await card().locator('.kv', { hasText: 'Umumiy natija' }).count() === 0,
     'Bitta manba qolsa «Umumiy natija» qatori chiqmaydi');

// ---------- hech narsa bo'lmasa karta umuman chiqmasin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.transactions = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(!/Birlashgan hisobot/.test(await pg.locator('#screen').textContent()),
     'Hech narsa bo‘lmasa karta chiqmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
