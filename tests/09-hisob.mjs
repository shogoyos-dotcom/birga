import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
const dialogs = [];
pg.on('dialog', async d => { dialogs.push(d.message()); await d.accept(); });

// bulutsiz holat: Supabase kutubxonasi yuklanmaydi
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
let t = await pg.locator('#screen').textContent();
must(/Hisob/.test(t), 'Profilda «Hisob» kartasi bor');
must(/Bulut sozlanmagan/.test(t), 'Bulutsiz holatda to‘g‘ri xabar');
must(await pg.locator('[data-act="link-email"]').count() === 0, 'Bulutsiz holatda kirish tugmalari ko‘rsatilmaydi');

// tekshiruv mantiqi — tarmoqqa chiqmasdan sinaymiz
await pg.evaluate(() => {
  const d = document.createElement('button');
  d.id = 'tbtn'; d.dataset.act = 'link-email'; d.textContent = 'x';
  document.body.appendChild(d);
});
await pg.evaluate(() => document.getElementById('tbtn').click()); await pg.waitForTimeout(350);
must(await pg.locator('input[name="email"]').count() === 1, 'Email qo‘shish oynasi ochildi');
must(await pg.locator('input[name="pass2"]').count() === 1, 'Parolni takrorlash maydoni bor');
must(/saqlanadi/.test(await pg.locator('#modal').textContent()), 'Hisob saqlanishi haqida izoh bor');

const tryIt = async (email, p1, p2) => {
  dialogs.length = 0;
  await pg.fill('input[name="email"]', email);
  await pg.fill('input[name="pass"]', p1);
  await pg.fill('input[name="pass2"]', p2);
  await pg.click('#modal button[type="submit"]');
  await pg.waitForTimeout(500);
  return dialogs.join(' | ');
};
must(/Email to‘g‘ri yozilmagan/.test(await tryIt('salom', 'parol123', 'parol123')), 'Noto‘g‘ri email ushlanadi');
must(/kamida 6 belgi/.test(await tryIt('a@b.uz', '123', '123')), 'Qisqa parol ushlanadi');
must(/mos kelmadi/.test(await tryIt('a@b.uz', 'parol123', 'parol999')), 'Mos kelmagan parollar ushlanadi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-email.png' });
await pg.click('.close-x'); await pg.waitForTimeout(300);

// kirish oynasi
await pg.evaluate(() => {
  const d = document.createElement('button');
  d.id = 'tbtn2'; d.dataset.act = 'sign-in'; d.textContent = 'x';
  document.body.appendChild(d);
});
await pg.evaluate(() => document.getElementById('tbtn2').click()); await pg.waitForTimeout(350);
must(await pg.locator('input[name="pass"]').count() === 1, 'Kirish oynasi ochildi');
must(await pg.locator('[data-act="reset-pass"]').count() === 1, '«Parolni unutdim» bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-kirish.png' });

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
