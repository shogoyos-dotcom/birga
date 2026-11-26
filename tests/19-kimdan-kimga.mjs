// «Kimdan / kimga» (ta'minotchi va klient) + Harakatlar hisoboti filtri
// va tahrirlashdan «Kassaga ham yozilsin».
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1400 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });
await pg.route('**/supabase*.js', r => r.abort());

const ym = new Date().toISOString().slice(0, 7);
const d = n => ym + '-' + String(n).padStart(2, '0');

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Kassa', opening: 0 }, { id: 'b', name: 'Karta', opening: 0 }],
  categories: [], transactions: [], budget: { monthly: 0 }, groups: [],
  items: [{ id: 'i1', name: '17*17', unit: 'dona', min: 0 },
          { id: 'i2', name: 'Qog‘oz', unit: 'quti', min: 0 }],
  stock: [
    { id:'s1', itemId:'i1', type:'in',  qty:220000, price:6,     date:o.d24, note:'',     party:'Inbazar',  txId:null },
    { id:'s2', itemId:'i1', type:'out', qty:100000, price:9,     date:o.d25, note:'',     party:'Shox aka', txId:null },
    { id:'s3', itemId:'i2', type:'in',  qty:10,     price:50000, date:o.d26, note:'tez',  party:'Ali',      txId:null }
  ]
})), { d24: d(4), d25: d(5), d26: d(6) });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

// ================= HARAKATLAR EKRANI =================
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-screen="moves"]').count() === 1, 'Ombor ekranida «Harakatlar» tugmasi bor');
await pg.click('[data-screen="moves"]'); await pg.waitForTimeout(500);

const rows = () => pg.locator('[data-act="edit-move"]');
const stat = async () => (await pg.locator('.card').first().textContent()).replace(/\s+/g, ' ');
must(await rows().count() === 3, 'Uchala harakat ham ro‘yxatda');
let st = await stat();
must(/Jami prihod\s*1 820 000/.test(st), 'Jami prihod 1 320 000 + 500 000 = 1 820 000: ' + st);
must(/Sotuv \(rasxod\)\s*900 000/.test(st), 'Sotuv 900 000');
must(/Foyda \(FIFO\)\s*\+300 000/.test(st), 'Foyda (FIFO) +300 000 (100 000 × (9 − 6))');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-harakatlar.png' });

// --- tovar bo'yicha ---
await pg.selectOption('#mvitem', 'i2'); await pg.waitForTimeout(400);
must(await rows().count() === 1, 'Tovar bo‘yicha filtr: Qog‘oz — 1 ta');
must(/Jami prihod\s*500 000/.test(await stat()), 'Faqat Qog‘ozning prihodi');
await pg.selectOption('#mvitem', ''); await pg.waitForTimeout(400);
must(await rows().count() === 3, 'Filtr olib tashlandi');

// --- ta'minotchi bo'yicha ---
must((await pg.locator('#mvsup option').allTextContents()).join('|') === 'Hamma ta‘minotchi|Ali|Inbazar',
     'Ta‘minotchilar ro‘yxati faqat prihoddan, yangisidan eskisiga');
must((await pg.locator('#mvcli option').allTextContents()).join('|') === 'Hamma klient|Shox aka',
     'Klientlar ro‘yxati faqat rasxoddan');
await pg.selectOption('#mvsup', 'Inbazar'); await pg.waitForTimeout(400);
must(await rows().count() === 1, 'Ta‘minotchi bo‘yicha: Inbazar — 1 ta');
must(/Harakatlar soni\s*1/.test(await stat()), 'Jami ham filtrga qarab hisoblanadi');

// --- klient tanlansa ta'minotchi tozalanadi ---
await pg.selectOption('#mvcli', 'Shox aka'); await pg.waitForTimeout(400);
must(await pg.locator('#mvsup').inputValue() === '', 'Klient tanlansa ta‘minotchi tozalanadi');
must(await rows().count() === 1, 'Klient bo‘yicha: Shox aka — 1 ta');
must(/Sotuv \(rasxod\)\s*900 000/.test(await stat()), 'Shox akaga sotilgani 900 000');
await pg.selectOption('#mvcli', ''); await pg.waitForTimeout(400);

// --- davr bo'yicha ---
must(await pg.locator('[data-act="repper"]').count() === 3, 'Oy / Yil / Davr tugmalari bor');
await pg.click('[data-act="repper"][data-p="year"]'); await pg.waitForTimeout(400);
must(await rows().count() === 3, 'Yil bo‘yicha ham uchalasi');
await pg.click('[data-act="repper"][data-p="month"]'); await pg.waitForTimeout(400);

