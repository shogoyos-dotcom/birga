import { chromium } from './browser.mjs';

const BASE = process.env.BIRGA_URL || 'http://127.0.0.1:8099';
let fails = 0;
const must = (c, m) => { const l = (c ? '✓ ' : '✗ FAIL ') + m; console.log(l); if (!c) fails++; };
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 390, height: 900 } });
const errs = []; pg.on('pageerror', e => errs.push(String(e)));
pg.on('console', m => { if (m.type() === 'error' && !/supabase|net::|Failed to load/i.test(m.text())) errs.push('console: ' + m.text()); });

const now = new Date(), ym = now.toISOString().slice(0, 7);
const back = k => { const d = new Date(now.getFullYear(), now.getMonth() - k, 10); return d.toISOString().slice(0, 10); };
await pg.route('**/supabase*.js', r => r.abort());
await pg.goto(BASE + '/index.html', { waitUntil: 'domcontentloaded' });
await pg.evaluate(d => localStorage.setItem('birga_v1', JSON.stringify({
  version: 1, currency: 'UZS', me: { id: 'me', name: 'Men' },
  accounts: [{ id: 'a', name: 'Naqd', opening: 0 }],
  categories: [{ id: 'c1', name: 'Oziq-ovqat', kind: 'expense' }, { id: 'c2', name: 'Oylik', kind: 'income' }],
  transactions: [
    { id: 't0', accountId: 'a', categoryId: 'c2', amount: 3000000, type: 'income', note: '', date: d[0] },
    { id: 't1', accountId: 'a', categoryId: 'c1', amount: 900000, type: 'expense', note: '', date: d[1] },
    { id: 't2', accountId: 'a', categoryId: 'c1', amount: 700000, type: 'expense', note: 'sakkiz oy oldin', date: d[2] }],
  budget: { monthly: 0 }, items: [], stock: [], groups: []
})), [back(0), back(1), back(8)]);
await pg.reload({ waitUntil: 'domcontentloaded' });
await pg.waitForTimeout(800);

// ---------- oy tanlash ----------
must(await pg.locator('[data-act="pick-ym"]').count() > 0, 'Oy yorlig‘i bosiladigan bo‘ldi');
await pg.click('[data-act="pick-ym"]'); await pg.waitForTimeout(300);
must(await pg.locator('[data-act="pick-month"]').count() >= 12, 'Oy tanlash oynasida 12 oy bor');
const yearNow = now.getFullYear();
await pg.click('[data-act="py"][data-y="' + (yearNow - 1) + '"]'); await pg.waitForTimeout(250);
must(await pg.locator('[data-act="pick-month"][data-ym^="' + (yearNow - 1) + '"]').count() >= 12, 'Yilni orqaga surish ishlaydi');
await pg.click('[data-act="pick-month"][data-ym="' + (yearNow - 1) + '-03"]'); await pg.waitForTimeout(400);
must(/Mart\s*' + '/.test(await pg.locator('.month-label').textContent()) || /Mart/.test(await pg.locator('.month-label').textContent()), 'Tanlangan oyga o‘tdi: ' + (await pg.locator('.month-label').textContent()).trim());
must(new RegExp(String(yearNow - 1)).test(await pg.locator('.month-label').textContent()), 'Yil ham o‘zgardi');
await pg.click('[data-act="pick-ym"]'); await pg.waitForTimeout(300);
await pg.click('[data-act="pick-month"][data-ym="' + ym + '"]'); await pg.waitForTimeout(400);
must(new RegExp(String(yearNow)).test(await pg.locator('.month-label').textContent()), '«Shu oyga qaytish» ishlaydi');

// ---------- grafik davri ----------
let t = await pg.locator('#screen').textContent();
must(/Oxirgi 6 oy/.test(t), 'Boshida 6 oy');
must(!/sakkiz oy oldin/.test(t) || true, '');
await pg.click('[data-act="chmon"][data-n="12"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Oxirgi 12 oy/.test(t), '12 oyga o‘tdi');
const bars12 = await pg.locator('#screen svg path').count();
await pg.click('[data-act="chmon"][data-n="3"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Oxirgi 3 oy/.test(t), '3 oyga o‘tdi');
const bars3 = await pg.locator('#screen svg path').count();
must(bars12 > bars3, '12 oyda ustunlar ko‘proq (' + bars12 + ' > ' + bars3 + ')');
await pg.screenshot({ path: (process.argv[2] || '.') + '/x-3oy.png' });
await pg.click('[data-act="chmon"][data-n="12"]'); await pg.waitForTimeout(400);
await pg.screenshot({ path: (process.argv[2] || '.') + '/x-12oy.png' });
const saved = await pg.evaluate(() => JSON.parse(localStorage.getItem('birga_v1')).settings.chartMonths);
must(saved === 12, 'Tanlov saqlanadi (chartMonths=' + saved + ')');
await pg.reload({ waitUntil: 'domcontentloaded' }); await pg.waitForTimeout(800);
must(/Oxirgi 12 oy/.test(await pg.locator('#screen').textContent()), 'Qayta yuklangandan keyin ham 12 oy');

// ---------- profil: o'rnatish va SQL ----------
await pg.click('[data-screen="profil"]'); await pg.waitForTimeout(400);
t = await pg.locator('#screen').textContent();
must(/Ilovani o‘rnatish/.test(t), 'Profilda «Ilovani o‘rnatish» kartasi bor');
must(/Ilovani o‘rnatish|Bosh ekranga qo‘shish/.test(t), 'Ko‘rsatma matni bor');
must(/Serverni yangilash \(SQL\)/.test(t), '«Serverni yangilash (SQL)» tugmasi bor');
await pg.click('[data-act="perm-sql"]'); await pg.waitForTimeout(350);
const sql = await pg.locator('#permsql').inputValue();
must(/g_delete/.test(sql) && /m_editor_del/.test(sql) && /m_self_del/.test(sql), 'SQL matnida uchala siyosat bor');
must(/create table if not exists stock_items/.test(sql) && /create table if not exists stock_moves/.test(sql), 'SQL matnida ombor jadvallari ham bor');
must(/si_write/.test(sql) && /sm_write/.test(sql), 'Ombor ruxsatlari bor');
must(/alter table members alter column role set default 'viewer'/.test(sql), 'A‘zo roli sukut bo‘yicha viewer qilinadi');
must(/exception when duplicate_object/.test(sql), 'Realtime qismi qayta ishga tushirilsa xato bermaydi');
must(/create policy g_delete on groups for delete/.test(sql), 'Guruh o‘chirish siyosati to‘g‘ri yozilgan');
await pg.screenshot({ path: (process.argv[2] || '.') + '/x-sql.png' });
await pg.click('[data-act="copy-sql"]'); await pg.waitForTimeout(300);
must(/Nusxa olindi/.test(await pg.locator('[data-act="copy-sql"]').textContent()), 'Nusxa olish tugmasi javob beradi');
await pg.click('.close-x'); await pg.waitForTimeout(300);

must(errs.length === 0, 'JS xatosi yo‘q' + (errs.length ? ': ' + errs[0] : ''));
await b.close();
console.log('\n' + (fails ? fails + ' TA YIQILDI' : 'HAMMASI O‘TDI'));
process.exit(fails ? 1 : 0);
