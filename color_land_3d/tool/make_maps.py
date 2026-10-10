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
import collections
import json
import zlib
import math
import os
import sys
import urllib.request

BASE = ('https://raw.githubusercontent.com/nvkelso/natural-earth-vector/'
        'master/geojson')
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get('NE_CACHE', os.path.join(HERE, '..', 'build', 'naturalearth'))
OUT = os.path.join(HERE, '..', 'data', 'maps')

## Maydon to'ri o'yin panjarasidan shuncha marta maydaroq.
## Chegara shu to'rda chiziqli interpolatsiya bilan topiladi.
SUB = 2

## Chegara sathi.
ISO = 0.5

## Koordinatalar shuncha ulushda yoziladi (1/64 katak).
FIXED = 64

## Har maydonda taxminan shuncha quruqlik katagi bo'lsin.
TARGET_LAND = 26000

## Panjara tomoni shundan oshmasin.
MAX_SIDE = 460

## Shundan kichik orol olib tashlanadi (katak).
MIN_ISLAND = 24

## Shundan uzun ko'prik chizilmaydi — bo'lak olib tashlanadi (katak).
MAX_BRIDGE = 90

## Ko'prik yarim kengligi (katak). Silliqlashdan keyin ham qolishi
## uchun yetarlicha keng.
BRIDGE_RADIUS = 2.2

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


def components(land, w, h):
    """Quruqlikning bog'langan bo'laklari (4 tomonlama)."""
    label = [0] * (w * h)
    sizes = {}
    current = 0
    for start in range(w * h):
        if not land[start] or label[start]:
            continue
        current += 1
        stack = [start]
        label[start] = current
        count = 0
        while stack:
            i = stack.pop()
            count += 1
            x, y = i % w, i // w
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h:
                    j = ny * w + nx
                    if land[j] and not label[j]:
                        label[j] = current
                        stack.append(j)
        sizes[current] = count
    return label, sizes


def stamp_disc(mask, w, h, cx, cy, radius):
    r = int(math.ceil(radius))
    r2 = radius * radius
    for dy in range(-r, r + 1):
        y = cy + dy
        if y < 0 or y >= h:
            continue
        row = y * w
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy > r2:
                continue
            x = cx + dx
            if 0 <= x < w:
                mask[row + x] = 1


def stamp_line(mask, w, h, x0, y0, x1, y1, radius):
    """Ikki nuqta orasiga qalin yo'l chizadi."""
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for s in range(steps + 1):
        cx = int(round(x0 + (x1 - x0) * s / steps))
        cy = int(round(y0 + (y1 - y0) * s / steps))
        stamp_disc(mask, w, h, cx, cy, radius)


def drop_small(land, w, h, min_island):
    """Juda kichik orollarni olib tashlaydi — ularda o'ynab bo'lmaydi."""
    label, sizes = components(land, w, h)
    alive = {k for k, n in sizes.items() if n >= min_island}
    removed = 0
    for i in range(w * h):
        if land[i] and label[i] not in alive:
            land[i] = 0
            removed += 1
    return removed


