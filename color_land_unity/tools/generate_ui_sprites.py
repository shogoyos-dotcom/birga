import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Resources", "UI"))
os.makedirs(OUT_DIR, exist_ok=True)

def create_glossy_button(width, height, radius, c_top, c_bot, c_bevel, c_border, filename):
    # Render at 2x resolution for super-crisp antialiasing
    w2, h2, r2 = width * 2, height * 2, radius * 2
    img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 1. Drop shadow / 3D bottom bevel
    bevel_offset = int(height * 0.08 * 2)
    draw.rounded_rectangle([2, 2 + bevel_offset, w2 - 3, h2 - 3], radius=r2, fill=c_bevel)
    
    # 2. Main button body with vertical gradient
    body_img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    body_draw = ImageDraw.Draw(body_img)
    body_h = h2 - bevel_offset
    
    for y in range(body_h):
        t = y / max(1, body_h)
        r = int(c_top[0] * (1 - t) + c_bot[0] * t)
        g = int(c_top[1] * (1 - t) + c_bot[1] * t)
        b = int(c_top[2] * (1 - t) + c_bot[2] * t)
        body_draw.line([(0, y), (w2, y)], fill=(r, g, b, 255))
        
    mask = Image.new("L", (w2, h2), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([2, 2, w2 - 3, body_h], radius=r2, fill=255)
    img.paste(body_img, (0, 0), mask)
    
    # 3. Top-half glossy shine highlight
    shine_img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine_img)
    shine_h = int(body_h * 0.45)
    for y in range(shine_h):
        t = y / max(1, shine_h)
        alpha = int(120 * (1.0 - t * 0.85))
        shine_draw.line([(0, y), (w2, y)], fill=(255, 255, 255, alpha))
        
    shine_mask = Image.new("L", (w2, h2), 0)
    shine_mask_draw = ImageDraw.Draw(shine_mask)
    shine_mask_draw.rounded_rectangle([4, 4, w2 - 5, shine_h], radius=max(2, r2 - 4), fill=255)
    img.paste(shine_img, (0, 0), shine_mask)
    
    # 4. Crisp Border outline
    border_draw = ImageDraw.Draw(img)
    border_draw.rounded_rectangle([2, 2, w2 - 3, h2 - 3], radius=r2, outline=c_border, width=4)
    border_draw.rounded_rectangle([2, 2, w2 - 3, body_h], radius=r2, outline=c_border, width=4)
    
    # Downsample with Lanczos for smooth antialiasing
    final = img.resize((width, height), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, filename)
    final.save(out_path, "PNG")
    print(f"[SAVED UI] {filename} -> {out_path}")

def create_pill(width, height, c_fill, c_border, filename, has_glow=False, glow_col=None):
    w2, h2 = width * 2, height * 2
    r2 = h2 // 2
    img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if has_glow and glow_col:
        # Soft outer glow
        glow_img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
        g_draw = ImageDraw.Draw(glow_img)
        g_draw.rounded_rectangle([8, 8, w2 - 9, h2 - 9], radius=r2 - 8, outline=glow_col, width=12)
        glow_blur = glow_img.filter(ImageFilter.GaussianBlur(radius=6))
        img = Image.alpha_composite(img, glow_blur)
        draw = ImageDraw.Draw(img)
        
    # Main pill fill
    draw.rounded_rectangle([4, 4, w2 - 5, h2 - 5], radius=r2, fill=c_fill, outline=c_border, width=4)
    
    # Top highlight curve
    shine_h = h2 // 3
    shine_mask = Image.new("L", (w2, h2), 0)
    s_draw = ImageDraw.Draw(shine_mask)
    s_draw.rounded_rectangle([6, 6, w2 - 7, shine_h], radius=max(2, r2 - 4), fill=90)
    
    shine_layer = Image.new("RGBA", (w2, h2), (255, 255, 255, 90))
    img.paste(shine_layer, (0, 0), shine_mask)
    
    final = img.resize((width, height), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, filename)
    final.save(out_path, "PNG")
    print(f"[SAVED UI] {filename} -> {out_path}")

def create_dialog_panel(width, height, radius, c_bg, c_border, c_inner_border, filename):
    w2, h2, r2 = width * 2, height * 2, radius * 2
    img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Base dark panel
    draw.rounded_rectangle([4, 4, w2 - 5, h2 - 5], radius=r2, fill=c_bg, outline=c_border, width=6)
    # Inner subtle glow border
    draw.rounded_rectangle([12, 12, w2 - 13, h2 - 13], radius=max(4, r2 - 8), outline=c_inner_border, width=3)
    
    final = img.resize((width, height), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, filename)
    final.save(out_path, "PNG")
    print(f"[SAVED UI] {filename} -> {out_path}")

