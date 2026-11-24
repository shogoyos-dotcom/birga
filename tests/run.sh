#!/usr/bin/env bash
# Birga Hamyon — brauzer testlari
#
#   npx http-server -p 8099 -s ..     # boshqa terminalda
#   ./run.sh                          # yoki: BIRGA_URL=http://localhost:3000 ./run.sh
#
# Har bir fayl mustaqil: localStorage ga ma'lumot joylab, ilovani
# haqiqiy brauzerda (Chromium) ochadi va natijani tekshiradi.
set -u
fail=0
for f in [0-9]*.mjs; do
  echo "── $f"
  node "$f" "${1:-.}" || fail=1
  echo
done
[ $fail -eq 0 ] && echo "✅ HAMMA TEST O'TDI" || echo "❌ YIQILGAN TESTLAR BOR"
exit $fail
