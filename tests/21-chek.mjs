// «Chek» rejimi: taomlar ro'yxati, kim nimani yegani, xizmat haqi
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1800 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });
await pg.route('**/index.html*', async r0 => {
  const res = await r0.fetch();
  await r0.fulfill({ response: res, body: (await res.text()).replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1'," )});
});
await pg.route('**/supabase*.js', r => r.abort());

const ME = '__me__';
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME,   name: 'Izzat',    role: 'owner',  user_id: 'u1' },
            { id: 'm2', name: 'Etiketka', role: 'editor', user_id: 'u2' },
            { id: 'm3', name: 'SHO',      role: 'editor', user_id: 'u3' },
            { id: 'm4', name: 'Ismoil',   role: 'editor', user_id: 'u4' }],
  expenses: [], settlements: [], items: [], stock: [], notes: []
};
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Izzat' },
    accounts: [{ id: 'a', name: 'Kassa', opening: 0 }],
    categories: [], transactions: [], budget: { monthly: 0 }, groups: [o.g], items: [], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
await pg.click('#fab'); await pg.waitForTimeout(600);
must(await pg.locator('#modal [data-m="bill"]').count() === 1, '«Chek» rejimi tugmasi bor');
await pg.click('#modal [data-m="bill"]'); await pg.waitForTimeout(500);
must(await pg.locator('#modal .bill-line').count() === 1, 'Bitta bo‘sh qator bilan ochiladi');
must(await pg.locator('#modal .bill-who button[aria-pressed="true"]').count() === 4,
     'Sukut bo‘yicha hamma belgilangan');

const stat = async () => (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
const calcs = async () => (await pg.locator('#modal .split-list .calc').allTextContents()).map(x => x.replace(/\s+/g, ' ').trim());
const amtVal = () => pg.locator('#modal #eamt').inputValue();
must(/Taomlarni yozing/.test(await stat()), 'Bo‘sh holatda nima qilish kerakligi yozilgan');

// ---- haqiqiy chek: OQ SAROY, 27.11.2026 ----
const L = [
  ['NON',             12000,  null],                          // hammasi
  ['SVEJEE ASSORTI',  25000,  ['Etiketka', 'Ismoil']],         // bularni olib tashlaymiz
  ['KIYMA',           40000,  ['Izzat', 'Etiketka', 'SHO']],
  ['NOHOTSHURAK',     54000,  ['Etiketka', 'SHO', 'Ismoil']],
  ['ASSORTI OQSAROY', 104000, null],
  ['NORIN S KAZI',    45000,  ['Izzat', 'Etiketka']],
  ['SHIFOI JAHON',    70000,  null],
  ['CHOY KORA',       10000,  null]
];
for (let i = 0; i < L.length; i++) {
  if (i) { await pg.click('#modal [data-bact="add"]'); await pg.waitForTimeout(150); }
  await pg.fill(`#modal .bname[data-i="${i}"]`, L[i][0]);
  await pg.fill(`#modal .bamt[data-i="${i}"]`, String(L[i][1]));
  if (L[i][2]) for (const nm of L[i][2]) {
    await pg.click(`#modal .bill-line >> nth=${i} >> .bill-who button:text-is("${nm}")`);
  }
  await pg.waitForTimeout(100);
}
must(await pg.locator('#modal .bill-line').count() === 8, '8 ta qator');
must(await amtVal() === '360000', 'Xizmat haqisiz summa o‘zi to‘ldi: 360 000 · ' + await amtVal());

await pg.fill('#modal #bsvc', '10'); await pg.waitForTimeout(500);
must(await amtVal() === '396000', 'Xizmat 10% bilan: 396 000 · ' + await amtVal());
let st = await stat();
must(/8 ta qator/.test(st) && /360 000/.test(st) && /xizmat 10% = 396 000/.test(st), 'Holat qatori: ' + st);

// NON 12 000 ni 4 ga: har biriga 3 000; KIYMA 40 000 faqat Ismoilga; …
let c = await calcs();
must(/^127 050/.test(c[0]), 'Izzat 127 050 · ' + c[0]);
must(/^53 900/.test(c[1]),  'Etiketka 53 900 · ' + c[1]);
must(/^92 400/.test(c[2]),  'SHO 92 400 · ' + c[2]);
must(/^122 650/.test(c[3]), 'Ismoil 122 650 · ' + c[3]);
let out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(out.reduce((a, x) => a + x.share, 0) === 396000, 'Ulushlar yig‘indisi aynan 396 000 — tiyin yo‘qolmaydi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/c-chek.png' });

// ---- qatorni o'chirish ----
await pg.click('#modal .bill-line >> nth=4 >> .bill-x'); await pg.waitForTimeout(400);
must(await pg.locator('#modal .bill-line').count() === 7, 'Qator o‘chdi');
must(await amtVal() === String(Math.round((360000 - 104000) * 1.1)), 'Summa qayta hisoblandi: ' + await amtVal());

// ---- «hammasi» tugmasi ----
await pg.click('#modal .bill-line >> nth=1 >> .bill-who .all'); await pg.waitForTimeout(300);
must(await pg.locator('#modal .bill-line').nth(1).locator('.bill-who button[aria-pressed="true"]').count() === 4,
     '«hammasi» hammani belgilaydi');
await pg.click('#modal .bill-line >> nth=1 >> .bill-who .all'); await pg.waitForTimeout(300);
must(await pg.locator('#modal .bill-line').nth(1).locator('.bill-who button[aria-pressed="true"]').count() === 0,
     'Yana bosilsa hammasi olinadi');
// hech kim belgilanmagan qator — baribir hammaga teng tegadi
c = await calcs();
must(c.every(x => !/^0/.test(x)), 'Hech kim belgilanmagan qator hammaga teng bo‘linadi');

// ---- kalkulyator qator maydonida ----
await pg.fill('#modal .bamt[data-i="0"]', '2*6000'); await pg.waitForTimeout(400);
await pg.locator('#modal .bname[data-i="0"]').click(); await pg.waitForTimeout(300);
must(await pg.locator('#modal .bamt[data-i="0"]').inputValue() === '12000',
     'Qator narxida ham kalkulyator: 2*6000 → 12000');

// ---- summani qo'lda boshqacha yozsa — chek nisbatida bo'linadi ----
await pg.fill('#modal #eamt', '300000'); await pg.waitForTimeout(400);
st = await stat();
must(/nisbat bo‘yicha bo‘linadi/.test(st), 'Qo‘lda boshqa summa — nisbat saqlanadi: ' + st);
out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(out.reduce((a, x) => a + x.share, 0) === 300000, 'Yangi summa ham to‘liq bo‘linadi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
