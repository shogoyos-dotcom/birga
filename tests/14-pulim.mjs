import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1100 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Bulutsiz muhitda meId(g) '__me__' qaytaradi.
const ME = '__me__';
const now = new Date(), ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');

// Firma holati:
//   kassa: 5 000 000 ochilish − 1 000 000 tovar + 900 000 sotuv = 4 900 000
//   ombor: 100 kg olindi, 60 sotildi → 40 × 10 000 = 400 000
//   ishchi: 614 763 qarzdor
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Aziz', role: 'viewer', user_id: 'u2' }],
  expenses: [{ id: 'e1', type: 'expense', title: 'Qarz', amount: 614763, paidBy: ME, date: dd(10),
               splits: [{ memberId: 'm2', share: 614763 }] }],
  settlements: [], items: [], stock: []
};

await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Kassa', opening: 5000000 }],
    categories: [{ id: 'c1', name: 'Tovar', kind: 'expense' }, { id: 'c2', name: 'Sotuv', kind: 'income' }],
    transactions: [
      { id: 't1', accountId: 'a', categoryId: 'c1', amount: 1000000, type: 'expense', note: 'Shakar', date: o.d3 },
      { id: 't2', accountId: 'a', categoryId: 'c2', amount: 900000,  type: 'income',  note: 'Sotuv',  date: o.d7 }
    ],
    budget: { monthly: 0 }, groups: [o.g],
    items: [{ id: 'i1', name: 'Shakar', unit: 'kg', min: 0 }],
    stock: [{ id: 's1', itemId: 'i1', type: 'in',  qty: 100, price: 10000, date: o.d3, txId: 't1' },
            { id: 's2', itemId: 'i1', type: 'out', qty: 60,  price: 15000, date: o.d7, txId: 't2' }]
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp, d3: dd(3), d7: dd(7) });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(1000);

let t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');

// ---------- asosiy javob: pulim qancha ----------
must(/Pulim — naqd/.test(t), '«Pulim — naqd» kartasi bor');
must(/Pulim — naqd ?4 900 000/.test(t), 'Naqd 4 900 000 = 5 000 000 − 1 000 000 + 900 000');
// eng tepada turishi kerak — oylik natijadan oldin
must(t.indexOf('Pulim') < t.indexOf('Bu oy sof natija'), 'Oylik natijadan TEPADA turadi');

// ---------- tarkibi ----------
must(/Ombordagi tovar\s*400 000/.test(t),   'Ombordagi tovar 400 000 (40 kg × 10 000)');
must(/Menga qaytariladi\s*614 763/.test(t), 'Menga qaytariladi 614 763');
must(/Sof boylik\s*\+5 914 763/.test(t),    'Sof boylik 5 914 763 = 4 900 000 + 400 000 + 614 763');
must(/naqd pulga ta‘sir qilmaydi/.test(t),  'Guruh pulining kassaga tegmasligi haqida eslatma bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/p-pulim.png' });

// ---------- qarzdor tomon ham to'g'ri ishorada bo'lsin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  const g = st.groups[0];
  // endi MEN qarzdorman: Aziz to'lagan, ulush menga
  g.expenses = [{ id: 'e2', type: 'expense', title: 'Qarz', amount: 200000, paidBy: 'm2',
                  date: g.expenses[0].date, splits: [{ memberId: '__me__', share: 200000 }] }];
  st.groups = [g];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.setItem('birga_groups_cache', JSON.stringify([g]));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/Men qaytaraman\s*−200 000/.test(t), 'Qarzim manfiy ishora bilan: −200 000');
must(/Sof boylik\s*\+5 100 000/.test(t),  'Sof boylik 5 100 000 = 4 900 000 + 400 000 − 200 000');

// ---------- ombor va guruh bo'lmasa faqat naqd qolsin ----------
await pg.evaluate(() => {
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.items = []; st.stock = []; st.groups = [];
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.removeItem('birga_groups_cache');
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/Pulim — naqd ?4 900 000/.test(t), 'Naqd baribir ko‘rinadi');
must(!/Sof boylik/.test(t), 'Boshqa narsa bo‘lmasa «Sof boylik» qatori chiqmaydi');
must(!/naqd pulga ta‘sir qilmaydi/.test(t), 'Guruh yo‘q — eslatma ham yo‘q');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
