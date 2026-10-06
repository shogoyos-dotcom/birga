#!/usr/bin/env python3
"""Dunyo xaritasini va poytaxtlarni o'yin panjarasiga aylantiradi.

Manba — Natural Earth (public domain, CC0):
  ne_110m_land.geojson                    quruqlik chegaralari
  ne_110m_populated_places_simple.geojson  shaharlar (poytaxtlar bilan)

Ishga tushirish:
  python3 tool/make_world_map.py [kenglik] [balandlik]

Natija:
  lib/data/world_map.dart   quruqlik niqobi (base64, bit-bit)
  lib/data/capitals.dart    poytaxtlar: nomi, davlat kodi, katak koordinatasi

Fayllar yuklab olinmagan bo'lsa, skript ularni o'zi yuklaydi.
"""
import base64
import json
import os
import sys
import urllib.request

BASE = (
    'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/'
    'master/geojson'
)
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, '..', 'build', 'naturalearth')
OUT = os.path.join(HERE, '..', 'lib', 'data')

# Antarktida o'yin uchun foydasiz — kesib tashlanadi.
LAT_TOP = 83.0
LAT_BOTTOM = -58.0


def fetch(name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        print(f'yuklanmoqda: {name}')
        urllib.request.urlretrieve(f'{BASE}/{name}', path)
    return json.load(open(path))


def to_grid(lon, lat, w, h):
    x = (lon + 180.0) / 360.0 * w
    y = (LAT_TOP - lat) / (LAT_TOP - LAT_BOTTOM) * h
    return x, y


def rings(geom):
    if geom['type'] == 'Polygon':
        yield from geom['coordinates']
    elif geom['type'] == 'MultiPolygon':
        for poly in geom['coordinates']:
            yield from poly


def rasterize(w, h):
    """Scanline to'ldirish: har qator uchun kesishmalar juft-juft bo'yab
    chiqiladi. Juft-toq qoidasi tufayli ichki teshiklar (masalan Kaspiy)
    o'z-o'zidan suv bo'lib qoladi."""
    data = fetch('ne_110m_land.geojson')
    polys = []
    for f in data['features']:
        for r in rings(f['geometry']):
            polys.append([to_grid(c[0], c[1], w, h) for c in r])

    land = bytearray(w * h)
    for y in range(h):
        cy = y + 0.5
        xs = []
        for ring in polys:
            n = len(ring)
            for i in range(n):
                x1, y1 = ring[i]
                x2, y2 = ring[(i + 1) % n]
                if (y1 <= cy < y2) or (y2 <= cy < y1):
                    t = (cy - y1) / (y2 - y1)
                    xs.append(x1 + t * (x2 - x1))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            a = max(0, int(xs[i] + 0.5))
            b = min(w, int(xs[i + 1] + 0.5))
            for x in range(a, b):
                land[y * w + x] = 1
    return land


def nearest_land(land, w, h, x, y, radius=6):
    """Poytaxt suvga tushib qolsa (qirg'oq dag'al chizilgani uchun),
    eng yaqin quruqlik katagiga suriladi."""
    if 0 <= x < w and 0 <= y < h and land[y * w + x]:
        return x, y
    best = None
    for r in range(1, radius + 1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and land[ny * w + nx]:
                    d = dx * dx + dy * dy
                    if best is None or d < best[0]:
                        best = (d, nx, ny)
        if best:
            return best[1], best[2]
    return None


def make_island(land, w, h, x, y, size=3):
    """Kichik orol-davlat 110m xaritada umuman yo'q (Maldiv, Tuvalu...).
    Poytaxt tushib qolmasligi uchun o'sha joyda kichik orol yaratiladi."""
    half = size // 2
    for dy in range(-half, half + 1):
        for dx in range(-half, half + 1):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                land[ny * w + nx] = 1


def free_spot(land, w, h, taken, x, y, radius=3):
    """Ikki poytaxt bir katakka tushsa, yonidagi bo'sh quruqlikka suradi."""
    if (x, y) not in taken:
        return x, y
    for r in range(1, radius + 1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                nx, ny = x + dx, y + dy
                if (nx, ny) in taken:
                    continue
                if 0 <= nx < w and 0 <= ny < h and land[ny * w + nx]:
                    return nx, ny
    return x, y


def capitals(land, w, h):
    data = fetch('ne_110m_populated_places_simple.geojson')
    rows = []
    for f in data['features']:
        p = f['properties']
        if 'capital' not in str(p.get('featurecla', '')).lower():
            continue
        lon, lat = f['geometry']['coordinates'][:2]
        if not (LAT_BOTTOM < lat < LAT_TOP):
            continue
        fx, fy = to_grid(lon, lat, w, h)
        gx, gy = int(fx), int(fy)
        spot = nearest_land(land, w, h, gx, gy)
        if spot is None:
            make_island(land, w, h, gx, gy)
            spot = (gx, gy)
        code = (p.get('iso_a2') or '').strip().upper()
        if len(code) != 2 or not code.isalpha():
            code = ''
        name = p.get('nameascii') or p.get('name')
        pop = int(p.get('pop_max') or 0)
        rows.append((name, code, spot[0], spot[1], pop))

    taken = set()
    out = []
    for name, code, x, y, pop in rows:
        x, y = free_spot(land, w, h, taken, x, y)
        taken.add((x, y))
        out.append((name, code, x, y, pop))
    # Aholisi ko'p shahar oldinda — yozuvlar zich joyda shular qoladi.
    return sorted(out, key=lambda c: (-c[4], c[0]))


def dart_escape(text):
    return text.replace('\\', '\\\\').replace("'", "\\'")


def write_map(land, w, h):
    packed = bytearray((w * h + 7) // 8)
    for i, v in enumerate(land):
        if v:
            packed[i >> 3] |= 1 << (i & 7)
    blob = base64.b64encode(bytes(packed)).decode()
    lines = [blob[i:i + 76] for i in range(0, len(blob), 76)]
    body = '\n'.join(f"    '{ln}'" for ln in lines)
    total = sum(land)
    path = os.path.join(OUT, 'world_map.dart')
    with open(path, 'w') as f:
        f.write(f'''// GENERATSIYA QILINGAN FAYL — qo'lda tahrirlanmasin.
// Yaratuvchi: tool/make_world_map.py
// Manba: Natural Earth 1:110m land (public domain).
import 'dart:convert';
import 'dart:typed_data';

/// Dunyo xaritasining panjaradagi o'lchami.
const int kWorldWidth = {w};
const int kWorldHeight = {h};

/// Quruqlik kataklari soni (jami {w * h} tadan).
const int kWorldLandCells = {total};

/// Kengliklar oralig'i — Antarktida kiritilmagan.
const double kWorldLatTop = {LAT_TOP};
const double kWorldLatBottom = {LAT_BOTTOM};

/// Quruqlik niqobi: har katak uchun bitta bit, base64 da.
const String _packed =
{body};

/// Niqobni ochadi: 1 — quruqlik, 0 — suv.
Uint8List decodeWorldLand() {{
  final bytes = base64Decode(_packed);
  final land = Uint8List(kWorldWidth * kWorldHeight);
  for (var i = 0; i < land.length; i++) {{
    land[i] = (bytes[i >> 3] >> (i & 7)) & 1;
  }}
  return land;
}}
''')
    print(f'world_map.dart: {w}x{h}, quruqlik {total} '
          f'({total * 100 / (w * h):.1f}%), base64 {len(blob) / 1024:.1f} KB')


def write_capitals(caps, w, h):
    rows = ',\n'.join(
        f"  Capital('{dart_escape(n)}', '{c}', {x}, {y}, {pop})"
        for n, c, x, y, pop in caps
    )
    path = os.path.join(OUT, 'capitals.dart')
    with open(path, 'w') as f:
        f.write(f'''// GENERATSIYA QILINGAN FAYL — qo'lda tahrirlanmasin.
// Yaratuvchi: tool/make_world_map.py
// Manba: Natural Earth 1:110m populated places (public domain).

/// Xaritadagi poytaxt.
class Capital {{
  const Capital(this.name, this.countryCode, this.x, this.y, this.population);

  final String name;

  /// ISO 3166-1 alpha-2; noma'lum bo'lsa bo'sh satr.
  final String countryCode;

  /// Panjaradagi katak koordinatasi.
  final int x;
  final int y;

  /// Aholisi — yozuvlar zich joyda qaysi biri ko'rsatilishini belgilaydi.
  final int population;
}}

/// Dunyodagi poytaxtlar ({len(caps)} ta), aholisi bo'yicha kamayish
/// tartibida.
const List<Capital> kCapitals = <Capital>[
{rows},
];
''')
    print(f'capitals.dart: {len(caps)} ta poytaxt')


if __name__ == '__main__':
    width = int(sys.argv[1]) if len(sys.argv) > 1 else 520
    height = int(sys.argv[2]) if len(sys.argv) > 2 else 205
    os.makedirs(OUT, exist_ok=True)
    mask = rasterize(width, height)
    # Poytaxtlar avval hisoblanadi — ular niqobga kichik orollar qo'shishi
    # mumkin, shuning uchun xarita keyin yoziladi.
    caps = capitals(mask, width, height)
    write_map(mask, width, height)
    write_capitals(caps, width, height)
