import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1000 }, hasTouch: true, isMobile: true });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Guruhning EGA oynalari (xarajat qo'shish, bo'linish) canEdit() talab qiladi,
// u esa SB_UID ga qarab ishlaydi. Bulut bloklangani uchun SB_UID normalda null
// bo'lib qoladi va bu oynalar umuman ochilmaydi. Shuning uchun sahifani yo'lda
// ushlab, "kirgan foydalanuvchi u1" holatini taqlid qilamiz.
await pg.route('**/index.html*', async route => {
  const res = await route.fetch();
  const body = (await res.text())
    .replace('var SB=null, SB_UID=null,', "var SB=null, SB_UID='u1',");
  await route.fulfill({ response: res, body });
});
await pg.route('**/supabase*.js', r => r.abort());

const ME = '__me__';
const now = new Date(), ym = now.toISOString().slice(0, 7);
const dd = n => ym + '-' + String(n).padStart(2, '0');
// modal sarlavhasi bosishni to'sib qolishi mumkin — to'g'ridan-to'g'ri bosamiz
const closeModal = async () => {
  await pg.locator('#modal .close-x').evaluate(e => e.click());
  await pg.waitForTimeout(300);
};

const grp = {
  id: 'g1', name: 'ETIKETKA', currency: 'UZS', meMemberId: ME,
  members: [{ id: ME, name: 'Men', role: 'owner', user_id: 'u1' },
            { id: 'm2', name: 'Aziz', role: 'editor', user_id: 'u2' },
            { id: 'm3', name: 'Bek',  role: 'editor', user_id: 'u3' }],
  expenses: [], settlements: [], items: [], stock: []
};

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(o => {
  localStorage.setItem('birga_v1', JSON.stringify({
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Kassa', opening: 0 }],
    categories: [{ id: 'c1', name: 'Ish haqi', kind: 'expense' }, { id: 'c2', name: 'Savdo', kind: 'income' }],
    transactions: [], budget: { monthly: 0 }, groups: [o.g],
    items: [{ id: 'i1', name: 'Qog‘oz', unit: 'quti', min: 0 }], stock: []
  }));
  localStorage.setItem('birga_groups_cache', JSON.stringify([o.g]));
}, { g: grp });
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);

// ================= KALKULYATOR =================
// --- shaxsiy amaliyot oynasida ---
await pg.click('#fab'); await pg.waitForTimeout(500);
const amt = pg.locator('#modal input[name="amount"]');
must(await amt.count() === 1, 'Amaliyot oynasi ochildi');

// Telefon klaviaturasida + va × tugmalari YO'Q — shuning uchun maydon ostida
// o'z amal tugmalarimiz bo'lishi SHART, aks holda ifoda yozib bo'lmaydi.
must(await pg.locator('#modal .calcpad:not([hidden])').count() === 0, 'Tugmalar fokusdan oldin yashirin');
await amt.click(); await pg.waitForTimeout(300);
const keys = pg.locator('#modal .calcpad:not([hidden]) .ckey');
must(await keys.count() === 6, 'Fokusda 6 ta amal tugmasi chiqadi');
must((await keys.allTextContents()).join('') === '+−×÷()', 'Tugmalar: + − × ÷ ( )');

// faqat raqam yozib, amallarni TUGMADAN bosamiz
const key = t => pg.locator('#modal .calcpad .ckey', { hasText: t }).first();
await amt.type('3');
await key('×').tap();
await amt.type('45000');
await key('+').tap();
await amt.type('500');
await pg.waitForTimeout(300);
must(await amt.inputValue() === '3×45000+500', 'Tugmalar maydonga belgi qo‘yadi: ' + await amt.inputValue());
must(/135 500/.test(await pg.locator('#modal .calcline:not([hidden])').first().textContent()),
     'Tugma bilan yozilgan ifoda hisoblanadi: 3 × 45 000 + 500 = 135 500');
must(await pg.evaluate(() => document.activeElement && document.activeElement.name) === 'amount',
     'Tugma bosilganda fokus maydonda qoladi (klaviatura yopilmaydi)');
