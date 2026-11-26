// «Teng» rejimida shaxsiy qo'shimcha:
//   69 000 dan 7 000 Izzatniki, qolgan 62 000 Izzat bilan SHO ga teng
//   → Izzat 38 000, SHO 31 000
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1000 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// guruh egasi sifatida ishlash uchun SB_UID ni o'rnatamiz
await pg.route('**/index.html*', async route => {
  const res = await route.fetch();
  const body = (await res.text()).replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1',");
  await route.fulfill({ response: res, body });
});
await pg.route('**/supabase*.js', r => r.abort());

const ME = '__me__';
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME,   name: 'Izzat',    role: 'owner',  user_id: 'u1' },
            { id: 'm2', name: 'Etiketka', role: 'editor', user_id: 'u2' },
            { id: 'm3', name: 'SHO',      role: 'editor', user_id: 'u3' },
            { id: 'm4', name: 'Ismoil',   role: 'editor', user_id: 'u4' }],
  expenses: [], settlements: [], items: [], stock: []
};

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Izzat' },
    accounts: [{ id: 'a', name: 'Kassa', opening: 0 }],
    categories: [{ id: 'c1', name: 'Oziq-ovqat', kind: 'expense' }],
    transactions: [], budget: { monthly: 0 }, groups: [o.g], items: [], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
await pg.click('#fab'); await pg.waitForTimeout(600);
must(await pg.locator('#modal #mseg').count() === 1, 'Guruh amaliyoti oynasi ochildi');

await pg.fill('#modal input[name="title"]', 'Inbazar');
await pg.fill('#modal #eamt', '69000');
await pg.waitForTimeout(400);

