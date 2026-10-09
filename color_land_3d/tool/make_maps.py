#!/usr/bin/env python3
"""O'yin maydonlarini Natural Earth ma'lumotidan yaratadi.

Har maydon uchun ikkita niqob yoziladi:

  * **mantiq niqobi** — o'yin panjarasi (bir katak = bir o'yin katagi).
    Harakat, iz va hudud shu niqob bo'yicha hisoblanadi.
  * **chizish niqobi** — uch barobar maydaroq va **silliqlangan**.
    Arena geometriyasi shundan quriladi, shuning uchun qirg'oq
    zinapoya emas, mayin chiziq bo'lib ko'rinadi.

Silliqlash kubik (B-splayn) yadro bilan bajariladi — arena shaderidagi
hudud chegarasi bilan bir xil usul. Bo'sag'a 0.5 dan pastroq olingan:
shunda ingichka bo'g'ozlar va kichik orollar yo'qolmaydi. Baribir
yo'qolganlari uchun har bir quruqlik katagining markazi majburan
quruqlik qilib qoldiriladi.

Manba — Natural Earth 1:110m (public domain, CC0).

Ishga tushirish:
  python3 tool/make_maps.py

Natija:
  data/maps/<id>.bin     niqoblar
  data/maps/index.json   maydonlar ro'yxati va poytaxtlar
"""
import json
import math
import os
import sys
import urllib.request

BASE = ('https://raw.githubusercontent.com/nvkelso/natural-earth-vector/'
        'master/geojson')
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get('NE_CACHE', os.path.join(HERE, '..', 'build', 'naturalearth'))
OUT = os.path.join(HERE, '..', 'data', 'maps')

## Chizish niqobi mantiq niqobidan shuncha marta maydaroq.
SCALE = 3

## Silliqlash bo'sag'asi: aynan yarim — quruqlik maydoni saqlanadi.
THRESHOLD = 0.5

## Har maydonda taxminan shuncha quruqlik katagi bo'lsin.
TARGET_LAND = 26000

## Panjara tomoni shundan oshmasin.
MAX_SIDE = 460

## Maydonlar. `box` — (lon0, lon1, lat_pastki, lat_yuqori); berilmasa
## materikning o'z chegarasidan olinadi.
##
## Natural Earth Rossiyani "Europe" deb belgilaydi, shuning uchun
## Yevropa qutisi qo'lda cheklanadi va Rossiya Osiyoga ham qo'shiladi.
MAPS = [
    {'id': 'world', 'name': 'World', 'continents': None,
     'box': (-180.0, 180.0, -58.0, 83.0), 'target': 32000},
    {'id': 'africa', 'name': 'Africa', 'continents': ['Africa']},
    {'id': 'asia', 'name': 'Asia', 'continents': ['Asia'],
     'extra': ['Russia'], 'box': (25.0, 190.0, -11.0, 78.0)},
    {'id': 'europe', 'name': 'Europe', 'continents': ['Europe'],
     'box': (-25.0, 45.0, 34.0, 71.0)},
    {'id': 'north_america', 'name': 'North America',
     'continents': ['North America']},
    {'id': 'south_america', 'name': 'South America',
     'continents': ['South America']},
    {'id': 'oceania', 'name': 'Oceania', 'continents': ['Oceania'],
     'box': (110.0, 190.0, -48.0, 0.0)},
]


