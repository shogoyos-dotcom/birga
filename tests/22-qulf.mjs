// Qulf: PIN kod, grafik kalit (chizib ham, bosib ham), fonda turgach qayta so'rash
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1200 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });
await pg.route('**/supabase*.js', r => r.abort());

const locked = async () => (await pg.locator('#lockscreen').getAttribute('hidden')) === null;
const sub = async () => (await pg.locator('#lockscreen #lksub').textContent()).replace(/\s+/g, ' ');

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(800);
must(!(await locked()), 'Qulf qo‘yilmagan — ilova darrov ochiladi');

// ================= PIN =================
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(500);
must(await pg.locator('[data-act="lock-set"]').count() === 1, 'Profilda «Qulf» kartasi bor');
await pg.click('[data-act="lock-set"]'); await pg.waitForTimeout(400);
must((await pg.locator('#modal [data-lk]').allTextContents()).join('|') === 'PIN kod|Grafik kalit',
     'Ikki xil qulf taklif qilinadi');
await pg.click('#modal [data-lk="pin"]'); await pg.waitForTimeout(400);
const mk = n => pg.locator(`#modal .lk-pad button[data-k="${n}"]`);
must(await pg.locator('#modal .lk-pad button').count() === 12, 'Raqam klaviaturasi: 0–9, ⌫, OK');
await mk('1').click(); await mk('2').click(); await mk('3').click();
await mk('ok').click(); await pg.waitForTimeout(300);
must(/Kamida 4 raqam/.test(await pg.locator('#modal #lkmsg').textContent()), '3 raqamga rozi bo‘lmaydi');
await mk('4').click();
await mk('ok').click(); await pg.waitForTimeout(300);
must(/Yana bir marta/.test(await pg.locator('#modal #lkmsg').textContent()), 'Ikkinchi marta so‘raydi');
// mos kelmasa
for (const d of '9999') await mk(d).click();
await mk('ok').click(); await pg.waitForTimeout(300);
must(/Mos kelmadi/.test(await pg.locator('#modal #lkmsg').textContent()), 'Mos kelmasa boshidan');
// to'g'ri
for (const d of '1234') await mk(d).click(); await mk('ok').click(); await pg.waitForTimeout(300);
let alerted = '';
pg.once('dialog', d => { alerted = d.message(); d.accept(); });
for (const d of '1234') await mk(d).click(); await mk('ok').click(); await pg.waitForTimeout(700);
must(/Qulf qo‘yildi/.test(alerted), 'Qo‘yilgani aytiladi');
const cfg = JSON.parse(await pg.evaluate(() => localStorage.getItem('birga_lock')));
must(cfg.kind === 'pin' && cfg.len === 4, 'PIN va uzunligi saqlandi');
must(!/1234/.test(JSON.stringify(cfg)) && cfg.hash.length === 64,
     'Kod ochiq saqlanmaydi — SHA-256 va tuz');

// qayta ochganda so'raydi
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
must(await locked(), 'Qayta ochilganda qulf chiqadi');
must(await pg.locator('#lockscreen .lk-dots i').count() === 4, 'Nuqtalar soni PIN uzunligicha');
const lk = n => pg.locator(`#lockscreen .lk-pad button[data-k="${n}"]`);
for (const d of '9999') await lk(d).click(); await pg.waitForTimeout(500);
must(/Noto‘g‘ri/.test(await sub()), 'Noto‘g‘ri kod rad etiladi: ' + await sub());
must(await locked(), 'Qulf ochilmaydi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/q-pin.png' });
for (const d of '1234') await lk(d).click(); await pg.waitForTimeout(700);
must(!(await locked()), 'To‘g‘ri kodda ochiladi — OK bosish shart emas');
must(await pg.locator('#screen .card').count() > 0, 'Ilova ishlayapti');

// ================= GRAFIK KALIT =================
await pg.evaluate(() => localStorage.removeItem('birga_lock'));
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(700);
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
await pg.click('[data-act="lock-set"]'); await pg.waitForTimeout(400);
await pg.click('#modal [data-lk="pattern"]'); await pg.waitForTimeout(400);
must(await pg.locator('#modal .lk-grid circle.d').count() === 9, '3×3 nuqta');

// chizib kiritish (telefonda shunday bo'ladi)
async function swipe(sel, idx) {
  const boxes = [];
  for (const i of idx) boxes.push(await pg.locator(`${sel} .lk-grid circle.hit[data-i="${i}"]`).boundingBox());
  await pg.mouse.move(boxes[0].x + boxes[0].width / 2, boxes[0].y + boxes[0].height / 2);
  await pg.mouse.down();
  for (let k = 1; k < boxes.length; k++)
    await pg.mouse.move(boxes[k].x + boxes[k].width / 2, boxes[k].y + boxes[k].height / 2, { steps: 6 });
  await pg.mouse.up();
  await pg.waitForTimeout(400);
}
await swipe('#modal', [0, 1, 2, 4, 6]);
must(/Yana bir marta chizing/.test(await pg.locator('#modal #lkmsg').textContent()), 'Chizib kiritish ishlaydi');
pg.once('dialog', d => d.accept());
await swipe('#modal', [0, 1, 2, 4, 6]); await pg.waitForTimeout(600);
must((await pg.evaluate(() => localStorage.getItem('birga_lock'))) !== null, 'Grafik kalit saqlandi');

await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
must(await locked() && await pg.locator('#lockscreen .lk-grid').count() === 1, 'Qulfda chizish maydoni chiqadi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/q-grafik.png' });
await swipe('#lockscreen', [2, 1, 0]);
must(await locked(), 'Boshqa shakl ochmaydi');
await swipe('#lockscreen', [0, 1, 2, 4, 6]);
must(!(await locked()), 'To‘g‘ri shakl ochadi');

// nuqtalarni birma-bir bosib ham bo'ladi
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
for (const i of [0, 1, 2, 4, 6]) await pg.locator(`#lockscreen .lk-grid circle.hit[data-i="${i}"]`).click({ force: true });
must(await pg.locator('#lockscreen .lk-grid circle.d.on').count() === 5, 'Bosilgan nuqtalar belgilanadi');
await pg.click('#lockscreen [data-grid-ok]'); await pg.waitForTimeout(600);
must(!(await locked()), 'Birma-bir bosib ham ochiladi («Tayyor»)');

// ================= O'CHIRISH =================
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="lock-off"]').count() === 1, 'Qulfni o‘chirish tugmasi bor');
pg.once('dialog', d => d.accept());
await pg.click('[data-act="lock-off"]'); await pg.waitForTimeout(500);
must((await pg.evaluate(() => localStorage.getItem('birga_lock'))) === null, 'Qulf o‘chdi');
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(700);
must(!(await locked()), 'Endi so‘ramaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
