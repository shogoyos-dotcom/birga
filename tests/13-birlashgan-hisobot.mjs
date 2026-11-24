import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1000 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Bulutsiz muhitda meId(g) '__me__' qaytaradi — guruhdagi o'z qatorimiz
// shu id bilan bo'lsa, ulush hisobi ham sinaladi.
const ME = '__me__';
const now = new Date(), ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');
const PREV = (() => { const d = new Date(now.getFullYear(), now.getMonth() - 1, 15); return d.toISOString().slice(0, 10); })();

const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Aziz', role: 'editor', user_id: 'u2' }],
  expenses: [
    // Ijara 600 000, teng bo'lingan → mening ulushim 300 000
    { id: 'e1', type: 'expense', title: 'Ijara', amount: 600000, paidBy: ME, date: dd(5),
      splits: [{ memberId: ME, share: 300000 }, { memberId: 'm2', share: 300000 }] },
    // Buyurtma 400 000 tushum → ulushim 200 000
    { id: 'e2', type: 'income', title: 'Buyurtma', amount: 400000, paidBy: ME, date: dd(6),
      splits: [{ memberId: ME, share: 200000 }, { memberId: 'm2', share: 200000 }] }
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
    stock: [
      { id: 's1', itemId: 'i1', type: 'in',  qty: 100, price: 10000, date: o.d3, txId: null },
      { id: 's2', itemId: 'i1', type: 'out', qty: 60,  price: 15000, date: o.d7, txId: null },
      // o'tgan oydagi sotuv — bu oyning hisobotiga KIRMASIN
      { id: 's3', itemId: 'i1', type: 'out', qty: 10,  price: 99000, date: o.prev, txId: null }
    ]
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp, d3: dd(3), d7: dd(7), prev: PREV });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(1000);

const card = pg.locator('.card', { hasText: 'Birlashgan hisobot' });
must(await card.count() === 1, '«Birlashgan hisobot» kartasi bor');
let t = (await card.textContent()).replace(/\s+/g, ' ');

// ---------- ombor qismi: FIFO, faqat shu oy ----------
// 60 × 15 000 = 900 000 sotuv ; tannarx 60 × 10 000 = 600 000 ; foyda +300 000
must(/Sotuv\s*900 000/.test(t),                     'Sotuv 900 000 (o‘tgan oydagi sotuv kirmaydi)');
must(/Sotilganning tannarxi\s*600 000/.test(t),     'Tannarx 600 000 (FIFO: 60 × 10 000)');
must(/Foyda \(FIFO\)\s*\+300 000/.test(t),          'Ombor foydasi +300 000');
must(!/990 000/.test(t),                            'O‘tgan oyning 990 000 lik sotuvi aralashmagan');

// ---------- guruh qismi: mening ulushim ----------
must(/Tushum\s*200 000/.test(t),            'Guruh tushumi (ulushim) 200 000');
must(/Xarajat\s*300 000/.test(t),           'Guruh xarajati (ulushim) 300 000');
must(/Menga qaytariladi\s*100 000/.test(t), 'Menga qaytariladi 100 000');
must(/Men qaytaraman\s*0/.test(t),          'Men qaytaraman 0');

// ---------- umumiy natija ----------
// 300 000 (ombor) + (200 000 − 300 000) (guruh) = +200 000
must(/Umumiy natija \(ombor \+ guruh\)\s*\+200 000/.test(t), 'Umumiy natija +200 000');
must(await card.locator('[data-screen="ombor"]').count() === 1 &&
     await card.locator('[data-screen="groups"]').count() === 1, 'Ombor va Guruhlar tugmalari bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-hisobot.png' });

// ---------- boshqa oyga o'tsa, ombor raqamlari ham o'zgarsin ----------
await pg.click('[data-act="month"][data-d="-1"]'); await pg.waitForTimeout(500);
t = (await pg.locator('.card', { hasText: 'Birlashgan hisobot' }).textContent()).replace(/\s+/g, ' ');
must(/Sotuv\s*990 000/.test(t), 'O‘tgan oyda sotuv 990 000 (10 × 99 000)');
must(!/Sotuv\s*900 000/.test(t), 'Bu oyning sotuvi o‘tgan oyga qo‘shilmagan');
await pg.click('[data-act="month"][data-d="1"]'); await pg.waitForTimeout(500);

// ---------- ombor ham, guruh ham bo'lmasa karta chiqmasin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items = []; st.stock = []; st.groups = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.removeItem('birga_groups_cache');
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
must(!/Birlashgan hisobot/.test(await pg.locator('#screen').textContent()),
     'Ombor ham guruh ham bo‘lmasa karta chiqmaydi');

// ---------- faqat ombor bo'lsa: guruh qismi va umumiy natija chiqmasin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items = [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }];
  st.stock = [{ id: 's1', itemId: 'i1', type: 'in', qty: 5, price: 1000, date: st.transactions.length ? '' : new Date().toISOString().slice(0, 10), txId: null }];
  localStorage.setItem('birga_v1', JSON.stringify(st));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
t = await pg.locator('#screen').textContent();
must(/Birlashgan hisobot/.test(t), 'Faqat ombor bo‘lsa ham karta chiqadi');
must(!/Guruh · ulushingiz/.test(t), 'Guruh yo‘q — guruh bo‘limi chiqmaydi');
must(!/Umumiy natija/.test(t), 'Bitta tomon bo‘lsa «Umumiy natija» chiqmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