// ================= TAHRIRLASH: KASSAGA HAM YOZILSIN =================
await pg.locator('[data-act="edit-move"]').last().click();   // eng eskisi: Inbazar prihodi
await pg.waitForTimeout(600);
must(await pg.locator('#modal select[name="party"]').inputValue() === 'Inbazar',
     'Tahrirlashda ta‘minotchi tanlangan turadi');
must((await pg.locator('#modal #mpartyl').textContent()) === 'Kimdan (ta‘minotchi)',
     'Prihodda yorliq «Kimdan (ta‘minotchi)»');
must(await pg.locator('#modal input[name="kassa"]').count() === 1,
     'Tahrirlash oynasida «Kassaga ham yozilsin» bor');
must(await pg.locator('#modal input[name="kassa"]').isChecked() === false, 'Hozircha kassaga yozilmagan');

// pulni endi to'ladik — belgilaymiz
await pg.locator('#modal input[name="kassa"]').check(); await pg.waitForTimeout(300);
must(await pg.locator('#modal select[name="accountId"]').count() === 1, 'Hisob tanlagich ochiladi');
await pg.selectOption('#modal select[name="accountId"]', { label: 'Karta' });
must(/1 320 000/.test(await pg.locator('#modal #mhint').textContent()), 'Qancha yozilishi aytiladi');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(700);

const after = await pg.evaluate(() => {
  const s = JSON.parse(localStorage.getItem('birga_v1'));
  const m = s.stock.filter(x => x.id === 's1')[0];
  const t = s.transactions.filter(x => x.id === m.txId)[0];
  return { party: m.party, txId: !!m.txId, tx: t && { amount: t.amount, type: t.type, accountId: t.accountId } };
});
must(after.party === 'Inbazar', 'Ta‘minotchi saqlanib qoldi');
must(after.txId, 'Harakat kassadagi amaliyotga bog‘landi');
must(JSON.stringify(after.tx) === JSON.stringify({ amount: 1320000, type: 'expense', accountId: 'b' }),
     'Kassaga 1 320 000 chiqim, Karta hisobiga: ' + JSON.stringify(after.tx));
must(/kassada/.test(await rows().last().textContent()), 'Ro‘yxatda «kassada» deb turadi');

// ================= YANGI TA'MINOTCHI OCHISH =================
await pg.click('#fab'); await pg.waitForTimeout(600);
const psel = pg.locator('#modal select[name="party"]');
must((await psel.locator('option').allTextContents()).join('|') === '— yo‘q —|Ali|Inbazar|+ Yangi…',
     'Yangi harakatda ro‘yxat + «Yangi…» turadi');
must(await pg.locator('#modal input[name="partyNew"]').isVisible() === false, 'Yangi nom maydoni yashirin');
await psel.selectOption('__new'); await pg.waitForTimeout(300);
must(await pg.locator('#modal input[name="partyNew"]').isVisible(), '«Yangi…» tanlansa maydon ochiladi');
await pg.fill('#modal input[name="partyNew"]', 'Yangi zavod');

// rasxodga o'tsa — klientlar ro'yxati
await pg.click('#modal [data-t="out"]'); await pg.waitForTimeout(300);
must((await pg.locator('#modal #mpartyl').textContent()) === 'Kimga (klient)', 'Rasxodda yorliq «Kimga (klient)»');
must((await psel.locator('option').allTextContents()).join('|') === '— yo‘q —|Shox aka|+ Yangi…',
     'Rasxodda klientlar ro‘yxati chiqadi');
await pg.click('#modal [data-t="in"]'); await pg.waitForTimeout(300);

await psel.selectOption('__new'); await pg.waitForTimeout(200);
await pg.fill('#modal input[name="partyNew"]', 'Yangi zavod');
await pg.fill('#modal input[name="qty"]', '5');
await pg.fill('#modal input[name="price"]', '1000');
await pg.fill('#modal input[name="note"]', 'sinov');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(700);

const made = await pg.evaluate(() => {
  const s = JSON.parse(localStorage.getItem('birga_v1'));
  const m = s.stock[s.stock.length - 1];
  return { party: m.party, note: m.note, qty: m.qty };
});
must(made.party === 'Yangi zavod', 'Yangi ta‘minotchi saqlandi: ' + made.party);
must(made.note === 'sinov', 'Izoh alohida saqlandi: ' + made.note);
must(await pg.locator('#mvsup option').count() === 4, 'Yangi ta‘minotchi filtrda ham paydo bo‘ldi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
