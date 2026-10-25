import bpy
import bmesh
import math
import os

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Models"))
os.makedirs(OUT_DIR, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def add_colored_part(obj, color):
    mesh = obj.data
    ca = mesh.color_attributes.new(name="Color", type='FLOAT_COLOR', domain='CORNER')
    for d in ca.data:
        d.color = color
    return obj

def create_box(name, size, loc, color):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return add_colored_part(obj, color)

def create_cylinder(name, radius, depth, loc, color, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=vertices, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return add_colored_part(obj, color)

def create_cone(name, radius, depth, loc, color, vertices=16):
    bpy.ops.mesh.primitive_cone_add(radius1=radius, depth=depth, vertices=vertices, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return add_colored_part(obj, color)

def create_sphere(name, radius, loc, color, segments=16, ring_count=12):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, segments=segments, ring_count=ring_count, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return add_colored_part(obj, color)

def join_and_export(filename, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    main_obj = bpy.context.active_object
    
    # Smooth normals
    bpy.ops.object.shade_smooth()
    
    out_path = os.path.join(OUT_DIR, filename).replace("\\", "/")
    bpy.ops.wm.obj_export(filepath=out_path, export_colors=True)
    print(f"[EXPORTED] {filename} -> {out_path}")

# ==============================================================================
# 1. CASTLE SMALL (European Fairytale Castle)
# ==============================================================================
def build_castle_small():
    reset_scene()
    parts = []
    
    c_sandstone = (0.86, 0.84, 0.80, 1.0)
    c_white     = (0.94, 0.94, 0.97, 1.0)
    c_red_roof  = (0.86, 0.22, 0.20, 1.0)
    c_turquoise = (0.08, 0.74, 0.72, 1.0)
    c_gold      = (0.98, 0.82, 0.16, 1.0)
    c_wood      = (0.38, 0.22, 0.12, 1.0)
    
    # Base plinth
    parts.append(create_box("Plinth", (4.2, 4.2, 0.4), (0, 0, 0.2), c_sandstone))
    
    # Central Keep Tower
    parts.append(create_box("Keep", (2.4, 2.4, 3.2), (0, 0, 1.8), c_white))
    
    # 4 Corner Turrets
    turret_r = 0.55
    turret_h = 3.6
    roof_h = 1.4
    offsets = [(-1.5, -1.5), (1.5, -1.5), (1.5, 1.5), (-1.5, 1.5)]
    for idx, (ox, oy) in enumerate(offsets):
        parts.append(create_cylinder(f"Turret_{idx}", turret_r, turret_h, (ox, oy, turret_h*0.5), c_white, 16))
        parts.append(create_cone(f"TurretRoof_{idx}", turret_r * 1.25, roof_h, (ox, oy, turret_h + roof_h*0.5), c_red_roof, 16))
        parts.append(create_sphere(f"TurretFinial_{idx}", 0.16, (ox, oy, turret_h + roof_h + 0.12), c_gold, 10, 8))
        
    # Central Turquoise Dome atop Keep
    parts.append(create_sphere("CentralDome", 1.15, (0, 0, 3.8), c_turquoise, 18, 14))
    
    # Gold Spire
    parts.append(create_cylinder("SpirePole", 0.06, 1.2, (0, 0, 4.7), c_gold, 8))
    parts.append(create_sphere("SpireFinial", 0.22, (0, 0, 5.35), c_gold, 10, 8))
    
    # Arched Gate
    parts.append(create_box("GateSurround", (1.1, 0.25, 1.5), (0, -1.25, 0.95), c_sandstone))
    parts.append(create_box("GateDoor", (0.8, 0.28, 1.25), (0, -1.26, 0.85), c_wood))
    
    join_and_export("castle_small.obj", parts)

# ==============================================================================
# 2. CASTLE MEDIUM (Samarkand / Oriental Palace)
# ==============================================================================
def build_castle_medium():
    reset_scene()
    parts = []
    
    c_terracotta = (0.82, 0.62, 0.42, 1.0)
    c_ivory      = (0.95, 0.94, 0.90, 1.0)
    c_turquoise  = (0.06, 0.76, 0.74, 1.0)
    c_gold       = (0.98, 0.80, 0.15, 1.0)
    c_deep_blue  = (0.12, 0.35, 0.65, 1.0)
    
    # Base Courtyard Plinth
    parts.append(create_box("Plinth", (6.5, 5.0, 0.4), (0, 0, 0.2), c_terracotta))
    
    # Grand Central Portal (Pishtaq)
    parts.append(create_box("PishtaqFrame", (3.2, 1.2, 5.0), (0, -1.2, 2.7), c_ivory))
    # Vaulted Iwan Niche (Darker depth)
    parts.append(create_box("IwanNiche", (1.8, 0.8, 3.6), (0, -1.45, 2.0), c_deep_blue))
    
    # Central Palace Building behind Pishtaq
    parts.append(create_box("PalaceBody", (4.8, 3.2, 3.0), (0, 0.6, 1.7), c_ivory))
    
    # Monumental Fluted Turquoise Dome
    parts.append(create_sphere("MainDome", 1.6, (0, 0.6, 4.0), c_turquoise, 22, 16))
    parts.append(create_cylinder("DomeDrum", 1.45, 0.7, (0, 0.6, 3.4), c_terracotta, 20))
    parts.append(create_cylinder("DomeSpire", 0.08, 1.4, (0, 0.6, 5.4), c_gold, 8))
    parts.append(create_sphere("DomeCrescent", 0.26, (0, 0.6, 6.15), c_gold, 12, 8))
    
    # Side Palace Galleries with mini turquoise domes
    for side in (-2.2, 2.2):
        parts.append(create_box(f"SideWing_{side}", (1.8, 2.6, 2.4), (side, 0.3, 1.4), c_ivory))
        parts.append(create_sphere(f"SideDome_{side}", 0.75, (side, 0.3, 3.0), c_turquoise, 16, 12))
        parts.append(create_cylinder(f"SideSpire_{side}", 0.04, 0.6, (side, 0.3, 3.9), c_gold, 8))
        
    # Twin Majestic Minarets
    minaret_r = 0.42
    minaret_h = 6.2
    for side in (-3.0, 3.0):
        parts.append(create_cylinder(f"Minaret_{side}", minaret_r, minaret_h, (side, -1.2, minaret_h*0.5), c_ivory, 16))
        # Balcony (sherefe)
        parts.append(create_cylinder(f"Balcony_{side}", minaret_r*1.35, 0.3, (side, -1.2, minaret_h*0.75), c_terracotta, 16))
        # Spire
        parts.append(create_cone(f"MinSpire_{side}", minaret_r*1.15, 1.2, (side, -1.2, minaret_h + 0.6), c_gold, 16))
        parts.append(create_sphere(f"MinFinial_{side}", 0.16, (side, -1.2, minaret_h + 1.25), c_gold, 10, 8))
        
    join_and_export("castle_medium.obj", parts)

# ==============================================================================
# 3. CASTLE LARGE (Imperial Sovereign Citadel)
# ==============================================================================
def build_castle_large():
    reset_scene()
    parts = []
    
    c_granite   = (0.74, 0.75, 0.79, 1.0)
    c_royal_w   = (0.93, 0.94, 0.96, 1.0)
    c_mansard   = (0.84, 0.20, 0.18, 1.0)
    c_gold      = (0.98, 0.82, 0.16, 1.0)
    c_gate_dark = (0.24, 0.16, 0.12, 1.0)
    
    # Monumental Citadel Foundation
    parts.append(create_box("Foundation", (8.5, 7.5, 0.5), (0, 0, 0.25), c_granite))
    
    # Main Palace Keep Block
    parts.append(create_box("PalaceTier1", (6.4, 5.4, 3.5), (0, 0, 2.0), c_royal_w))
    parts.append(create_box("PalaceTier2", (4.8, 3.8, 2.2), (0, 0, 4.4), c_royal_w))
    
    # Royal Red Mansard Roof
    parts.append(create_box("MansardRoof", (4.4, 3.4, 1.2), (0, 0, 5.8), c_mansard))
    
    # Sovereign Central Tower
    parts.append(create_box("SovereignTower", (1.6, 1.6, 3.6), (0, 0, 7.4), c_royal_w))
    parts.append(create_cone("SovereignSpire", 1.2, 2.5, (0, 0, 10.2), c_mansard, 16))
    parts.append(create_sphere("ImperialCrown", 0.35, (0, 0, 11.55), c_gold, 12, 10))
    
    # 4 Mighty Corner Bastion Towers
    bastion_r = 0.85
    bastion_h = 5.2
    b_offsets = [(-3.6, -3.0), (3.6, -3.0), (3.6, 3.0), (-3.6, 3.0)]
    for idx, (bx, by) in enumerate(b_offsets):
        parts.append(create_cylinder(f"Bastion_{idx}", bastion_r, bastion_h, (bx, by, bastion_h*0.5), c_royal_w, 18))
        # Machicolations ledge
        parts.append(create_cylinder(f"Machi_{idx}", bastion_r*1.2, 0.35, (bx, by, bastion_h - 0.2), c_granite, 18))
        # Conical Spire
        parts.append(create_cone(f"BastRoof_{idx}", bastion_r*1.2, 2.0, (bx, by, bastion_h + 0.95), c_mansard, 18))
        parts.append(create_sphere(f"BastFinial_{idx}", 0.22, (bx, by, bastion_h + 2.0), c_gold, 10, 8))
        
    # Grand Imperial Portal
    parts.append(create_box("PortalFrame", (2.4, 0.8, 2.4), (0, -2.8, 1.4), c_granite))
    parts.append(create_box("PortalDoor", (1.6, 0.85, 1.8), (0, -2.85, 1.1), c_gate_dark))
    
    join_and_export("castle_large.obj", parts)

# ==============================================================================
# 4. TREE STYLIZED PINE (Flared Multi-Tier Pine)
# ==============================================================================
def build_tree_pine():
    reset_scene()
    parts = []
    
    c_trunk = (0.44, 0.26, 0.14, 1.0)
    c_pine1 = (0.12, 0.52, 0.22, 1.0)
    c_pine2 = (0.16, 0.64, 0.28, 1.0)
    c_pine3 = (0.22, 0.76, 0.35, 1.0)
    
    # Curved Trunk with root flare
    parts.append(create_cylinder("Trunk", 0.28, 1.5, (0, 0, 0.75), c_trunk, 12))
    parts.append(create_cone("RootFlare", 0.45, 0.4, (0, 0, 0.2), c_trunk, 12))
    
    # 3 Flared Conical Foliage Tiers
    parts.append(create_cone("TierBottom", 1.55, 1.1, (0, 0, 1.8), c_pine1, 16))
    parts.append(create_cone("TierMiddle", 1.25, 0.95, (0, 0, 2.5), c_pine2, 16))
    parts.append(create_cone("TierTop",    0.85, 0.85, (0, 0, 3.15), c_pine3, 16))
    
    join_and_export("tree_stylized_pine.obj", parts)

# ==============================================================================
# 5. TREE STYLIZED ROUND (Fluffy Cloud Deciduous)
# ==============================================================================
def build_tree_round():
    reset_scene()
    parts = []
    
    c_trunk = (0.46, 0.28, 0.16, 1.0)
    c_leaf_shadow = (0.18, 0.58, 0.22, 1.0)
    c_leaf_main   = (0.28, 0.78, 0.28, 1.0)
    c_leaf_sun    = (0.42, 0.88, 0.32, 1.0)
    
    # Trunk
    parts.append(create_cylinder("Trunk", 0.32, 1.8, (0, 0, 0.9), c_trunk, 12))
    
    # Puffy fused foliage clusters
    parts.append(create_sphere("CanopyBase", 1.35, (0, 0, 2.3), c_leaf_shadow, 16, 12))
    parts.append(create_sphere("PuffLeft",   0.85, (-0.6, 0.3, 2.6), c_leaf_main, 14, 10))
    parts.append(create_sphere("PuffRight",  0.90, (0.6, -0.2, 2.7), c_leaf_main, 14, 10))
    parts.append(create_sphere("PuffFront",  0.80, (0.1, -0.6, 2.5), c_leaf_main, 14, 10))
    parts.append(create_sphere("PuffTop",    0.95, (0, 0, 3.15), c_leaf_sun, 14, 10))
    
    join_and_export("tree_stylized_round.obj", parts)

# ==============================================================================
# 6. ROCK STYLIZED (Faceted Low-Poly Boulder)
# ==============================================================================
def build_rock_stylized():
    reset_scene()
    parts = []
    
    c_rock_shade = (0.48, 0.52, 0.58, 1.0)
    c_rock_lit   = (0.68, 0.72, 0.78, 1.0)
    
    # Irregular faceted boulder
    parts.append(create_sphere("RockBase", 1.2, (0, 0, 0.6), c_rock_shade, 8, 6))
    parts.append(create_sphere("RockFacet1", 0.9, (0.35, 0.25, 0.8), c_rock_lit, 7, 5))
    parts.append(create_sphere("RockFacet2", 0.7, (-0.4, -0.2, 0.5), c_rock_shade, 6, 5))
    
    join_and_export("rock_stylized.obj", parts)

# ==============================================================================
# 7. BRIDGE WOODEN (Arched Wooden Bridge)
# ==============================================================================
def build_bridge_wooden():
    reset_scene()
    parts = []
    
    c_wood_deck = (0.62, 0.42, 0.24, 1.0)
    c_wood_rail = (0.48, 0.30, 0.16, 1.0)
    c_wood_post = (0.38, 0.22, 0.12, 1.0)
    
    # Arched Deck Planks
    parts.append(create_box("DeckArch", (2.4, 6.8, 0.22), (0, 0, 0.5), c_wood_deck))
    
    # 4 Pilings / Support Posts
    parts.append(create_cylinder("Post1", 0.18, 1.6, (-1.0, -2.4, 0.2), c_wood_post, 10))
    parts.append(create_cylinder("Post2", 0.18, 1.6, ( 1.0, -2.4, 0.2), c_wood_post, 10))
    parts.append(create_cylinder("Post3", 0.18, 1.6, (-1.0,  2.4, 0.2), c_wood_post, 10))
    parts.append(create_cylinder("Post4", 0.18, 1.6, ( 1.0,  2.4, 0.2), c_wood_post, 10))
    
    # Side Handrails & Balusters
    for side in (-1.15, 1.15):
        # Top Rail
        parts.append(create_box(f"Rail_{side}", (0.14, 6.7, 0.16), (side, 0, 1.05), c_wood_rail))
        # Balusters
        for y_pos in (-2.4, -1.2, 0, 1.2, 2.4):
            parts.append(create_cylinder(f"Baluster_{side}_{y_pos}", 0.08, 0.55, (side, y_pos, 0.76), c_wood_post, 8))
            
    join_and_export("bridge_wooden.obj", parts)

# ==============================================================================
# 8. MOUNTAIN SNOWY (Alpine Snow Peak)
# ==============================================================================
def build_mountain_snowy():
    reset_scene()
    parts = []
    
    c_granite = (0.45, 0.48, 0.54, 1.0)
    c_snow    = (0.96, 0.98, 1.00, 1.0)
    
    # Faceted Pyramid Mountain
    parts.append(create_cone("MountainBase", 7.5, 9.5, (0, 0, 4.75), c_granite, 10))
    # Snow mantle fitting top 35% of peak
    parts.append(create_cone("SnowMantle", 3.2, 3.8, (0, 0, 7.8), c_snow, 10))
    
    join_and_export("mountain_snowy.obj", parts)

# ==============================================================================
# 9. CHARACTER BALL (Cute Anime Ball Character)
# ==============================================================================
def build_character_ball():
    reset_scene()
    parts = []
    
    c_white_body = (0.95, 0.95, 0.97, 1.0) # Player body is dynamically tinted in Unity
    c_black_eye  = (0.04, 0.04, 0.06, 1.0)
    c_glint      = (1.00, 1.00, 1.00, 1.0)
    c_mouth      = (0.08, 0.08, 0.12, 1.0)
    c_silver     = (0.88, 0.90, 0.94, 1.0)
    c_gold       = (0.98, 0.80, 0.15, 1.0)
    
    # Main Subdivided Candy Sphere Body
    parts.append(create_sphere("Body", 0.85, (0, 0, 0.85), c_white_body, 28, 20))
    
    # 2 Large Expressive Cartoon Eyes
    for eye_idx in (-1, 1):
        ox = eye_idx * 0.24
        parts.append(create_sphere(f"Eye_{eye_idx}", 0.18, (ox, 0.74, 0.98), c_black_eye, 16, 12))
        # Main Upper Glint Sparkle
        parts.append(create_sphere(f"GlintMain_{eye_idx}", 0.065, (ox + 0.045, 0.85, 1.08), c_glint, 10, 8))
        # Sub Lower Glint Sparkle
        parts.append(create_sphere(f"GlintSub_{eye_idx}", 0.035, (ox - 0.04, 0.85, 0.90), c_glint, 8, 6))
        
    # Cute Smiling Mouth
    parts.append(create_cylinder("Mouth", 0.08, 0.04, (0, 0.82, 0.74), c_mouth, 12))
    
    # Flagpole on Back
    parts.append(create_cylinder("Flagpole", 0.035, 1.4, (0, -0.65, 1.45), c_silver, 10))
    parts.append(create_sphere("Finial", 0.12, (0, -0.65, 2.18), c_gold, 10, 8))
    
    join_and_export("character_ball.obj", parts)

if __name__ == "__main__":
    print("=== STARTING BLENDER 4.2 MODEL GENERATION ===")
    build_castle_small()
    build_castle_medium()
    build_castle_large()
    build_tree_pine()
    build_tree_round()
    build_rock_stylized()
    build_bridge_wooden()
    build_mountain_snowy()
    build_character_ball()
    print("=== ALL STYLIZED 3D MODELS BUILT AND EXPORTED SUCCESSFULLY ===")