await pg.locator('#modal input[name="note"]').click(); await pg.waitForTimeout(400);
must(await amt.inputValue() === '135500', 'Tugma bilan yozilgani ham songa aylanadi');
must(await pg.locator('#modal .calcpad:not([hidden])').count() === 0, 'Maydondan chiqqanda tugmalar yashirinadi');

await amt.click();
await amt.fill('3*45000');
await pg.waitForTimeout(250);
let line = pg.locator('#modal .calcline:not([hidden])').first();
must(await line.count() === 1, 'Ifoda yozilsa natija ko‘rinadi');
must(/135 000/.test(await line.textContent()), 'Jonli natija: 3 × 45 000 = 135 000');
await pg.locator('#modal input[name="note"]').click();   // blur
await pg.waitForTimeout(250);
must(await amt.inputValue() === '135000', 'Klaviaturadan yozilgan ifoda ham ishlaydi');
must(await pg.locator('#modal .calcline:not([hidden])').count() === 0, 'Natija qatori yashirinadi');

// oddiy son kalkulyator sifatida ko'rinmasin
await amt.fill('250000'); await pg.waitForTimeout(250);
must(await pg.locator('#modal .calcline:not([hidden])').count() === 0, 'Oddiy songa natija qatori chiqmaydi');
// chala ifodaga ham chiqmasin
await amt.fill('3*'); await pg.waitForTimeout(250);
must(await pg.locator('#modal .calcline:not([hidden])').count() === 0, 'Chala ifodaga natija chiqmaydi');
// qavs va bo'lish
await amt.fill('(100000+50000)/3'); await pg.waitForTimeout(250);
must(/50 000/.test(await pg.locator('#modal .calcline:not([hidden])').first().textContent()),
     'Qavs va bo‘lish ham ishlaydi: (100 000 + 50 000) ÷ 3 = 50 000');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-calc.png' });
await closeModal();

// --- ombor oynasida: miqdor ham hisoblansin ---
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
await pg.click('#fab'); await pg.waitForTimeout(500);
await pg.fill('#modal input[name="qty"]', '12*3'); await pg.waitForTimeout(250);
must(/36/.test(await pg.locator('#modal .calcline:not([hidden])').first().textContent()),
     'Miqdor maydonida ham hisoblanadi: 12 × 3 = 36');
await pg.fill('#modal input[name="price"]', '8000+500'); await pg.waitForTimeout(250);
const lines = await pg.locator('#modal .calcline:not([hidden])').allTextContents();
must(lines.some(x => /8 500/.test(x)), 'Narx maydonida ham: 8 000 + 500 = 8 500');
await closeModal();

// ================= FOIZ BILAN BO'LISH =================
await pg.click('[data-screen="groups"]'); await pg.waitForTimeout(400);
await pg.click('.row.tap'); await pg.waitForTimeout(500);
await pg.click('#fab'); await pg.waitForTimeout(600);
must(await pg.locator('#modal #mseg').count() === 1, 'Guruh amaliyoti oynasi ochildi (ega sifatida)');
must(await pg.locator('#modal [data-m="pct"]').count() === 1, '«Foiz» tugmasi bor');

await pg.fill('#modal input[name="title"]', 'Foyda ulushi');
await pg.fill('#modal #eamt', '1450000');
await pg.click('#modal [data-m="pct"]'); await pg.waitForTimeout(400);
const pin = pg.locator('#modal .sinput');
must(await pin.count() === 3, 'Har a‘zo uchun foiz maydoni');
must(await pg.locator('#modal .pcs').count() === 3, '% belgisi ko‘rinadi');

await pin.nth(1).fill('10');
await pin.nth(2).fill('5');
await pg.waitForTimeout(400);
let st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 15%/.test(st) && /qolgan 85% bo‘linmaydi/.test(st),
     '15% da qolgani bo‘linmasligi aytiladi: ' + st);