const chk = pg.locator('#modal .pcheck');
const own = pg.locator('#modal .xinput');
const calcs = async () => (await pg.locator('#modal .calc').allTextContents()).map(x => x.replace(/\s+/g, ' ').trim());
const stat = async () => (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');

must(await own.count() === 4, '«Teng» da har a‘zoda shaxsiy summa maydoni bor');
must(await own.first().getAttribute('placeholder') === '+ shaxsiy', 'Maydon nima uchunligi yozilgan');

// faqat Izzat va SHO qatnashadi
await chk.nth(1).uncheck(); await chk.nth(3).uncheck(); await pg.waitForTimeout(300);
let c = await calcs();
must(/34 500/.test(c[0]) && /34 500/.test(c[2]), 'Shaxsiysiz — avvalgidek teng: 34 500 / 34 500');

// endi 7 000 Izzatniki
await own.nth(0).fill('7000'); await pg.waitForTimeout(400);
c = await calcs();
must(/^38 000/.test(c[0]), 'Izzat = 7 000 + 31 000 = 38 000 · chiqdi: ' + c[0]);
must(/^31 000/.test(c[2]), 'SHO = 31 000 · chiqdi: ' + c[2]);
must(/^0/.test(c[1]) && /^0/.test(c[3]), 'Qatnashmaganlarga 0');

let st = await stat();
must(/Shaxsiy summa 7 000/.test(st) && /qolgan 62 000/.test(st) && /2 kishiga teng/.test(st)
     && /31 000/.test(st), 'Holat qatori hisobni tushuntiradi: ' + st);

let out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(JSON.stringify(out) === JSON.stringify([{ memberId: '__me__', share: 38000 },
                                             { memberId: 'm3', share: 31000 }]),
     'Saqlanadigan ulushlar: ' + JSON.stringify(out));
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-shaxsiy.png' });

// shaxsiy maydonda ham kalkulyator ishlasin
await own.nth(0).fill('3000+4000'); await pg.waitForTimeout(400);
c = await calcs();
must(/^38 000/.test(c[0]), 'Shaxsiy maydonda ifoda ham hisoblanadi: 3000+4000 → 38 000');

// ikki kishida shaxsiy
await own.nth(2).fill('5000'); await pg.waitForTimeout(400);
c = await calcs();
// 69 000 − 12 000 = 57 000 → 28 500 har biriga
must(/^35 500/.test(c[0]) && /^33 500/.test(c[2]),
     'Ikkovida ham shaxsiy: 7 000+28 500 = 35 500, 5 000+28 500 = 33 500 · ' + c[0] + ' / ' + c[2]);

// hech kim belgilanmasa — shaxsiysi borlar baribir yoziladi
await chk.nth(0).uncheck(); await chk.nth(2).uncheck(); await pg.waitForTimeout(400);
st = await stat();
must(/Shaxsiy summa 12 000/.test(st) && /to‘lovchida qoladi/.test(st),
     'Hech kim belgilanmasa qolgani to‘lovchida qolishi aytiladi: ' + st);
out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(JSON.stringify(out) === JSON.stringify([{ memberId: '__me__', share: 7000 },
                                             { memberId: 'm3', share: 5000 }]),
     'Faqat shaxsiy summalar yoziladi: ' + JSON.stringify(out));

// shaxsiy summalar umumiy summadan oshsa — saqlanmaydi
await own.nth(0).fill('80000'); await pg.waitForTimeout(400);
st = await stat();
must(/oshib ketdi/.test(st), 'Oshib ketgani aytiladi: ' + st);
must(await pg.evaluate(() => document.getElementById('modal')._readSplits()) === null,
     'Oshib ketsa saqlanmaydi');

// tozalab — yana to'g'ri holatga qaytadi
await own.nth(0).fill('7000'); await own.nth(2).fill('');
await chk.nth(0).check(); await chk.nth(2).check(); await pg.waitForTimeout(400);
out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(JSON.stringify(out) === JSON.stringify([{ memberId: '__me__', share: 38000 },
                                             { memberId: 'm3', share: 31000 }]),
     'Tuzatilgandan keyin yana 38 000 / 31 000: ' + JSON.stringify(out));

// boshqa rejimga o'tib qaytsa — shaxsiy maydon tozalanadi, eski xulq saqlanadi
await pg.click('#modal [data-m="pct"]'); await pg.waitForTimeout(300);
await pg.click('#modal [data-m="equal"]'); await pg.waitForTimeout(400);
must((await pg.locator('#modal .xinput').first().inputValue()) === '', 'Rejim almashsa shaxsiy maydon tozalanadi');
st = await stat();
must(/4 kishi teng — har biriga 17 250/.test(st), 'Shaxsiysiz holat avvalgidek: ' + st);

// ================= «NIMA UCHUN» MAJBURIY EMAS =================
must((await pg.locator('#modal label', { hasText: 'Nima uchun' }).first().textContent()).includes('ixtiyoriy'),
     '«Nima uchun» yorlig‘ida «ixtiyoriy» yozilgan');
// nomsiz amaliyot — ro'yxatda kategoriya nomi ko'rinsin
await pg.evaluate(() => {
  const s = JSON.parse(localStorage.getItem('birga_v1'));
  s.groups[0].expenses = [
    { id:'e1', type:'expense', title:'',  amount:50000, date:'2026-11-26', paidBy:'__me__',
      categoryName:'Oziq-ovqat', splits:[{memberId:'__me__', share:50000}] },
    { id:'e2', type:'income',  title:'',  amount:30000, date:'2026-11-26', paidBy:'m2',
      categoryName:'', splits:[{memberId:'m2', share:30000}] }
  ];
  localStorage.setItem('birga_v1', JSON.stringify(s));
  localStorage.setItem('birga_groups_cache', JSON.stringify(s.groups));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
let gt = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/Oziq-ovqat/.test(gt), 'Nomsiz xarajat kategoriya nomi bilan ko‘rinadi: ' + gt.slice(0, 80));
must(/Tushum/.test(gt), 'Kategoriyasi ham yo‘q bo‘lsa — turi ko‘rinadi («Tushum»)');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-nomsiz.png' });

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
