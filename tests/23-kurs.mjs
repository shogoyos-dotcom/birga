// Valyuta kursi: Markaziy bankdan avtomatik, o'z bankiniki qo'lda
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

// Markaziy bank javobi — test tarmoqqa bog'liq bo'lmasin
let cbuHits = 0;
await pg.route('**/cbu.uz/**', async r => {
  cbuHits++;
  await r.fulfill({ status: 200, contentType: 'application/json',
    headers: { 'access-control-allow-origin': '*' },
    body: JSON.stringify([
      { Ccy: 'USD', Rate: '12002.10', Nominal: '1',   Date: '27.11.2026' },
      { Ccy: 'EUR', Rate: '13166.30', Nominal: '1',   Date: '27.11.2026' },
      { Ccy: 'RUB', Rate: '152.45',   Nominal: '1',   Date: '27.11.2026' },
      { Ccy: 'JPY', Rate: '7534.00',  Nominal: '100', Date: '27.11.2026' }]) });
});

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(2500);
const cache = JSON.parse(await pg.evaluate(() => localStorage.getItem('birga_rates')) || 'null');
must(cache && cache.list.USD === 12002.1, 'Markaziy bank kursi olindi va keshlandi');
must(cache.date === '27.11.2026', 'Sanasi ham saqlanadi');
must(cache.list.JPY === undefined, 'Faqat kerakli valyutalar (USD/EUR/RUB)');

await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(600);
const card = pg.locator('.card').filter({ has: pg.locator('h2', { hasText: 'Valyuta kursi' }) });
let t = (await card.textContent()).replace(/\s+/g, ' ');
must(/Markaziy bank · 27.11.2026/.test(t), 'Kartada MB va sana');
must(/USD\s*12 002.1 so'm/.test(t), 'USD kursi ko‘rinadi: ' + (t.match(/USD[^E]*/) || [''])[0]);
must(/brauzer to‘g‘ridan-to‘g‘ri o‘qiy olmaydi/.test(t), 'Nega bank kursi qo‘lda yozilishi tushuntirilgan');

// ---- o'z bankining kursi ----
await pg.click('[data-act="rates-bank"]'); await pg.waitForTimeout(400);
must((await pg.locator('#modal input[name="bname"]').inputValue()) === 'Ipak Yo‘li', 'Bank nomi taklif qilinadi');
await pg.fill('#modal input[name="buy"]', '11965');
await pg.fill('#modal input[name="sell"]', '12050');
await pg.click('#modal button[type="submit"]'); await pg.waitForTimeout(600);
t = (await card.textContent()).replace(/\s+/g, ' ');
must(/Ipak Yo‘li/.test(t), 'Bank nomi kartada');
must(/Dollar — olish\s*11 965/.test(t) && /Dollar — sotish\s*12 050/.test(t), 'Olish va sotish kursi: ' + t.slice(0, 90));
await pg.screenshot({ path: (process.argv[2] || '.') + '/v-kurs.png' });

// ---- asosiy ekranda dollardagi qiymat ----
await pg.click('[data-screen="home"]'); await pg.waitForTimeout(600);
let hero = (await pg.locator('.balance-hero').first().textContent()).replace(/\s+/g, ' ');
must(/≈ \$/.test(hero), 'Pulim ostida dollardagi qiymat chiqadi');
must(/Ipak Yo‘li kursi bo‘yicha/.test(hero), 'Qaysi kurs ishlatilgani yozilgan: ' + hero);
const cash = parseInt((hero.match(/([\d ]+) so'm/) || [0, '0'])[1].replace(/\s/g, ''), 10);
const usd = parseInt((hero.match(/≈ \$([\d ]+)/) || [0, '0'])[1].replace(/\s/g, ''), 10);
must(usd === Math.round(cash / 12050), 'Bank sotish kursi bo‘yicha hisoblanadi: ' + cash + ' / 12050 = ' + usd);

// bank kursi o'chirilsa — MB kursiga qaytadi
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(500);
await pg.click('[data-act="rates-bank"]'); await pg.waitForTimeout(400);
await pg.click('#modal [data-act="rates-bank-off"]'); await pg.waitForTimeout(600);
await pg.click('[data-screen="home"]'); await pg.waitForTimeout(600);
hero = (await pg.locator('.balance-hero').first().textContent()).replace(/\s+/g, ' ');
must(/Markaziy bank kursi bo‘yicha/.test(hero), 'Bank kursi o‘chsa — Markaziy bankniki: ' + hero);

// ---- valyuta tanlagichi nima qilishi aytilgan ----
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(500);
t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/Bu faqat summalar yonida yoziladigan belgi/.test(t), 'Valyuta tanlagichi summani o‘girmasligi yozilgan');

// ---- kesh: ikkinchi ochilishda qayta so'ralmaydi ----
const before = cbuHits;
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(2200);
must(cbuHits === before, 'Kesh yangi — qaytadan so‘ralmaydi (' + cbuHits + ' ta so‘rov)');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
