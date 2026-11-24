import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

// Bulutsiz muhitda myRole() hamma vaqt 'viewer' qaytaradi —
// demak guruh ombori ustida "faqat ko'rish" holatini aynan shunday sinaymiz.
const D = '2026-11-20';
const grp = {
  id: 'g1', name: 'Do‘kon', currency: 'UZS', meMemberId: 'me',
  members: [{ id: 'me', name: 'Men', role: 'viewer', user_id: 'u1', can_stock: true }],
  expenses: [], settlements: [],
  items: [{ id: 'gi1', name: 'Guruh shakari', unit: 'kg', min: 0 }],
  stock: [
    { id: 'gs1', itemId: 'gi1', type: 'in', qty: 200, price: 9000, date: D, note: '', txId: null },
    { id: 'gs2', itemId: 'gi1', type: 'out', qty: 50, price: 14000, date: D, note: '', txId: null }
  ]
};
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(g => {
  const st = {
    version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
    accounts: [{ id: 'a', name: 'Naqd', opening: 0 }], categories: [],
    transactions: [], budget: { monthly: 0 }, groups: [g],
    items: [{ id: 'i1', name: 'Telefon shakari', unit: 'kg', min: 0 }],
    stock: [{ id: 's1', itemId: 'i1', type: 'in', qty: 10, price: 1000, date: '2026-11-20', note: '', txId: null }]
  };
  localStorage.setItem('birga_v1', JSON.stringify(st));
  localStorage.setItem('birga_groups_cache', JSON.stringify([g]));
}, grp);
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(900);

await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
let t = await pg.locator('#screen').textContent();

// ---- Ombor ekranida tanlagich YO'Q, profil nomi bor ----
must(/Mening omborim/.test(t), 'Ombor sarlavhasida joriy profil: Mening omborim');
must(await pg.locator('#screen .chips [data-act="oscope"]').count() === 0, 'Ombor ekranida ombor tanlagichi yo‘q');

// ---- profil Profil bo'limidan almashtiriladi ----
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
must(await pg.locator('[data-act="oscope"]').count() === 2, 'Profilda ikkita profil tanlovi (shaxsiy + guruh)');
must(/Shaxsiy profil/.test(await pg.locator('#screen').textContent()), '«Shaxsiy profil» qatori bor');
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(300);
t = await pg.locator('#screen').textContent();
must(await pg.locator('.row[data-act="open-item"]').count() === 0, 'Bosh ekranda tovar ro‘yxati yo‘q — u Tovarlar ichida');
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
must(/Telefon shakari/.test(await pg.locator('#screen').textContent()), 'Telefon omborida o‘z tovari ko‘rinadi');
must(await pg.locator('[data-act="add-item"]').count() > 0, 'Telefon omborida «Tovar +» bor');
await pg.click('.back-btn'); await pg.waitForTimeout(300);

// ---- guruh profiliga o'tish (rolim: faqat ko'radi, lekin ombor ochilgan) ----
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="oscope"][data-s="g1"]'); await pg.waitForTimeout(500);
t = await pg.locator('#screen').textContent();
must(/faqat ko‘rasiz/.test(t), '«Faqat ko‘rasiz» ogohlantirishi chiqdi');
must(/Faqat ko‘radi/.test(t), 'Sarlavhada rol yozilgan');
must(await pg.locator('[data-act="add-item"]').count() === 0, 'Ruxsatsizda «Tovar qo‘shish» tugmasi YO‘Q');
must(/150 kg/.test(t) === false && /Tovarlar \(1\)/.test(t), 'Guruh ombori ko‘rinadi: Tovarlar (1)');
// FIFO guruh ma'lumotida ham ishlaydi: 200×9000 kirim, 50 sotildi → tannarx 450 000, foyda 700 000-450 000
must(/Sotilganning tannarxi\s*450 000/.test(t.replace(/\s+/g, ' ')), 'Guruh omborida tannarx 450 000 (50×9000)');
must(/Foyda \(FIFO\)\s*\+250 000/.test(t.replace(/\s+/g, ' ')), 'Guruh omborida foyda +250 000 (700 000 − 450 000)');
await pg.screenshot({ path: (process.argv[2] || '.') + '/o-guruh.png' });

// ---- ro'yxat va tovar ekranida ham tugmalar yo'q ----
await pg.click('[data-act="nav"][data-screen="items"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Guruh shakari/.test(t) && !/Telefon shakari/.test(t), 'Guruh tovarlari ko‘rinadi, telefonniki emas');
must(await pg.locator('[data-act="add-item"]').count() === 0 && /faqat ko‘rish/.test(t), 'Tovarlar ekranida ham yozish tugmasi yo‘q');
await pg.click('.row[data-act="open-item"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(await pg.locator('[data-act="add-move"]').count() === 0, 'Tovar ekranida «Prihod +/Rasxod −» yo‘q');
must(await pg.locator('[data-act="edit-item"]').count() === 0, '«Tahrirlash» yo‘q');
must(await pg.locator('[data-act="edit-move"]').count() === 0, 'Harakat qatori bosilmaydi');
must(/150 kg/.test(t), 'Qoldiq to‘g‘ri: 150 kg (200 − 50)');
await pg.screenshot({ path: (process.argv[2] || '.') + '/o-tovar.png' });

// ---- FAB bosilsa ogohlantirish ----
let alerted = '';
pg.once('dialog', d => { alerted = d.message(); d.accept(); });
await pg.click('#fab'); await pg.waitForTimeout(500);
must(/huquqi yo‘q/.test(alerted), 'FAB bosilsa ruxsat haqida xabar: ' + alerted.slice(0, 50));

// ---- telefon omboriga qaytish: hammasi avvalgidek ----
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="oscope"][data-s="local"]'); await pg.waitForTimeout(500);
t = await pg.locator('#screen').textContent();
must(!/faqat ko‘rasiz/.test(t), 'Telefon omborida cheklov yo‘q');
must(await pg.locator('[data-act="add-item"]').count() > 0, 'Telefon omborida tugmalar qaytdi');
must(/Ko‘chirish|ko‘chirish/.test(t) === false, 'Telefon omborida ko‘chirish kartasi chiqmaydi (u guruhda chiqadi)');

// tanlov saqlanadimi
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="oscope"][data-s="g1"]'); await pg.waitForTimeout(400);
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
must(/faqat ko‘rasiz/.test(await pg.locator('#screen').textContent()), 'Tanlangan ombor qayta yuklangandan keyin ham saqlanadi');

// ---- ruxsat berilmagan a'zo guruh omborini KO'RMAYDI ----
await pg.evaluate(() => {
  const g = JSON.parse(localStorage.getItem('birga_groups_cache'))[0];
  g.members[0].can_stock = false;
  localStorage.setItem('birga_groups_cache', JSON.stringify([g]));
  const st = JSON.parse(localStorage.getItem('birga_v1'));
  st.groups = [g]; localStorage.setItem('birga_v1', JSON.stringify(st));
});
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(900);
await pg.click('[data-screen="ombor"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/ombor huquqini bermagan/.test(t), 'Ruxsatsiz a‘zoga ombor yopiq');
must(!/Guruh shakari/.test(t) && !/Tovarlar \(/.test(t), 'Yopiq omborda tovarlar ko‘rinmaydi');
await pg.screenshot({ path: (process.argv[2] || '.') + '/o-yopiq.png' });

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
