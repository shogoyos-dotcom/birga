#!/usr/bin/env python3
"""NotoColorEmoji shriftini o'yin ishlatadigan belgilargagina qisqartiradi.

To'liq rangli emoji shrifti ~10.8 MB — APK hajmining katta qismi.
O'yinda esa atigi 40 emoji, 12 odam tasviri, belet belgisi va barcha
davlat bayroqlari kerak. Bayroq ikki "regional indicator" belgisining
ligaturasi, shuning uchun `ccmp` jadvali saqlanadi — aks holda bayroq
o'rniga qutichali harflar chiqadi.

Ishlatish (fonttools kerak):
    python3 tool/subset_emoji_font.py

Natija: assets/fonts/NotoColorEmoji.ttf o'rniga qisqartirilgan nusxa.
Asl fayl .full nusxasi sifatida saqlanadi.
"""
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "assets/fonts/NotoColorEmoji.ttf"
BACKUP = FONT.with_suffix(".ttf.full")
PROFILE = ROOT / "scripts/app/profile.gd"

# Qo'shimcha belgilar: belet (do'kon) va variatsiya tanlagich.
EXTRA = [0x1F39F, 0xFE0F]


def wanted() -> set[int]:
    src = PROFILE.read_text(encoding="utf-8")
    emojis = re.search(
        r"const EMOJIS: PackedStringArray = \[(.*?)\]", src, re.S).group(1)
    figures = re.search(
        r"const FIGURE_GLYPHS: PackedStringArray = \[(.*?)\]", src, re.S).group(1)

    codes = set(EXTRA)
    for item in re.findall(r'"([^"]+)"', emojis):
        codes.update(ord(ch) for ch in item)
    for code in re.findall(r"\\U([0-9A-Fa-f]{6})", figures):
        codes.add(int(code, 16))
    # Barcha bayroqlar: 26 ta "regional indicator" harfi yetarli,
    # ligaturalar ularning yopilishi orqali saqlanadi.
    codes.update(range(0x1F1E6, 0x1F200))
    return codes


def main() -> int:
    source = BACKUP if BACKUP.exists() else FONT
    if not BACKUP.exists():
        shutil.copy2(FONT, BACKUP)
    codes = sorted(wanted())
    print("saqlanadigan belgilar: %d" % len(codes))
    subprocess.run([
        sys.executable, "-m", "fontTools.subset", str(source),
        "--unicodes=" + ",".join("U+%04X" % c for c in codes),
        "--layout-features+=ccmp",
        "--notdef-outline",
        "--output-file=" + str(FONT),
    ], check=True)
    print("hajm: %.1f MB -> %.1f MB" % (
        source.stat().st_size / 1e6, FONT.stat().st_size / 1e6))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
