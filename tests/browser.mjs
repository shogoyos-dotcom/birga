/* Playwright ni topish.
   Odatda: tests papkasida `npm install` qilinadi.
   Agar playwright boshqa joyda turgan bo'lsa:
     PLAYWRIGHT_PATH=/yo'l/playwright/index.mjs ./run.sh            */
let mod;
try {
  mod = await import('playwright');
} catch (e) {
  const alt = process.env.PLAYWRIGHT_PATH;
  if (!alt) {
    console.error("playwright topilmadi. `cd tests && npm install` qiling,\n" +
                  "yoki PLAYWRIGHT_PATH orqali yo'lini ko'rsating.");
    process.exit(2);
  }
  mod = await import(alt);
}
export const chromium = mod.chromium;
