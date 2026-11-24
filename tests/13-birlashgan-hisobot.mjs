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
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
    transactions: [], budget: { monthly: 0 }, groups: [o.g],
    items: [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }],
    // hamma kelish narxi 10 000 — FIFO navbati natijani o'zgartirmasin
    stock: [
      { id: 'p1', itemId: 'i1', type: 'in',  qty: 200, price: 10000, date: o.oIn,  txId: null },
      { id: 'p2', itemId: 'i1', type: 'in',  qty: 100, price: 10000, date: o.cIn,  txId: null },
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

// ---------- guruh: ulush 0, lekin qarz bor ----------
must(/Tushum \(ulushingiz\)\s*0/.test(t),  'Ulush bo‘yicha tushum 0 (pulni men berganman)');
must(/Xarajat \(ulushingiz\)\s*0/.test(t), 'Ulush bo‘yicha xarajat 0');
must(/Menga qaytariladi\s*568 263/.test(t),'Menga qaytariladi 568 263');
must(/Guruh bo‘yicha sof\s*\+568 263/.test(t), 'Guruh bo‘yicha sof +568 263');

// ---------- ASOSIY TUZATISH: qarz jamiga kiradi ----------
must(/Umumiy natija \(ombor \+ guruh\)\s*\+868 263/.test(t),
     'Umumiy natija +868 263 = ombor 300 000 + qarz 568 263');
must(!/Umumiy natija \(ombor \+ guruh\)\s*0 /.test(t), 'Guruhda pul bor ekan, jami 0 emas');
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
must(/Umumiy natija \(ombor \+ guruh\)\s*\+1 118 263/.test(t),
     'Yil: umumiy +1 118 263 = 550 000 + 568 263');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-yil.png' });

// tanlov saqlanadimi
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(/Sotuv\s*1 650 000/.test((await card().textContent()).replace(/\s+/g, ' ')),
     'Yillik tanlov qayta yuklangandan keyin ham saqlanadi');
await card().locator('[data-act="repper"][data-p="month"]').click(); await pg.waitForTimeout(500);
must(/Sotuv\s*900 000/.test((await card().textContent()).replace(/\s+/g, ' ')), 'Oyga qaytdi');

// ---------- karta qachon chiqmaydi ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items = []; st.stock = []; st.groups = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.removeItem('birga_groups_cache');
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(!/Birlashgan hisobot/.test(await pg.locator('#screen').textContent()),
     'Ombor ham guruh ham bo‘lmasa karta chiqmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