def plan_bridges(land, w, h, max_bridge):
    """Orollarni materikka ulaydigan eng qisqa ko'priklarni rejalashtiradi.

    Suv bo'ylab ko'p manbali BFS har suv katagi uchun eng yaqin
    quruqlik katagini topadi; ikki bo'lak uchrashgan joy ular
    orasidagi eng tor suv oralig'i bo'ladi. Shundan keyin Kruskal
    bilan hammasi bitta tarmoqqa bog'lanadi.

    Natija: (ko'priklar, ulanmay qolgan bo'lak raqamlari, belgilar).
    """
    label, sizes = components(land, w, h)
    if len(sizes) <= 1:
        return [], set(), label

    INF = 1 << 30
    dist = [INF] * (w * h)
    origin = [-1] * (w * h)
    owner = [0] * (w * h)
    queue = collections.deque()
    for i in range(w * h):
        if land[i]:
            dist[i] = 0
            origin[i] = i
            owner[i] = label[i]
            queue.append(i)
    while queue:
        i = queue.popleft()
        x, y = i % w, i // w
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            j = ny * w + nx
            if land[j] or dist[j] != INF:
                continue
            dist[j] = dist[i] + 1
            origin[j] = origin[i]
            owner[j] = owner[i]
            queue.append(j)

    best = {}
    for i in range(w * h):
        if owner[i] == 0:
            continue
        x, y = i % w, i // w
        for nx, ny in ((x + 1, y), (x, y + 1)):
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            j = ny * w + nx
            if owner[j] == 0 or owner[j] == owner[i]:
                continue
            key = (min(owner[i], owner[j]), max(owner[i], owner[j]))
            cost = dist[i] + dist[j] + 1
            if key not in best or cost < best[key][0]:
                best[key] = (cost, origin[i], origin[j])

    parent = {k: k for k in sizes}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    bridges = []
    for (a, b), (cost, ia, ib) in sorted(best.items(), key=lambda e: e[1][0]):
        if cost > max_bridge:
            continue
        ra, rb = find(a), find(b)
        if ra == rb:
            continue
        parent[ra] = rb
        bridges.append((ia % w, ia // w, ib % w, ib // w))

    main = find(max(sizes, key=lambda k: sizes[k]))
    dead = {k for k in sizes if find(k) != main}
    return bridges, dead, label


def dilate(mask, w, h, radius):
    """Niqobni `radius` katakka kengaytiradi (ikki o'q bo'ylab)."""
    tmp = bytearray(w * h)
    for y in range(h):
        row = y * w
        for x in range(w):
            for dx in range(-radius, radius + 1):
                xx = x + dx
                if 0 <= xx < w and mask[row + xx]:
                    tmp[row + x] = 1
                    break
    out = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            for dy in range(-radius, radius + 1):
                yy = y + dy
                if 0 <= yy < h and tmp[yy * w + x]:
                    out[y * w + x] = 1
                    break
    return out


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


def build_field(land, w, h, sub):
    """Quruqlikning uzluksiz maydoni: 0 — suv, 1 — quruqlik.

    Niqob `sub` barobar maydaroq to'rga ko'chiriladi va uch marta
    kvadrat silliqlash bilan yumshatiladi (taxminan gauss, sigma ~ bir
    katak). Chegara shu maydonning 0.5 sathidan olinadi — shuning
    uchun u katakka yopishmaydi va silliq egri chiziq bo'ladi.
    """
    fw, fh = w * sub, h * sub
    field = [0.0] * (fw * fh)
    for y in range(h):
        row = y * w
        for x in range(w):
            if not land[row + x]:
                continue
            for sy in range(y * sub, (y + 1) * sub):
                base = sy * fw + x * sub
                for sx in range(sub):
                    field[base + sx] = 1.0
    for _ in range(3):
        field = box_blur(field, fw, fh, sub)
    return field, fw, fh


def logic_from_field(field, fw, w, h, sub):
    """Mantiq niqobi: katak markazidagi qiymat 0.5 dan katta bo'lsa
    quruqlik. Ko'rinadigan chegara ham shu sathdan olingani uchun ikkisi
    bir-biriga mos tushadi."""
    land = bytearray(w * h)
    half = sub // 2
    for y in range(h):
        for x in range(w):
            if field[(y * sub + half) * fw + x * sub + half] >= ISO:
                land[y * w + x] = 1
    return land


def stamp_field(field, fw, fh, x0, y0, x1, y1, radius, sub):
    """Maydonga quruqlik yo'li chizadi (ko'prik)."""
    fx0, fy0 = (x0 + 0.5) * sub, (y0 + 0.5) * sub
    fx1, fy1 = (x1 + 0.5) * sub, (y1 + 0.5) * sub
    r = radius * sub
    steps = int(max(abs(fx1 - fx0), abs(fy1 - fy0))) + 1
    for s in range(steps + 1):
        cx = fx0 + (fx1 - fx0) * s / steps
        cy = fy0 + (fy1 - fy0) * s / steps
        ri = int(math.ceil(r))
        for dy in range(-ri, ri + 1):
            yy = int(cy) + dy
            if yy < 0 or yy >= fh:
                continue
            for dx in range(-ri, ri + 1):
                if dx * dx + dy * dy > r * r:
                    continue
                xx = int(cx) + dx
                if 0 <= xx < fw:
                    field[yy * fw + xx] = 1.0


def clear_field(field, fw, fh, keep, w, h, sub):
    """Olib tashlangan oroldan qolgan maydonni nolga tushiradi."""
    near = dilate(keep, w, h, 2)
    for fy in range(fh):
        cy = (fy // sub) * w
        row = fy * fw
        for fx in range(fw):
            if field[row + fx] > 0.0 and not near[cy + fx // sub]:
                field[row + fx] = 0.0


# ——— Marching squares: maydondan silliq geometriya ———

def contour_mesh(field, fw, fh, sub):
    """Maydonning 0.5 sathidan arena geometriyasini quradi.

    Har kvadrat (to'rtta qo'shni namuna) ichida quruqlik qismi
    ko'pburchak bo'lib chiqariladi; chiziq kvadrat qirralarini
    **chiziqli interpolatsiya** bilan kesadi, shuning uchun chegara
    katakka yopishmaydi va zinapoya bo'lmaydi.

    To'liq ichkaridagi kvadratlar qator bo'ylab birlashtiriladi
    (greedy), aks holda uchburchaklar soni behuda ko'payardi.

    Natija: (ustki uchburchaklar, devor kesmalari) — ikkalasi ham
    katak birligidagi (x, z) juftliklar ro'yxati.
    """
    scale = 1.0 / sub
    tris = []
    walls = []

    def value(x, y):
        return field[y * fw + x]

    def point(x, y):
        return ((x + 0.5) * scale, (y + 0.5) * scale)

    def cross(ax, ay, bx, by):
        va, vb = value(ax, ay), value(bx, by)
        t = 0.5 if vb == va else (ISO - va) / (vb - va)
        t = min(1.0, max(0.0, t))
        pa, pb = point(ax, ay), point(bx, by)
        return (pa[0] + (pb[0] - pa[0]) * t, pa[1] + (pb[1] - pa[1]) * t)

    for y in range(fh - 1):
        x = 0
        while x < fw - 1:
            corners = ((x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1))
            inside = [value(cx, cy) >= ISO for cx, cy in corners]
            if all(inside):
                # To'liq ichkarida: qatordagi ketma-ket kvadratlarni
                # bitta to'rtburchakka birlashtiramiz.
                end = x
                while end < fw - 1 and value(end, y) >= ISO \
                        and value(end + 1, y) >= ISO \
                        and value(end + 1, y + 1) >= ISO \
                        and value(end, y + 1) >= ISO:
                    end += 1
                a = point(x, y)
                b = point(end, y)
                c = point(end, y + 1)
                d = point(x, y + 1)
                tris.append((a, b, c))
                tris.append((a, c, d))
                x = end
                continue
            if not any(inside):
                x += 1
                continue

            poly = []          # (nuqta, chegara ustidami)
            for i in range(4):
                j = (i + 1) % 4
                if inside[i]:
                    poly.append((point(*corners[i]), False))
                if inside[i] != inside[j]:
                    poly.append((cross(*corners[i], *corners[j]), True))

            saddle = inside[0] == inside[2] and inside[1] == inside[3] \
                and inside[0] != inside[1]
            middle = sum(value(cx, cy) for cx, cy in corners) / 4.0
            if saddle and ((inside[0] and middle < ISO)
                           or (inside[1] and middle < ISO)):
                # Egar holati: ikki burchak alohida uchburchak bo'ladi,
                # aks holda ko'pburchak o'zini kesib o'tardi.
                parts = [poly[0:3], poly[3:6]]
            else:
                parts = [poly]

            for part in parts:
                if len(part) < 3:
                    continue
                for k in range(1, len(part) - 1):
                    tris.append((part[0][0], part[k][0], part[k + 1][0]))
                for k in range(len(part)):
                    cur = part[k]
                    nxt = part[(k + 1) % len(part)]
                    if cur[1] and nxt[1]:
                        walls.append((cur[0], nxt[0]))
            x += 1
    return tris, walls


def pack_mesh(tris, walls):
    """Geometriyani ixcham ikkilik ko'rinishga keltiradi.

    Koordinatalar 1/64 katak aniqligida uint16 bo'lib yoziladi — bu
    ko'z ilg'amaydigan aniqlik, lekin hajmni ikki barobar kamaytiradi.
    """
    out = bytearray()
    out += len(tris).to_bytes(4, 'little')
    for tri in tris:
        for px, py in tri:
            out += int(round(px * FIXED)).to_bytes(2, 'little')
            out += int(round(py * FIXED)).to_bytes(2, 'little')
    out += len(walls).to_bytes(4, 'little')
    for a, b in walls:
        for px, py in (a, b):
            out += int(round(px * FIXED)).to_bytes(2, 'little')
            out += int(round(py * FIXED)).to_bytes(2, 'little')
    return bytes(out)


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


def places_for(places, land, box, w, h):
    """Maydon ichidagi shaharlar: poytaxtlar va yirik shaharlar.

    Natural Earth 1:50m ro'yxatida 1251 shahar bor — barcha davlat
    poytaxtlari va dunyodagi yirik shaharlar. Suvga tushib qolgani
    eng yaqin quruqlikka suriladi.
    """
    lon0, lon1, lat0, lat1 = box
    sx = w / (lon1 - lon0)
    sy = h / (lat1 - lat0)
    taken = set()
    rows = []
    for f in places['features']:
        p = f['properties']
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
            # 1 — davlat poytaxti: unga ustun ham qo'yiladi.
            'cap': 1 if int(p.get('adm0cap') or 0) == 1 else 0,
        })
    rows.sort(key=lambda c: (-c['cap'], -c['pop'], c['name']))
    return rows


def write_map(spec, w, h, land, mesh):
    os.makedirs(OUT, exist_ok=True)
    body = (w.to_bytes(2, 'little') + h.to_bytes(2, 'little')
            + pack(land) + mesh)
    # Godot "DEFLATE" rejimi zlib sarlavhasi bilan ishlaydi va ochilgan
    # hajmni oldindan biladi — shuning uchun hajm faylga yoziladi.
    blob = (b'CLM4' + len(body).to_bytes(4, 'little')
            + zlib.compress(body, 9))
    path = os.path.join(OUT, spec['id'] + '.bin')
    with open(path, 'wb') as f:
        f.write(blob)
    return len(blob), len(body)


def main():
    land_data = fetch('ne_110m_land.geojson')
    country_data = fetch('ne_110m_admin_0_countries.geojson')
    places = fetch('ne_50m_populated_places_simple.geojson')

    index = []
    total_bytes = 0
    for spec in MAPS:
        print(spec['id'])
        polys = collect(spec, land_data, country_data)
        box = bounds(polys, spec)
        w, h, raw, _ = grid_for(
            polys, box, spec.get('target', TARGET_LAND))
        drop_small(raw, w, h, MIN_ISLAND)

        field, fw, fh = build_field(raw, w, h, SUB)
        land = logic_from_field(field, fw, w, h, SUB)

        # Orollarni ulaydigan ko'priklar maydonga chiziladi, shuning
        # uchun ular ham silliq chetga ega bo'ladi.
        bridges, dead, label = plan_bridges(
            land, w, h, spec.get('max_bridge', MAX_BRIDGE))
        for x0, y0, x1, y1 in bridges:
            stamp_field(field, fw, fh, x0, y0, x1, y1, BRIDGE_RADIUS, SUB)
        dropped = 0
        if dead:
            keep = bytearray(land)
            for i in range(w * h):
                if land[i] and label[i] in dead:
                    keep[i] = 0
                    dropped += 1
            clear_field(field, fw, fh, keep, w, h, SUB)
        land = logic_from_field(field, fw, w, h, SUB)

        # Oxirgi tozalash: ajralib qolgan mayda bo'lak ham ketsin.
        comp, sizes = components(land, w, h)
        if len(sizes) > 1:
            main_part = max(sizes, key=lambda k: sizes[k])
            keep = bytearray(land)
            for i in range(w * h):
                if land[i] and comp[i] != main_part:
                    keep[i] = 0
                    dropped += 1
            clear_field(field, fw, fh, keep, w, h, SUB)
            land = logic_from_field(field, fw, w, h, SUB)

        tris, walls = contour_mesh(field, fw, fh, SUB)
        rows = places_for(places, land, box, w, h)
        count = sum(land)
        _, parts = components(land, w, h)
        size, raw_size = write_map(spec, w, h, land, pack_mesh(tris, walls))
        total_bytes += size
        print(f'    {len(bridges)} ko\'prik, {dropped} katak tashlandi, '
              f'{len(parts)} bo\'lak, quruqlik {count}')
        print(f'    {len(tris)} uchburchak, {len(walls)} devor, '
              f'{size / 1024:.0f} KB (siqilmagan {raw_size / 1024:.0f} KB), '
              f'{len(rows)} shahar')
        index.append({
            'id': spec['id'], 'name': spec['name'],
            'width': w, 'height': h, 'land': count, 'places': rows,
        })

    # Davlat -> materik: onlayn reyting uchun kerak.
    table = {}
    for f in country_data['features']:
        props = f['properties']
        code = (props.get('ISO_A2') or '').strip().upper()
        continent = props.get('CONTINENT') or ''
        if len(code) == 2 and code.isalpha() and continent:
            table[code] = continent
    with open(os.path.join(HERE, '..', 'data', 'continents.json'), 'w') as f:
        json.dump(dict(sorted(table.items())), f, ensure_ascii=False,
                  separators=(',', ':'))

    with open(os.path.join(OUT, 'index.json'), 'w') as f:
        json.dump({'maps': index}, f, ensure_ascii=False,
                  separators=(',', ':'))
    print(f'jami {total_bytes / 1024:.0f} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main())
