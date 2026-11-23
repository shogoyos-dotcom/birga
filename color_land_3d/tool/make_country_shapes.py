#!/usr/bin/env python3
"""Mamlakatlar yo'li uchun soddalashtirilgan shakllar.

Bosh menyudagi "mamlakatni egallash" yo'li shu fayldan o'qiladi:
har mamlakatning konturi va unga kerak bo'ladigan ochko.

Shakl Natural Earth 1:110m dan olinadi (public domain, CC0) va
Duglas-Pyoker usuli bilan soddalashtiriladi — menyuda u 200
nuqtali emas, 40 nuqtali chiziq bo'lib chiziladi, fayl esa
kichik bo'lib qoladi.

Koordinatalar 0..1 oralig'iga keltiriladi, nisbati saqlanadi va
shakl kvadrat ichida markazlashtiriladi: chizuvchi hech narsa
hisoblamasdan, to'g'ridan-to'g'ri chizaveradi.

Ishga tushirish:
  python3 tool/make_country_shapes.py

Natija:
  data/country_shapes.json
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get(
    'NE_CACHE', os.path.join(HERE, '..', 'build', 'naturalearth'))
OUT = os.path.join(HERE, '..', 'data', 'country_shapes.json')

## Yo'l: uydan boshlanib, dunyoga chiqadi. Tartibi ataylab shunday —
## birinchi mamlakat o'yinchining o'z yurti bo'lsin.
ORDER = [
    'Uzbekistan', 'Kyrgyzstan', 'Tajikistan', 'Turkmenistan',
    'Azerbaijan', 'Kazakhstan', 'Afghanistan', 'Turkey', 'Iran',
    'Pakistan', 'Saudi Arabia', 'Egypt', 'India', 'China',
    'Mongolia', 'Russia', 'Indonesia', 'Japan', 'Germany', 'France',
    'Spain', 'United Kingdom', 'Italy', 'Brazil', 'Argentina',
    'United States of America', 'Canada', 'Australia',
]

## Birinchi mamlakatning narxi va har keyingisiga qo'shiladigani.
GOAL_FIRST = 120
GOAL_STEP = 70

## Bitta halqada shuncha nuqtadan ortiq qolmasin.
MAX_POINTS = 44
## Eng katta halqaning shuncha ulushidan kichik orol tashlanadi.
MIN_RING = 0.03
## Bitta mamlakatdan shuncha halqa olinadi.
MAX_RINGS = 6


def rings(geom):
    if geom['type'] == 'Polygon':
        yield from geom['coordinates']
    elif geom['type'] == 'MultiPolygon':
        for poly in geom['coordinates']:
            yield from poly


def area(ring):
    """Ko'pburchak yuzi (ishorasiz)."""
    total = 0.0
    for i in range(len(ring)):
        x0, y0 = ring[i - 1][0], ring[i - 1][1]
        x1, y1 = ring[i][0], ring[i][1]
        total += x0 * y1 - x1 * y0
    return abs(total) * 0.5


def simplify(ring, tolerance):
    """Duglas-Pyoker. Halqa yopiq, shuning uchun ikki uchi qoladi."""
    if len(ring) <= 3:
        return ring
    keep = [False] * len(ring)
    keep[0] = keep[-1] = True
    stack = [(0, len(ring) - 1)]
    while stack:
        first, last = stack.pop()
        if last <= first + 1:
            continue
        ax, ay = ring[first]
        bx, by = ring[last]
        dx, dy = bx - ax, by - ay
        span = math.hypot(dx, dy)
        worst, at = -1.0, first
        for i in range(first + 1, last):
            px, py = ring[i]
            if span == 0.0:
                gap = math.hypot(px - ax, py - ay)
            else:
                gap = abs(dy * px - dx * py + bx * ay - by * ax) / span
            if gap > worst:
                worst, at = gap, i
        if worst > tolerance:
            keep[at] = True
            stack.append((first, at))
            stack.append((at, last))
    return [p for p, k in zip(ring, keep) if k]


def thin(ring):
    """Nuqtalar soni chegaradan oshmaguncha soddalashtiradi."""
    tolerance = 0.02
    out = simplify(ring, tolerance)
    while len(out) > MAX_POINTS and tolerance < 20.0:
        tolerance *= 1.6
        out = simplify(ring, tolerance)
    return out


def shape_of(feature):
    all_rings = [r for r in rings(feature['geometry']) if len(r) >= 4]
    all_rings.sort(key=area, reverse=True)
    biggest = area(all_rings[0])
    kept = [r for r in all_rings[:MAX_RINGS]
            if area(r) >= biggest * MIN_RING]

    # Uzunlik kenglikka qarab siqiladi: aks holda shimoldagi
    # mamlakat cho'zilib ketadi.
    lats = [c[1] for r in kept for c in r]
    scale = math.cos(math.radians(sum(lats) / len(lats)))
    flat = [[(c[0] * scale, -c[1]) for c in thin(r)] for r in kept]

    xs = [p[0] for r in flat for p in r]
    ys = [p[1] for r in flat for p in r]
    width = max(xs) - min(xs)
    height = max(ys) - min(ys)
    span = max(width, height) or 1.0
    # Kvadrat ichida markazga qo'yiladi.
    ox = (span - width) * 0.5 - min(xs)
    oy = (span - height) * 0.5 - min(ys)
    out = []
    for ring in flat:
        row = []
        for x, y in ring:
            row.append(round((x + ox) / span, 4))
            row.append(round((y + oy) / span, 4))
        out.append(row)
    return out


def main():
    path = os.path.join(CACHE, 'ne_110m_admin_0_countries.geojson')
    data = json.load(open(path, encoding='utf-8'))
    by_name = {}
    for f in data['features']:
        p = f['properties']
        for key in ('NAME', 'NAME_LONG', 'ADMIN'):
            if p.get(key):
                by_name.setdefault(p[key], f)

    out = []
    for i, name in enumerate(ORDER):
        feature = by_name.get(name)
        if feature is None:
            raise SystemExit(f'topilmadi: {name}')
        # Natural Earth ayrim mamlakatda `ISO_A2` ni "-99" qilib
        # qo'yadi (Fransiya, Norvegiya) — zaxira maydonlar bor.
        props = feature['properties']
        code = ''
        for key in ('ISO_A2', 'ISO_A2_EH', 'WB_A2'):
            value = props.get(key) or ''
            if len(value) == 2 and value.isalpha():
                code = value
                break
        if not code:
            raise SystemExit(f'{name}: ISO kodi yo\'q')
        out.append({
            'code': code,
            'name': name,
            'goal': GOAL_FIRST + GOAL_STEP * i,
            'rings': shape_of(feature),
        })

    points = sum(len(r) // 2 for c in out for r in c['rings'])
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump({'countries': out}, f, ensure_ascii=False,
                  separators=(',', ':'))
    size = os.path.getsize(OUT)
    print(f'{len(out)} mamlakat, {points} nuqta, {size // 1024} KB')


if __name__ == '__main__':
    main()