def create_joystick_sprites():
    # 1. Ring (Translucent cyan/navy outer disc with directional arcs)
    w2, h2 = 512, 512
    ring = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(ring)
    # Translucent disc fill
    r_draw.ellipse([24, 24, w2 - 25, h2 - 25], fill=(12, 45, 82, 130), outline=(56, 189, 248, 210), width=6)
    # Inner circular ring
    r_draw.ellipse([64, 64, w2 - 65, h2 - 65], outline=(125, 211, 252, 90), width=4)
    # Directional tick markers (Up, Down, Left, Right)
    cx, cy = w2 // 2, h2 // 2
    r_draw.line([(cx, 32), (cx, 48)], fill=(255, 255, 255, 180), width=4)
    r_draw.line([(cx, h2 - 48), (cx, h2 - 32)], fill=(255, 255, 255, 180), width=4)
    r_draw.line([(32, cy), (48, cy)], fill=(255, 255, 255, 180), width=4)
    r_draw.line([(w2 - 48, cy), (w2 - 32, cy)], fill=(255, 255, 255, 180), width=4)
    
    ring_final = ring.resize((256, 256), Image.Resampling.LANCZOS)
    ring_final.save(os.path.join(OUT_DIR, "joy_ring.png"), "PNG")
    
    # 2. Knob (3D Glossy White Ceramic Sphere)
    kw2, kh2 = 256, 256
    knob = Image.new("RGBA", (kw2, kh2), (0, 0, 0, 0))
    k_draw = ImageDraw.Draw(knob)
    # Soft drop shadow
    k_draw.ellipse([8, 14, kw2 - 9, kh2 - 2], fill=(0, 0, 0, 75))
    # Main White sphere body with soft shading
    k_draw.ellipse([8, 8, kw2 - 9, kh2 - 9], fill=(245, 248, 254, 255), outline=(210, 225, 240, 255), width=5)
    # Top specular glint
    k_draw.ellipse([50, 24, kw2 - 90, kh2 - 130], fill=(255, 255, 255, 240))
    # Center subtle indent / grip
    k_draw.ellipse([kw2//2 - 18, kh2//2 - 18, kw2//2 + 18, kh2//2 + 18], fill=(230, 238, 246, 200))
    
    knob_final = knob.resize((128, 128), Image.Resampling.LANCZOS)
    knob_final.save(os.path.join(OUT_DIR, "joy_knob.png"), "PNG")
    print("[SAVED UI] Joystick sprites (joy_ring.png, joy_knob.png)")

def create_notification_badge():
    s = 128
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Red circle with white border
    draw.ellipse([4, 4, s - 5, s - 5], fill=(239, 68, 68, 255), outline=(255, 255, 255, 255), width=6)
    # White exclamation mark
    font_size = 72
    try:
        font = ImageFont.truetype("arialbd.ttf", font_size)
    except:
        font = ImageFont.load_default()
    draw.text((s // 2, s // 2), "!", fill=(255, 255, 255, 255), anchor="mm", font=font)
    
    final = img.resize((64, 64), Image.Resampling.LANCZOS)
    final.save(os.path.join(OUT_DIR, "badge_exclamation.png"), "PNG")
    print("[SAVED UI] badge_exclamation.png")

if __name__ == "__main__":
    print("=== GENERATING HIGH-END CARTOON UI SPRITES ===")
    
    # 1. 5 Chunky Glossy Buttons
    # Green Play Button (#22c55e)
    create_glossy_button(
        width=512, height=110, radius=32,
        c_top=(74, 222, 128), c_bot=(21, 128, 61), c_bevel=(15, 83, 39), c_border=(10, 48, 24),
        filename="btn_green.png"
    )
    
    # Blue Maps Button (#0284c7)
    create_glossy_button(
        width=512, height=110, radius=32,
        c_top=(56, 189, 248), c_bot=(2, 132, 199), c_bevel=(3, 105, 161), c_border=(12, 74, 110),
        filename="btn_blue.png"
    )
    
    # Orange Shop Button (#f97316)
    create_glossy_button(
        width=512, height=110, radius=32,
        c_top=(251, 146, 60), c_bot=(234, 88, 12), c_bevel=(194, 65, 12), c_border=(124, 45, 18),
        filename="btn_orange.png"
    )
    
    # Purple Daily Button (#a855f7)
    create_glossy_button(
        width=512, height=110, radius=32,
        c_top=(192, 132, 252), c_bot=(147, 51, 234), c_bevel=(107, 33, 168), c_border=(88, 28, 135),
        filename="btn_purple.png"
    )
    
    # Slate Settings Button (#475569)
    create_glossy_button(
        width=512, height=110, radius=32,
        c_top=(148, 163, 184), c_bot=(71, 85, 105), c_bevel=(51, 65, 85), c_border=(30, 41, 59),
        filename="btn_slate.png"
    )
    
    # 2. Pills
    # Glowing Cyan Percent Capsule (#06b6d4)
    create_pill(
        width=256, height=80,
        c_fill=(6, 182, 212, 245), c_border=(34, 211, 238, 255),
        filename="pill_cyan.png",
        has_glow=True, glow_col=(34, 211, 238, 160)
    )
    
    # Navy Pill for Menu, Crown, and Lang (#0f172a)
    create_pill(
        width=256, height=80,
        c_fill=(15, 23, 42, 235), c_border=(51, 65, 85, 255),
        filename="pill_navy.png"
    )
    
    # 3. Dialog Window Background
    create_dialog_panel(
        width=512, height=512, radius=40,
        c_bg=(11, 17, 32, 248), c_border=(56, 189, 248, 220), c_inner_border=(30, 58, 138, 160),
        filename="panel_dialog.png"
    )
    
    # 4. Leaderboard Card
    create_dialog_panel(
        width=320, height=320, radius=28,
        c_bg=(15, 23, 42, 225), c_border=(250, 204, 21, 200), c_inner_border=(30, 41, 59, 140),
        filename="panel_leaderboard.png"
    )
    
    # 5. Joystick and Badges
    create_joystick_sprites()
    create_notification_badge()
    
    print("=== ALL HIGH-END CARTOON UI SPRITES GENERATED SUCCESSFULLY ===")
