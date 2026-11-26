import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';

const log = [];
let fails = 0;
const must = (c, m) => { log.push((c ? '✓ ' : '✗ FAIL ') + m); if (!c) fails++; };

const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 780 } });
const errs = [];
pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(800);

const tabs = await pg.$$eval('.tab', els => els.map(e => e.textContent.trim()));
must(tabs.length === 5 && tabs.some(t => /Ombor/.test(t)), 'Tabbarda 5 bo\'lim, Ombor bor: ' + tabs.join(' | '));

await pg.click('[data-screen="ombor"]');
await pg.waitForTimeout(250);
must(await pg.locator('text=Ombor bo‘sh').count() > 0, 'Bo\'sh ombor holati ko\'rinadi');

await pg.click('button[data-act="add-item"]');
await pg.waitForTimeout(200);
await pg.fill('input[name="name"]', 'Shakar');
await pg.selectOption('select[name="unit"]', 'kg');
await pg.fill('input[name="min"]', '10');
await pg.click('button[type="submit"]');
await pg.waitForTimeout(300);
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350);
must(await pg.locator('.row .t', { hasText: 'Shakar' }).count() > 0, 'Tovar qo\'shildi, Tovarlar ro\'yxatida ko\'rinadi');
await pg.click('.back-btn'); await pg.waitForTimeout(300);

await pg.click('#fab');
await pg.waitForTimeout(200);
await pg.fill('input[name="qty"]', '50');
await pg.fill('input[name="price"]', '12000');
await pg.check('input[name="kassa"]');
await pg.waitForTimeout(150);
must(await pg.locator('#maccf').isVisible(), 'Kassa belgilansa hisob maydoni chiqadi');
await pg.click('form button[type="submit"]');
await pg.waitForTimeout(400);

let st = await pg.evaluate(() => JSON.parse(localStorage.getItem('birga_v1')));
must(st.stock.length === 1 && st.stock[0].qty === 50 && st.stock[0].type === 'in', 'Prihod saqlandi: 50 kg');
const inTx = st.transactions.filter(t => t.id === st.stock[0].txId)[0];
must(!!inTx && inTx.type === 'expense' && inTx.amount === 600000, 'Kassaga chiqim yozildi: 600 000 (50x12000)');
must(st.categories.some(c => c.id === 'c_tovar'), 'Tovar kategoriyasi avtomatik yaratildi');
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350);
must(await pg.locator('text=50 kg').count() > 0, 'Tovarlar ro\'yxatida qoldiq 50 kg');

if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]');
await pg.waitForTimeout(300);
must(/50 kg/.test(await pg.locator('.balance-hero .big').textContent()), 'Tovar ekranida qoldiq 50 kg');

await pg.click('[data-act="add-move"][data-t="out"]');
await pg.waitForTimeout(200);
await pg.fill('input[name="qty"]', '45');
await pg.fill('input[name="price"]', '16000');
await pg.check('input[name="kassa"]');
await pg.click('form button[type="submit"]');
await pg.waitForTimeout(400);

st = await pg.evaluate(() => JSON.parse(localStorage.getItem('birga_v1')));
const outMove = st.stock.filter(m => m.type === 'out')[0];
const outTx = st.transactions.filter(t => t.id === outMove.txId)[0];
must(!!outTx && outTx.type === 'income' && outTx.amount === 720000, 'Rasxod kassaga kirim bo\'ldi: 720 000 (45x16000)');
must(/5 kg/.test(await pg.locator('.balance-hero .big').textContent()), 'Qoldiq 5 kg (50-45)');
must(await pg.locator('text=Qoldiq eng kam chegaradan past').count() > 0, 'Kam qoldiq ogohlantirishi chiqdi');

await pg.click('[data-screen="ombor"]');
await pg.waitForTimeout(250);
must(await pg.locator('text=Kam qolgan').count() > 0, 'Ombor ekranida «Kam qolgan» hisobi bor');

await pg.click('[data-screen="tx"]');
await pg.waitForTimeout(300);
const txt = await pg.locator('#screen').textContent();
must(/Shakar/.test(txt) && /prihod/.test(txt) && /rasxod/.test(txt), 'Kassa yozuvlari Amaliyotlar ro\'yxatida ko\'rinadi');

await pg.click('[data-screen="ombor"]');
await pg.waitForTimeout(200);
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]');
await pg.waitForTimeout(250);
await pg.click('.row[data-act="move-view"]');   // avval ma'lumot oynasi
await pg.waitForTimeout(250);
// qaysi harakat ochilganini modaldagi tugmadan aniqlaymiz
const delId = await pg.getAttribute('[data-act="del-move"]', 'data-id');
const delMove = st.stock.filter(m => m.id === delId)[0];
must(!!delMove && !!delMove.txId, 'O\'chiriladigan harakat kassaga bog\'langan (' + (delMove && delMove.type) + ')');
pg.once('dialog', d => d.accept());
await pg.click('[data-act="del-move"]');
await pg.waitForTimeout(400);
st = await pg.evaluate(() => JSON.parse(localStorage.getItem('birga_v1')));
must(st.stock.length === 1 && st.stock.filter(m => m.id === delId).length === 0, 'Harakat o\'chirildi');
must(st.transactions.filter(t => t.id === delMove.txId).length === 0, 'O\'chirilgan harakatning kassa yozuvi ham o\'chdi');
const keep = st.stock[0];
must(st.transactions.filter(t => t.id === keep.txId).length === 1, 'Qolgan harakatning kassa yozuvi tegilmadi');

await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(700);
await pg.click('[data-screen="ombor"]');
await pg.waitForTimeout(300);
must(await pg.locator('text=Shakar').count() > 0, 'Qayta yuklangandan keyin ma\'lumot joyida');

for (const [sc, marker] of [['home', 'Asosiy'], ['groups', 'Guruhlar'], ['profil', 'Hisoblar']]) {
  await pg.click(`[data-screen="${sc}"]`);
  await pg.waitForTimeout(250);
  const t = await pg.locator('#screen').textContent();
  must(t.includes(marker) && !/Xatolik:/.test(t), `«${sc}» ekrani ishlayapti`);
}

must(errs.length === 0, 'Sahifada JS xatosi yo\'q' + (errs.length ? ': ' + errs.slice(0, 3).join(' / ') : ''));

await pg.click('[data-screen="ombor"]');
await pg.waitForTimeout(300);
await pg.screenshot({ path: (process.argv[2] || '.') + '/ombor.png' });
if (await pg.locator('[data-act="nav"][data-screen="items"]').count()) { await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(350); }
await pg.click('.row[data-act="open-item"]');
await pg.waitForTimeout(300);
await pg.screenshot({ path: (process.argv[2] || '.') + '/tovar.png' });

await b.close();
console.log(log.join('\n'));
console.log('\n' + (fails ? fails + ' TA TEST YIQILDI' : 'HAMMA TEST O\'TDI (' + log.length + ' ta)'));
process.exit(fails ? 1 : 0);