def fetch(name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        print(f'yuklanmoqda: {name}')
        urllib.request.urlretrieve(f'{BASE}/{name}', path)
    return json.load(open(path))


def rings(geom):
    if geom['type'] == 'Polygon':
        yield from geom['coordinates']
    elif geom['type'] == 'MultiPolygon':
        for poly in geom['coordinates']:
            yield from poly


def shift(lon, lon0, lon1):
    """180-meridiandan o'tadigan quti uchun uzunlikni suradi."""
    if lon1 > 180.0 and lon < lon0:
        return lon + 360.0
    return lon


def collect(spec, land_data, country_data):
    """Maydonga kiradigan ko'pburchaklar va ularning chegarasi."""
    if spec['continents'] is None:
        polys = [r for f in land_data['features'] for r in rings(f['geometry'])]
    else:
        names = set(spec.get('extra', []))
        polys = []
        for f in country_data['features']:
            p = f['properties']
            if p.get('CONTINENT') in spec['continents'] or p.get('NAME') in names:
                polys.extend(rings(f['geometry']))
    return polys


def bounds(polys, spec):
    if 'box' in spec:
        return spec['box']
    lons = [c[0] for ring in polys for c in ring]
    lats = [c[1] for ring in polys for c in ring]
    lon0, lon1 = min(lons), max(lons)
    # 180-meridiandan o'tganini sezish: oraliq juda keng chiqsa,
    # manfiy uzunliklar 360 ga suriladi.
    if lon1 - lon0 > 180.0:
        moved = [c + 360.0 if c < 0 else c for c in lons]
        if max(moved) - min(moved) < lon1 - lon0:
            lon0, lon1 = min(moved), max(moved)
    pad_x = (lon1 - lon0) * 0.03
    pad_y = (max(lats) - min(lats)) * 0.03
    return (lon0 - pad_x, lon1 + pad_x,
            max(min(lats) - pad_y, -58.0), min(max(lats) + pad_y, 83.0))


def rasterize(polys, box, w, h):
    """Scanline to'ldirish: juft-toq qoidasi tufayli ichki dengizlar
    (Kaspiy kabi) o'z-o'zidan suv bo'lib qoladi."""
    lon0, lon1, lat0, lat1 = box
    sx = w / (lon1 - lon0)
    sy = h / (lat1 - lat0)
    edges = []
    for ring in polys:
        pts = [((shift(c[0], lon0, lon1) - lon0) * sx, (lat1 - c[1]) * sy)
               for c in ring]
        for i in range(len(pts)):
            edges.append((pts[i], pts[(i + 1) % len(pts)]))

    land = bytearray(w * h)
    for y in range(h):
        cy = y + 0.5
        xs = []
        for (x1, y1), (x2, y2) in edges:
            if (y1 <= cy < y2) or (y2 <= cy < y1):
                xs.append(x1 + (cy - y1) / (y2 - y1) * (x2 - x1))
        xs.sort()
        row = y * w
        for i in range(0, len(xs) - 1, 2):
            a = max(0, int(xs[i] + 0.5))
            b = min(w, int(xs[i + 1] + 0.5))
            for x in range(a, b):
                land[row + x] = 1
    return land


def grid_for(polys, box, target):
    """Quruqlik kataklari soni `target` ga yaqin bo'ladigan panjara."""
    lon0, lon1, lat0, lat1 = box
    aspect = (lon1 - lon0) / (lat1 - lat0)
    low, high = 0.2, 6.0
    best = None
    for _ in range(12):
        k = (low + high) / 2.0           # katak / gradus
        w = min(MAX_SIDE, max(40, int(round((lon1 - lon0) * k))))
        h = min(MAX_SIDE, max(40, int(round((lat1 - lat0) * k))))
        land = rasterize(polys, box, w, h)
        count = sum(land)
        best = (w, h, land, count)
        if count > target:
            high = k
        else:
            low = k
        if abs(count - target) < target * 0.06:
            break
    print(f'    panjara {best[0]}x{best[1]}, quruqlik {best[3]} '
          f'({best[3] * 100 / (best[0] * best[1]):.1f}%), nisbat {aspect:.2f}')
    return best


def box_blur(field, w, h, radius):
    """Yugurib boruvchi yig'indi bilan kvadrat silliqlash (ikki o'q)."""
    out = [0.0] * (w * h)
    size = radius * 2 + 1
    for y in range(h):
        row = y * w
        total = field[row] * (radius + 1)
        for x in range(1, radius + 1):
            total += field[row + min(x, w - 1)]
        for x in range(w):
            out[row + x] = total / size
            total += field[row + min(x + radius + 1, w - 1)]
            total -= field[row + max(x - radius, 0)]

    done = [0.0] * (w * h)
    for x in range(w):
        total = out[x] * (radius + 1)
        for y in range(1, radius + 1):
            total += out[min(y, h - 1) * w + x]
        for y in range(h):
            done[y * w + x] = total / size
            total += out[min(y + radius + 1, h - 1) * w + x]
            total -= out[max(y - radius, 0) * w + x]
    return done


def smooth(land, w, h, scale):
    """Chizish niqobi: `scale` barobar maydaroq va silliqlangan.

    Uch marta kvadrat silliqlash taxminan gauss yadrosini beradi
    (sigma ~ bir katak). Shuning uchun qirg'oqdagi bir kataklik
    zinapoyalar ham yo'qoladi, nafaqat burchaklar.
    """
    hw, hh = w * scale, h * scale
    field = [0.0] * (hw * hh)
    for y in range(h):
        row = y * w
        for x in range(w):
            if not land[row + x]:
                continue
            for sy in range(y * scale, (y + 1) * scale):
                base = sy * hw + x * scale
                for sx in range(scale):
                    field[base + sx] = 1.0

    for _ in range(3):
        field = box_blur(field, hw, hh, scale)

    out = bytearray(hw * hh)
    for i, v in enumerate(field):
        if v >= THRESHOLD:
            out[i] = 1
    return out, hw, hh


def logic_from(render, w, h, scale):
    """Mantiq niqobi silliqlangan niqobdan olinadi.

    Shunda ko'rinadigan quruqlik bilan yuriladigan quruqlik aynan bir
    xil bo'ladi: ko'rinmas yerda yurib qolish ham, ko'rinib turib
    kirib bo'lmaydigan burun ham bo'lmaydi.
    """
    hw = w * scale
    half = scale * scale / 2.0
    land = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            count = 0
            for sy in range(y * scale, (y + 1) * scale):
                base = sy * hw + x * scale
                for sx in range(scale):
                    count += render[base + sx]
            if count >= half:
                land[y * w + x] = 1
    return land


def pack(bits):
    out = bytearray((len(bits) + 7) // 8)
    for i, v in enumerate(bits):
        if v:
            out[i >> 3] |= 1 << (i & 7)
    return bytes(out)


def nearest_land(land, w, h, x, y, radius=5):
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


def capitals_for(places, land, box, w, h):
    """Maydon chegarasiga tushadigan poytaxtlar."""
    lon0, lon1, lat0, lat1 = box
    sx = w / (lon1 - lon0)
    sy = h / (lat1 - lat0)
    taken = set()
    rows = []
    for f in places['features']:
        p = f['properties']
        if 'capital' not in str(p.get('featurecla', '')).lower():
            continue
        lon, lat = f['geometry']['coordinates'][:2]
        lon = shift(lon, lon0, lon1)
        if not (lon0 <= lon <= lon1 and lat0 <= lat <= lat1):
            continue
        x = int((lon - lon0) * sx)
        y = int((lat1 - lat) * sy)
        spot = nearest_land(land, w, h, x, y)
        if spot is None or spot in taken:
            continue
        taken.add(spot)
        code = (p.get('iso_a2') or '').strip().upper()
        rows.append({
            'name': p.get('nameascii') or p.get('name'),
            'code': code if len(code) == 2 and code.isalpha() else '',
            'x': spot[0], 'y': spot[1],
            'pop': int(p.get('pop_max') or 0),
        })
    rows.sort(key=lambda c: (-c['pop'], c['name']))
    return rows


def write_map(spec, w, h, land, render, hw, hh):
    os.makedirs(OUT, exist_ok=True)
    header = (b'CLM3'
              + w.to_bytes(2, 'little') + h.to_bytes(2, 'little')
              + SCALE.to_bytes(1, 'little') + b'\0'
              + hw.to_bytes(2, 'little') + hh.to_bytes(2, 'little'))
    blob = header + pack(land) + pack(render)
    path = os.path.join(OUT, spec['id'] + '.bin')
    with open(path, 'wb') as f:
        f.write(blob)
    return len(blob)


def main():
    land_data = fetch('ne_110m_land.geojson')
    country_data = fetch('ne_110m_admin_0_countries.geojson')
    places = fetch('ne_110m_populated_places_simple.geojson')

    index = []
    total_bytes = 0
    for spec in MAPS:
        print(spec['id'])
        polys = collect(spec, land_data, country_data)
        box = bounds(polys, spec)
        w, h, raw, _ = grid_for(
            polys, box, spec.get('target', TARGET_LAND))
        render, hw, hh = smooth(raw, w, h, SCALE)
        land = logic_from(render, w, h, SCALE)
        count = sum(land)
        caps = capitals_for(places, land, box, w, h)
        print(f'    silliqlashdan keyin quruqlik {count}')
        size = write_map(spec, w, h, land, render, hw, hh)
        total_bytes += size
        print(f'    {size / 1024:.0f} KB, {len(caps)} poytaxt')
        index.append({
            'id': spec['id'], 'name': spec['name'],
            'width': w, 'height': h, 'scale': SCALE,
            'land': count, 'capitals': caps,
        })

    with open(os.path.join(OUT, 'index.json'), 'w') as f:
        json.dump({'maps': index}, f, ensure_ascii=False,
                  separators=(',', ':'))
    print(f'jami {total_bytes / 1024:.0f} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main())
