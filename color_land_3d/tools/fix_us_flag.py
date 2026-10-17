import math

rows = [
    (15, [28, 88, 148, 208, 268, 328]),
    (42, [58, 118, 178, 238, 298]),
    (69, [28, 88, 148, 208, 268, 328]),
    (96, [58, 118, 178, 238, 298]),
    (123, [28, 88, 148, 208, 268, 328]),
    (150, [58, 118, 178, 238, 298]),
    (177, [28, 88, 148, 208, 268, 328]),
    (204, [58, 118, 178, 238, 298]),
    (231, [28, 88, 148, 208, 268, 328])
]

R = 10.5
r = 4.2

stars = []
for y, xs in rows:
    for x in xs:
        pts = []
        for k in range(10):
            ang = -math.pi/2 + k * (math.pi / 5.0)
            rad = R if k % 2 == 0 else r
            px = round(x + rad * math.cos(ang), 2)
            py = round(y + rad * math.sin(ang), 2)
            pts.append(f"{px},{py}")
        stars.append(f'  <polygon fill="#fff" points="{" ".join(pts)}"/>')

svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" id="flag-icons-us" viewBox="0 0 640 480">
  <path fill="#bd3d44" d="M0 0h640v480H0"/>
  <path stroke="#fff" stroke-width="37" d="M0 55.3h640M0 129h640M0 203h640M0 277h640M0 351h640M0 425h640"/>
  <path fill="#192f5d" d="M0 0h364.8v258.5H0"/>
  <g id="stars">
{chr(10).join(stars)}
  </g>
</svg>"""

with open(r"d:\antigravity\color land\color_land_3d\assets\flags\svg\US.svg", "w", encoding="utf-8") as f:
    f.write(svg_content)

with open(r"d:\antigravity\color land\color_land_3d\assets\flags\svg\UM.svg", "w", encoding="utf-8") as f:
    f.write(svg_content)

print(f"Generated {len(stars)} stars in US.svg and UM.svg")
