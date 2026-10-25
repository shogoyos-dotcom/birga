import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Resources", "UI"))
os.makedirs(OUT_DIR, exist_ok=True)

def create_play_icon():
    # 96x96 glossy white play triangle
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    s_pts = [(30, 22), (30, 78), (76, 50)]
    draw.polygon(s_pts, fill=(0, 0, 0, 90))
    img = img.filter(ImageFilter.GaussianBlur(2))
    draw = ImageDraw.Draw(img)
    
    # White Play Triangle
    pts = [(28, 20), (28, 76), (74, 48)]
    draw.polygon(pts, fill=(255, 255, 255, 255))
    # Bevel highlight
    draw.line([(28, 20), (74, 48)], fill=(255, 255, 255, 255), width=3)
    draw.line([(28, 20), (28, 76)], fill=(230, 240, 255, 255), width=3)
    draw.line([(28, 76), (74, 48)], fill=(190, 205, 220, 255), width=3)
    
    # Inner gloss
    inner_pts = [(32, 26), (32, 48), (56, 38)]
    draw.polygon(inner_pts, fill=(255, 255, 255, 120))
    
    img.save(os.path.join(OUT_DIR, "icon_play.png"))
    print("Saved icon_play.png")

def create_map_icon():
    # 96x96 folded 3-panel adventure map with pin
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Map folds: 3 segments
    # Panel 1 (left)
    p1 = [(18, 28), (38, 22), (38, 76), (18, 82)]
    # Panel 2 (middle)
    p2 = [(38, 22), (58, 28), (58, 82), (38, 76)]
    # Panel 3 (right)
    p3 = [(58, 28), (78, 22), (78, 76), (58, 82)]
    
    # Shadow
    s_pts = [(18, 32), (78, 26), (78, 84), (18, 88)]
    draw.polygon(s_pts, fill=(0, 0, 0, 70))
    img = img.filter(ImageFilter.GaussianBlur(2))
    draw = ImageDraw.Draw(img)
    
    # Colors: bright parchment / stylized map colors
    draw.polygon(p1, fill=(240, 245, 250, 255))
    draw.polygon(p2, fill=(215, 225, 235, 255))
    draw.polygon(p3, fill=(245, 250, 255, 255))
    
    # Map details: green islands & blue contour
    draw.ellipse([22, 38, 34, 52], fill=(76, 175, 80, 220))
    draw.ellipse([42, 44, 54, 62], fill=(33, 150, 243, 220))
    draw.ellipse([62, 32, 74, 48], fill=(76, 175, 80, 220))
    
    # Panel borders
    draw.line(p1 + [p1[0]], fill=(160, 180, 200, 255), width=2)
    draw.line(p2 + [p2[0]], fill=(150, 170, 190, 255), width=2)
    draw.line(p3 + [p3[0]], fill=(160, 180, 200, 255), width=2)
    
    # Red locator pin on middle panel
    draw.ellipse([43, 28, 55, 40], fill=(244, 67, 54, 255))
    draw.polygon([(44, 37), (54, 37), (49, 48)], fill=(244, 67, 54, 255))
    draw.ellipse([47, 32, 51, 36], fill=(255, 255, 255, 255))
    
    img.save(os.path.join(OUT_DIR, "icon_map.png"))
    print("Saved icon_map.png")

