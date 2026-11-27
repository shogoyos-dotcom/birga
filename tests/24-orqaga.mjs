// Telefondagi «orqaga» tugmasi: ilovadan shartta chiqib ketmasin
import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 1000 }, hasTouch: true, isMobile: true,
                             serviceWorkers: 'block' });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });
await pg.route('**/supabase*.js', r => r.abort());
await pg.route('**/cbu.uz/**', r => r.abort());

const screen = () => pg.evaluate(() => document.querySelector('#tabbar [aria-current="page"]').dataset.screen);
const modalOpen = async () => (await pg.locator('#modal').getAttribute('hidden')) === null;

await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);
must(await screen() === 'home', 'Asosiy ekranda boshlanadi');

// ---- ekrandan ekranga qaytadi ----
await pg.click('[data-screen="tx"]'); await pg.waitForTimeout(350);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(350);
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(350);
must(await screen() === 'profil', 'Profilga o‘tdik');
await pg.goBack(); await pg.waitForTimeout(350);
must(await screen() === 'ombor', 'Orqaga — Omborga qaytdi');
await pg.goBack(); await pg.waitForTimeout(350);
must(await screen() === 'tx', 'Yana orqaga — Amaliyotlar');
await pg.goBack(); await pg.waitForTimeout(350);
must(await screen() === 'home', 'Yana orqaga — Asosiy');

// ---- ochiq oyna yopiladi, ilova chiqmaydi ----
await pg.click('#fab'); await pg.waitForTimeout(500);
must(await modalOpen(), 'Amaliyot oynasi ochildi');
await pg.goBack(); await pg.waitForTimeout(400);
must(!(await modalOpen()), 'Orqaga bosilsa avval oyna yopiladi');
must(await screen() === 'home', 'Ekran o‘zgarmaydi');
must(await pg.locator('#screen .card').count() > 0, 'Ilova joyida');

// ---- asosiy ekranda — so'raydi ----
let asked = '';
pg.once('dialog', d => { asked = d.message(); d.dismiss(); });
await pg.goBack(); await pg.waitForTimeout(500);
must(/chiqasizmi/i.test(asked), 'Chiqishdan oldin so‘raydi: ' + asked);
must(await pg.locator('#screen .card').count() > 0, '«Yo‘q» desa ilova joyida qoladi');

// yana so'raydi — bir martalik emas
asked = '';
pg.once('dialog', d => { asked = d.message(); d.dismiss(); });
await pg.goBack(); await pg.waitForTimeout(500);
must(/chiqasizmi/i.test(asked), 'Keyingi safar ham so‘raydi');

// ---- qulf ochiq bo'lsa orqaga chiqib bo'lmaydi ----
await pg.evaluate(() => localStorage.setItem('birga_lock',
  JSON.stringify({ kind: 'pin', salt: 'x', hash: 'yoq', len: 4, bio: false, credId: null })));
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
must((await pg.locator('#lockscreen').getAttribute('hidden')) === null, 'Qulf chiqdi');
let asked2 = '';
pg.once('dialog', d => { asked2 = d.message(); d.dismiss(); });
await pg.goBack(); await pg.waitForTimeout(500);
must(asked2 === '', 'Qulfda chiqish so‘ralmaydi');
must((await pg.locator('#lockscreen').getAttribute('hidden')) === null, 'Qulf joyida qoladi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
