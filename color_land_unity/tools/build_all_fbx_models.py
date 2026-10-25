import bpy
import bmesh
import math
import os

OUT_DIRS = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Models")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Resources", "Models"))
]
for d in OUT_DIRS:
    os.makedirs(d, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

_mat_cache = {}
def get_material(name, color_rgba, roughness=0.35, metallic=0.0):
    key = (name, color_rgba, roughness, metallic)
    if key in _mat_cache and _mat_cache[key].name in bpy.data.materials:
        return _mat_cache[key]
    mat = bpy.data.materials.new(name=name)
    mat.diffuse_color = color_rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color_rgba
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    _mat_cache[key] = mat
    return mat

def apply_mat(obj, mat):
    obj.data.materials.append(mat)
    return obj

def create_box(name, size, loc, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return apply_mat(obj, mat)

def create_cylinder(name, radius, depth, loc, mat, vertices=16, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=vertices, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    return apply_mat(obj, mat)

def create_cone(name, radius, depth, loc, mat, vertices=16, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(radius1=radius, depth=depth, vertices=vertices, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    return apply_mat(obj, mat)

def create_sphere(name, radius, loc, mat, segments=18, ring_count=14):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, segments=segments, ring_count=ring_count, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return apply_mat(obj, mat)

def join_and_export_fbx(filenames, objects):
    if isinstance(filenames, str):
        filenames = [filenames]
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    if len(objects) > 1:
        bpy.ops.object.join()
    active_obj = bpy.context.active_object
    bpy.ops.object.shade_smooth()

    for filename in filenames:
        for d in OUT_DIRS:
            out_path = os.path.join(d, filename).replace("\\", "/")
            bpy.ops.export_scene.fbx(
                filepath=out_path,
                axis_forward='-Z',
                axis_up='Y',
                use_selection=True,
                global_scale=1.0,
                apply_unit_scale=True,
                apply_scale_options='FBX_SCALE_ALL',
                bake_space_transform=True,
                path_mode='AUTO'
            )
            print(f"[EXPORTED FBX] {filename} -> {out_path}")

# ==============================================================================
# 1. BERLIN / FAIRYTALE CASTLE (Crimson Roofs, Cream Stone, Turrets, Banners)
# ==============================================================================
def build_castle_berlin():
    reset_scene()
    parts = []

    m_stone  = get_material("Mat_Ber_Stone",  (0.96, 0.95, 0.92, 1.0), 0.38)
    m_trim   = get_material("Mat_Ber_Trim",   (0.52, 0.54, 0.58, 1.0), 0.45)
    m_roof   = get_material("Mat_Ber_Roof",   (0.88, 0.16, 0.20, 1.0), 0.25)
    m_gold   = get_material("Mat_Ber_Gold",   (0.98, 0.84, 0.16, 1.0), 0.18, 0.75)
    m_wood   = get_material("Mat_Ber_Wood",   (0.36, 0.22, 0.14, 1.0), 0.50)
    m_banner = get_material("Mat_Ber_Banner", (0.90, 0.14, 0.16, 1.0), 0.30)
    m_window = get_material("Mat_Ber_Window", (0.16, 0.22, 0.32, 1.0), 0.15)

    # Foundation Plinth
    parts.append(create_box("BasePlinth", (2.8, 2.8, 0.35), (0, 0, 0.175), m_trim))
    parts.append(create_box("BaseStep", (2.5, 2.5, 0.20), (0, 0, 0.45), m_stone))

    # Main Palace Body (Ground & 1st Floor)
    parts.append(create_box("MainKeep", (1.8, 1.8, 1.4), (0, 0, 1.25), m_stone))
    parts.append(create_box("Cornice", (1.9, 1.9, 0.12), (0, 0, 1.98), m_trim))

    # Upper Cathedral Tower
    parts.append(create_box("UpperTower", (1.2, 1.2, 1.2), (0, 0, 2.60), m_stone))
    parts.append(create_box("UpperCornice", (1.3, 1.3, 0.10), (0, 0, 3.22), m_trim))

    # Grand Steeple / Main Spire
    parts.append(create_cone("MainSpire", 1.0, 1.7, (0, 0, 4.10), m_roof, 16))
    parts.append(create_sphere("MainFinial", 0.15, (0, 0, 5.0), m_gold, 12, 8))

    # 4 Corner Bastion Turrets
    t_r = 0.32
    t_h = 2.4
    offsets = [(-1.15, -1.15), (1.15, -1.15), (1.15, 1.15), (-1.15, 1.15)]
    for i, (tx, ty) in enumerate(offsets):
        parts.append(create_cylinder(f"Turret_{i}", t_r, t_h, (tx, ty, t_h * 0.5 + 0.30), m_stone, 14))
        parts.append(create_cylinder(f"TurretTrim_{i}", t_r * 1.22, 0.15, (tx, ty, t_h + 0.32), m_trim, 14))
        parts.append(create_cone(f"TurretRoof_{i}", t_r * 1.30, 1.1, (tx, ty, t_h + 0.95), m_roof, 14))
        parts.append(create_sphere(f"TurretFinial_{i}", 0.09, (tx, ty, t_h + 1.55), m_gold, 8, 6))

    # Arched Entrance Gate & Portcullis
    parts.append(create_box("GateArch", (0.75, 0.25, 0.90), (0, -0.92, 0.80), m_trim))
    parts.append(create_box("GateDoor", (0.50, 0.12, 0.70), (0, -0.95, 0.70), m_wood))

    # Front Windows
    for wx in [-0.5, 0.5]:
        parts.append(create_box(f"WinLower_{wx}", (0.24, 0.10, 0.38), (wx, -0.92, 1.35), m_window))
        parts.append(create_box(f"WinUpper_{wx}", (0.22, 0.10, 0.34), (wx, -0.62, 2.70), m_window))
    # Rose Window (Upper Central)
    parts.append(create_cylinder("RoseWindow", 0.28, 0.12, (0, -0.62, 2.75), m_window, 12, rot=(math.radians(90), 0, 0)))

    # Red Swallowtail Banners on Front Turrets
    for i, tx in enumerate([-1.15, 1.15]):
        parts.append(create_cylinder(f"FlagPole_{i}", 0.03, 0.9, (tx, -1.15, t_h + 1.8), m_trim, 8))
        parts.append(create_box(f"Banner_{i}", (0.55, 0.04, 0.34), (tx + 0.28, -1.15, t_h + 2.05), m_banner))

    join_and_export_fbx(["castle_berlin.fbx", "castle_small.fbx"], parts)

# ==============================================================================
# 2. TASHKENT / ROYAL WATER PALACE (Fluted Turquoise Domes, White Marble, Gold)
# ==============================================================================
def build_castle_tashkent():
    reset_scene()
    parts = []

    m_marble  = get_material("Mat_Tas_Marble", (0.98, 0.98, 0.96, 1.0), 0.30)
    m_turq    = get_material("Mat_Tas_Turq",   (0.00, 0.75, 0.85, 1.0), 0.20)
    m_gold    = get_material("Mat_Tas_Gold",   (0.98, 0.84, 0.16, 1.0), 0.15, 0.80)
    m_cobalt  = get_material("Mat_Tas_Cobalt", (0.08, 0.36, 0.78, 1.0), 0.26)
    m_pier    = get_material("Mat_Tas_Pier",   (0.85, 0.87, 0.90, 1.0), 0.45)
    m_arch    = get_material("Mat_Tas_Arch",   (0.12, 0.20, 0.36, 1.0), 0.25)

    # Island Pier / Raised Stone Quay
    parts.append(create_box("QuayBase", (3.4, 3.4, 0.35), (0, 0, 0.175), m_pier))
    parts.append(create_box("QuayStep", (3.0, 3.0, 0.20), (0, 0, 0.45), m_marble))

    # Front Stone Steps leading into Water
    parts.append(create_box("Steps1", (1.4, 0.6, 0.12), (0, -1.8, 0.06), m_pier))
    parts.append(create_box("Steps2", (1.6, 0.4, 0.20), (0, -1.6, 0.15), m_pier))

    # Main Palace Pavilion Body
    parts.append(create_box("PalaceTier1", (2.4, 2.4, 1.3), (0, 0, 1.15), m_marble))
    parts.append(create_box("Cornice1",   (2.5, 2.5, 0.12), (0, 0, 1.83), m_cobalt))

    # Upper Pavilion Tier
    parts.append(create_box("PalaceTier2", (1.7, 1.7, 0.85), (0, 0, 2.30), m_marble))
    parts.append(create_box("Cornice2",   (1.8, 1.8, 0.10), (0, 0, 2.75), m_cobalt))

    # Grand Central Ribbed Fluted Turquoise Dome
    parts.append(create_cylinder("DomeDrum", 0.85, 0.45, (0, 0, 3.0), m_marble, 22))
    parts.append(create_cylinder("DomeBand", 0.90, 0.12, (0, 0, 3.10), m_cobalt, 22))
    parts.append(create_sphere("GrandTurqDome", 0.98, (0, 0, 3.65), m_turq, 24, 18))
    parts.append(create_cone("GrandSpire", 0.24, 0.95, (0, 0, 4.60), m_gold, 16))
    parts.append(create_sphere("SpireCrescent", 0.14, (0, 0, 5.12), m_gold, 12, 8))

    # 4 Corner Royal Bastions with Turquoise Ribbed Domes
    b_r = 0.32
    b_h = 2.5
    offsets = [(-1.25, -1.25), (1.25, -1.25), (1.25, 1.25), (-1.25, 1.25)]
    for i, (bx, by) in enumerate(offsets):
        parts.append(create_cylinder(f"Bastion_{i}", b_r, b_h, (bx, by, b_h * 0.5 + 0.35), m_marble, 16))
        parts.append(create_cylinder(f"BastionBand_{i}", b_r * 1.18, 0.12, (bx, by, b_h + 0.35), m_cobalt, 16))
        parts.append(create_sphere(f"BastDome_{i}", b_r * 1.20, (bx, by, b_h + 0.58), m_turq, 18, 14))
        parts.append(create_cone(f"BastSpire_{i}", 0.10, 0.42, (bx, by, b_h + 0.90), m_gold, 12))
        parts.append(create_sphere(f"BastOrb_{i}", 0.06, (bx, by, b_h + 1.15), m_gold, 8, 6))

    # Grand Arched Portal (Pishtaq Facade)
    parts.append(create_box("FrontPortal", (1.1, 0.30, 1.2), (0, -1.22, 1.15), m_cobalt))
    parts.append(create_box("PortalArch",  (0.72, 0.34, 0.95), (0, -1.22, 1.0), m_arch))
    parts.append(create_box("PortalTrim",  (1.15, 0.32, 0.14), (0, -1.22, 1.80), m_gold))

    # Colonnade / Balcony Railings
    for side, py in [("Front", -0.9), ("Back", 0.9)]:
        parts.append(create_box(f"Railing_{side}", (2.2, 0.08, 0.22), (0, py, 1.95), m_gold))

    # Azure Sovereign Flag on Mast
    parts.append(create_cylinder("SovereignMast", 0.035, 1.8, (1.35, 1.35, 2.8), m_pier, 8))
    parts.append(create_box("SovereignFlag", (0.65, 0.04, 0.38), (1.68, 1.35, 3.4), m_cobalt))

    join_and_export_fbx(["castle_tashkent.fbx", "castle_large.fbx"], parts)

# ==============================================================================
# 3. SAMARKAND / ANCIENT MADRASA (Monumental Pishtaq, Turquoise Domes, Minarets)
# ==============================================================================
def build_castle_samarkand():
    reset_scene()
    parts = []

    m_sand   = get_material("Mat_Sam_Sand",   (0.94, 0.86, 0.72, 1.0), 0.45)
    m_turq   = get_material("Mat_Sam_Turq",   (0.00, 0.78, 0.82, 1.0), 0.22)
    m_cobalt = get_material("Mat_Sam_Cobalt", (0.10, 0.38, 0.82, 1.0), 0.25)
    m_gold   = get_material("Mat_Sam_Gold",   (0.98, 0.84, 0.18, 1.0), 0.18, 0.75)
    m_door   = get_material("Mat_Sam_Door",   (0.30, 0.18, 0.12, 1.0), 0.50)

    # Base Plinth
    parts.append(create_box("Base", (2.8, 2.5, 0.35), (0, 0, 0.175), m_sand))
    # Madrasa Courtyard Body
    parts.append(create_box("Block", (2.2, 1.8, 1.4), (0, 0, 1.05), m_sand))

    # Monumental Pishtaq Entrance Portal
    parts.append(create_box("PishtaqFrame", (1.55, 0.45, 2.5), (0, -0.80, 1.55), m_cobalt))
    parts.append(create_box("PishtaqNiche", (1.00, 0.50, 1.7), (0, -0.80, 1.15), m_sand))
    parts.append(create_box("PishtaqDoor",  (0.60, 0.16, 0.95), (0, -0.82, 0.78), m_door))
    parts.append(create_box("PishtaqTop",   (1.65, 0.50, 0.22), (0, -0.80, 2.85), m_turq))
    parts.append(create_box("PishtaqGold",  (1.68, 0.52, 0.08), (0, -0.80, 2.98), m_gold))

    # Ribbed Fluted Turquoise Melon Dome
    parts.append(create_cylinder("DomeDrum", 0.72, 0.50, (0, 0.30, 2.0), m_sand, 20))
    parts.append(create_cylinder("DomeBand", 0.76, 0.12, (0, 0.30, 2.15), m_cobalt, 20))
    parts.append(create_sphere("TurqDome", 0.85, (0, 0.30, 2.58), m_turq, 22, 18))
    parts.append(create_cone("DomeSpire", 0.20, 0.70, (0, 0.30, 3.35), m_gold, 14))
    parts.append(create_sphere("SpireBall", 0.12, (0, 0.30, 3.75), m_gold, 10, 8))

    # 2 Flanking Tall Patterned Minarets
    for i, mx in enumerate([-1.25, 1.25]):
        my = -0.75
        parts.append(create_cylinder(f"Minaret_{i}", 0.24, 3.0, (mx, my, 1.50), m_sand, 16))
        parts.append(create_cylinder(f"MinRing1_{i}", 0.28, 0.15, (mx, my, 1.8), m_cobalt, 16))
        parts.append(create_cylinder(f"MinRing2_{i}", 0.28, 0.15, (mx, my, 2.7), m_cobalt, 16))
        parts.append(create_cylinder(f"MinBalcony_{i}", 0.32, 0.12, (mx, my, 3.0), m_gold, 16))
        parts.append(create_cone(f"MinCap_{i}", 0.26, 0.65, (mx, my, 3.40), m_turq, 16))
        parts.append(create_sphere(f"MinBall_{i}", 0.10, (mx, my, 3.78), m_gold, 8, 6))

    join_and_export_fbx(["castle_samarkand.fbx", "castle_medium.fbx"], parts)

# ==============================================================================
# 4. DUBAI / GOLDEN ROYAL PALACE (Dazzling Gold Onion Domes, White Terraces)
# ==============================================================================
def build_castle_dubai():
    reset_scene()
    parts = []

    m_white  = get_material("Mat_Dub_White", (0.98, 0.98, 0.98, 1.0), 0.28)
    m_gold   = get_material("Mat_Dub_Gold",  (0.98, 0.78, 0.14, 1.0), 0.14, 0.85)
    m_dgold  = get_material("Mat_Dub_DGold", (0.86, 0.62, 0.10, 1.0), 0.18, 0.80)
    m_base   = get_material("Mat_Dub_Base",  (0.90, 0.87, 0.82, 1.0), 0.42)
    m_arch   = get_material("Mat_Dub_Arch",  (0.20, 0.26, 0.38, 1.0), 0.30)

    # Wide Terrace Base
    parts.append(create_box("Terrace", (3.2, 2.8, 0.35), (0, 0, 0.175), m_base))
    parts.append(create_box("TerraceStep", (2.8, 2.4, 0.20), (0, 0, 0.45), m_white))

    # Main Palace Hall
    parts.append(create_box("Hall1", (2.4, 2.0, 1.3), (0, 0, 1.20), m_white))
    parts.append(create_box("Cornice1", (2.5, 2.1, 0.12), (0, 0, 1.90), m_gold))

    # Upper Pavilion Terrace
    parts.append(create_box("Hall2", (1.8, 1.5, 0.85), (0, 0, 2.35), m_white))
    parts.append(create_box("Cornice2", (1.9, 1.6, 0.10), (0, 0, 2.82), m_gold))

    # Grand Golden Onion Dome
    parts.append(create_cylinder("DomeDrum", 0.75, 0.45, (0, 0, 3.08), m_white, 22))
    parts.append(create_sphere("GoldOnionDome", 0.90, (0, 0, 3.65), m_gold, 24, 18))
    parts.append(create_cone("GoldSpire", 0.22, 1.0, (0, 0, 4.60), m_dgold, 16))
    parts.append(create_sphere("SpireCrescent", 0.12, (0, 0, 5.15), m_gold, 12, 8))

    # 2 Flanking Golden Minarets
    for i, mx in enumerate([-1.3, 1.3]):
        my = -0.8
        parts.append(create_cylinder(f"GMin_{i}", 0.22, 2.8, (mx, my, 1.40), m_white, 16))
        parts.append(create_cylinder(f"GBalcony_{i}", 0.30, 0.15, (mx, my, 2.65), m_gold, 16))
        parts.append(create_sphere(f"GDome_{i}", 0.28, (mx, my, 2.95), m_gold, 16, 12))
        parts.append(create_cone(f"GSpire_{i}", 0.08, 0.55, (mx, my, 3.35), m_dgold, 12))

    # Arched Arabesque Loggia (Front Portal)
    parts.append(create_box("LoggiaFrame", (1.2, 0.30, 1.1), (0, -1.05, 1.10), m_gold))
    parts.append(create_box("LoggiaNiche", (0.85, 0.35, 0.88), (0, -1.05, 0.98), m_arch))

    join_and_export_fbx("castle_dubai.fbx", parts)

# ==============================================================================
# 5. COASTAL LIGHTHOUSE (Red/White Striped Tower with Glowing Glass Cupola)
# ==============================================================================
def build_lighthouse():
    reset_scene()
    parts = []

    m_rock   = get_material("Mat_Light_Rock",  (0.48, 0.50, 0.54, 1.0), 0.65)
    m_white  = get_material("Mat_Light_White", (0.98, 0.98, 0.98, 1.0), 0.30)
    m_red    = get_material("Mat_Light_Red",   (0.90, 0.18, 0.22, 1.0), 0.28)
    m_dark   = get_material("Mat_Light_Dark",  (0.18, 0.20, 0.24, 1.0), 0.35)
    m_glass  = get_material("Mat_Light_Glass", (0.99, 0.92, 0.40, 1.0), 0.12)
    m_gold   = get_material("Mat_Light_Gold",  (0.98, 0.84, 0.16, 1.0), 0.15, 0.80)

    # Rocky Plinth Foundation
    parts.append(create_cylinder("RockBase", 1.4, 0.5, (0, 0, 0.25), m_rock, 10))

    # Tapered Striped Tower Tiers (alternating White & Red)
    stripes = [
        (0.85, 0.80, 0.8, 0.85, m_white),
        (0.80, 0.75, 0.8, 1.65, m_red),
        (0.75, 0.70, 0.8, 2.45, m_white),
        (0.70, 0.65, 0.8, 3.25, m_red),
        (0.65, 0.62, 0.7, 4.00, m_white)
    ]
    for i, (r_bot, r_top, h, z, mat) in enumerate(stripes):
        parts.append(create_cone(f"Tier_{i}", r_bot, h, (0, 0, z), mat, 18))

    # Upper Metal Gallery & Railing
    parts.append(create_cylinder("Balcony", 0.82, 0.12, (0, 0, 4.40), m_dark, 18))
    parts.append(create_cylinder("Railing", 0.80, 0.28, (0, 0, 4.58), m_dark, 18))

    # Glowing Glass Lantern Chamber
    parts.append(create_cylinder("LanternGlass", 0.50, 0.60, (0, 0, 4.75), m_glass, 16))

    # Metal Roof Cupola & Finial
    parts.append(create_cone("CupolaRoof", 0.62, 0.55, (0, 0, 5.30), m_dark, 18))
    parts.append(create_sphere("CupolaFinial", 0.10, (0, 0, 5.65), m_gold, 10, 8))

    join_and_export_fbx("lighthouse.fbx", parts)

# ==============================================================================
# 6. TREE STYLIZED PINE (3-Tier Flared Lush Cartoon Pine)
# ==============================================================================
def build_tree_pine():
    reset_scene()
    parts = []

    m_bark  = get_material("Mat_Pine_Bark", (0.36, 0.22, 0.14, 1.0), 0.55)
    m_pine1 = get_material("Mat_Pine_Low",  (0.12, 0.44, 0.18, 1.0), 0.38)
    m_pine2 = get_material("Mat_Pine_Mid",  (0.18, 0.56, 0.24, 1.0), 0.38)
    m_pine3 = get_material("Mat_Pine_Top",  (0.24, 0.68, 0.28, 1.0), 0.38)

    parts.append(create_cylinder("Trunk", 0.15, 0.8, (0, 0, 0.40), m_bark, 10))
    parts.append(create_cone("Flare", 0.24, 0.25, (0, 0, 0.12), m_bark, 10))
    parts.append(create_cone("Tier1", 0.85, 0.80, (0, 0, 0.95), m_pine1, 14))
    parts.append(create_cone("Tier2", 0.68, 0.70, (0, 0, 1.45), m_pine2, 14))
    parts.append(create_cone("Tier3", 0.48, 0.60, (0, 0, 1.90), m_pine3, 14))

    join_and_export_fbx("tree_stylized_pine.fbx", parts)

# ==============================================================================
# 7. TREE STYLIZED ROUND (Fluffy Multi-Sphere Deciduous Canopy)
# ==============================================================================
def build_tree_round():
    reset_scene()
    parts = []

    m_bark  = get_material("Mat_Round_Bark", (0.38, 0.24, 0.15, 1.0), 0.55)
    m_leaf1 = get_material("Mat_Leaf_Low",   (0.16, 0.52, 0.20, 1.0), 0.35)
    m_leaf2 = get_material("Mat_Leaf_Mid",   (0.25, 0.68, 0.26, 1.0), 0.35)
    m_leaf3 = get_material("Mat_Leaf_High",  (0.36, 0.80, 0.32, 1.0), 0.35)

    parts.append(create_cylinder("Trunk", 0.16, 1.1, (0, 0, 0.55), m_bark, 10))
    parts.append(create_sphere("CanopyMain", 0.82, (0, 0, 1.55), m_leaf2, 18, 14))
    parts.append(create_sphere("ClusterL",   0.55, (-0.45, 0.15, 1.40), m_leaf1, 14, 10))
    parts.append(create_sphere("ClusterR",   0.58, ( 0.45, -0.15, 1.45), m_leaf2, 14, 10))
    parts.append(create_sphere("ClusterF",   0.52, ( 0.10, -0.42, 1.35), m_leaf1, 14, 10))
    parts.append(create_sphere("ClusterT",   0.50, ( 0.05, 0.05, 1.95),  m_leaf3, 14, 10))

    join_and_export_fbx("tree_stylized_round.fbx", parts)

# ==============================================================================
# 8. ROCK STYLIZED (Faceted Low-Poly Boulder)
# ==============================================================================
def build_rock():
    reset_scene()
    parts = []

    m_rock1 = get_material("Mat_Rock_Main", (0.55, 0.58, 0.62, 1.0), 0.60)
    m_rock2 = get_material("Mat_Rock_Dark", (0.42, 0.44, 0.48, 1.0), 0.65)

    parts.append(create_sphere("MainRock", 0.75, (0, 0, 0.42), m_rock1, 8, 6))
    parts.append(create_sphere("SubRock1", 0.48, (0.50, 0.20, 0.25), m_rock2, 7, 5))
    parts.append(create_sphere("SubRock2", 0.35, (-0.42, -0.30, 0.20), m_rock1, 7, 5))

    join_and_export_fbx("rock_stylized.fbx", parts)

# ==============================================================================
# 9. WOODEN ARCHED BRIDGE (Planks, Railings, Support Pilings)
# ==============================================================================
def build_bridge():
    reset_scene()
    parts = []

    m_plank = get_material("Mat_Brdg_Plank", (0.52, 0.34, 0.20, 1.0), 0.48)
    m_dark  = get_material("Mat_Brdg_Dark",  (0.32, 0.20, 0.12, 1.0), 0.55)

    # 13 Arched Cross Planks
    num_planks = 13
    span = 2.4
    arch_h = 0.38
    for i in range(num_planks):
        t = (i / (num_planks - 1)) * 2.0 - 1.0
        x = t * (span * 0.5)
        z = (1.0 - t * t) * arch_h + 0.15
        tilt = math.atan(-2.0 * t * arch_h / (span * 0.5))
        p = create_box(f"Plank_{i}", (0.16, 1.15, 0.06), (x, 0, z), m_plank, rot=(0, tilt, 0))
        parts.append(p)

    # Left and Right Handrails
    xs = [-1.2, -0.8, -0.4, 0.0, 0.4, 0.8, 1.2]
    zs = [(1.0 - (x / 1.2)**2) * arch_h + 0.15 for x in xs]
    for side, y in [("Left", -0.56), ("Right", 0.56)]:
        for i in range(len(xs)):
            parts.append(create_cylinder(f"Post_{side}_{i}", 0.04, 0.45, (xs[i], y, zs[i] + 0.22), m_dark, 8))
        for i in range(len(xs) - 1):
            xmid = (xs[i] + xs[i+1]) * 0.5
            zmid = (zs[i] + zs[i+1]) * 0.5 + 0.42
            dx = xs[i+1] - xs[i]
            dz = zs[i+1] - zs[i]
            seg_len = math.sqrt(dx*dx + dz*dz)
            ang = math.atan2(dz, dx)
            r = create_box(f"Rail_{side}_{i}", (seg_len, 0.07, 0.07), (xmid, y, zmid), m_dark, rot=(0, -ang, 0))
            parts.append(r)

    # Support Pilings
    parts.append(create_cylinder("Piling_1", 0.08, 0.8, (-0.65, -0.55, 0.15), m_dark, 8))
    parts.append(create_cylinder("Piling_2", 0.08, 0.8, (-0.65,  0.55, 0.15), m_dark, 8))
    parts.append(create_cylinder("Piling_3", 0.08, 0.8, ( 0.65, -0.55, 0.15), m_dark, 8))
    parts.append(create_cylinder("Piling_4", 0.08, 0.8, ( 0.65,  0.55, 0.15), m_dark, 8))

    join_and_export_fbx("bridge_wooden.fbx", parts)

# ==============================================================================
# 10. ALPINE SNOWY MOUNTAIN (Majestic Alpine Mountain Peak)
# ==============================================================================
def build_mountain():
    reset_scene()
    parts = []

    m_rock = get_material("Mat_Mnt_Rock", (0.44, 0.48, 0.54, 1.0), 0.65)
    m_snow = get_material("Mat_Mnt_Snow", (0.97, 0.98, 1.00, 1.0), 0.28)

    parts.append(create_cone("MntBase", 3.4, 5.2, (0, 0, 2.6), m_rock, 10))
    parts.append(create_cone("Shoulder1", 2.0, 3.6, (1.6, -0.6, 1.8), m_rock, 8))
    parts.append(create_cone("Shoulder2", 1.8, 3.2, (-1.5, 0.8, 1.6), m_rock, 8))
    parts.append(create_cone("SnowCapMain", 1.6, 2.4, (0, 0, 4.3), m_snow, 10))
    parts.append(create_cone("SnowCapShld", 0.9, 1.6, (1.6, -0.6, 3.1), m_snow, 8))

    join_and_export_fbx("mountain_snowy.fbx", parts)

# ==============================================================================
# 11. CHARACTER BALL (Cute Stylized Ball with Anime Eyes, Smile, Antenna)
# ==============================================================================
def build_character():
    reset_scene()
    parts = []

    m_skin   = get_material("Mat_Char_Skin",  (0.10, 0.65, 1.00, 1.0), 0.18)
    m_white  = get_material("Mat_Char_White", (0.98, 0.98, 0.98, 1.0), 0.12)
    m_pupil  = get_material("Mat_Char_Pupil", (0.05, 0.08, 0.16, 1.0), 0.12)
    m_mouth  = get_material("Mat_Char_Mouth", (0.12, 0.06, 0.08, 1.0), 0.25)
    m_gold   = get_material("Mat_Char_Gold",  (0.98, 0.82, 0.16, 1.0), 0.15, 0.75)

    # Smooth Sphere Body
    parts.append(create_sphere("Body", 0.50, (0, 0, 0.50), m_skin, 24, 18))

    # Anime Eyes (Looking towards -Y in Blender -> +Z in Unity)
    for eye_x, name in [(-0.16, "Left"), (0.16, "Right")]:
        parts.append(create_sphere(f"EyeWhite_{name}", 0.13, (eye_x, -0.42, 0.58), m_white, 14, 10))
        parts.append(create_sphere(f"Pupil_{name}", 0.09, (eye_x, -0.485, 0.58), m_pupil, 12, 8))
        parts.append(create_sphere(f"Sparkle1_{name}", 0.040, (eye_x - 0.025, -0.515, 0.625), m_white, 8, 6))
        parts.append(create_sphere(f"Sparkle2_{name}", 0.022, (eye_x + 0.035, -0.510, 0.535), m_white, 8, 6))

    # Happy Mouth
    parts.append(create_cylinder("SmileMouth", 0.075, 0.08, (0, -0.49, 0.44), m_mouth, 12, rot=(math.radians(90), 0, 0)))

    # Golden Antenna with Glowing Orb
    parts.append(create_cylinder("AntennaPole", 0.025, 0.45, (0, 0, 1.15), m_white, 8))
    parts.append(create_sphere("AntennaOrb", 0.09, (0, 0, 1.40), m_gold, 12, 8))

    join_and_export_fbx("character_ball.fbx", parts)

# ==============================================================================
# 12. TRAIL BEAD (Neutral Procedural Bead Mesh)
# ==============================================================================
def build_trail_bead():
    reset_scene()
    parts = []

    m_bead = get_material("Mat_Bead_Gloss", (1.0, 1.0, 1.0, 1.0), 0.16)
    bead = create_sphere("TrailBead", 0.44, (0, 0, 0.35), m_bead, 20, 16)
    parts.append(bead)

    join_and_export_fbx("trail_bead.fbx", parts)

if __name__ == "__main__":
    print("=== BUILDING ALL 12 ENHANCED FBX 3D MODELS IN BLENDER 4.2 ===")
    build_castle_berlin()
    build_castle_tashkent()
    build_castle_samarkand()
    build_castle_dubai()
    build_lighthouse()
    build_tree_pine()
    build_tree_round()
    build_rock()
    build_bridge()
    build_mountain()
    build_character()
    build_trail_bead()
    print("=== ALL 12 MODELS BUILT AND EXPORTED SUCCESSFULLY ===")