def create_shop_icon():
    # 96x96 stylized store front / awning icon
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.rectangle([20, 48, 76, 80], fill=(0, 0, 0, 60))
    img = img.filter(ImageFilter.GaussianBlur(2))
    draw = ImageDraw.Draw(img)
    
    # Store Base
    draw.rectangle([22, 48, 74, 78], fill=(255, 255, 255, 240))
    draw.rectangle([28, 56, 44, 78], fill=(56, 189, 248, 220)) # Glass window
    draw.rectangle([52, 54, 68, 78], fill=(203, 213, 225, 255)) # Door
    draw.ellipse([63, 65, 66, 68], fill=(245, 158, 11, 255)) # Door knob
    
    # Striped Awning (Red & White / Orange & White)
    stripes = [
        ((16, 26), (28, 26), (25, 48), (14, 48)),
        ((28, 26), (40, 26), (37, 48), (25, 48)),
        ((40, 26), (52, 26), (49, 48), (37, 48)),
        ((52, 26), (64, 26), (61, 48), (49, 48)),
        ((64, 26), (76, 26), (73, 48), (61, 48)),
        ((76, 26), (82, 26), (80, 48), (73, 48)),
    ]
    colors = [(255, 255, 255, 255), (249, 115, 22, 255)]
    for i, poly in enumerate(stripes):
        c = colors[i % 2]
        draw.polygon(poly, fill=c)
        draw.line(list(poly) + [poly[0]], fill=(200, 80, 10, 180), width=1)
        
    # Awning Scallops
    for x in range(16, 80, 11):
        draw.ellipse([x, 44, x + 11, 52], fill=colors[((x - 16) // 11) % 2])
        
    img.save(os.path.join(OUT_DIR, "icon_shop.png"))
    print("Saved icon_shop.png")

def create_trophy_icon():
    # 96x96 shiny gold trophy cup
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([30, 78, 66, 88], fill=(0, 0, 0, 70))
    img = img.filter(ImageFilter.GaussianBlur(2))
    draw = ImageDraw.Draw(img)
    
    # Base pedestal
    draw.rectangle([34, 72, 62, 80], fill=(120, 53, 15, 255))
    draw.rectangle([38, 66, 58, 72], fill=(217, 119, 6, 255))
    draw.rectangle([44, 54, 52, 66], fill=(245, 158, 11, 255)) # Stem
    
    # Handles (ears)
    draw.ellipse([20, 28, 42, 50], outline=(245, 158, 11, 255), width=5)
    draw.ellipse([54, 28, 76, 50], outline=(245, 158, 11, 255), width=5)
    
    # Trophy Cup Body
    cup_pts = [(30, 24), (66, 24), (60, 54), (36, 54)]
    draw.polygon(cup_pts, fill=(251, 191, 36, 255))
    draw.ellipse([30, 18, 66, 30], fill=(254, 240, 138, 255)) # Top rim
    
    # Specular gloss highlight
    draw.polygon([(34, 26), (44, 26), (40, 50), (36, 50)], fill=(255, 255, 255, 160))
    # Star embossed on cup
    draw.polygon([(48, 33), (50, 39), (56, 39), (51, 43), (53, 49), (48, 45), (43, 49), (45, 43), (40, 39), (46, 39)], fill=(255, 255, 255, 230))
    
    img.save(os.path.join(OUT_DIR, "icon_trophy.png"))
    print("Saved icon_trophy.png")

def create_settings_icon():
    # 96x96 metallic chrome gear
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([22, 24, 78, 80], fill=(0, 0, 0, 60))
    img = img.filter(ImageFilter.GaussianBlur(2))
    draw = ImageDraw.Draw(img)
    
    cx, cy = 48, 48
    r_outer = 32
    r_inner = 23
    r_hole = 11
    teeth = 8
    
    # Outer cogs
    pts = []
    for i in range(teeth * 2):
        angle = i * math.pi / teeth
        r = r_outer if (i % 2 == 0) else r_inner
        # small offset for tooth bevel
        px = cx + r * math.cos(angle)
        py = cy + r * math.sin(angle)
        pts.append((px, py))
        
    draw.polygon(pts, fill=(226, 232, 240, 255))
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=(203, 213, 225, 255))
    
    # Specular ring
    draw.ellipse([cx - r_inner + 3, cy - r_inner + 3, cx + r_inner - 3, cy + r_inner - 3], outline=(255, 255, 255, 200), width=2)
    # Center hole
    draw.ellipse([cx - r_hole, cy - r_hole, cx + r_hole, cy + r_hole], fill=(51, 65, 85, 255))
    draw.ellipse([cx - r_hole + 1, cy - r_hole + 1, cx + r_hole - 1, cy + r_hole - 1], fill=(30, 41, 59, 255))
    
    img.save(os.path.join(OUT_DIR, "icon_settings.png"))
    print("Saved icon_settings.png")

if __name__ == "__main__":
    create_play_icon()
    create_map_icon()
    create_shop_icon()
    create_trophy_icon()
    create_settings_icon()
    print("All 5 menu button icons generated successfully!")
