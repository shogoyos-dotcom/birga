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
// Native confirm() emas, o'z oynamiz: Androidda PWA ichida native oyna
// chiqmay qolishi mumkin edi.
const exOpen = async () => (await pg.locator('#exitask').getAttribute('hidden')) === null;
const histLen = () => pg.evaluate(() => history.length);
const len0 = await histLen();
await pg.goBack(); await pg.waitForTimeout(500);
must(await exOpen(), 'Chiqishdan oldin so‘rov oynasi chiqadi');
must(/chiqasizmi/i.test(await pg.locator('#exitask .ex-t').textContent()), 'Matni tushunarli');
must(await pg.locator('#exitask #exno').count() === 1 && await pg.locator('#exitask #exyes').count() === 1,
     'Ikkita tugma: «Yo‘q» va «Ha, chiqaman»');
await pg.screenshot({ path: (process.argv[2] || '.') + '/o-chiqish.png' });
await pg.click('#exitask #exno'); await pg.waitForTimeout(400);
must(!(await exOpen()), '«Yo‘q» bosilsa yopiladi');
must(await pg.locator('#screen .card').count() > 0, 'Ilova joyida qoladi');

// yana so'raydi — bir martalik emas
await pg.goBack(); await pg.waitForTimeout(500);
must(await exOpen(), 'Keyingi safar ham so‘raydi');
// so'rov ochiq turganda orqaga bosilsa — faqat so'rov yopiladi
await pg.goBack(); await pg.waitForTimeout(450);
must(!(await exOpen()), 'So‘rov ochiq turganda orqaga — so‘rov yopiladi');
must(await pg.locator('#screen .card').count() > 0, 'Ilova baribir joyida');

// tarix cheksiz o'smasin — har orqadan keyin qo'riqchi bittaligicha qoladi
must(await histLen() === len0, 'Tarix o‘smaydi (' + len0 + ' → ' + await histLen() + ')');

// ---- qulf ochiq bo'lsa orqaga chiqib bo'lmaydi ----
await pg.evaluate(() => localStorage.setItem('birga_lock',
  JSON.stringify({ kind: 'pin', salt: 'x', hash: 'yoq', len: 4, bio: false, credId: null })));
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
must((await pg.locator('#lockscreen').getAttribute('hidden')) === null, 'Qulf chiqdi');
await pg.goBack(); await pg.waitForTimeout(500);
must(!(await exOpen()), 'Qulfda chiqish so‘ralmaydi');
must((await pg.locator('#lockscreen').getAttribute('hidden')) === null, 'Qulf joyida qoladi');

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
