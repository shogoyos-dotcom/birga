import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Resources", "UI", "title_logo_3d.png"))

def make_title_logo():
    # 2x supersampling: 1600 x 840
    W, H = 1600, 840
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    
    font_impact = "C:/Windows/Fonts/impact.ttf"
    font_color = ImageFont.truetype(font_impact, 290)
    font_land = ImageFont.truetype(font_impact, 210)
    
    letters = [
        ('C', (0, 220, 255), (0, 140, 220)),
        ('O', (255, 225, 0), (220, 160, 0)),
        ('L', (255, 135, 15), (210, 75, 0)),
        ('O', (255, 45, 80), (190, 15, 45)),
        ('R', (140, 75, 255), (85, 25, 195)),
    ]
    
    temp_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    temp_draw = ImageDraw.Draw(temp_img)
    
    letter_widths = []
    for char, _, _ in letters:
        bbox = temp_draw.textbbox((0, 0), char, font=font_color)
        w = bbox[2] - bbox[0]
        letter_widths.append(w)
        
    total_w = sum(letter_widths) + len(letters) * 22
    start_x = (W - total_w) // 2
    y_pos = 50
    
    # 1. Outer dark drop shadow
    cur_x = start_x
    for i, (char, _, _) in enumerate(letters):
        w = letter_widths[i]
        for step in range(26, 0, -2):
            temp_draw.text((cur_x, y_pos + step), char, font=font_color, fill=(5, 10, 20, 255), stroke_width=20, stroke_fill=(5, 10, 20, 255))
        cur_x += w + 22
        
    img = Image.alpha_composite(img, temp_img)
    
    # 2. 3D extruded colored body
    cur_x = start_x
    for i, (char, c_top, c_dark) in enumerate(letters):
        w = letter_widths[i]
        let_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        let_draw = ImageDraw.Draw(let_img)
        
        # 3D extrusion downward
        for step in range(16, 0, -1):
            t = step / 16.0
            r = int(c_dark[0] * t + c_top[0] * (1 - t) * 0.8)
            g = int(c_dark[1] * t + c_top[1] * (1 - t) * 0.8)
            b = int(c_dark[2] * t + c_top[2] * (1 - t) * 0.8)
            let_draw.text((cur_x, y_pos + step), char, font=font_color, fill=(r, g, b, 255), stroke_width=12, stroke_fill=(15, 20, 35, 255))
            
        # Front face with soft vertical gradient
        bbox = let_draw.textbbox((cur_x, y_pos), char, font=font_color)
        bh = bbox[3] - bbox[1]
        
        # Draw front face in solid color first
        let_draw.text((cur_x, y_pos), char, font=font_color, fill=c_top, stroke_width=12, stroke_fill=(15, 20, 35, 255))
        
        # Add smooth gloss gradient to top 60% of letter
        grad_mask = Image.new("L", (W, H), 0)
        g_draw = ImageDraw.Draw(grad_mask)
        g_draw.text((cur_x, y_pos), char, font=font_color, fill=255)
        
        shine_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(shine_layer)
        for gy in range(int(bh * 0.65)):
            alpha = int(140 * (1.0 - (gy / (bh * 0.65))))
            s_draw.line([(0, bbox[1] + gy), (W, bbox[1] + gy)], fill=(255, 255, 255, alpha))
            
        shine_cut = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        shine_cut.paste(shine_layer, (0, 0), grad_mask)
        
        let_img = Image.alpha_composite(let_img, shine_cut)
        img = Image.alpha_composite(img, let_img)
        cur_x += w + 22
        
    # -------------------------------------------------------------
    # 3. "LAND 3D" LINE
    # -------------------------------------------------------------
    land_text = "LAND 3D"
    land_bbox = temp_draw.textbbox((0, 0), land_text, font=font_land)
    land_w = land_bbox[2] - land_bbox[0]
    land_x = (W - land_w) // 2
    land_y = y_pos + 330
    
    land_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    land_draw = ImageDraw.Draw(land_img)
    
    # 3D dark shadow
    for step in range(24, 0, -2):
        land_draw.text((land_x, land_y + step), land_text, font=font_land, fill=(5, 15, 30, 255), stroke_width=18, stroke_fill=(5, 10, 25, 255))
        
    # 3D cyan extruded depth
    for step in range(16, 0, -1):
        t = step / 16.0
        r = int(10 * t + 0 * (1 - t))
        g = int(100 * t + 180 * (1 - t))
        b = int(190 * t + 255 * (1 - t))
        land_draw.text((land_x, land_y + step), land_text, font=font_land, fill=(r, g, b, 255), stroke_width=12, stroke_fill=(10, 20, 40, 255))
        
    # Crisp white front face
    land_draw.text((land_x, land_y), land_text, font=font_land, fill=(255, 255, 255, 255), stroke_width=12, stroke_fill=(10, 20, 40, 255))
    
    img = Image.alpha_composite(img, land_img)
    
    # Downsample to 800 x 420 with Lanczos
    final = img.resize((800, 420), Image.Resampling.LANCZOS)
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    final.save(OUT_PATH, "PNG")
    print(f"[SUCCESS] 3D Title Logo generated -> {OUT_PATH}")

if __name__ == "__main__":
    make_title_logo()
