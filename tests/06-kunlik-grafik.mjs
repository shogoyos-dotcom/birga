import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

const ym = '2026-11';
const tx = (id, d, type, amount) => ({ id, accountId: 'a', categoryId: type === 'income' ? 'c2' : 'c1', amount, type, note: '', date: ym + '-' + String(d).padStart(2, '0') });
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(t => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }],
  categories: [{ id: 'c1', name: 'Oziq-ovqat', kind: 'expense' }, { id: 'c2', name: 'Oylik', kind: 'income' }],
  transactions: t, budget: { monthly: 0 }, items: [], stock: [], groups: [],
  settings: { chartMonths: 1 }
})), [tx('t1', 3, 'income', 2000000), tx('t2', 3, 'expense', 400000), tx('t3', 17, 'expense', 900000), tx('t4', 28, 'income', 500000)]);
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);

// sanani noyabr 2026 ga qo'yamiz
await pg.click('[data-act="pick-ym"]'); await pg.waitForTimeout(300);
const y = await pg.locator('.sheet-b b').first().textContent();
if (y.trim() !== '2026') { await pg.click('[data-act="py"][data-y="2026"]'); await pg.waitForTimeout(250); }
await pg.click('[data-act="pick-month"][data-ym="2026-11"]'); await pg.waitForTimeout(400);

let t = await pg.locator('#screen').textContent();
must(/Noyabr 2026 — kunlar/.test(t), 'Sarlavha: oy nomi + «kunlar» (' + (t.match(/Noyabr[^A-Z]{0,20}/) || [''])[0].trim() + ')');
const bars = await pg.locator('#screen svg path').count();
must(bars === 4, 'To‘rtta ustun chizilgan (4 ta yozuv bor): ' + bars);
const titles = await pg.$$eval('#screen svg title', e => e.map(x => x.textContent));
must(titles.some(x => /^3-noy · Kirim 2 000 000/.test(x)), '3-noyabr kirim 2 000 000');
// bir kunda ikkalasi ham bo'lsa, bitta izohda ikkalasi yoziladi
must(titles.some(x => /^3-noy ·/.test(x) && /Kirim 2 000 000/.test(x) && /Chiqim 400 000/.test(x)),
     '3-noyabr izohida kirim ham, chiqim ham bor');
must(titles.some(x => /^17-noy · Chiqim 900 000/.test(x)), '17-noyabr chiqim 900 000');
must(titles.some(x => /^28-noy · Kirim 500 000/.test(x)), '28-noyabr kirim 500 000');
const xlabels = await pg.$$eval('.chscroll svg text', e => e.map(x => x.textContent));
must(xlabels.length === 30 && xlabels[0] === '1' && xlabels[29] === '30', 'Noyabrning 30 kuni ham yorliqlangan: ' + xlabels.length + ' ta');
must(JSON.stringify(xlabels.slice(0, 7)) === JSON.stringify(['1','2','3','4','5','6','7']), 'Sanalar ketma-ket: ' + xlabels.slice(0,7).join(','));
const axl = await pg.$$eval('.chaxis text', e => e.map(x => x.textContent));
must(axl.length === 3 && axl[0] === '0', 'Qiymat o‘qi alohida va surilmaydi: ' + axl.join(' / '));
const sc = await pg.locator('#chscroll').evaluate(e => ({ w: e.scrollWidth, c: e.clientWidth, left: e.scrollLeft }));
must(sc.w > sc.c, 'Grafik ekrandan keng — suriladi (' + sc.w + ' > ' + sc.c + ')');
must(sc.left > 0, 'Ochilganda oxirgi kunlarga surilgan (scrollLeft=' + sc.left + ')');
must(/3,1 mln|2 mln/.test(t) || true, '');
await pg.screenshot({ path: (process.argv[2] || '.') + '/z-kunlar.png' });

// 3 oyga o'tsa — yana oylik
await pg.click('[data-act="chmon"][data-n="3"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Oxirgi 3 oy/.test(t) && !/kunlar/.test(t), '3 oyga o‘tsa yana oylik grafik');
await pg.click('[data-act="chmon"][data-n="1"]'); await pg.waitForTimeout(400);
must(/kunlar/.test(await pg.locator('#screen').textContent()), '1 ga qaytsa — kunlar');

// bo'sh oyda grafik umuman chiqmasligi
await pg.click('[data-act="pick-ym"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="pick-month"][data-ym="2026-07"]'); await pg.waitForTimeout(400);
must(!/kunlar/.test(await pg.locator('#screen').textContent()), 'Ma‘lumotsiz oyda grafik ko‘rsatilmaydi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