let shares = (await pg.locator('#modal .calc').allTextContents()).map(x => x.replace(/\s+/g, ' ').trim());
must(/145 000/.test(shares[1]), 'Aziz 10% = 145 000');
must(/72 500/.test(shares[2]),  'Bek 5% = 72 500');
must(/^0/.test(shares[0]),      'Foiz yozilmaganga 0');
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-foiz.png' });

// saqlanadigan ulushlar
let out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(JSON.stringify(out) === JSON.stringify([{ memberId: 'm2', share: 145000 }, { memberId: 'm3', share: 72500 }]),
     'Saqlanadigan ulushlar to‘g‘ri: ' + JSON.stringify(out));

// 100%
await pin.nth(1).fill('95'); await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 100%/.test(st) && /1 450 000/.test(st), '100% da jami summa ko‘rsatiladi: ' + st);

// --- KASR FOIZ (27,5%) — butun songa yaxlitlanib ketmasin ---
// Oldin parseAmount ishlatilgani uchun 27,5 → 28 bo'lib ketardi: jami 100
// o'rniga 101% chiqib "oshib ketdi" deyilardi, summa ham noto'g'ri edi.
await pg.fill('#modal #eamt', '66000');
await pin.nth(0).fill('27,5');
await pin.nth(1).fill('27,5');
await pin.nth(2).fill('45');
await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 100%/.test(st) && /66 000/.test(st), '27,5 + 27,5 + 45 = aniq 100%: ' + st);
shares = (await pg.locator('#modal .calc').allTextContents()).map(x => x.replace(/\s+/g, ' ').trim());
must(/^18 150/.test(shares[0]), 'Men 27,5% = 18 150 (28% → 18 480 emas): ' + shares[0]);
must(/^18 150/.test(shares[1]), 'Aziz 27,5% = 18 150: ' + shares[1]);
must(/^29 700/.test(shares[2]), 'Bek 45% = 29 700: ' + shares[2]);
out = await pg.evaluate(() => document.getElementById('modal')._readSplits());
must(JSON.stringify(out) === JSON.stringify([{ memberId: '__me__', share: 18150 },
                                             { memberId: 'm2', share: 18150 },
                                             { memberId: 'm3', share: 29700 }]),
     'Kasr foizdagi ulushlar saqlanadi: ' + JSON.stringify(out));
// nuqta bilan yozilgani ham
await pin.nth(0).fill('27.5'); await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 100%/.test(st), 'Nuqta bilan ham: 27.5 → 100%: ' + st);
// kasr foiz yetmasa — qolgani ko'rsatiladi
await pin.nth(2).fill('40'); await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 95%/.test(st) && /qolgan 5% bo‘linmaydi/.test(st), '95% da qolgan 5%: ' + st);
await pin.nth(0).fill('27,55'); await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/Jami 95,05%/.test(st), 'Yuzdan bir ham ko‘rinadi: ' + st);
await pg.screenshot({ path: (process.argv[2] || '.') + '/k-foiz-kasr.png' });
await pg.fill('#modal #eamt', '1450000');
await pin.nth(0).fill('');
await pin.nth(2).fill('5');
await pg.waitForTimeout(300);

// 100% dan oshsa — saqlanmasin
await pin.nth(1).fill('120'); await pg.waitForTimeout(400);
st = (await pg.locator('#modal #sstat').textContent()).replace(/\s+/g, ' ');
must(/oshib ketdi/.test(st), '125% da ogohlantiradi: ' + st);
must(await pg.evaluate(() => document.getElementById('modal')._readSplits()) === null,
     '100% dan oshsa saqlanmaydi');

// foiz maydonida ham kalkulyator ishlasin
await pin.nth(1).fill('5+5'); await pg.waitForTimeout(400);
shares = (await pg.locator('#modal .calc').allTextContents()).map(x => x.replace(/\s+/g, ' ').trim());
must(/145 000/.test(shares[1]), 'Foiz maydonida ham hisoblanadi: 5+5 = 10% → 145 000');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
