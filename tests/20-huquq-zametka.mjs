// To'liq huquq · guruh zametkasi · guruh ombori haqida eslatma · chiqishda tasdiq
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1500 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// guruh egasi sifatida ishlaymiz
await pg.route('**/index.html*', async route => {
  const res = await route.fetch();
  await route.fulfill({ response: res, body: (await res.text()).replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1',") });
});
await pg.route('**/supabase*.js', r => r.abort());

const ME = '__me__';
const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME,   name: 'Izzat',  role: 'owner',  user_id: 'u1' },
            { id: 'm2', name: 'Ismoil', role: 'viewer', user_id: 'u2', can_stock: false },
            { id: 'm3', name: 'SHO',    role: 'editor', user_id: 'u3' }],
  expenses: [], settlements: [],
  items: [{ id: 'gi', name: 'Qog‘oz', unit: 'dona', min: 0 }], stock: [],
  notes: [{ id: 'n1', body: 'Nurikka 500 000 qarz\nSeshanba kuni beriladi',
            createdBy: 'u1', createdAt: '2026-11-26T10:40:00Z' }]
};

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Izzat' },
    accounts: [{ id: 'a', name: 'Kassa', opening: 0 }],
    categories: [], transactions: [], budget: { monthly: 0 },
    groups: [o.g], items: [], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

// ============ GURUH OMBORI HAQIDA ESLATMA ============
// A'zo Ombor ni ochsa o'zining shaxsiy omborini ko'radi — guruhnikini topa olmaydi
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(500);
let t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/Guruh ombori/.test(t), 'Shaxsiy profilda turganda guruh ombori haqida aytiladi');
must(/shaxsiy/i.test(t), 'Hozir qaysi ombor ochiqligi yozilgan');
must(await pg.locator('[data-act="oscope"][data-s="g1"]').count() === 1, 'Bir bosishda o‘tish tugmasi bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-ombor-eslatma.png' });
await pg.click('[data-act="oscope"][data-s="g1"]'); await pg.waitForTimeout(600);
t = (await pg.locator('#screen').textContent()).replace(/\s+/g, ' ');
must(/ETIKETKA/.test(t) && !/Guruh ombori/.test(t), 'O‘tgandan keyin eslatma yo‘qoladi: guruh ombori ochiq');
must(await pg.locator('[data-act="nav"][data-screen="moves"]').count() === 1, 'Guruh omborida ham Harakatlar bor');

// ============ ZAMETKA ============
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(600);
must(await pg.locator('[data-act="edit-note"]').count() === 1, 'Zametka guruh ekranida ko‘rinadi');
t = (await pg.locator('.card', { hasText: 'Zametkalar' }).textContent()).replace(/\s+/g, ' ');
must(/Nurikka 500 000 qarz/.test(t), 'Zametka matni ko‘rinadi');
must(/Seshanba kuni beriladi/.test(t), 'Ko‘p qatorli matn ham to‘liq');
must(/Izzat · 26-noy 10:40/.test(t), 'Kim va qachon yozgani ko‘rinadi: ' + t.slice(0, 90));
// ikkala tabda ham
await pg.click('[data-act="gtab"][data-tab="balances"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="edit-note"]').count() === 1, 'Balanslar tabida ham ko‘rinadi');
await pg.click('[data-act="gtab"][data-tab="expenses"]'); await pg.waitForTimeout(400);

await pg.click('[data-act="edit-note"]'); await pg.waitForTimeout(500);
must(await pg.locator('#modal textarea[name="body"]').count() === 1, 'Zametka oynasi ochildi');
must((await pg.locator('#modal textarea[name="body"]').inputValue()).indexOf('Nurikka') === 0, 'Matn oynaga tushdi');
must(/Qo‘shdi/.test(await pg.locator('#modal .view-meta').textContent()), 'Oynada ham kim qo‘shgani yozilgan');
must(await pg.locator('#modal [data-act="del-note"]').count() === 1, '«O‘chirish» bor');
await pg.screenshot({ path: (process.argv[2] || '.') + '/h-zametka.png' });
await pg.locator('#modal .close-x').evaluate(e => e.click()); await pg.waitForTimeout(300);

// ============ TO'LIQ HUQUQ ============
await pg.click('[data-act="gtab"][data-tab="balances"]'); await pg.waitForTimeout(500);
const row = nm => pg.locator('.card', { hasText: 'A‘zolar' }).locator('.row', { hasText: nm }).last();
must(await row('Ismoil').locator('[data-act="mfull"]').count() === 1, 'Ko‘ruvchida «To‘liq huquq» tugmasi bor');
must(await row('Ismoil').locator('[data-act="mstock"]').count() === 1, '«Omborni ko‘rsin» ham bor');
must(await row('SHO').locator('[data-act="mfull"]').count() === 0, 'Tahrirlovchida tugma kerak emas');
must(/omborni ko‘radi/.test(await row('SHO').textContent()), 'Tahrirlovchi omborni baribir ko‘radi deb yozilgan');
// tasdiq so'raladi va rad etilsa hech narsa o'zgarmaydi
let asked = '';
pg.once('dialog', d => { asked = d.message(); d.dismiss(); });
await row('Ismoil').locator('[data-act="mfull"]').click(); await pg.waitForTimeout(500);
must(/to‘liq huquq/i.test(asked), 'To‘liq huquqdan oldin tasdiq so‘raladi: ' + asked.split('\n')[0]);
must(await row('Ismoil').locator('[data-act="mfull"]').count() === 1, 'Rad etilsa hech narsa o‘zgarmaydi');

// ============ CHIQISHDA TASDIQ ============
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(500);
if (await pg.locator('[data-act="sign-out"]').count()) {
  asked = '';
  pg.once('dialog', d => { asked = d.message(); d.dismiss(); });
  await pg.click('[data-act="sign-out"]'); await pg.waitForTimeout(400);
  must(/chiqasizmi/i.test(asked), 'Chiqishdan oldin tasdiq so‘raladi: ' + asked.split('\n')[0]);
} else {
  must(true, 'Chiqish tugmasi yo‘q (bulut ulanmagan) — o‘tkazib yuborildi');
}

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
